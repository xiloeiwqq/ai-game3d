class_name ResourceObject
extends StaticBody3D

var resource_id := ""

func configure(id: String) -> void:
	resource_id = id
	name = "Object_%s" % id
	var definition := ResourceCatalog.get_resource(id)
	if definition.is_empty():
		push_error("Attempt to build unknown resource: %s" % id)
		return
	VisualFactory.build_object(self, id)
	if ResourceCatalog.is_blocking(id):
		var raw: Array = definition.get("size", [1.0, 1.0, 1.0])
		var size := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
		VisualFactory.add_collision_box(self, size, Vector3(0, size.y / 2.0, 0))
	else:
		collision_layer = 0
