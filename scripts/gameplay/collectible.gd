class_name Collectible
extends Area3D

signal collected(unique_id: String)

var resource_id := "crystal_blue"
var unique_id := "item"
var was_collected := false
var base_y := 0.0
var phase := 0.0

func configure(id: String, id_suffix: String) -> void:
	resource_id = id
	unique_id = "%s_%s" % [id, id_suffix]
	name = "Collectible_%s" % unique_id
	VisualFactory.build_collectible(self, id)
	var shape := SphereShape3D.new()
	shape.radius = 0.75
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.95
	add_child(collision)
	var audio := AudioStreamPlayer3D.new()
	audio.name = "CollectSound"
	audio.stream = SoundFactory.tone(720.0 if id != "artifact_gold" else 880.0)
	audio.max_distance = 14.0
	add_child(audio)
	body_entered.connect(_on_body_entered)

func _ready() -> void:
	base_y = position.y
	phase = float(unique_id.hash() % 100) * 0.03

func _process(delta: float) -> void:
	if was_collected:
		return
	var visual := get_node_or_null("FloatingVisual")
	if visual:
		visual.rotation.y += delta * 1.25
		visual.position.y = 1.05 + sin(Time.get_ticks_msec() * 0.0025 + phase) * 0.13

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		attempt_collect()

func attempt_collect() -> bool:
	if was_collected:
		return false
	if not AppState.collect(unique_id):
		return false
	was_collected = true
	monitoring = false
	collected.emit(unique_id)
	var audio := get_node_or_null("CollectSound") as AudioStreamPlayer3D
	if audio:
		audio.play()
	var visual := get_node_or_null("FloatingVisual")
	if visual:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(visual, "scale", Vector3.ZERO, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(visual, "position:y", 2.2, 0.28)
		await tween.finished
	visible = false
	await get_tree().create_timer(0.25).timeout
	queue_free()
	return true
