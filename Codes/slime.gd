extends Node2D

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
	pass
