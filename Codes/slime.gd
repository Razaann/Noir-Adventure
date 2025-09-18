extends CharacterBody2D

@export var health = 3
@export var patrol_speed = 50.0
@export var patrol_distance = 200.0

# Knockback tuning
@export var knockback_resistance = 0.3
@export var knockback_duration = 0.3
@export var knockback_damping = 200.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var detection_area = $DetectArea
@onready var death_sfx = $DeathSFX

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var start_position: Vector2
var patrol_direction = 1

# Knockback state
var is_knocked_back = false
var knockback_timer = 0.0

var left_limit: float
var right_limit: float


func _ready():
	start_position = global_position
	left_limit = start_position.x - patrol_distance / 2
	right_limit = start_position.x + patrol_distance / 2	
	detection_area.body_entered.connect(_on_detection_area_body_entered)


func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Knockback logic
	if is_knocked_back:
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knocked_back = false
		else:
			# Smoothly damp knockback
			velocity.x = move_toward(velocity.x, 0, knockback_damping * delta)
	else:
		# Normal patrol behavior
		patrol_movement()
	
	move_and_slide()
	update_animations()


func patrol_movement():
	velocity.x = patrol_direction * patrol_speed

	if patrol_direction < 0 and global_position.x <= left_limit:
		patrol_direction = 0
		await get_tree().create_timer(1.0).timeout
		patrol_direction = 1
	elif patrol_direction > 0 and global_position.x >= right_limit:
		patrol_direction = 0
		await get_tree().create_timer(1.0).timeout
		patrol_direction = -1
	
	animated_sprite.flip_h = (patrol_direction > 0)


func update_animations():
	if is_knocked_back:
		animated_sprite.play("hurt")
	elif velocity.x != 0:
		animated_sprite.play("idle") # <-- maybe later make a "walk" anim?
	else:
		animated_sprite.play("idle")


# --- Knockback System ---
func apply_knockback(incoming_force: Vector2):
	is_knocked_back = true
	knockback_timer = knockback_duration
	velocity = incoming_force * knockback_resistance


func take_damage(damage: int, knockback_force: Vector2):
	health -= damage
	apply_knockback(knockback_force)
	print("Enemy took damage! Health: ", health)
	
	if health <= 0:
		die()


func die():
	print("Enemy died!")
	death_sfx.play()
	animated_sprite.play("death")
	collision_shape.disabled = true
	await animated_sprite.animation_finished
	queue_free()


func is_enemy() -> bool:
	return true


func _on_detection_area_body_entered(body):
	if body.has_method("take_player_knockback"):
		var knockback_direction = (body.global_position - global_position).normalized() * 300.0
		body.take_player_knockback(knockback_direction)
