extends Control

@onready var restart_button = $RestartButton

# Called when the node enters the scene tree for the first time.
func _ready():
	restart_button.pressed.connect(_on_restart_button_pressed)


func _on_restart_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn") 
