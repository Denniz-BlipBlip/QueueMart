extends Node
class_name CustomerAnimator
@export var sprite: AnimatedSprite2D
@export var mover: CustomerMover
@export var skins: Array[SpriteFrames] = []
var facing: String = "front"
func _ready():
	var parent = get_parent()
	if not sprite:
		var found = parent.find_children("*", "AnimatedSprite2D", true, false)
		if not found.is_empty():
			sprite = found[0]
	if not mover:
		for child in parent.get_children():
			if child is CustomerMover:
				mover = child
	if mover:
		mover.velocity_updated.connect(_on_velocity_updated)
	if sprite and not skins.is_empty():
		sprite.sprite_frames = skins.pick_random()
	_check_animations()
	_on_velocity_updated(Vector2.ZERO)
func _check_animations():
	if not sprite:
		push_warning("%s: no AnimatedSprite2D found, so animations won't play." % get_parent().scene_file_path)
		return
	if not sprite.sprite_frames:
		push_warning("Customer: the AnimatedSprite2D has no Sprite Frames.")
		return
	var has_walk = false
	for anim_name in sprite.sprite_frames.get_animation_names():
		if anim_name.begins_with("walk"):
			has_walk = true
	if not has_walk:
		push_warning("Customer: no animation starts with 'walk'. Found: %s" % ", ".join(sprite.sprite_frames.get_animation_names()))
func face(direction: Vector2):
	if direction == Vector2.ZERO:
		return
	if absf(direction.x) > absf(direction.y):
		facing = "right" if direction.x > 0.0 else "left"
	else:
		facing = "front" if direction.y > 0.0 else "back"
	_on_velocity_updated(Vector2.ZERO)
func _on_velocity_updated(velocity: Vector2):
	if not sprite or not sprite.sprite_frames:
		return
	var moving = velocity.length() > 5.0
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
func _find_animation(base: String) -> String:
	var frames = sprite.sprite_frames
	var options = [base + "_" + facing]
	if facing == "front":
		options.append(base + "_down")
	elif facing == "back":
		options.append(base + "_up")
	elif facing == "left":
		options.append(base + "_right")
	options.append_array([base, base + "_front", base + "_down", base + "_right"])
	for option in options:
		if frames.has_animation(option):
			return option
	return ""
