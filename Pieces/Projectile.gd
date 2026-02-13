extends RigidBody2D

export var velocity = Vector2()
export var speed = 100
export var gravity = 10
onready var scaling = $scaling
var deletable
var fill_value

#export var angle = 270 #upwards

# Called when the node enters the scene tree for the first time.
func _ready():
#	var beltdetector = get_tree().get_root().find_node("Game", true, false) #signal from "Game" node
#	beltdetector.connect("belt_detector", self, "move_belt")
#	var eating = get_tree().get_root().find_node("Game", true, false)
#	eating.connect("time_to_eat", self, "eat")  #problem: not only sent to current instance, but to all instances, that's why all will get affected
#	var ready_to_delete = get_tree().get_root().find_node("Game", true, false)
#	ready_to_delete.connect("ready_to_delete", self, "set_delete") 
#	scaling.interpolate_property($projectile, "scale", Vector2(1.5, 1.5), Vector2(3, 3), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
#	scaling.start()
	pass


func _physics_process(delta):
	if global_position.y >= 285 && global_position.x >= 320:
		eat()
	pass
#
#func set_delete():
#	deletable = true

#func move_belt(belt_entered):
#	print("MOVE BELT")
	
func eat():
	print("EATEATEAT")
	$"../AudioStreamPlayer".play()
	queue_free()
	var darm_node = get_tree().get_root().find_node("TextureProgress", true, false) #signal from "Game" node
	darm_node.value += 10
#	fill_value += 1
#	emit_signal("darm", fill_value)

func _on_scaling_tween_completed(object, key):
	if $projectile.scale == Vector2(3, 3):
		scaling.interpolate_property($projectile, "scale", Vector2(3, 3), Vector2(1.5, 1.5), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
		scaling.start()

	pass # Replace with function body.
	
func fill_stomach(color):
#	var projectile = load("res://Pieces/Projectile"+color+".tscn") #what is to be shot
#	var bullet = projectile.instance() #instancing var
#	add_child(bullet) #actual child added
#	print("shooting ", i_j_pix) #just to check the coordinates in pixels
	print("double check if color has passed ", color)
#	bullet.position = Vector2(100, 100) #telling godot the position of the sprite placement

	
