extends CharacterBody2D

const SPEED = 180
const JUMP_VELOCITY = -300.0
@onready var sword = $Sword
@onready var collision_shape_2d = $Sword/CollisionShape2D
@onready var player_anim = $PlayerAnim
@onready var slime_anim = $SlimeAnim
@onready var attack_sfx = $AttackSfx
@onready var jump_sfx = $JumpSfx

var jumps_left : int = 0
const Total_Jumps : int = 2
var is_attacking = false

func _ready():
	sword.monitoring = false  # Disable sword hitbox by default
	$Sword.body_entered.connect(_on_sword_body_entered)
	

func _physics_process(delta):
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if not is_attacking:
		movement()
	
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

func movement():
	# Handle jump.
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
	
	# Im thinking for making the double jump is accesiable after interact with the power up
	# by making the if nested, and check the boolean
	
	# Handle double jump
	if is_on_floor():
		jumps_left = Total_Jumps
	
	if jumps_left > 0 && velocity.y >= 0.0:
		if Input.is_action_just_pressed("jump"):
			jump_sfx.play()
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1 

	# Get the input direction and handle the movement/deceleration, the value from input direction is: -1, 0, 1
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("move_left", "move_right")
	
	# Usable but suck as hell gonna change it later
	# Flip the sprite & Update sword position based on sprite facing
	if direction > 0:
		player_anim.flip_h = false
		sword.position.x = 14 # To the right
	elif direction < 0:
		player_anim.flip_h = true
		sword.position.x = -14 # To the left
	
	if is_on_floor():
		if direction == 0:
			player_anim.play("idle")
		else:
			player_anim.play("run")
	else:
		player_anim.play("jump")
	
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
		attack_sfx.play()
		sword.monitoring = true
		$Sword/CollisionShape2D.disabled = false
		
		await get_tree().create_timer(0.3).timeout
		sword.monitoring = false
		$Sword/CollisionShape2D.disabled = true
		is_attacking = false

# For detect enemies collision 
func _on_sword_body_entered(body):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage()
