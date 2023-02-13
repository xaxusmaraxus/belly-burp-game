extends Node2D

enum {
	READY,
	PLAY,
	GAMEOVER
}


export (int) var power = 10
var life: int = 10
var level: int = 1
var state = READY
var enemy #Inherited Enemy node

onready var ui = $UI
onready var grid = $Grid
onready var sign_screen = $Screens/SignScreen
onready var end_screen = $Screens/EndScreen
onready var sign_timer = $Screens/SignTimer


func _ready():
	randomize()
	grid.connect("waiting_started", self, "_on_Grid_waiting_started")
	grid.connect("waiting_finished", self, "_on_Grid_waiting_finished")
	ui.update_level(level)
	ui.update_life(life)
	end_screen.hide()
	sign_screen.show()
	sign_timer.start()


func _on_SignTimer_timeout():
	match state:
		READY:
			sign_screen.get_node("SignLabel").text = "Go!"
			state = PLAY
		PLAY:
			sign_timer.stop()
			sign_screen.hide()
			# spawn_enemy()
		GAMEOVER:
			sign_screen.hide()
			end_screen.show_result(level - 1)
			end_screen.show()


func lose():
	get_tree().paused = true
	state = GAMEOVER
	sign_screen.get_node("SignLabel").text = "GAME\nOVER!"
	sign_screen.show()
	sign_timer.start()


# Connected signal
func _on_Grid_waiting_started():
	if enemy != null:
		enemy.attack_timer.paused = true


# Connected signal
func _on_Grid_waiting_finished(total_combo):
	if enemy != null:
		enemy.hit(power, total_combo)

