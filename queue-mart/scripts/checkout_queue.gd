extends Node2D
signal front_changed(customer)
signal customer_served(customer)
@export var layout: QueueLayout
@export var max_length: int = 15
@export var balking: bool = false
@export var join_distance: float = 10.0
@export var auto_serve_time: float = 0.0
@export var test_serve_key: bool = false
var line: Array = []
func _ready():
	if not layout:
		for child in get_children():
			if child is QueueLayout:
				layout = child
	if not layout:
		push_warning("CheckoutQueue needs a QueueLayout child node.")
func is_full() -> bool:
	return balking and line.size() >= max_length
func tail_position(customer) -> Vector2:
	return layout.position_for(line, customer, global_position)
func join(customer):
	line.push_back(customer)
	customer.arrived.connect(_on_customer_arrived.bind(customer))
	customer.tree_exiting.connect(_on_customer_gone.bind(customer))
	customer.set_target(layout.positions(line, global_position).back())
	if line.size() == 1:
		front_changed.emit(customer)
func finish_front():
	if line.is_empty():
		return
	var served = line.pop_front()
	customer_served.emit(served)
	if is_instance_valid(served):
		served.leave()
	_refresh()
func _refresh():
	var slots = layout.positions(line, global_position)
	for i in line.size():
		line[i].set_target(slots[i])
	front_changed.emit(line[0] if not line.is_empty() else null)
func _on_customer_arrived(customer):
	var index = line.find(customer)
	if index >= 0:
		customer.face(layout.facing_for(index))
	if auto_serve_time > 0.0 and not line.is_empty() and line[0] == customer:
		get_tree().create_timer(auto_serve_time).timeout.connect(_auto_serve.bind(customer))
func _auto_serve(customer):
	if is_instance_valid(customer) and not line.is_empty() and line[0] == customer:
		finish_front()
func _on_customer_gone(customer):
	if customer in line:
		line.erase(customer)
		_refresh()
func _unhandled_input(event):
	if test_serve_key and event.is_action_pressed("ui_accept"):
		finish_front()
