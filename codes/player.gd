extends CharacterBody2D

const SPEED = 180
const JUMP_VELOCITY = -300.0
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var sword = $Sword

var jumps_left : int = 0
const Total_Jumps : int = 2
var is_attacking = false

func _ready():
	sword.monitoring = false  # Disable sword hitbox by default

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if not is_attacking:
		movement()
	
	update_sword_position()
	
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

func movement():
	# Handle jump.
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
	
	# Im thinking for making the double jump is accesiable after interact with the power up
	# by making the if nested
	# Handle double jump
	if is_on_floor():
		jumps_left = Total_Jumps
	
	if jumps_left > 0 && velocity.y >= 0.0:
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1 

	# Get the input direction and handle the movement/deceleration, the value from input direction is: -1, 0, 1
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("move_left", "move_right")
	
	# Flip the sprite
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true
	
	if is_on_floor():
		if direction == 0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("jump")
	
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
		animated_sprite_2d.play("attack")
		sword.monitoring = true
		
		await get_tree().create_timer(0.3).timeout
		sword.monitoring = false
		is_attacking = false

# Usable but suck as hell gonna change it later
# Update sword position based on sprite facing
func update_sword_position():
	if animated_sprite_2d.flip_h :
		sword.position.x = -12 # To the left
	else:
		sword.position.x = 12 # To the right
