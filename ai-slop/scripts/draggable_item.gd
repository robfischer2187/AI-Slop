extends Control

@export var item_name: String = "DOGS"

var dragging: bool = false
var offset: Vector2
var start_position: Vector2

func _ready():
	start_position = position
	add_to_group("draggable")

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			dragging = true
			offset = get_global_mouse_position() - global_position
		else:
			dragging = false

func _process(delta):
	if dragging:
		global_position = get_global_mouse_position() - offset
