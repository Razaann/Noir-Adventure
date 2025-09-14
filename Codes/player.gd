extends CharacterBody2D

const SPEED = 75.0
const JUMP_VELOCITY = -250.0 # -250
@export var attack_damage = 1
@export var attack_knockback_force = 300.0
@export var player_knockback_force = 200.0
@export var max_health = 3

# Nodes
@onready var player_anim = $PlayerAnim
@onready var slash_effect = $SlashEffect
@onready var dash_duration = $DashDuration
@onready var dash_cooldown = $DashCooldown
@onready var sword_area = $SwordArea
@onready var sword_col = $SwordArea/SwordCol
@onready var jump_sfx = $JumpSFX
@onready var attack_sfx = $AttackSFX
@onready var player_collision = $PlayerCol
@onready var detection_area = $DetectArea

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

# Knockback
var is_knocked_back = false
var knockback_timer = 0.0
var knockback_duration = 0.3

func _ready():
	sword_col.disabled = true
	current_health = max_health

func _physics_process(delta):
	if is_dead:
		move_and_slide() # still allow gravity to pull down
		return
	
	var direction = Input.get_axis("move_left", "move_right")
	
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Knockback
	if is_knocked_back:
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knocked_back = false
	else:
		# Animation & jump
		set_animation(direction)
		jump()
		
		# Dash
		if Input.is_action_just_pressed("dash") and can_dash:
			if player_anim.flip_h:
				dashDirection = -1 
			else:
				dashDirection = 1
			
			is_dash = true
			can_dash = false
			dash_duration.start()
			dash_cooldown.start(1.0)
		
		if is_dash:
			velocity.x = dashDirection * (SPEED * 1.5) * 2
			velocity.y = 0
		elif is_attack:
			velocity.x = 0
		else:
			if direction:
				if direction > 0:
					player_anim.flip_h = false
					slash_effect.flip_h = false
					slash_effect.position.x = 16
					sword_area.position.x = 0
					velocity.x = direction * SPEED
				elif direction < 0:
					player_anim.flip_h = true
					slash_effect.flip_h = true
					slash_effect.position.x = -16
					sword_area.position.x = -30
					velocity.x = direction * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
		
		# Attack
		if Input.is_action_just_pressed("attack") and not is_attack:
			attack()
	
	move_and_slide()

# Jump handling
func jump():
	if is_on_floor():
		jumps_left = 2
	
	if jumps_left > 0 and velocity.y >= 0.0:
		if Input.is_action_just_pressed("jump"):
			jump_sfx.play()
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1 

# Attack handling

func attack():
	if is_on_floor() and not is_attack:
		is_attack = true
		player_anim.play("attack")
		
		var dir
		
		if player_anim.flip_h == false :
			dir = 1
		else:
			dir = -1
			
		var offset = 8 * dir   # lunge distance in px
		
		# tween a quick step forward
		tween = get_tree().create_tween()
		tween.tween_property(self, "position:x", position.x + offset, 0.1)
		
		# restart slash effect
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


# Animations
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
	if body.has_method("is_enemy") and body.is_enemy():
		var knockback_direction = (global_position - body.global_position).normalized()
		take_damage(1, knockback_direction)

# Player takes damage
func take_damage(amount: int, knockback_direction: Vector2):
	if is_knocked_back or is_dead:
		return
	
	current_health -= amount
	print("Player health: ", current_health)
	
	if current_health > 0:
		# Knockback
		is_knocked_back = true
		knockback_timer = knockback_duration
		velocity.x = knockback_direction.x * player_knockback_force
		velocity.y = -150 # small upward knockback
	else:
		die(knockback_direction)

# Death handling
func die(knockback_direction: Vector2):
	is_dead = true
	velocity = Vector2.ZERO
	player_anim.play("death")
	player_collision.queue_free()
	
	# Knockback effect on death
	is_knocked_back = true
	knockback_timer = knockback_duration
	velocity.x = knockback_direction.x * player_knockback_force
	velocity.y = -100
	
	# Slow Mo & reload scene
	Engine.time_scale = 0.5
	await get_tree().create_timer(0.5).timeout
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://Scenes/game_over.tscn")
