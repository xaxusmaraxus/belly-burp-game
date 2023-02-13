extends Node

# TODO
# * Add dedicated move and release sounds
# * Add sound mapping (to match food, also move and release sounds)


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var sqm = $SoundQueueManager


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Grid_move_sound():
	pass # Replace with function body.


func _on_Grid_release_sound():
	pass # Replace with function body.


func _on_Grid_match_sound(_combo_number: int):
	print("match_sound event received. Arg: %s" % _combo_number)
	# var vanilla_burp = sqm.create_sound_event(0.0, 0, 1.0, 0.0, 20.0, 20000.0)
	var random_pitch = randf() * 0.2 + 0.9
	var filter_open = 0.5 + _combo_number * 0.5
	var pseudo_bandpass_burp = sqm.create_sound_event(0.0, 0, random_pitch, 0.0, 900.0 / filter_open, 2000.0 * filter_open)
	sqm.play(pseudo_bandpass_burp)
