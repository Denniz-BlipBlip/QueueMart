extends Node
class_name CustomerShopper
signal finished_shopping
@export var mover: CustomerMover
@export var wait_time_min: float = 2.0
@export var wait_time_max: float = 5.0
var route: Array[Vector2] = []
var index: int = 0
var active: bool = false
func _ready():
	if not mover:
		for child in get_parent().get_children():
			if child is CustomerMover:
				mover = child
func start_route(points: Array[Vector2]):
	route = points
	index = 0
	active = true
	_next()
func on_stop_reached():
	if not active:
		return
	get_tree().create_timer(randf_range(wait_time_min, wait_time_max)).timeout.connect(_next)
func cancel():
	active = false
func _next():
	if not active:
		return
	if index < route.size():
		mover.move_to(route[index])
		index += 1
	else:
		active = false
		finished_shopping.emit()
