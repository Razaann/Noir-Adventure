extends CharacterBody2D

@export var speed = 300.0
@export var jump_velocity = -400.0
@export var attack_range = 100.0
@export var attack_damage = 1
@export var attack_knockback_force = 500.0
@export var player_knockback_force = 300.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/CollisionShape2D
@onready var player_collision = $CollisionShape2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_attacking = false
var is_on_ground = false

func _ready():
	# Make sure attack area is initially disabled
	attack_collision.disabled = true
	
	# Connect attack area signal
	attack_area.body_entered.connect(_on_attack_area_body_entered)

func _physics_process(delta):
	# Handle gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		is_on_ground = false
	else:
		is_on_ground = true
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	# Handle attack - only when on ground and not already attacking
	if Input.is_action_just_pressed("attack") and is_on_ground and not is_attacking:
		perform_attack()
	
	# Handle movement - only if not attacking
	if not is_attacking:
		handle_movement()
	
	move_and_slide()
	update_animations()

func handle_movement():
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		velocity.x = direction * speed
		
		# Update facing direction
		if direction > 0:
			animated_sprite.flip_h = false
			attack_area.position.x = 16
		elif direction < 0:
			animated_sprite.flip_h = true
			attack_area.position.x = -16
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

func perform_attack():
	is_attacking = true
	velocity.x = 0  # Stop movement during attack
	
	# Enable attack collision
	attack_collision.disabled = false
	
	# Play attack animation
	animated_sprite.play("attack")
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	
	# Disable attack collision and reset state
	attack_collision.disabled = true
	is_attacking = false

func update_animations():
	if is_attacking:
		return  # Don't change animation during attack
	
	if not is_on_floor():
		animated_sprite.play("jump")
	elif velocity.x != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

func _on_attack_area_body_entered(body):
	if body.has_method("take_damage"):
		# Calculate knockback direction
		var knockback_direction = (body.global_position - global_position).normalized()
		body.take_damage(attack_damage, knockback_direction * attack_knockback_force)

func take_player_knockback(knockback_direction):
	# Apply knockback to player
	velocity.x = knockback_direction.x * player_knockback_force
	velocity.y = knockback_direction.y * player_knockback_force

# Called when player collides with enemy
func _on_body_entered(body):
	if body.has_method("is_enemy") and body.is_enemy():
		# Calculate knockback direction (away from enemy)
		var knockback_direction = (global_position - body.global_position).normalized()
		take_player_knockback(knockback_direction)
