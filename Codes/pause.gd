extends Control

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		pause_menu()
	

func pause_menu():
	if get_tree().paused == true:
		$".".hide()
		get_tree().paused = false
	elif get_tree().paused == false:
		$".".show()
		get_tree().paused = true


func _on_pause_button_pressed():
	pass # Replace with function body.
