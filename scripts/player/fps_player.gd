class_name FPSPlayer
extends CharacterBody3D

signal pause_requested
signal interaction_hint_changed(text: String)

@export var walk_speed := 5.2
@export var sprint_speed := 8.0
@export var acceleration := 18.0
@export var jump_velocity := 5.2

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay

var gravity := 9.8
var control_enabled := true
var last_hint := ""

func _ready() -> void:
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if not control_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_look(event.relative)
	if event.is_action_pressed("interact") and ray.is_colliding():
		var target := ray.get_collider()
		if target and target.has_method("interact"):
			target.interact(self)

func _physics_process(delta: float) -> void:
	if not control_enabled:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_x := direction.x * speed
	var target_z := direction.z * speed
	velocity.x = move_toward(velocity.x, target_x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_z, acceleration * delta)
	move_and_slide()
	_update_interaction_hint()

func set_control_enabled(value: bool) -> void:
	control_enabled = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE

func _apply_mouse_look(relative: Vector2) -> void:
	rotate_y(-relative.x * GameSettings.mouse_sensitivity)
	head.rotation.x = clampf(head.rotation.x - relative.y * GameSettings.mouse_sensitivity, deg_to_rad(-86.0), deg_to_rad(86.0))

func _update_interaction_hint() -> void:
	var hint := ""
	if ray.is_colliding():
		var target := ray.get_collider()
		if target and target.has_method("get_prompt"):
			hint = str(target.get_prompt())
	if hint != last_hint:
		last_hint = hint
		interaction_hint_changed.emit(hint)
