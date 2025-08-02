extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var animation_player = $AnimationPlayer

func _ready():
	color_rect.visible = false
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)

func transition():
	color_rect = true
	animation_player.play("Fade In")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Fade In" :
		animation_player.play("Fade Out")
	elif anim_name == "Fade Out" :
		color_rect.visible = false	
