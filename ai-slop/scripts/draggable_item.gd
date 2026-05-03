extends Control

@export var item_name: String = "DOGS"

var dragging: bool = false
var offset: Vector2
var start_position: Vector2

func _ready():
	size = Vector2(80, 80)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	start_position = position
	add_to_group("draggable")
	rotation_degrees = randf_range(-8, 8)
	scale = Vector2.ONE * randf_range(0.9, 1.1)
	z_index = randi_range(0, 50)
	
	var use_text = randf() < 0.5
	
	if use_text:
		setup_text()
	else:
		setup_image()

func setup_text():
	var label = Label.new()
	label.text = item_name
	
	var font = load("res://assets/fonts/IBMPlexMono-SemiBold.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 18)
	
	label.modulate = Color(0, 0, 0)
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	add_child(label)

func setup_image():
	var tex = $TextureRect
	tex.texture = preload("res://icon.svg")
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(64, 64)
	tex.size = size
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			dragging = true
			offset = get_tree().get_root().get_node("Main").virtual_mouse_pos - global_position
		else:
			dragging = false
			get_tree().get_root().get_node("Main").try_drop_item(self)

func _process(_delta):
	if dragging:
		var mouse = get_tree().get_root().get_node("Main").virtual_mouse_pos
		global_position = mouse - offset
