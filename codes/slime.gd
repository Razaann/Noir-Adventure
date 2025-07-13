extends CharacterBody2D

const Speed = 50

var direction = 1
@onready var slime_anim = $SlimeAnim
@onready var collision_shape_2d = $CollisionShape2D
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var death_sfx = $DeathSfx
var is_dying = false

func _process(delta):
	movement(delta)

func take_damage(amount := 1):
	if is_dying:
		return
	
	is_dying = true
	collision_shape_2d.disabled = true
	direction = 0 # Stop the slime
	slime_anim.play("death")
	death_sfx.play()
	
	await slime_anim.animation_finished
	queue_free()

func movement(delta):
		if ray_cast_right.is_colliding():
			direction = -1
			slime_anim.flip_h = true
		elif ray_cast_left.is_colliding():
			direction = 1
			slime_anim.flip_h = false
	
		position.x += direction * Speed * delta
	
