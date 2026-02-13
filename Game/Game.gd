extends Node2D

enum {
	READY,
	PLAY,
	GAMEOVER
}

var state = READY
var score = 0

onready var grid = $Grid
onready var sign_screen = $Screens/SignScreen
onready var end_screen = $Screens/EndScreen
onready var sign_timer = $Screens/SignTimer
onready var kraken_button = $Area2D
onready var kraken_label = $Area2D/RichTextLabel
onready var burp_sound = $Burp_sound
onready var bear = $Bear
onready var tween = $scaling

# Visual effect nodes (create them if not exist)
onready var flash_overlay: ColorRect = _create_flash_overlay()

func _ready():
	randomize()
	grid.connect("waiting_started", self, "_on_Grid_waiting_started")
	grid.connect("waiting_finished", self, "_on_Grid_waiting_finished")
	end_screen.hide()
	sign_screen.show()
	sign_timer.start()
	
	# Connect kraken button input
	kraken_button.connect("input_event", self, "_on_KrakenButton_input")


func _create_flash_overlay() -> ColorRect:
	var flash = ColorRect.new()
	flash.name = "FlashOverlay"
	flash.color = Color(1, 1, 1, 0)
	flash.rect_min_size = Vector2(720, 1080)
	add_child(flash)
	return flash


func _on_KrakenButton_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		release_the_kraken()


func release_the_kraken():
	if state != PLAY:
		return
	
	print("🎆 RELEASE THE KRAKEN!")
	
	# 1. Play burp sound
	burp_sound.play()
	
	# 2. Clear the grid (remove all pieces)
	grid.clear_all_pieces()
	
	# 3. Calculate and add score (dopamine reward!)
	var combo_bonus = max(1, grid.combo) * 100
	var belch_bonus = grid.belch_size * 500
	score += 1000 + combo_bonus + belch_bonus
	print("Score: ", score)
	
	# 4. Dopamine visual effects - screen flashes!
	_trigger_dopamine_flashes()
	
	# 5. Bear animation - burp shake
	_bear_shake()
	
	# 6. Reset belch counter
	grid.belch_size = 0


func _trigger_dopamine_flashes():
	# Multiple rapid white flashes for dopamine hit!
	var flash_tween = Tween.new()
	add_child(flash_tween)
	
	# Sequence of flashes
	flash_tween.tween_property(flash_overlay, "color", Color(1, 1, 1, 0.8), 0.05)
	flash_tween.tween_property(flash_overlay, "color", Color(1, 1, 1, 0), 0.1)
	flash_tween.tween_callback(func(): flash_overlay.color = Color(1, 0.9, 0.5, 0.6))  # Warm glow
	flash_tween.tween_property(flash_overlay, "color", Color(1, 1, 1, 0), 0.15)
	flash_tween.tween_callback(func(): flash_overlay.color = Color(0.5, 1, 0.5, 0.4))  # Green glow
	flash_tween.tween_property(flash_overlay, "color", Color(1, 1, 1, 0), 0.1)
	flash_tween.tween_callback(func(): flash_overlay.color = Color(1, 0.8, 0.2, 0.5))  # Gold glow
	flash_tween.tween_property(flash_overlay, "color", Color(1, 1, 1, 0), 0.2)
	flash_tween.tween_callback(func(): flash_overlay.color = Color(1, 1, 1, 0))  # Clear


func _bear_shake():
	# Bear does a burp shake animation
	var original_pos = bear.position
	tween.interpolate_property(bear, "position", 
		original_pos, original_pos + Vector2(0, 20), 0.1, 
		Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	tween.interpolate_property(bear, "position", 
		original_pos + Vector2(0, 20), original_pos, 0.2, 
		Tween.TRANS_BOUNCE, Tween.EASE_IN)
	tween.start()


func _on_SignTimer_timeout():
	match state:
		READY:
			kraken_label.text = "Go!"
			state = PLAY
		PLAY:
			sign_timer.stop()
			sign_screen.hide()
		GAMEOVER:
			sign_screen.hide()
			end_screen.show_result(score)
			end_screen.show()


func lose():
	get_tree().paused = true
	state = GAMEOVER
	kraken_label.text = "GAME\nOVER!"
	sign_screen.show()
	sign_timer.start()


func _on_Grid_waiting_started():
	print("Player ended their move")


func _on_Grid_waiting_finished(matched_colors):
	print("Game finished calculating: ", matched_colors)
