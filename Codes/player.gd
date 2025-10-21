extends CharacterBody2D

const SPEED = 75.0
const JUMP_VELOCITY = -250.0
@export var attack_damage = 1
@export var attack_knockback_force = 200.0
@export var player_knockback_force = 120.0
@export var max_health = 3

# Nodes
@onready var player_anim = $PlayerAnim
@onready var slash_effect = $SlashEffect
@onready var dash_duration = $DashDuration
@onready var dash_cooldown = $DashCooldown
@onready var sword_area = $SwordArea
@onready var sword_col = $SwordArea/SwordCol
@onready var player_collision = $PlayerCol
@onready var detection_area = $DetectArea

# SFX
@onready var jump_sfx = $Node/JumpSFX
@onready var attack_sfx = $Node/AttackSFX
@onready var dash_sfx = $Node/DashSFX
@onready var hurt_sfx = $Node/HurtSFX
@onready var dead_sfx = $Node/DeadSFX

# For dash
var is_dash = false
var can_dash = true
var dashDirection : int

# For double jumps
var jumps_left = 0

# For attack
var is_attack = false
var tween: Tween

# Health
var current_health: int
var is_dead = false

# Improved knockback system
var is_knocked_back = false
var knockback_velocity = Vector2.ZERO
var knockback_timer = 0.0
var knockback_duration = 0.4
var knockback_friction = 500.0
var i_frames_timer = 0.0
var i_frames_duration = 1.0
var is_invulnerable = false

# ADDED: This variable controls whether the player can perform any action.
var can_act: bool = false

func _ready():
	sword_col.disabled = true
	current_health = max_health
	
	# ADDED: Wait for 1 second when the player spawns, then enable actions.
	#await get_tree().create_timer(1.0).timeout
	can_act = true

func _physics_process(delta):
	if is_dead:
		move_and_slide()
		return
	
	# Handle invincibility frames
	if is_invulnerable:
		i_frames_timer -= delta
		# Visual feedback - flicker sprite
		player_anim.modulate.a = 0.5 + 0.5 * sin(i_frames_timer * 20)
		if i_frames_timer <= 0:
			is_invulnerable = false
			player_anim.modulate.a = 1.0
	
	var direction = Input.get_axis("move_left", "move_right")
	
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle one way platfrom
	if Input.is_action_pressed("down"):
		position.y += 1
	
	# Handle knockback
	if is_knocked_back:
		knockback_timer -= delta
		
		# Apply knockback velocity with friction
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		velocity.x = knockback_velocity.x
		
		# Allow some air control during knockback
		if not is_on_floor() and direction != 0:
			velocity.x += direction * SPEED * 0.3 * delta
		
		if knockback_timer <= 0 or (is_on_floor() and abs(knockback_velocity.x) < 10):
			is_knocked_back = false
			knockback_velocity = Vector2.ZERO
	else:
		# Normal movement and actions
		set_animation(direction)
		
		# ADDED: Check if the player is allowed to act before processing input.
		if can_act:
			jump()
			handle_dash()
			handle_movement(direction)
			handle_attack()
	
	move_and_slide()

func handle_dash():
	if Input.is_action_just_pressed("dash") and can_dash and not is_knocked_back:
		dash_sfx.play()
		dashDirection = -1 if player_anim.flip_h else 1
		
		is_dash = true
		can_dash = false
		dash_duration.start()
		dash_cooldown.start(1.0)

func handle_movement(direction):
	if is_dash:
		velocity.x = dashDirection * (SPEED * 3.0)
		velocity.y = 0
	elif is_attack:
		# Allow slight movement during attack
		velocity.x = move_toward(velocity.x, direction * SPEED * 0.3, SPEED * 2)
	else:
		if direction:
			# Update sprite direction
			player_anim.flip_h = direction < 0
			slash_effect.flip_h = direction < 0
			slash_effect.position.x = 16 if direction > 0 else -16
			sword_area.position.x = 0 if direction > 0 else -32
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

func handle_attack():
	if Input.is_action_just_pressed("attack") and not is_attack and not is_knocked_back:
		attack()

func jump():
	if is_on_floor():
		jumps_left = 2
	
	if jumps_left > 0 and velocity.y >= 0.0:
		if Input.is_action_just_pressed("jump") and not is_knocked_back:
			jump_sfx.play()
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1

func attack():
	if not is_attack:
		is_attack = true
		player_anim.play("attack")
		
		slash_effect.visible = true
		slash_effect.stop()
		slash_effect.play("attack")
		
		attack_sfx.play()
		sword_area.monitoring = true
		sword_col.disabled = false
		
		await slash_effect.animation_finished
		
		slash_effect.visible = false
		sword_area.monitoring = false
		sword_col.disabled = true
		is_attack = false

func set_animation(direction):
	if is_dead:
		player_anim.play("death")
		return
	
	if is_dash:
		player_anim.play("dash")
		return
	
	if is_attack and is_on_floor():
		player_anim.play("attack")
		return
	
	if is_knocked_back:
		player_anim.play("hurt")
		return
	
	if is_on_floor():
		if direction == 0:
			player_anim.play("idle")
		else:
			player_anim.play("run")
	else:
		if velocity.y < 0:
			player_anim.play("jump")
		elif velocity.y > 0:
			player_anim.play("fall")

# Dash timers
func _on_dash_duration_timeout():
	is_dash = false

func _on_dash_cooldown_timeout():
	can_dash = true

# Sword hitting enemies
func _on_sword_area_body_entered(body):
	if body.has_method("take_damage"):
		var knockback_direction = (body.global_position - global_position).normalized()
		body.take_damage(attack_damage, knockback_direction * attack_knockback_force)

# Detect enemy body collision (player takes damage)
func _on_detect_area_body_entered(body):
	if body.has_method("is_enemy") and body.is_enemy() and not is_invulnerable:
		var knockback_direction = (global_position - body.global_position).normalized()
		take_damage(1, knockback_direction)

# Improved player damage system
func take_damage(amount: int, knockback_direction: Vector2):
	if is_invulnerable or is_dead:
		return
	
	current_health -= amount
	print("Player health: ", current_health)
	
	if current_health > 0:
		# Start invincibility frames
		is_invulnerable = true
		i_frames_timer = i_frames_duration
		
		# Apply knockback
		is_knocked_back = true
		knockback_timer = knockback_duration
		
		var knockback_strength = player_knockback_force
		if is_on_floor():
			knockback_velocity.x = knockback_direction.x * knockback_strength
			knockback_velocity.y = -100
		else:
			# Stronger knockback in air
			knockback_velocity.x = knockback_direction.x * knockback_strength * 1.2
			knockback_velocity.y = knockback_direction.y * knockback_strength * 0.5
	else:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	player_anim.play("death")
	player_collision.queue_free()
	
	await get_tree().create_timer(0.5).timeout
	await player_anim.animation_finished
	get_tree().change_scene_to_file("res://Scenes/Level/game_over.tscn")
