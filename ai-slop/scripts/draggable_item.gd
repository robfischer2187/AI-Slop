extends Control

@export var item_name: String = "DOGS"
@export var texture_path: String = ""
@export var is_correct: bool = false


var dragging: bool = false
var offset: Vector2
var start_position: Vector2
var drag_item: AudioStreamPlayer2D


func _ready():
	size = Vector2(80, 80)
	mouse_filter = Control.MOUSE_FILTER_STOP
	drag_item = AudioStreamPlayer2D.new()
	drag_item.stream = preload("res://assets/sounds/pick-item.mp3")
	drag_item.volume_db = 10.0
	add_child(drag_item)
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
	label.add_theme_font_size_override("font_size", 24)
	
	label.modulate = Color(0, 0, 0)
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	add_child(label)

func setup_image():
	var tex = $TextureRect
	
	if texture_path != "":
		tex.texture = load(texture_path)
	
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(72, 72)
	tex.size = size
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			dragging = true
			drag_item.play()
			offset = get_tree().get_root().get_node("Main").virtual_mouse_pos - global_position
		else:
			dragging = false
			get_tree().get_root().get_node("Main").try_drop_item(self)

func _process(_delta):
	if dragging:
		var mouse = get_tree().get_root().get_node("Main").virtual_mouse_pos
		global_position = mouse - offset
