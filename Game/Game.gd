extends Node2D

enum {
	READY,
	PLAY,
	GAMEOVER
}


var state = READY

onready var grid = $Grid
onready var sign_screen = $Screens/SignScreen
onready var end_screen = $Screens/EndScreen
onready var sign_timer = $Screens/SignTimer


func _ready():
	randomize()
	grid.connect("waiting_started", self, "_on_Grid_waiting_started")
	grid.connect("waiting_finished", self, "_on_Grid_waiting_finished")
	end_screen.hide()
	sign_screen.show()
	sign_timer.start()
#	

#func shoot():
#	var projectile = load("res://Pieces/Projectile.tscn")
#	var bullet = projectile.instance()
#	add_child(bullet)
#	print("shooting ", bullet)
#	bullet.position = Vector2(360, 750)

func _on_SignTimer_timeout():
	match state:
		READY:
			sign_screen.get_node("SignLabel").text = "Go!"
			state = PLAY
		PLAY:
			sign_timer.stop()
			sign_screen.hide()
		GAMEOVER:
			sign_screen.hide()
			end_screen.show_result(42)
			end_screen.show()


func lose():
	get_tree().paused = true
	state = GAMEOVER
	sign_screen.get_node("SignLabel").text = "GAME\nOVER!"
	sign_screen.show()
	sign_timer.start()


# Connected signal
func _on_Grid_waiting_started():
	print("This function gets triggered when the player has ended their move")


# Connected signal
func _on_Grid_waiting_finished(matched_colors):
	print("This function gets triggered when the game has finished calculating the effects of the player's move")
	print("Matched colors: %s" % str(matched_colors))
#	shoot()

