extends CharacterBody2D

@export var health = 3
@export var patrol_speed = 50.0
@export var patrol_distance = 200.0
@export var knockback_resistance = 0.8

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectArea
@onready var death_sfx = $DeathSFX

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var start_position: Vector2
var patrol_direction = 1
var is_knocked_back = false
var knockback_timer = 0.0
var knockback_duration = 0.3

var left_limit: float
var right_limit: float


func _ready():
	start_position = global_position
	left_limit = start_position.x - patrol_distance / 2
	right_limit = start_position.x + patrol_distance / 2	
	# Connect detection area to handle player collision
	detection_area.body_entered.connect(_on_detection_area_body_entered)


func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle knockback
	if is_knocked_back:
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knocked_back = false
			velocity.x = move_toward(velocity.x, 0, 200.0)
	else:
		# Normal patrol behavior
		patrol_movement()
	
	move_and_slide()
	update_animations()


func patrol_movement():
	# Move in patrol direction
	velocity.x = patrol_direction * patrol_speed

	# Turn around if we reach the patrol boundaries
	if patrol_direction < 0 and global_position.x <= left_limit:
		patrol_direction = 0
		await get_tree().create_timer(1.0).timeout
		patrol_direction = 1
	elif patrol_direction > 0 and global_position.x >= right_limit:
		patrol_direction = 0
		await get_tree().create_timer(1.0).timeout
		patrol_direction = -1
	
	# Flip sprite based on movement direction
	if patrol_direction > 0:
		animated_sprite.flip_h = true
	elif patrol_direction < 0:
		animated_sprite.flip_h = false


func update_animations():
	if is_knocked_back:
		animated_sprite.play("hurt")
	elif velocity.x != 0:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("idle")

func take_damage(damage: int, knockback_force: Vector2):
	health -= damage
	
	# Apply knockback
	is_knocked_back = true
	knockback_timer = knockback_duration
	velocity.x = knockback_force.x * knockback_resistance
	velocity.y = knockback_force.y * knockback_resistance
	
	print("Enemy took damage! Health: ", health)
	
	if health <= 0:
		die()

func die():
	print("Enemy died!")
	# Add death animation or effects here
	death_sfx.play()
	animated_sprite.play("death")
	collision_shape.disabled = true
	
	# Wait for death animation then remove
	await animated_sprite.animation_finished
	queue_free()


func is_enemy() -> bool:
	return true


func _on_detection_area_body_entered(body):
	# When player enters detection area (collision with player)
	if body.has_method("take_player_knockback"):
		# Calculate knockback direction for player
		var knockback_direction = (body.global_position - global_position).normalized()
		body.take_player_knockback(knockback_direction)
