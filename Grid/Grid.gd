extends Area2D

# TODO
# * Add position information to match_sound event (to set panning)
# * Add color/food information to match_sound event (to match burp to food)

signal waiting_started
signal waiting_finished(total_combo)
signal move_sound
signal match_sound(combo_number)
signal release_sound
signal shoot_pixels
signal color_info(color)

const pieces_scn = [
	preload("res://Pieces/PieceBeige.tscn"),
	preload("res://Pieces/PieceBlue.tscn"),
	preload("res://Pieces/PieceGreen.tscn"),
	preload("res://Pieces/PiecePink.tscn"),
	preload("res://Pieces/PieceYellow.tscn")
]

const combo_obj_scn = preload("res://Signs/Combo.tscn")

var width: = 7
var height: = 6
var x_start: = 30
var y_start: = 1070
var grid_size: = 95
var y_offset: = 3

var board = []
var moving_piece
var last_pos = Vector2()

var is_initializing = true
var is_touching = false
var is_swapping = false
var is_waiting = false

var matched_groups = 0
var matched_colors: Array = []
var combo: int = 0
var shoot_pixels
var sound = 0
var randomsound = RandomNumberGenerator.new()
var color_info
var scale_shoot
var belch_size = 0

onready var pieces_container = $PiecesContainer
onready var wait_timer = $WaitTimer

func _ready():
	randomize()
	board = make_2d_array()
	spawn_pieces()
	is_initializing = false

func make_2d_array() -> Array:
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array


func spawn_pieces():
	print("start spawn_pieces")
	for i in width:
		for j in height:
			if board[i][j] == null:
				var index = floor(rand_range(0, pieces_scn.size()))
				var piece = pieces_scn[index].instance()
				if is_initializing:
					while match_at(i, j, piece.color):
						piece.queue_free()
						index = floor(rand_range(0, pieces_scn.size()))
						piece = pieces_scn[index].instance()
				pieces_container.add_child(piece)
				piece.connect("collided", self, "_on_Piece_collided")
				piece.position = grid_to_pixel(i, j + y_offset)
				piece.move(grid_to_pixel(i, j))
				board[i][j] = piece
	print("end spawn_pieces")
	


func match_at(column, row, color):
	if column >= 2:
		if board[column-1][row] != null and board[column-2][row] != null:
			if board[column-1][row].color == color and board[column-2][row].color == color:
				return true
	if row >= 2:
		if board[column][row-1] != null and board[column][row-2] != null:
			if board[column][row-1].color == color and board[column][row-2].color == color:
				return true


func grid_to_pixel(column, row) -> Vector2:
	var pixel_pos = Vector2()
	pixel_pos.x = x_start + grid_size * column
	pixel_pos.y = y_start - grid_size * row
	return pixel_pos


func pixel_to_grid(pixel_x, pixel_y) -> Vector2:
	var grid_pos = Vector2()
	grid_pos.x = floor((pixel_x - x_start) / grid_size)
	grid_pos.y = floor((pixel_y - y_start) / -grid_size)
	return grid_pos


func is_in_grid(grid_position: Vector2) -> bool:
	if grid_position.x >= 0 and grid_position.x < width \
	and grid_position.y >= 0 and grid_position.y < height:
		return true
	else:
		return false


func _process(_delta):
#	if $"../Darm/TextureProgress".value == 100:
#		print("BUUUURP")
#		$"../Burp_sound".play()
#		$"../Darm/TextureProgress".value = 0
	if belch_size == 5:
		for n in belch_size:
#			emit_signal("match_sound", n)
			$"../Burp_sound".play()
			print(n)
			n -= 1
	if not is_waiting:
		touch_input()


func touch_input():
	if Input.is_action_just_pressed("touch"):
		touch_piece()
	if Input.is_action_just_released("touch") and is_touching:
		release_piece()


func touch_piece():
	var pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(pos.x, pos.y)
	if is_in_grid(grid_pos):
		last_pos = grid_pos
		moving_piece = board[last_pos.x][last_pos.y]
		is_touching = true
		moving_piece.enable_held()


func release_piece():
	for i in width:
		for j in height:
			if board[i][j] == moving_piece:
				moving_piece.move(grid_to_pixel(i, j))
				break
	moving_piece.disable_held()
	is_touching = false
	emit_signal("release_sound")
	emit_signal("waiting_started")
	acid_reflux() #hook acid reflux here


# connected signal
func _on_Piece_collided(self_piece):
	if is_touching and not is_swapping:
		is_swapping = true
		swap_pieces(self_piece)
		is_swapping = false


func swap_pieces(collided_piece):
	var collided_pos = pixel_to_grid(collided_piece.position.x, collided_piece.position.y)
	if board[last_pos.x][last_pos.y] == moving_piece:
		board[last_pos.x][last_pos.y] = collided_piece
		collided_piece.move(grid_to_pixel(last_pos.x, last_pos.y))
		board[collided_pos.x][collided_pos.y] = moving_piece
		last_pos = collided_pos
		emit_signal("move_sound")


func _on_Grid_area_exited(area):
	if area.is_in_group("Pieces") and area.held:
		release_piece()


func _on_TouchTimer_timeout():
	if is_touching:
		release_piece()


func _on_Grid_waiting_started():
	is_waiting = true
	
	while check_matches():
		find_matches()
		wait_timer.start()
		yield(wait_timer, "timeout")
		if matched_groups > 0:
			for index in range(1, matched_groups + 1):
				combo += 1
				delete_matches(index)
				wait_timer.start()
				yield(wait_timer, "timeout")
			matched_groups = 0
		collapse_columns()
		wait_timer.start()
		yield(wait_timer, "timeout")
		spawn_pieces()
		wait_timer.start()
		yield(wait_timer, "timeout")
	
	is_waiting = false
	emit_signal("waiting_finished", matched_colors.duplicate())
	combo = 0
	matched_colors.clear()



func find_matches():
	print("start find_matches")
	for i in width:
		for j in height:
			if board[i][j] != null:
				var current_color = board[i][j].color
				if i < width - 2:
					if board[i+1][j] != null \
					and board[i+2][j] != null:
						if board[i+1][j].color == current_color \
						and board[i+2][j].color == current_color:
							var matched_index: int
							if board[i][j].matched:
								matched_index = board[i][j].matched_index
							else:
								matched_groups += 1
								matched_index = matched_groups
								matched_colors.append(current_color)
#							shoot_pixels = grid_to_pixel(i+1, j) #shooting the matches upwards, shooting where the match is version
							shoot_pixels = Vector2(550,50) #dropdown version
							scale_shoot = Vector2(1.5, 1.5)
							shoot(shoot_pixels, current_color, scale_shoot) #shooting the matches upwards, passing the position of the match and it's color
							board[i][j].make_matched(matched_index)
							board[i+1][j].make_matched(matched_index)
							board[i+2][j].make_matched(matched_index)
				if j < height - 2:
					if board[i][j+1] != null \
					and board[i][j+2] != null:
						if board[i][j+1].color == current_color \
						and board[i][j+2].color == current_color:
							var matched_index: int
							if board[i][j].matched:
								matched_index = board[i][j].matched_index
							else:
								matched_groups += 1
								matched_index = matched_groups
								matched_colors.append(current_color)
#							shoot_pixels = grid_to_pixel(i, j+1) #shooting the matches upwards, shooting where the match is version
							shoot_pixels = Vector2(550,50) #dropdown version
							scale_shoot = Vector2(1.5, 1.5)
							shoot(shoot_pixels, current_color, scale_shoot) #shooting the matches upwards, passing the position of the match and it's color
							board[i][j].make_matched(matched_index)
							board[i][j+1].make_matched(matched_index)
							board[i][j+2].make_matched(matched_index)
	print("end find_matches")

#shooting the matches upwards function
func acid_reflux():
	$"../dynamicwater".scale.y += 1
	$"../Plate/CollisionShape2D".position.y -= 10

func shoot(i_j_pix, color, scale):
	if color == null:
		print("no shootery")
	else:
		var projectile = load("res://Pieces/Projectile"+color+".tscn") #what is to be shot
		var bullet = projectile.instance() #instancing var
		print("color      ", color)
		add_child(bullet) #actual child added
	##	print("shooting ", i_j_pix) #just to check the coordinates in pixels
	##	print("double check if color has passed ", projectile)
		bullet.get_tree().get_root().find_node("projectile_absolute", true, false).scale = scale
		bullet.position = i_j_pix #telling godot the position of the sprite placement
		color_info = color
#		emit_signal("color_info", projectile)
#		color_info = color
	
	


func delete_matches(index):
	print("start delete_matches")
	# emit_signal("deleting_matches")  # TODO: emit this with color information; probably not right here
	var combo_displayed = false
	for i in width:
		for j in height:
			if board[i][j] != null:
				if board[i][j].matched:
					if board[i][j].matched_index == index:
						if combo_displayed == false:
							combo_displayed = true
							spawn_combo_count(board[i][j])
						emit_signal("shoot_pixels")
						board[i][j].queue_free()
						board[i][j] = null
	play_sound()
	print("end delete_matches")

func play_sound():
	var val = randomsound.randi_range(1,5)
	var snd = get_node("../TEMP_SOUNDS/s"+str(val))
	snd.play()
#	yield(snd, "finished")

func spawn_combo_count(first_piece):
	var combo_obj = combo_obj_scn.instance()
	combo_obj.position = first_piece.position
	add_child(combo_obj)
	combo_obj.display_combo(combo)


func collapse_columns():
	print("start collapse_columns")
	for i in width:
		for j in height:
			if board[i][j] == null:
				for k in range(j + 1, height):
					if board[i][k] != null:
						board[i][k].move(grid_to_pixel(i, j))
						board[i][j] = board[i][k]
						board[i][k] = null
						break
	print("end collapse_columns")


func check_matches() -> bool:
	print("start check_matches")
	for i in width:
		for j in height:
			if board[i][j] != null:
				if match_at(i, j, board[i][j].color):
					print("end check_matches")
					return true
	print("end check_matches")
	return false




func _on_Stomach_detector_body_entered(body):
	$"../Stomach_detector/Timer".start()
	pass # Replace with function body.


func _on_Timer_timeout():
	var stomach_opening = Vector2(193, 64)
	var scale_bullet = Vector2(1.5, 1.5)
	shoot(stomach_opening, color_info, scale_bullet)
	belch_size += 1
	pass # Replace with function body.

