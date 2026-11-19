extends Node

const MAIN_MENU_SCENE := preload("res://scenes/ui/main_menu.tscn")
const CREATE_WORLD_SCENE := preload("res://scenes/ui/create_world.tscn")
const GENERATION_SCENE := preload("res://scenes/ui/generation.tscn")
const HUD_SCENE := preload("res://scenes/ui/game_hud.tscn")
const VICTORY_SCENE := preload("res://scenes/ui/victory.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/settings.tscn")
const ABOUT_SCENE := preload("res://scenes/ui/about.tscn")
const WORLD_SCENE := preload("res://scenes/world/generated_world.tscn")

@onready var world_root: Node3D = $WorldRoot
@onready var interface: CanvasLayer = $Interface

var current_screen: Control
var world_instance: WorldBuilder
var menu_preview: MenuPreview
var llm_service: LLMWorldService
var hud: GameHUD
var gameplay_active := false
var last_description := ""
var last_options: Dictionary = {}
var last_demo_path := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	llm_service = LLMWorldService.new()
	add_child(llm_service)
	menu_preview = MenuPreview.new()
	world_root.add_child(menu_preview)
	show_main_menu()
	AppLogger.info("Application started. Catalog %s." % ResourceCatalog.version())

func show_main_menu() -> void:
	gameplay_active = false
	_clear_world()
	AppState.clear_world()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_preview.set_active(true)
	var screen := MAIN_MENU_SCENE.instantiate() as MainMenu
	_set_screen(screen)
	screen.set_api_status(llm_service.is_configured())
	screen.create_requested.connect(func(): show_create_world(false))
	screen.examples_requested.connect(func(): show_create_world(true))
	screen.settings_requested.connect(show_settings)
	screen.about_requested.connect(show_about)

func show_create_world(focus_examples: bool = false) -> void:
	gameplay_active = false
	_clear_world()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_preview.set_active(true)
	var screen := CREATE_WORLD_SCENE.instantiate() as CreateWorldScreen
	_set_screen(screen)
	screen.set_api_available(llm_service.is_configured())
	if focus_examples:
		screen.focus_examples()
	screen.back_requested.connect(show_main_menu)
	screen.generate_requested.connect(_on_generate_requested)
	screen.demo_requested.connect(_on_demo_requested)

func show_settings() -> void:
	var screen := SETTINGS_SCENE.instantiate() as SettingsScreen
	_set_screen(screen)
	screen.back_requested.connect(show_main_menu)

func show_about() -> void:
	var screen := ABOUT_SCENE.instantiate() as AboutScreen
	_set_screen(screen)
	screen.back_requested.connect(show_main_menu)

func _on_generate_requested(description: String, options: Dictionary) -> void:
	last_description = description
	last_options = options.duplicate(true)
	last_demo_path = ""
	_start_generation_screen(description, str(options.get("mode", "offline")))
	_run_generation.call_deferred()

func _on_demo_requested(path: String, description: String) -> void:
	last_description = description
	last_options = {"mode": "demo"}
	last_demo_path = path
	_start_generation_screen(description, "demo")
	_run_generation.call_deferred()

func _start_generation_screen(description: String, mode: String) -> void:
	var screen := GENERATION_SCENE.instantiate() as GenerationScreen
	_set_screen(screen)
	screen.begin(description.left(42), mode)
	screen.back_requested.connect(func(): show_create_world(false))
	screen.retry_requested.connect(_retry_generation)

func _retry_generation() -> void:
	_start_generation_screen(last_description, str(last_options.get("mode", "offline")))
	_run_generation.call_deferred()

func _run_generation() -> void:
	var generation := current_screen as GenerationScreen
	if generation == null:
		return
	var mode := str(last_options.get("mode", "offline"))
	var world: Dictionary = {}
	generation.set_stage(0, "Анализируем твою идею и параметры...")
	await get_tree().create_timer(0.18).timeout
	if mode == "demo":
		var loaded := SaveService.load_world(last_demo_path)
		if not loaded.ok:
			_generation_error(str(loaded.error))
			return
		world = loaded.world
	elif mode == "ai":
		if not llm_service.is_configured():
			_generation_error("AI API не настроен. Игра не подменяет AI заранее подготовленным уровнем: настройте API или выберите офлайн-алгоритм.")
			return
		generation.set_stage(0, "Подключение к LLM API • %s" % llm_service.model)
		var ai_result: Dictionary = await llm_service.generate_world(last_description, last_options)
		if not ai_result.ok:
			AppLogger.error("AI generation failed: %s" % str(ai_result.error))
			_generation_error(str(ai_result.error))
			return
		world = ai_result.world
	else:
		world = ProceduralGenerator.generate(last_description, last_options)
	generation = current_screen as GenerationScreen
	if generation == null:
		return
	generation.set_stage(1, "Каталог проверен • разрешённые resource_id подобраны")
	await get_tree().create_timer(0.14).timeout
	generation.set_stage(2, "Карта %d×%d • seed %d" % [int(world.map.width), int(world.map.depth), int(world.seed)])
	await get_tree().create_timer(0.14).timeout
	generation.set_stage(3, "Проверяем границы, пересечения и маршруты BFS...")
	var validation := WorldValidator.validate(world)
	if not validation.valid:
		var repair := WorldValidator.validate_and_repair(world)
		if repair.valid:
			world = repair.world
			AppLogger.warning("World auto-repaired: %s" % "; ".join(repair.repairs))
		else:
			_generation_error("Уровень отклонён валидатором:\n• " + "\n• ".join(repair.errors))
			return
	await get_tree().create_timer(0.16).timeout
	generation.set_stage(4, "Размещаем физику, освещение, объекты и игрока...")
	var save := SaveService.save_world(world, last_description, mode)
	if save.ok:
		AppState.last_save_path = str(save.path)
	else:
		AppLogger.warning("World save failed: %s" % str(save.error))
	await _build_and_launch(world, last_description, mode)

func _build_and_launch(world: Dictionary, description: String, mode: String) -> void:
	_clear_world()
	menu_preview.set_active(false)
	AppState.begin_world(world, description, mode)
	world_instance = WORLD_SCENE.instantiate() as WorldBuilder
	world_root.add_child(world_instance)
	var stats := world_instance.build(world)
	world_instance.exit_reached.connect(_on_exit_reached)
	world_instance.player.pause_requested.connect(_toggle_pause)
	var generation := current_screen as GenerationScreen
	if generation:
		generation.complete()
	AppLogger.info("World built in %.2f ms with %d objects." % [float(stats.build_ms), int(stats.objects)])
	await get_tree().create_timer(0.45).timeout
	_show_hud()

func _show_hud() -> void:
	gameplay_active = true
	hud = HUD_SCENE.instantiate() as GameHUD
	_set_screen(hud)
	hud.resume_requested.connect(_toggle_pause)
	hud.menu_requested.connect(show_main_menu)
	hud.new_world_requested.connect(func(): show_create_world(false))
	if world_instance and world_instance.player:
		world_instance.player.interaction_hint_changed.connect(hud.set_interaction_hint)
		world_instance.player.set_control_enabled(true)

func _toggle_pause() -> void:
	if not gameplay_active or hud == null:
		return
	var paused := not hud.is_paused()
	hud.set_pause(paused)
	if world_instance and world_instance.player:
		world_instance.player.set_control_enabled(not paused)

func _on_exit_reached() -> void:
	if not gameplay_active:
		return
	if not AppState.can_exit():
		AppState.toast_requested.emit("Сначала найди все три предмета!")
		return
	gameplay_active = false
	var completion := AppState.finish_world()
	if world_instance and world_instance.player:
		world_instance.player.set_control_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var victory := VICTORY_SCENE.instantiate() as VictoryScreen
	_set_screen(victory)
	victory.set_result(str(AppState.current_world.get("world_name", "Мир")), completion)
	victory.replay_requested.connect(_replay_world)
	victory.new_world_requested.connect(func(): show_create_world(false))
	victory.menu_requested.connect(show_main_menu)

func _replay_world() -> void:
	if AppState.current_world.is_empty():
		show_main_menu()
		return
	var data := AppState.current_world.duplicate(true)
	var description := AppState.current_description
	var mode := AppState.generation_mode
	_start_generation_screen(description, mode)
	var generation := current_screen as GenerationScreen
	generation.set_stage(4, "Пересобираем сохранённый мир...")
	await _build_and_launch(data, description, mode)

func _generation_error(message: String) -> void:
	var generation := current_screen as GenerationScreen
	if generation:
		generation.show_error(message)

func _set_screen(screen: Control) -> void:
	if current_screen and is_instance_valid(current_screen):
		interface.remove_child(current_screen)
		current_screen.queue_free()
	current_screen = screen
	interface.add_child(current_screen)

func _clear_world() -> void:
	if world_instance and is_instance_valid(world_instance):
		world_root.remove_child(world_instance)
		world_instance.queue_free()
	world_instance = null
	hud = null
