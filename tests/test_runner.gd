extends Node

const DEMO_PATHS := [
	"res://data/examples/01_enchanted_forest.json",
	"res://data/examples/02_abandoned_castle.json",
	"res://data/examples/03_mars_station.json",
	"res://data/examples/04_ancient_temple.json",
	"res://data/examples/05_ice_cave.json"
]

const THEME_DESCRIPTIONS := {
	"fantasy_forest": "Создай сказочный лес с гигантскими деревьями, грибами и озером.",
	"abandoned_castle": "Создай заброшенный замок с башнями, руинами и древними воротами.",
	"mars_station": "Создай марсианскую станцию с роботами и энергетическими батареями.",
	"ancient_temple": "Создай подземелье древнего храма с колоннами и сокровищами.",
	"ice_cave": "Создай ледяную пещеру со снегом, кристаллами и ледяными шпилями."
}

var _passed := 0
var _failed := 0
var _results: Array[Dictionary] = []
var _started_at := 0
var _build_times: Array[float] = []

func _ready() -> void:
	_started_at = Time.get_ticks_msec()
	call_deferred("_run_all")

func _run_all() -> void:
	await get_tree().process_frame
	print("\n=== AI WORLD GENERATOR: AUTOMATED TESTS ===")
	_test_catalog()
	var demos := _test_demo_json()
	_test_procedural_generation()
	_test_pathfinder()
	_test_validator_failures(demos[0])
	_test_validator_repair(demos[0])
	_test_llm_response_parser()
	_test_game_rules(demos[0])
	_test_save_and_load(demos[0])
	_test_logging()
	_test_player_contract()
	await _test_player_physics()
	await _test_ui_scenes()
	await _test_world_builds(demos)
	_finish()

func _test_catalog() -> void:
	var catalog := ResourceCatalog.data()
	_check(not catalog.is_empty(), "Каталог ресурсов загружается")
	_check(ResourceCatalog.version() == "1.0", "Версия каталога — 1.0")
	_check(ResourceCatalog.THEMES.size() == 5, "Каталог содержит пять тем")
	var resources: Dictionary = catalog.get("resources", {})
	_check(resources.size() == 31, "Каталог содержит 31 разрешённый ресурс")
	for resource_id in resources:
		var definition: Dictionary = resources[resource_id]
		_check(definition.has("category") and definition.has("footprint") and definition.has("size"), "Ресурс %s имеет категорию, footprint и size" % resource_id)
		var footprint := ResourceCatalog.footprint(resource_id, 0)
		var size: Array = definition.get("size", [])
		_check(footprint.x > 0 and footprint.y > 0 and size.size() == 3, "Габариты ресурса %s корректны" % resource_id)

func _test_demo_json() -> Array[Dictionary]:
	var demos: Array[Dictionary] = []
	for path in DEMO_PATHS:
		var loaded := SaveService.load_world(path)
		_check(bool(loaded.get("ok", false)), "Демо JSON загружается: %s" % path.get_file())
		if not loaded.get("ok", false):
			continue
		var world: Dictionary = loaded.world
		var validation := WorldValidator.validate(world)
		_check(bool(validation.valid), "Демо проходит строгую валидацию и BFS: %s" % path.get_file(), "Ошибки: %s" % str(validation.errors))
		_check(world.collectibles.size() == 3, "В демо ровно три предмета: %s" % path.get_file())
		demos.append(world)
	_check(demos.size() == 5, "Все пять офлайн-миров готовы к запуску")
	return demos

func _test_procedural_generation() -> void:
	var generated_worlds: Array[Dictionary] = []
	var index := 0
	for theme in ResourceCatalog.THEMES:
		var size_id: String = ["small", "medium", "large"][index % 3]
		var density_id: String = ["low", "medium", "high"][index % 3]
		var options := {"theme": theme, "size": size_id, "density": density_id, "difficulty": "normal"}
		var description := str(THEME_DESCRIPTIONS[theme])
		var world := ProceduralGenerator.generate(description, options)
		var validation := WorldValidator.validate(world)
		_check(bool(validation.valid), "Процедурный мир проходим: %s" % theme, "Ошибки: %s" % str(validation.errors))
		_check(str(world.theme_id) == theme, "Запрошенная тема соблюдена: %s" % theme)
		generated_worlds.append(world)
		index += 1
	var repeat_a := ProceduralGenerator.generate("Одинаковый воспроизводимый лес", {"theme": "fantasy_forest", "size": "medium"})
	var repeat_b := ProceduralGenerator.generate("Одинаковый воспроизводимый лес", {"theme": "fantasy_forest", "size": "medium"})
	_check(JSON.stringify(repeat_a) == JSON.stringify(repeat_b), "Одинаковые описание и параметры воспроизводят один мир")
	var small := ProceduralGenerator.generate("Маленький лес", {"theme": "fantasy_forest", "size": "small"})
	var large := ProceduralGenerator.generate("Большой лес", {"theme": "fantasy_forest", "size": "large"})
	_check(int(small.map.width) == 16 and int(large.map.width) == 30, "Параметр размера меняет карту 16×16 / 30×30")
	_check(int(generated_worlds[0].seed) != int(generated_worlds[1].seed), "Разные описания создают разные seed")

func _test_pathfinder() -> void:
	var blocked := {Vector2i(2, 0): true, Vector2i(2, 1): true, Vector2i(2, 2): true, Vector2i(2, 3): true}
	_check(GridPathfinder.path_exists(5, 5, blocked, Vector2i(0, 0), Vector2i(4, 0)), "BFS находит путь вокруг неполной стены")
	blocked[Vector2i(2, 4)] = true
	_check(not GridPathfinder.path_exists(5, 5, blocked, Vector2i(0, 0), Vector2i(4, 0)), "BFS отклоняет путь через сплошную стену")
	var shortest := GridPathfinder.shortest_path(5, 5, {}, Vector2i(0, 0), Vector2i(4, 4))
	_check(shortest.size() == 9, "BFS возвращает кратчайший маршрут")

func _test_validator_failures(baseline: Dictionary) -> void:
	var missing := baseline.duplicate(true)
	missing.erase("map")
	_check(not WorldValidator.validate(missing).valid, "Валидатор отклоняет отсутствующее обязательное поле")

	var extra_root := baseline.duplicate(true)
	extra_root["execute_code"] = "never"
	var extra_root_result := WorldValidator.validate(extra_root)
	_check(not extra_root_result.valid and _contains_text(extra_root_result.errors, "неожиданное поле"), "Строгая схема отклоняет дополнительное корневое поле")

	var extra_placement := baseline.duplicate(true)
	extra_placement.objects[0]["file_path"] = "res://unsafe.glb"
	var extra_placement_result := WorldValidator.validate(extra_placement)
	_check(not extra_placement_result.valid and _contains_text(extra_placement_result.errors, "неожиданное поле"), "Строгая схема отклоняет дополнительное поле объекта")

	var oversized_seed := baseline.duplicate(true)
	oversized_seed.seed = 2147483648
	_check(not WorldValidator.validate(oversized_seed).valid, "Валидатор ограничивает seed диапазоном int32 схемы")

	var unknown := baseline.duplicate(true)
	unknown.objects[0].resource_id = "unknown_model"
	_check(not WorldValidator.validate(unknown).valid, "Валидатор отклоняет неизвестный resource_id")

	var path_injection := baseline.duplicate(true)
	path_injection.objects[0].resource_id = "../../secret.glb"
	var path_result := WorldValidator.validate(path_injection)
	_check(not path_result.valid and _contains_text(path_result.errors, "запрещённый путь"), "Валидатор блокирует пути в resource_id")

	var overlap := baseline.duplicate(true)
	overlap.objects[1].cell_x = overlap.objects[0].cell_x
	overlap.objects[1].cell_z = overlap.objects[0].cell_z
	overlap.objects[1].rotation = overlap.objects[0].rotation
	var overlap_result := WorldValidator.validate(overlap)
	_check(not overlap_result.valid and _contains_text(overlap_result.errors, "пересекается"), "Валидатор обнаруживает пересечение объектов")

	var outside := baseline.duplicate(true)
	outside.collectibles[0].cell_x = int(outside.map.width) + 10
	_check(not WorldValidator.validate(outside).valid, "Валидатор отклоняет координаты вне карты")

	var bad_rotation := baseline.duplicate(true)
	bad_rotation.objects[0].rotation = 45
	_check(not WorldValidator.validate(bad_rotation).valid, "Валидатор отклоняет поворот 45°")

	var bad_type := baseline.duplicate(true)
	bad_type.player_start.cell_x = 1.5
	_check(not WorldValidator.validate(bad_type).valid, "Валидатор отклоняет дробный индекс клетки")

	var barrier := baseline.duplicate(true)
	barrier.objects = []
	for x in int(barrier.map.width):
		barrier.objects.append({"resource_id": "rock_01", "cell_x": x, "cell_z": 2, "rotation": 0})
	var barrier_result := WorldValidator.validate(barrier)
	_check(not barrier_result.valid and _contains_text(barrier_result.errors, "недоступ"), "Проверка проходимости отклоняет сплошной барьер")

func _test_validator_repair(baseline: Dictionary) -> void:
	var unsafe := baseline.duplicate(true)
	unsafe.objects[0].resource_id = "C:\\unsafe\\model.glb"
	var repaired := WorldValidator.validate_and_repair(unsafe)
	_check(bool(repaired.valid), "Автопочинка удаляет объект с опасным ID")
	_check(not repaired.repairs.is_empty(), "Автопочинка формирует понятный журнал изменений")

	var barrier := baseline.duplicate(true)
	barrier.objects = []
	for x in int(barrier.map.width):
		barrier.objects.append({"resource_id": "rock_01", "cell_x": x, "cell_z": 2, "rotation": 0})
	var route_repair := WorldValidator.validate_and_repair(barrier, int(barrier.map.width))
	_check(bool(route_repair.valid), "Автопочинка восстанавливает маршрут удалением блокирующего объекта")

func _test_llm_response_parser() -> void:
	var service := LLMWorldService.new()
	get_tree().root.add_child(service)
	var fenced := service._parse_model_json("```json\n{\"schema_version\":\"1.0\"}\n```")
	_check(bool(fenced.ok), "Парсер принимает JSON в markdown-ограждении")
	var embedded := service._parse_model_json("Ответ: {\"schema_version\":\"1.0\"} конец")
	_check(bool(embedded.ok), "Парсер безопасно извлекает единственный JSON-объект")
	var broken := service._parse_model_json("{сломанный JSON")
	_check(not broken.ok, "Парсер корректно отклоняет повреждённый ответ LLM")
	service.api_url = "http://example.com/v1/chat/completions"
	_check(not service.is_configured(), "Незашифрованный внешний HTTP API запрещён")
	service.api_url = "http://127.0.0.1:11434/v1/chat/completions"
	_check(service.is_configured(), "Локальный OpenAI-compatible API разрешён")
	var prompt := service._build_prompt("Лес с кристаллами", {}, "", "")
	_check("tree_01" in prompt and "crystal_blue" in prompt and "portal_exit" in prompt, "LLM получает белые списки разрешённых ID")
	service.queue_free()

func _test_game_rules(baseline: Dictionary) -> void:
	var rules := GameRules.new()
	_check(rules.collect_once("one"), "Первый сбор предмета засчитывается")
	_check(not rules.collect_once("one") and rules.count() == 1, "Повторный сбор предмета не засчитывается")
	_check(not rules.exit_allowed(), "Выход закрыт при 1/3")
	rules.collect_once("two")
	rules.collect_once("three")
	_check(rules.exit_allowed(), "Выход открыт только при 3/3")
	rules.reset()
	_check(rules.count() == 0 and not rules.exit_allowed(), "Повторная игра полностью сбрасывает правила")

	AppState.begin_world(baseline, "Автотест", "demo")
	_check(AppState.collect("item_1"), "Глобальное состояние принимает уникальный предмет")
	_check(not AppState.collect("item_1"), "Глобальное состояние отклоняет дубликат")
	AppState.collect("item_2")
	_check(not AppState.can_exit(), "Глобальный выход закрыт при 2/3")
	AppState.collect("item_3")
	_check(AppState.can_exit(), "Глобальный выход активируется при 3/3")
	AppState.reset_for_replay()
	_check(AppState.collected_ids.is_empty() and not AppState.can_exit(), "Replay сбрасывает счётчик и выход")

func _test_save_and_load(baseline: Dictionary) -> void:
	var saved := SaveService.save_world(baseline, "Описание из автоматического теста", "test")
	_check(bool(saved.ok), "Сгенерированный JSON сохраняется в user://")
	if saved.ok:
		var loaded := SaveService.load_world(str(saved.path))
		_check(bool(loaded.ok) and WorldValidator.validate(loaded.world).valid, "Сохранённый мир повторно загружается и валидируется")
	_check(not SaveService.load_world("C:/Windows/system.ini").ok, "Загрузка произвольного системного пути запрещена")
	var history := SaveService.load_descriptions()
	_check("Описание из автоматического теста" in history, "История пользовательских описаний сохраняется")

func _test_logging() -> void:
	var marker := "AUTOMATED_TEST_LOG_%d" % Time.get_ticks_msec()
	AppLogger.info(marker)
	var file := FileAccess.open(AppLogger.LOG_PATH, FileAccess.READ)
	_check(file != null, "Журнал приложения создаётся при первой записи")
	var content := file.get_as_text() if file else ""
	_check(marker in content, "Журнал приложения сохраняет сообщение")

func _test_player_contract() -> void:
	var player_scene := load("res://scenes/player/player.tscn") as PackedScene
	var player := player_scene.instantiate() as CharacterBody3D
	_check(player != null, "Игрок использует CharacterBody3D")
	var collision := player.get_node_or_null("Collision") as CollisionShape3D
	_check(collision != null and collision.shape is CapsuleShape3D, "У игрока есть физическая капсула")
	_check(player.get_node_or_null("Head/Camera3D") is Camera3D, "У игрока есть FPS-камера")
	_check(player.is_in_group("player"), "Игрок находится в collision-группе player")
	for action in ["move_forward", "move_back", "move_left", "move_right", "jump", "sprint", "interact", "pause"]:
		_check(InputMap.has_action(action), "Input Map содержит действие %s" % action)
	player.free()

func _test_player_physics() -> void:
	var arena := Node3D.new()
	arena.name = "PhysicsTestArena"
	get_tree().root.add_child(arena)
	var floor := StaticBody3D.new()
	floor.collision_layer = 1
	arena.add_child(floor)
	VisualFactory.add_collision_box(floor, Vector3(20, 0.4, 20), Vector3(0, -0.2, 0))
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	arena.add_child(wall)
	VisualFactory.add_collision_box(wall, Vector3(4, 3, 0.5), Vector3(0, 1.5, -2.0))
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as FPSPlayer
	arena.add_child(player)
	for frame in 5:
		await get_tree().physics_frame
	_check(player.is_on_floor(), "Игрок корректно определяется на полу")
	var start_z := player.position.z
	Input.action_press("move_forward")
	for frame in 12:
		await get_tree().physics_frame
	Input.action_release("move_forward")
	_check(player.position.z < start_z - 0.05, "WASD фактически перемещает CharacterBody3D")
	Input.action_press("move_forward")
	for frame in 90:
		await get_tree().physics_frame
	Input.action_release("move_forward")
	_check(player.position.z > -1.75 and player.position.z < -0.7, "Физическая капсула останавливается у стены и не проходит сквозь неё")
	player.position = Vector3.ZERO
	player.velocity = Vector3.ZERO
	for frame in 5:
		await get_tree().physics_frame
	Input.action_press("jump")
	await get_tree().physics_frame
	Input.action_release("jump")
	var highest_y := player.position.y
	for frame in 18:
		await get_tree().physics_frame
		highest_y = maxf(highest_y, player.position.y)
	_check(highest_y > 0.2, "Space фактически запускает прыжок с гравитацией")
	var old_yaw := player.rotation.y
	var old_pitch := player.head.rotation.x
	player._apply_mouse_look(Vector2(24, 12))
	_check(not is_equal_approx(player.rotation.y, old_yaw) and not is_equal_approx(player.head.rotation.x, old_pitch), "Движение мыши изменяет yaw и ограниченный pitch камеры")
	player._apply_mouse_look(Vector2(0, 100000))
	_check(player.head.rotation.x >= deg_to_rad(-86.01), "Вертикальный обзор мышью ограничен углом 86°")
	var pause_seen := [false]
	player.pause_requested.connect(func(): pause_seen[0] = true)
	var pause_event := InputEventAction.new()
	pause_event.action = "pause"
	pause_event.pressed = true
	player._unhandled_input(pause_event)
	_check(bool(pause_seen[0]), "Esc вызывает сигнал паузы")
	arena.queue_free()
	await get_tree().process_frame

func _test_ui_scenes() -> void:
	var scenes := [
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/ui/create_world.tscn",
		"res://scenes/ui/generation.tscn",
		"res://scenes/ui/game_hud.tscn",
		"res://scenes/ui/settings.tscn",
		"res://scenes/ui/about.tscn",
		"res://scenes/ui/victory.tscn"
	]
	for path in scenes:
		var packed := load(path) as PackedScene
		var screen := packed.instantiate()
		get_tree().root.add_child(screen)
		await get_tree().process_frame
		_check(screen is Control and screen.get_child_count() > 0, "UI-сцена создаётся: %s" % path.get_file())
		if path.ends_with("create_world.tscn"):
			await get_tree().process_frame
			var viewport_size: Vector2 = screen.get_viewport_rect().size
			var generate := screen.find_child("GenerateButton", true, false) as Button
			var demos: Array[Node] = screen.find_children("DemoButton*", "Button", true, false)
			_check(generate != null, "Кнопка генерации существует в адаптивном конструкторе")
			_check(demos.size() == 5, "Все пять кнопок демо созданы")
			if generate:
				_check(_control_inside_viewport(generate, viewport_size), "Кнопка «СГЕНЕРИРОВАТЬ МИР» видна при 1280×720", "rect=%s viewport=%s" % [str(generate.get_global_rect()), str(viewport_size)])
			for index in demos.size():
				var demo_button := demos[index] as Button
				_check(_control_inside_viewport(demo_button, viewport_size), "Кнопка демо %d видна при 1280×720" % (index + 1), "rect=%s viewport=%s" % [str(demo_button.get_global_rect()), str(viewport_size)])
			for first_index in demos.size():
				for second_index in range(first_index + 1, demos.size()):
					var first_button := demos[first_index] as Button
					var second_button := demos[second_index] as Button
					_check(not first_button.get_global_rect().intersects(second_button.get_global_rect()), "Кнопки демо %d и %d не перекрываются" % [first_index + 1, second_index + 1])
			var narrow_viewport := SubViewport.new()
			narrow_viewport.size = Vector2i(900, 600)
			narrow_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			get_tree().root.add_child(narrow_viewport)
			var narrow_screen := packed.instantiate() as CreateWorldScreen
			narrow_viewport.add_child(narrow_screen)
			await get_tree().process_frame
			await get_tree().process_frame
			var narrow_generate := narrow_screen.find_child("GenerateButton", true, false) as Button
			var narrow_demos: Array[Node] = narrow_screen.find_children("DemoButton*", "Button", true, false)
			_check(narrow_screen.main_layout.vertical, "При узком окне панели перестраиваются вертикально")
			_check(_control_inside_viewport_horizontally(narrow_generate, Vector2(900, 600)), "Кнопка генерации не обрезается по горизонтали при 900×600")
			for demo_node in narrow_demos:
				_check(_control_inside_viewport_horizontally(demo_node as Control, Vector2(900, 600)), "Кнопка демо не обрезается по горизонтали при 900×600")
			narrow_screen.page_scroll.ensure_control_visible(narrow_generate)
			await get_tree().process_frame
			await get_tree().process_frame
			_check(_control_inside_viewport(narrow_generate, Vector2(900, 600)), "Кнопка генерации доступна через прокрутку при 900×600")
			var first_narrow_demo := narrow_demos[0] as Button
			narrow_screen.page_scroll.ensure_control_visible(first_narrow_demo)
			await get_tree().process_frame
			await get_tree().process_frame
			_check(_control_inside_viewport(first_narrow_demo, Vector2(900, 600)), "Демо-кнопки доступны через прокрутку при 900×600")
			narrow_viewport.queue_free()
			await get_tree().process_frame
		screen.queue_free()
		await get_tree().process_frame

func _control_inside_viewport(control: Control, viewport_size: Vector2) -> bool:
	var rect := control.get_global_rect()
	return control.is_visible_in_tree() and rect.position.x >= -0.5 and rect.position.y >= -0.5 and rect.position.x + rect.size.x <= viewport_size.x + 0.5 and rect.position.y + rect.size.y <= viewport_size.y + 0.5

func _control_inside_viewport_horizontally(control: Control, viewport_size: Vector2) -> bool:
	var rect := control.get_global_rect()
	return control.is_visible_in_tree() and rect.position.x >= -0.5 and rect.position.x + rect.size.x <= viewport_size.x + 0.5

func _test_world_builds(demos: Array[Dictionary]) -> void:
	var packed := load("res://scenes/world/generated_world.tscn") as PackedScene
	for index in demos.size():
		var world: Dictionary = demos[index]
		AppState.begin_world(world, "Автотест 3D-сборки", "demo")
		var instance := packed.instantiate() as WorldBuilder
		get_tree().root.add_child(instance)
		var stats := instance.build(world)
		await get_tree().process_frame
		_build_times.append(float(stats.build_ms))
		_check(instance.player is CharacterBody3D, "3D-сборка создаёт FPS-игрока: %s" % str(world.theme_id))
		_check(instance.exit_portal is Area3D, "3D-сборка создаёт выход: %s" % str(world.theme_id))
		_check(int(stats.objects) == world.objects.size(), "3D-сборка создаёт все объекты: %s" % str(world.theme_id))
		_check(float(stats.build_ms) < 5000.0, "3D-сборка укладывается в 5 секунд: %s (%.2f ms)" % [str(world.theme_id), float(stats.build_ms)])
		instance.queue_free()
		await get_tree().process_frame

func _contains_text(values: Array, needle: String) -> bool:
	for value in values:
		if needle in str(value):
			return true
	return false

func _check(condition: bool, label: String, detail: String = "") -> void:
	if condition:
		_passed += 1
		_results.append({"status": "passed", "name": label})
		print("[PASS] %s" % label)
	else:
		_failed += 1
		_results.append({"status": "failed", "name": label, "detail": detail})
		printerr("[FAIL] %s%s" % [label, " — " + detail if not detail.is_empty() else ""])

func _finish() -> void:
	var duration := (Time.get_ticks_msec() - _started_at) / 1000.0
	var peak_memory := Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
	var max_build_time := 0.0
	for value in _build_times:
		max_build_time = maxf(max_build_time, value)
	var report := {
		"engine": Engine.get_version_info().get("string", "unknown"),
		"platform": OS.get_name(),
		"passed": _passed,
		"failed": _failed,
		"total": _passed + _failed,
		"duration_seconds": duration,
		"maximum_world_build_ms": max_build_time,
		"peak_static_memory_bytes": peak_memory,
		"live_ai_test": "skipped: AI_WORLD_API_URL is not configured in the test environment",
		"results": _results
	}
	var report_path := "user://automated_test_report.json"
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	print("=== RESULT: %d passed, %d failed, %.2f s ===" % [_passed, _failed, duration])
	print("TEST_REPORT_PATH=%s" % ProjectSettings.globalize_path(report_path))
	get_tree().quit(0 if _failed == 0 else 1)
