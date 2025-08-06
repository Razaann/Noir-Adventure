extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

# Nodes
@onready var player_anim = $PlayerAnim
@onready var dash_duration = $DashDuration
@onready var dash_cooldown = $DashCooldown
@onready var sword_area = $SwordArea
@onready var sword_col = $SwordArea/SwordCol
@onready var jump_sfx = $JumpSFX


# For dash
var is_dash = false
var can_dash = true
var dashDirection : int

# For double jumps
var jumps_left = 0

# For attack
var is_attack = false

func _physics_process(delta):
	var direction = Input.get_axis("move_left", "move_right")
	
	# Handle gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle animation & jump
	set_animation(direction)
	jump()
	
	# Handle dash
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
		velocity.x = dashDirection * SPEED * 3
		velocity.y = 0
	elif is_attack:
		velocity.x = 0
	else:
		if direction:
			if direction > 0:
				player_anim.flip_h = false
				sword_area.position.x = 16 # To the right
				velocity.x = direction * SPEED
			elif direction < 0:
				player_anim.flip_h = true
				sword_area.position.x = -16 # To the left
				velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
	
	if Input.is_action_just_pressed("attack") and not is_attack:
		attack()
	
	move_and_slide()


# Called when the node enters the scene tree for the first time.
func _ready():
	sword_col.disabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Handle jump
func jump():
	# Im thinking for making the double jump is accessable after interact with the power up
	# by making the if nested, and check the boolean
	
	# Handle double jump
	# If on the floor reset the total jumps left
	if is_on_floor():
		jumps_left = 2
	
	if jumps_left > 1 && velocity.y >= 0.0:
		if Input.is_action_just_pressed("jump"):
			jump_sfx.play()
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1 
	elif jumps_left == 1 && velocity.y >= 0.0:
		if Input.is_action_just_pressed("jump"):
			jump_sfx.play()
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1 


# Handle attack
func attack():
	if is_on_floor():
		is_attack = true
		player_anim.play("attack")
		#attack_sfx.play()
		sword_area.monitoring = true
		sword_col.disabled = false
		
		await get_tree().create_timer(0.3).timeout
		sword_area.monitoring = false
		sword_col.disabled = true
		is_attack = false


# Handle dash
func dash():
	pass


# Handle animations
func set_animation(direction):
	if is_dash:
		player_anim.play("dash")
		return
	#elif is_dash and is_on_floor():
		#player_anim.play("dash")
		#return
	
	if is_attack and is_on_floor():
		player_anim.play("attack")
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


func _on_dash_duration_timeout():
	is_dash = false


func _on_dash_cooldown_timeout():
	can_dash = true


func _on_sword_area_body_entered(body):
	if is_attack and body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(1)
