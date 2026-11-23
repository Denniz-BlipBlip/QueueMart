extends Node2D

signal front_changed(customer)
signal customer_served(customer)

@export var queue_direction: Vector2 = Vector2.RIGHT
@export var spacing: float = 24.0
@export var max_length: int = 15
@export var slots_per_row: int = 0
@export var row_direction: Vector2 = Vector2.DOWN
@export var balking: bool = false
@export var auto_serve_time: float = 0.0
@export var test_serve_key: bool = false

var line: Array = []

func is_full() -> bool:
	return balking and line.size() >= max_length

func slot_position(index: int) -> Vector2:
	var along = queue_direction.normalized()
	if slots_per_row <= 0:
		return global_position + along * spacing * index
	var column = index % slots_per_row
	var row = floori(float(index) / slots_per_row)
	return global_position + along * spacing * column + row_direction.normalized() * spacing * row

func join(customer):
	line.push_back(customer)
	customer.arrived.connect(_on_customer_arrived.bind(customer))
	customer.tree_exiting.connect(_on_customer_gone.bind(customer))
	customer.set_target(slot_position(line.size() - 1))
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
	for i in line.size():
		line[i].set_target(slot_position(i))
	front_changed.emit(line[0] if not line.is_empty() else null)

func _on_customer_arrived(customer):
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
