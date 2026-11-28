extends Node
class_name CustomerFootprint
@export var shape_node: CollisionShape2D
func _ready():
	if not shape_node:
		for child in get_parent().get_children():
			if child is CollisionShape2D:
				shape_node = child
				break
func get_extent(axis: Vector2) -> float:
	if not shape_node or not shape_node.shape:
		return 16.0
	var shape_scale = shape_node.global_scale.abs()
	var size = Vector2(16.0, 16.0)
	var shape = shape_node.shape
	if shape is RectangleShape2D:
		size = shape.size
	elif shape is CircleShape2D:
		size = Vector2(shape.radius * 2.0, shape.radius * 2.0)
	elif shape is CapsuleShape2D:
		size = Vector2(shape.radius * 2.0, shape.height)
	var direction = axis.normalized().abs()
	return direction.x * size.x * shape_scale.x + direction.y * size.y * shape_scale.y
