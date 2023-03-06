extends KinematicBody2D

var velocity = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	velocity.y = -200

func _physics_process(delta):
	move_and_slide(velocity)
