extends CharacterBody2D

@export var health := 3
@export var speed := 20
@onready var slime_anim = $SlimeAnim

var knockback_velocity = Vector2.ZERO
var knockback_duration := 0.1
var knockback_timer := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	slime_anim.play("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if knockback_timer > 0:
		velocity = knockback_velocity
		knockback_timer -= delta
	else:
		pass
		#velocity = move_toward(velocity, Vector2.ZERO, 100 * delta)
	
	move_and_slide()

func take_damage(amount: int):
	health -= amount
	slime_anim.play("hit")  # Add a "hit" animation
	if health <= 0:
		queue_free()
