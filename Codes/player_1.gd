extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

# For nodes
@onready var player_anim = $PlayerAnim
@onready var sword_col = $SwordArea/SwordCol
@onready var sword_area = $SwordArea
@onready var attack_cooldown = $AttackCooldown
@onready var dash_duration = $DashDuration

# For SFX
@onready var jump_sfx = $JumpSfx
@onready var jump_sfx_2 = $JumpSfx2

# For double jumps
var jumps_left = 0

# For attack
var is_attacking = false

# For dash
var is_dash = false
var can_dash = true
var dashDirection : int 


func _ready():
	sword_col.disabled = true


func _physics_process(delta):
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if not is_attacking and not is_dash:
		movement()
		jump()
	
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()
	
	if Input.is_action_just_pressed("dash") and can_dash:
		dash()
		


func movement():
	# Get the input direction and handle the movement/deceleration, the value from input direction is: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")
	
	# func
	#dash()
	
	# Flip the sprite & Update sword position based on sprite facing
	if direction > 0:
		player_anim.flip_h = false
		sword_area.position.x = 20 # To the right
	elif direction < 0:
		player_anim.flip_h = true
		sword_area.position.x = -20 # To the left
	
	# Handle animation state
	if is_on_floor():
		if direction == 0:
			player_anim.play("idle")
		else:
			player_anim.play("run")
	else:
		if velocity.y < 0:
			player_anim.play("jump")
		#elif velocity.y > 100:
			#player_anim.play("fall")
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


# Usable but suck as hell gonna change it later
func attack():
	if is_on_floor():
		is_attacking = true
		player_anim.play("attack")
		#attack_sfx.play()
		sword_area.monitoring = true
		sword_col.disabled = false
		
		await get_tree().create_timer(0.3).timeout
		sword_area.monitoring = false
		sword_col.disabled = true
		is_attacking = false
		


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
			jump_sfx_2.play()
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1 


func dash():
	if player_anim.flip_h:
		dashDirection = -1
	else:
		dashDirection = 1
	
	is_dash = true
	dash_duration.start()
	
	if is_dash:
		player_anim.play("dash")
		velocity.x = dashDirection * SPEED * 3
		velocity.y = 0


func _on_sword_area_body_entered(body):
	pass # Replace with function body.


func _on_dash_duration_timeout():
	is_dash = false
