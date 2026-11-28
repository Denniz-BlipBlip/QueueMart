extends CharacterBody2D
signal arrived
signal balked
signal left_store
@export var mover: CustomerMover
@export var shopper: CustomerShopper
@export var footprint: CustomerFootprint
@export var animator: CustomerAnimator
@export var auto_leave: bool = true
var exit_position: Vector2
var queue: Node2D = null
var heading_to_queue: bool = false
var in_queue: bool = false
var leaving: bool = false
var despawning: bool = false
func _ready():
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	for child in get_children():
		if child is CustomerMover and not mover:
			mover = child
		elif child is CustomerShopper and not shopper:
			shopper = child
		elif child is CustomerFootprint and not footprint:
			footprint = child
		elif child is CustomerAnimator and not animator:
			animator = child
	if not mover or not shopper:
		push_warning("%s: needs a CustomerMover and a CustomerShopper child node." % scene_file_path)
		return
	mover.target_reached.connect(_on_target_reached)
	shopper.finished_shopping.connect(_on_finished_shopping)
func _physics_process(_delta):
	if heading_to_queue:
		_approach_queue()
func get_extent(axis: Vector2) -> float:
	if footprint:
		return footprint.get_extent(axis)
	return 16.0
func face(direction: Vector2):
	if animator:
		animator.face(direction)
func start_route(points: Array[Vector2]):
	shopper.start_route(points)
func set_target(pos: Vector2):
	mover.move_to(pos)
func leave():
	heading_to_queue = false
	in_queue = false
	leaving = true
	shopper.cancel()
	mover.move_to(exit_position)
func despawn():
	if despawning:
		return
	despawning = true
	heading_to_queue = false
	mover.stop()
	mover.set_physics_process(false)
	left_store.emit()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
func _approach_queue():
	var tail = queue.tail_position(self)
	if global_position.distance_to(tail) <= queue.join_distance:
		heading_to_queue = false
		in_queue = true
		queue.join(self)
	elif not mover.has_target or mover.target.distance_to(tail) > 1.0:
		mover.move_to(tail)
func _on_target_reached():
	if leaving:
		despawn()
		return
	arrived.emit()
	if not in_queue and not heading_to_queue:
		shopper.on_stop_reached()
func _on_finished_shopping():
	if queue and queue.is_full():
		balked.emit()
		leave()
	elif queue:
		heading_to_queue = true
		_approach_queue()
	elif auto_leave:
		leave()
