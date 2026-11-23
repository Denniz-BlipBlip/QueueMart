extends Area2D

func _ready():
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("despawn") and body.leaving:
		body.despawn()
