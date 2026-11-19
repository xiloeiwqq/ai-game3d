class_name ExitPortal
extends Area3D

signal reached

var resource_id := "portal_exit"
var active := false
var surface: MeshInstance3D

func configure(id: String) -> void:
	resource_id = id
	name = "Exit_%s" % id
	surface = VisualFactory.build_exit(self, id)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 2.8, 2.6)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0, 1.4, 0)
	add_child(collision)
	body_entered.connect(_on_body_entered)
	set_active(false)

func _process(delta: float) -> void:
	if active and surface:
		surface.rotation.x += delta * 0.15
		surface.position.x = sin(Time.get_ticks_msec() * 0.003) * 0.035

func set_active(value: bool) -> void:
	active = value
	if not surface:
		return
	var color := Color(0.22, 0.9, 1.0, 0.68) if value else Color(0.20, 0.28, 0.34, 0.42)
	surface.material_override = VisualFactory.material(color, 0.1, 0.24, 3.2 if value else 0.25, true)
	var light := get_node_or_null("PortalLight") as OmniLight3D
	if value and light == null:
		light = OmniLight3D.new()
		light.name = "PortalLight"
		light.position = Vector3(0, 1.7, 0)
		light.light_color = Color("5be9ff")
		light.light_energy = 2.4
		light.omni_range = 7.0
		add_child(light)
	elif light:
		light.visible = value

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		reached.emit()

func get_prompt() -> String:
	return "Выход активен" if active else "Сначала найдите три предмета"
