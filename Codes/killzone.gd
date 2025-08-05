extends Area2D


func _on_body_entered(body):
	Engine.time_scale = 0.5
	#body.get_node("PlayerCol").queue_free()
	await get_tree().create_timer(0.5).timeout
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
	#get_tree().change_scene_to_file("res://path_to_scene.tscn")
