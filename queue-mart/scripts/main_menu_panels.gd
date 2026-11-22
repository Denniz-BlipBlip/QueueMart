extends Control

@export var start_button: Button
@export var highscore_button: Button
@export var about_button: Button

@export_file("*.tscn") var game_scene: String
@export_file("*.tscn") var highscore_scene: String
@export_file("about.tscn") var about_scene: String

func _ready():
	if start_button:
		start_button.pressed.connect(_go_to.bind(game_scene))
	if highscore_button:
		highscore_button.pressed.connect(_go_to.bind(highscore_scene))
	if about_button:
		about_button.pressed.connect(_go_to.bind(about_scene))

func _go_to(path: String):
	if path == "" or not ResourceLoader.exists(path):
		push_warning("Scene not found: '%s'. Set it in the Inspector on the MainMenu node." % path)
		return
	get_tree().change_scene_to_file(path)
