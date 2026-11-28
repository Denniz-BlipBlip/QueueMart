extends Node
class_name CustomerMover
signal target_reached
signal velocity_updated(velocity: Vector2)
@export var nav_agent: NavigationAgent2D
@export var speed: float = 60.0
@export var speed_variation: float = 0.15
@export var stop_distance: float = 4.0
@export var max_walk_time: float = 20.0
@export var use_avoidance: bool = false
@export var avoidance_radius: float = 8.0
var body: CharacterBody2D
var target: Vector2
var has_target: bool = false
var move_time: float = 0.0
var stuck_timer: float = 0.0
var stuck_count: int = 0
var last_check_position: Vector2
var sidestep_time: float = 0.0
var sidestep_dir: Vector2 = Vector2.ZERO
func _ready():
	body = get_parent() as CharacterBody2D
	speed *= randf_range(1.0 - speed_variation, 1.0 + speed_variation)
	if not nav_agent:
		var agents = body.find_children("*", "NavigationAgent2D", true, false)
		if not agents.is_empty():
			nav_agent = agents[0]
	if nav_agent:
		nav_agent.path_desired_distance = 4.0
		nav_agent.target_desired_distance = stop_distance
		nav_agent.radius = avoidance_radius
		nav_agent.max_speed = speed
		nav_agent.avoidance_enabled = use_avoidance
		nav_agent.velocity_computed.connect(_on_velocity_computed)
func move_to(pos: Vector2):
	target = pos
	has_target = true
	move_time = 0.0
	stuck_timer = 0.0
	stuck_count = 0
	last_check_position = body.global_position
	if nav_agent:
		nav_agent.target_position = pos
func stop():
	has_target = false
	body.velocity = Vector2.ZERO
	velocity_updated.emit(Vector2.ZERO)
func _physics_process(delta):
	if not has_target:
		if _avoidance_active():
			nav_agent.velocity = Vector2.ZERO
		velocity_updated.emit(Vector2.ZERO)
		return
	move_time += delta
	sidestep_time = maxf(sidestep_time - delta, 0.0)
	var to_target = target - body.global_position
	if to_target.length() <= stop_distance or move_time > max_walk_time:
		stop()
		target_reached.emit()
		return
	_check_stuck(delta, to_target)
	var desired = _move_direction(to_target) * speed
	if _avoidance_active():
		nav_agent.velocity = desired
	else:
		_apply_velocity(desired)
func _on_velocity_computed(safe_velocity: Vector2):
	if not has_target:
		return
	_apply_velocity(safe_velocity)
func _apply_velocity(new_velocity: Vector2):
	body.velocity = new_velocity
	body.move_and_slide()
	velocity_updated.emit(body.velocity)
func _nav_ready() -> bool:
	return nav_agent != null and NavigationServer2D.map_get_iteration_id(nav_agent.get_navigation_map()) != 0
func _avoidance_active() -> bool:
	return use_avoidance and _nav_ready()
func _move_direction(to_target: Vector2) -> Vector2:
	var base = to_target.normalized()
	if _nav_ready() and not nav_agent.is_navigation_finished():
		var step = nav_agent.get_next_path_position() - body.global_position
		if step.length() > 0.1:
			base = step.normalized()
	if sidestep_time > 0.0:
		return (base + sidestep_dir).normalized()
	return base
func _check_stuck(delta: float, to_target: Vector2):
	stuck_timer += delta
	if stuck_timer < 0.5:
		return
	stuck_timer = 0.0
	if body.global_position.distance_to(last_check_position) < 2.0:
		stuck_count += 1
	else:
		stuck_count = 0
	last_check_position = body.global_position
	if stuck_count >= 3:
		stuck_count = 0
		var forward = _move_direction(to_target)
		sidestep_dir = Vector2(-forward.y, forward.x) * (1.0 if randf() > 0.5 else -1.0)
		sidestep_time = 0.6
		if nav_agent:
			nav_agent.target_position = target
