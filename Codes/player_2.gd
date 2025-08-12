extends CharacterBody2D

@export var speed = 100.0
@export var jump_velocity = -300.0
@export var attack_range = 100.0
@export var attack_damage = 1
@export var attack_knockback_force = 500.0
@export var player_knockback_force = 300.0
@export var max_health = 3

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/CollisionShape2D
@onready var player_collision = $PlayerCol
@onready var detection_area = $DetectArea

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_attacking = false
var facing_right = true
var is_on_ground = false

# Health
var current_health: int

# Knockback
var is_knocked_back = false
var knockback_timer = 0.0
var knockback_duration = 0.3

# For Block All Input
var is_dead = false

func _ready():
	current_health = max_health
	attack_collision.disabled = true
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	detection_area.body_entered.connect(_on_detection_area_body_entered)

func _physics_process(delta):
	if is_dead:
		move_and_slide() # still allow gravity to pull player down
		return
	
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		is_on_ground = false
	else:
		is_on_ground = true

	# Knockback handling
	if is_knocked_back:
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knocked_back = false
	else:
		# Jump
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity
		
		# Attack
		if Input.is_action_just_pressed("attack") and is_on_ground and not is_attacking:
			perform_attack()
		
		# Movement
		if not is_attacking:
			handle_movement()

	move_and_slide()
	update_animations()

func handle_movement():
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * speed
		if direction > 0 and not facing_right:
			flip_character()
			attack_area.position.x = 16
		elif direction < 0 and facing_right:
			flip_character()
			attack_area.position.x = -16
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

func flip_character():
	facing_right = !facing_right
	animated_sprite.flip_h = !facing_right

func perform_attack():
	is_attacking = true
	velocity.x = 0
	attack_collision.disabled = false
	if facing_right:
		animated_sprite.play("attack")
	else:
		animated_sprite.play("attack")
	await get_tree().create_timer(0.3).timeout
	attack_collision.disabled = true
	is_attacking = false

func update_animations():
	if is_attacking:
		return
	if is_knocked_back:
		animated_sprite.play("hurt")
	elif not is_on_floor():
		animated_sprite.play("jump")
	elif velocity.x != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

func _on_attack_area_body_entered(body):
	if body.has_method("take_damage"):
		var knockback_direction = (body.global_position - global_position).normalized()
		body.take_damage(attack_damage, knockback_direction * attack_knockback_force)

# Called when touching enemy
func _on_detection_area_body_entered(body):
	if body.has_method("is_enemy") and body.is_enemy():
		var knockback_direction = (global_position - body.global_position).normalized()
		take_damage(1, knockback_direction)

# Take damage from enemy
func take_damage(amount: int, knockback_direction: Vector2):
	if is_knocked_back or is_dead:
		return # Ignore if already being knocked back

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
			# THIS THING F UP NEED TO DELETE THE PLAYER COL
		#is_knocked_back = true
		#knockback_timer = knockback_duration
		#velocity.x = knockback_direction.x * player_knockback_force
		#velocity.y = -150 # small upward knockback
		#Engine.time_scale = 0.5
		#player_collision.queue_free() # or player_collision.disabled = true
		#await get_tree().create_timer(0.5).timeout
		#Engine.time_scale = 1.0
		#get_tree().reload_current_scene()

func die(knockback_direction: Vector2):
	is_dead = false
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	player_collision.queue_free() # or player_collision.disabled = true
	
	# Optional knockback effect on death
	is_knocked_back = true
	knockback_timer = knockback_duration
	velocity.x = knockback_direction.x * player_knockback_force
	velocity.y = -150
	
	# Slow Mo & reload scene
	Engine.time_scale = 0.5
	await get_tree().create_timer(0.5).timeout
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
