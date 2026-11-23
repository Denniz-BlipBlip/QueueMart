extends CharacterBody2D

signal arrived
signal balked
signal left_store

@export var sprite: AnimatedSprite2D
@export var skins: Array[SpriteFrames] = []
@export var speed: float = 60.0
@export var speed_variation: float = 0.15
@export var stop_distance: float = 4.0
@export var max_walk_time: float = 10.0
@export var auto_leave: bool = true
@export var wait_time_min: float = 2.0
@export var wait_time_max: float = 5.0

var target: Vector2
var has_target: bool = false
var move_time: float = 0.0
var exit_position: Vector2
var leaving: bool = false
var despawning: bool = false
var facing: String = "front"
var queue: Node2D = null
var in_queue: bool = false
var route: Array[Vector2] = []
var route_index: int = 0

func _ready():
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	speed *= randf_range(1.0 - speed_variation, 1.0 + speed_variation)
	if sprite and not skins.is_empty():
		sprite.sprite_frames = skins.pick_random()
	_check_animations()
	_animate(false)

func _check_animations():
	if not sprite:
		push_warning("%s: the Sprite field is empty, so animations won't play." % scene_file_path)
		return
	if not sprite.sprite_frames:
		push_warning("%s: the AnimatedSprite2D has no Sprite Frames." % scene_file_path)
		return
	var names = sprite.sprite_frames.get_animation_names()
	var has_walk = false
	for anim_name in names:
		if anim_name.begins_with("walk"):
			has_walk = true
	if not has_walk:
		push_warning("%s: no animation starts with 'walk'. Found: %s" % [scene_file_path, ", ".join(names)])

func start_route(points: Array[Vector2]):
	route = points
	route_index = 0
	_go_next()

func _go_next():
	if despawning:
		return
	if route_index < route.size():
		set_target(route[route_index])
		route_index += 1
	elif queue and not queue.is_full():
		in_queue = true
		queue.join(self)
	else:
		if queue:
			balked.emit()
		leave()

func set_target(pos: Vector2):
	target = pos
	has_target = true
	move_time = 0.0

func leave():
	in_queue = false
	leaving = true
	set_target(exit_position)

func _physics_process(delta):
	if not has_target:
		velocity = Vector2.ZERO
		_animate(false)
		return
	move_time += delta
	var to_target = target - global_position
	if to_target.length() <= stop_distance or move_time > max_walk_time:
		_reach_target()
		return
	velocity = to_target.normalized() * speed
	move_and_slide()
	_animate(true)

func _reach_target():
	velocity = Vector2.ZERO
	has_target = false
	_animate(false)
	if leaving:
		despawn()
		return
	arrived.emit()
	if in_queue:
		return
	var at_end = route_index >= route.size()
	if not at_end or queue or auto_leave:
		var wait = randf_range(wait_time_min, wait_time_max)
		get_tree().create_timer(wait).timeout.connect(_go_next)

func _find_animation(base: String) -> String:
	var frames = sprite.sprite_frames
	var aliases = {"front": "down", "back": "up"}
	var options = [base + "_" + facing]
	if aliases.has(facing):
		options.append(base + "_" + aliases[facing])
	if facing == "left":
		options.append(base + "_right")
	options.append_array([base, base + "_front", base + "_down", base + "_right"])
	for option in options:
		if frames.has_animation(option):
			return option
	return ""

func _animate(moving: bool):
	if not sprite or not sprite.sprite_frames:
		return
	if moving:
		if absf(velocity.x) > absf(velocity.y):
			facing = "right" if velocity.x > 0.0 else "left"
		else:
			facing = "front" if velocity.y > 0.0 else "back"
	var hold = false
	var anim = _find_animation("walk" if moving else "idle")
	if anim == "" and not moving:
		anim = _find_animation("walk")
		hold = true
	if anim == "":
		return
	sprite.flip_h = facing == "left" and not anim.ends_with("_left")
	if hold:
		sprite.animation = anim
		sprite.frame = 0
		sprite.stop()
	elif sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)

func despawn():
	if despawning:
		return
	despawning = true
	set_physics_process(false)
	left_store.emit()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
