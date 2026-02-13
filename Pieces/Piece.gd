extends Area2D

signal collided(self_piece)

export (String) var color
export (Texture) var square_face

var matched = false
var matched_index = 0
var held = false
var point = 0
var offset = Vector2(35, -35)

onready var sprite = $Sprite
onready var collision_shape = $CollisionShape2D
onready var tween = $Tween


func _process(_delta):
	if held:
		position = get_global_mouse_position() - offset


func move(destination):
	tween.interpolate_property(self, "position", position, destination, .1, Tween.TRANS_QUINT, Tween.EASE_IN)
	tween.start()


func make_matched(index):
	matched = true
	matched_index = index
#	sprite.texture = square_face
	var shoot_pixels = get_tree().get_root().find_node("Grid", true, false) #signal from "Game" node
	shoot_pixels.connect("shoot_pixels", self, "match_move")
	
func match_move(pixels):
	tween.interpolate_property(sprite, "scale", Vector2(1, 1), Vector2(.1, .1), 0.5, Tween.TRANS_EXPO, Tween.EASE_IN)
	tween.start()
	print("ITS HAPPENING")
#	sprite.global_position = shoot_pixels


func enable_held():
	held = true
	sprite.scale = Vector2(1.5, 1.5)
	collision_shape.position = Vector2(43.75, -43.75)


func disable_held():
	held = false
	sprite.scale = Vector2(1.3, 1.3)
	collision_shape.position = Vector2(35, -35)


func _on_Piece_area_entered(area):
	if area.is_in_group("Pieces") and area.held:
		emit_signal("collided", self)
