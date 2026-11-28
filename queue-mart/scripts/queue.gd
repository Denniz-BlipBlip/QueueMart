extends Node
class_name QueueLayout
@export var queue_direction: Vector2 = Vector2.RIGHT
@export var row_direction: Vector2 = Vector2.DOWN
@export var slots_per_row: int = 0
@export var gap: float = 4.0
@export var look_direction: Vector2 = Vector2.ZERO
@export var front_look_direction: Vector2 = Vector2.DOWN
func positions(line: Array, origin: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var along = queue_direction.normalized()
	var across = row_direction.normalized()
	var pitch = _row_pitch(line, across)
	var offset = 0.0
	for i in line.size():
		var column = i
		var row = 0
		if slots_per_row > 0:
			column = i % slots_per_row
			row = floori(float(i) / slots_per_row)
		if column == 0:
			offset = 0.0
		else:
			offset += (line[i - 1].get_extent(along) + line[i].get_extent(along)) / 2.0 + gap
		result.append(origin + along * offset + across * pitch * row)
	return result
func position_for(line: Array, customer, origin: Vector2) -> Vector2:
	var extended = line.duplicate()
	extended.append(customer)
	return positions(extended, origin).back()
func _row_pitch(line: Array, across: Vector2) -> float:
	var widest = 0.0
	for customer in line:
		widest = maxf(widest, customer.get_extent(across))
	return widest + gap
func facing_for(index: int) -> Vector2:
	var line_look = look_direction
	if line_look == Vector2.ZERO:
		line_look = -queue_direction
	if index == 0 and front_look_direction != Vector2.ZERO:
		return front_look_direction
	return line_look
