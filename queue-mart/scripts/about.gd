extends Control

@export var back_button: Button
@export_file("*.tscn") var main_menu: String

func _ready():
	if back_button:
		back_button.pressed.connect(_go_to.bind(main_menu))

func _go_to(path: String):
	if path == "" or not ResourceLoader.exists(path):
		push_warning("Scene not found: '%s'. Set it in the Inspector on this node." % path)
		return
	get_tree().change_scene_to_file(path)
