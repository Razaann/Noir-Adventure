extends Node2D


func _on_transition_body_entered(body):
	get_tree().change_scene_to_file("res://Scenes/Level/level_1.tscn")
