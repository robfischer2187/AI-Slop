extends Control

enum Phase { LOGIN, LOADING, WELCOME, PROMPT }

@export var loading_seconds: float = 1.6
@export var welcome_hold_seconds: float = 2.5
@export var debug_fast_mode := false

@onready var login_panel: Control = get_node("LoginPanel")
@onready var loading_panel: Control = get_node("LoadingPanel")
@onready var welcome_panel: Control = get_node("WelcomePanel")

@onready var login_button: Button = get_node("LoginPanel/LoginButton")
@onready var progress_bar: ProgressBar = get_node("LoadingPanel/ProgressBar")
@onready var welcome_label: Label = get_node("WelcomePanel/WelcomeLabel")

@onready var support_prompt: Control = get_node("SupportPrompt")
@onready var sep: VSeparator = get_node("SupportPrompt/Panel/VBoxContainer/VSeparator2")
@onready var sep3: VSeparator = get_node("SupportPrompt/Panel/VBoxContainer/VSeparator3")
@onready var comp: Label = get_node("SupportPrompt/Panel/VBoxContainer/Label")
@onready var prompt_text: RichTextLabel = get_node("SupportPrompt/Panel/VBoxContainer/PromptText")
@onready var yes_button: Button = get_node("SupportPrompt/Panel/VBoxContainer/HBoxContainer/YesButton")
@onready var no_button: Button = get_node("SupportPrompt/Panel/VBoxContainer/HBoxContainer/NoButton")

@onready var alastor: Node2D = get_node("../../../../AlastorRoot")
@onready var slot: TextureRect = get_node("../InputSlots/Slot")

@onready var cursor_blocker: Control = get_node("../CursorBlockerArea")
@onready var fake_cursor: Sprite2D = get_node("../FakeCursor")

@onready var username_input: LineEdit = get_node("LoginPanel/UsernameInput")

@onready var screen_mat: ShaderMaterial = get_node("../ScreenOverlay/EffectRect").material
@onready var glitch_overlay: ColorRect = get_node("../../PCScreenArea/GlitchOverlay")
@onready var pc_screen: Control = get_node("../../PCScreenArea")
@onready var ui_container: Control = get_node("../..")
@onready var foto: Control = get_node("SupportPrompt/Panel/Foto")
@onready var coworkers_texture: TextureRect = get_node("../../../../Coworkers")

var virtual_mouse_pos: Vector2
var free_mouse := false

signal startup_finished(support_forced: bool)

var click_player: AudioStreamPlayer
var prestart_overlay: Control
var prestart_logo_layer: Control
var prestart_logo: TextureRect
var prestart_start_button: Button
var prestart_credit_button: Button
var no_glitch_player: AudioStreamPlayer
var typing_player: AudioStreamPlayer
var glitch_player: AudioStreamPlayer
var title_music: AudioStreamPlayer
var breath_player: AudioStreamPlayer

var phase: Phase = Phase.LOGIN
var employee_id: String = ""
var support_forced: bool = false
var forced_yes_mode := false
var start_message_visible := false
var intro_message_active := false
var skip_typewriter := false
var original_employee_id: String = ""

var coworkers_default_texture: Texture
var btn_font = load("res://assets/fonts/IBMPlexMono-SemiBold.ttf")

func _input(event):
	if intro_message_active and event is InputEventMouseButton and event.pressed:
		skip_typewriter = true
		
		click_player.pitch_scale = randf_range(0.3, 4.1)
		click_player.play()

func _ready() -> void:
	_reset_visual_state()
	if debug_fast_mode:
		loading_seconds = 0.3
		welcome_hold_seconds = 0.1

	_set_phase(Phase.LOGIN)
	login_panel.visible = false

	login_button.pressed.connect(_on_login_pressed)
	login_button.pressed.connect(_play_click_sound)

	yes_button.pressed.connect(_on_support_yes)
	no_button.pressed.connect(_on_support_no)

	if alastor != null:
		alastor.visible = false

	click_player = AudioStreamPlayer.new()
	click_player.stream = preload("res://assets/sounds/mouse-click.mp3")
	add_child(click_player)

	support_prompt.visible = false

	init_virtual_mouse()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	set_process(true)

	username_input.text_submitted.connect(_on_username_submitted)

	username_input.visible = false

	username_input.text_changed.connect(_on_username_changed)

	call_deferred("_create_prestart_overlay")

	if foto != null:
		foto.visible = false
		foto.modulate.a = 0.0

	if sep3 != null:
		sep3.visible = false
		sep3.modulate.a = 0.0

	coworkers_default_texture = coworkers_texture.texture

	typing_player = AudioStreamPlayer.new()
	typing_player.stream = preload("res://assets/sounds/Text_Appearing_Sound.mp3")
	typing_player.bus = "Master"
	add_child(typing_player)

	yes_button.pressed.connect(_play_click_sound)
	no_button.pressed.connect(_play_click_sound)

	glitch_player = AudioStreamPlayer.new()
	add_child(glitch_player)
	
	no_glitch_player = AudioStreamPlayer.new()
	no_glitch_player.stream = preload("res://assets/sounds/glitch.mp3")
	no_glitch_player.pitch_scale = randf_range(0.6, 1.2)
	no_glitch_player.volume_db = 6
	add_child(no_glitch_player)

	title_music = AudioStreamPlayer.new()
	title_music.stream = preload("res://assets/sounds/title_loop.mp3")
	title_music.bus = "Master"
	title_music.volume_db = -4
	title_music.autoplay = false
	title_music.stream.loop = true
	add_child(title_music)

	title_music.play()

	breath_player = AudioStreamPlayer.new()
	breath_player.stream = preload("res://assets/sounds/heavy_breath.mp3")
	breath_player.bus = "Master"
	breath_player.volume_db = -10
	add_child(breath_player)
	call_deferred("_play_intro_breath")

func _play_intro_breath():
	await get_tree().create_timer(0.5).timeout
	
	breath_player.pitch_scale = randf_range(0.9, 1.05)
	breath_player.volume_db = -10
	breath_player.play()

func _play_glitch_sound():
	var sounds = [
		preload("res://assets/sounds/glitch.mp3"),
		preload("res://assets/sounds/glitch2.mp3"),
		preload("res://assets/sounds/glitch3.mp3")
	]
	
	glitch_player.stop()
	glitch_player.stream = sounds.pick_random()
	glitch_player.pitch_scale = randf_range(1.7, 2.3)
	glitch_player.volume_db = randf_range(3, 8)
	glitch_player.play()

func flash_coworkers_caught(duration: float):
	coworkers_texture.texture = load("res://assets/art/AI GAME COWORKER CAUGHT (1).png")
	
	await get_tree().create_timer(duration).timeout
	
	if coworkers_texture:
		coworkers_texture.texture = coworkers_default_texture

func _on_username_changed(new_text: String) -> void:
	var upper = new_text.to_upper()
	
	if new_text != upper:
		var caret = username_input.caret_column
		username_input.text = upper
		username_input.caret_column = caret
	
	click_player.pitch_scale = randf_range(0.9, 1.1)
	click_player.play()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_prestart_overlay()

func _create_prestart_overlay() -> void:
	if prestart_overlay != null:
		return

	var menu_layer := CanvasLayer.new()
	menu_layer.layer = 100
	add_child(menu_layer)

	prestart_overlay = Control.new()
	prestart_overlay.name = "PreStartOverlay"
	prestart_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	prestart_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(prestart_overlay)

	prestart_logo_layer = Control.new()
	prestart_logo_layer.name = "PreStartLogoLayer"
	prestart_logo_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	prestart_logo_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(prestart_logo_layer)

	prestart_logo = TextureRect.new()
	prestart_logo.name = "MenuLogo"
	prestart_logo.texture = load("res://assets/art/AI GAME menu logo.png")
	prestart_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prestart_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prestart_logo.custom_minimum_size = Vector2(1820, 900)
	prestart_logo.size = Vector2(1820, 900)
	prestart_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prestart_logo_layer.add_child(prestart_logo)

	prestart_start_button = Button.new()
	prestart_start_button.name = "StartButton"
	prestart_start_button.text = "START"
	prestart_start_button.custom_minimum_size = Vector2(320, 90)
	prestart_start_button.add_theme_color_override("font_color", login_button.get_theme_color("font_color"))
	prestart_start_button.add_theme_font_override("font", btn_font)
	prestart_start_button.add_theme_font_size_override("font_size", 37)
	prestart_start_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	prestart_start_button.add_theme_color_override("font_pressed_color", login_button.get_theme_color("font_color"))
	prestart_start_button.mouse_filter = Control.MOUSE_FILTER_STOP
	prestart_start_button.pressed.connect(_on_prestart_start_pressed)
	prestart_start_button.pressed.connect(_play_click_sound)
	pc_screen.add_child(prestart_start_button)

	prestart_credit_button = Button.new()
	prestart_credit_button.name = "CreditButton"
	prestart_credit_button.text = "CREDIT"
	prestart_credit_button.custom_minimum_size = Vector2(320, 90)
	prestart_credit_button.add_theme_color_override("font_color", login_button.get_theme_color("font_color"))
	prestart_credit_button.add_theme_font_override("font", btn_font)
	prestart_credit_button.add_theme_font_size_override("font_size", 37)
	prestart_credit_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	prestart_credit_button.add_theme_color_override("font_pressed_color", login_button.get_theme_color("font_color"))
	prestart_credit_button.mouse_filter = Control.MOUSE_FILTER_STOP
	pc_screen.add_child(prestart_credit_button)
	prestart_credit_button.pressed.connect(_on_credit_pressed)
	prestart_credit_button.pressed.connect(_play_click_sound)

	if fake_cursor != null:
		fake_cursor.z_index = 999

	_layout_prestart_overlay()

func _layout_prestart_overlay() -> void:
	if prestart_overlay == null:
		return

	var screen_rect = pc_screen.get_global_rect()
	var center = screen_rect.position + screen_rect.size * 0.5

	if prestart_logo != null:
		prestart_logo.position = Vector2(
			center.x - (prestart_logo.size.x * 0.5),
			screen_rect.position.y - (prestart_logo.size.y * 0.5) - 40.0
		)

	var spacing := 120.0

	if prestart_start_button != null:
		prestart_start_button.global_position = Vector2(
			center.x - (prestart_start_button.size.x * 0.5),
			center.y - spacing * 0.5
		)

	if prestart_credit_button != null:
		prestart_credit_button.global_position = Vector2(
			center.x - (prestart_credit_button.size.x * 0.5),
			center.y + spacing * 0.5
		)

func _menu_start_glitch():
	var mat := screen_mat
	
	var duration = 0.4
	var elapsed = 0.0
	
	while elapsed < duration:
		elapsed += 0.01
		await get_tree().create_timer(0.01).timeout
		
		mat.set_shader_parameter("glitch_intensity", randf_range(1.2, 2.2))
		mat.set_shader_parameter("glitch_time", Time.get_ticks_msec() * randf_range(0.004, 0.02))
		
		glitch_overlay.modulate.a = randf_range(0.4, 1.0)
		
		if randf() < 0.4:
			_play_glitch_sound()
	
	glitch_overlay.modulate.a = 0.0
	
	mat.set_shader_parameter("glitch_intensity", 0.01)

func _on_prestart_start_pressed() -> void:
	await _menu_start_glitch()

	if title_music:
		title_music.stop()
	
	if prestart_overlay != null:
		var layer = prestart_overlay.get_parent()
		layer.queue_free()
		prestart_overlay = null
		prestart_logo_layer = null

	if prestart_start_button != null:
		prestart_start_button.queue_free()
		prestart_start_button = null

	if prestart_credit_button != null:
		prestart_credit_button.queue_free()
		prestart_credit_button = null

	if fake_cursor != null:
		fake_cursor.z_index = 100

	_set_phase(Phase.LOGIN)
	login_panel.visible = true
	login_button.disabled = false
	login_button.visible = true
	username_input.visible = false
	username_input.editable = true

func _on_credit_pressed():
	var main = get_tree().current_scene
	if main.has_method("show_credits"):
		await main.show_credits()

func _process(_delta):
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	update_virtual_mouse()
	
	if fake_cursor != null:
		fake_cursor.global_position = virtual_mouse_pos
	
	if prestart_logo != null and randf() < 0.01:
		_glitch_logo()

func _glitch_logo():
	if prestart_logo == null:
		return
	
	var original_pos = prestart_logo.position
	var original_rot = prestart_logo.rotation_degrees
	
	for i in range(randi_range(2, 5)):
		if not is_instance_valid(prestart_logo):
			return
		
		prestart_logo.position = original_pos + Vector2(
			randf_range(-8, 8),
			randf_range(-6, 6)
		)
		
		prestart_logo.rotation_degrees = original_rot + randf_range(-3, 3)
		prestart_logo.visible = randf() > 0.3
		
		await get_tree().create_timer(randf_range(0.01, 0.03)).timeout
	
	if not is_instance_valid(prestart_logo):
		return
	
	prestart_logo.position = original_pos
	prestart_logo.rotation_degrees = original_rot
	prestart_logo.visible = true

func _play_click_sound() -> void:
	click_player.play()

func _set_phase(p: Phase) -> void:
	phase = p
	login_panel.visible = (p == Phase.LOGIN)
	loading_panel.visible = (p == Phase.LOADING)
	welcome_panel.visible = (p == Phase.WELCOME)

func _on_login_pressed() -> void:
	login_button.disabled = true
	login_button.visible = false
	username_input.visible = true
	username_input.grab_focus()
	username_input.modulate.a = 0
	var t = create_tween()
	t.tween_property(username_input, "modulate:a", 1.0, 0.15)

func _on_username_submitted(text: String) -> void:
	click_player.pitch_scale = randf_range(0.9, 1.1)
	click_player.play()
	
	var input_text = text.strip_edges()
	
	if input_text == "":
		input_text = "G4M3J4M"
	
	original_employee_id = input_text.to_upper()
	
	employee_id = input_text.to_upper()
	employee_id = employee_id.substr(0, 10)
	
	var manipulation_roll = randf()
	
	if manipulation_roll < 0.35:
		employee_id = employee_id.replace("A", "4")
		employee_id = employee_id.replace("E", "3")
		employee_id = employee_id.replace("I", "1")
	
	elif manipulation_roll < 0.6:
		if employee_id.length() > 2:
			var idx = randi_range(0, employee_id.length() - 1)
			var chars = employee_id.split("")
			chars[idx] = ["X", "#", "%", "?"].pick_random()
			employee_id = "".join(chars)
	
	elif manipulation_roll < 0.8:
		employee_id += str(randi_range(1, 9))
	
	else:
		employee_id = employee_id.reverse()
	
	username_input.text = employee_id
	username_input.editable = false
	
	_set_phase(Phase.LOADING)
	await _play_loading()
	await _show_welcome_then_prompt()

func _play_loading() -> void:
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.show_percentage = false

	var t := 0.0
	while t < loading_seconds:
		await get_tree().process_frame
		t += get_process_delta_time()
		progress_bar.value = clampf((t / loading_seconds) * 100.0, 0.0, 100.0)

	progress_bar.value = 100

func _show_welcome_then_prompt() -> void:
	_set_phase(Phase.WELCOME)
	var data = _get_special_welcome_text(original_employee_id)

	if data["delay"] > 0.0:
		await get_tree().create_timer(data["delay"]).timeout

	if data["glitch"]:
		await _play_al_name_glitch()
	else:
		welcome_label.text = data["text"]

	await get_tree().create_timer(welcome_hold_seconds).timeout

	_set_phase(Phase.PROMPT)
	show_intro_message()

func show_intro_message():
	intro_message_active = true
	support_prompt.visible = true
	comp.visible = false
	sep.visible = false

	if foto != null:
		foto.visible = true
		foto.modulate.a = 0.0
		var t1 = create_tween()
		t1.tween_property(foto, "modulate:a", 1.0, 0.3)

	if sep3 != null:
		sep3.visible = true
		sep3.modulate.a = 0.0
		var t2 = create_tween()
		t2.tween_property(sep3, "modulate:a", 1.0, 0.3)

	yes_button.visible = false
	no_button.visible = false

	var text = "Today, you are tasked with AI Content Supply Flow.\n" + \
"Your task is to [color=red]feed[/color] the Artificial Intelligence\n" + \
"with content that corresponds to the prompt\n" + \
"given to you at the top of your screen.\n" + \
"You are required to provide exactly [color=red]24 correct inputs[/color].\n" + \
"Each incorrect input brings the system closer to failure.\n" + \
"At [color=red]24 errors[/color], the damage becomes [color=red]irreversible[/color].\n" + \
"This is your supervisor,\n[color=red]Mr. Alastor Slopp.[/color]\n" + \
"He will be monitoring your progress.\n" + \
"Ask him for help if you encounter problems.\n" + \
"Thank you for your hard work.\n\n" + \
"You can't spell SM[color=red]AI[/color]LE without AI."

	prompt_text.bbcode_enabled = true
	prompt_text.add_theme_font_size_override("normal_font_size", 18)
	prompt_text.clear()

	typewriter_intro(text)

func typewriter_intro(text: String) -> void:
	var visible_text := ""
	skip_typewriter = false

	typing_player.pitch_scale = randf_range(0.9, 1.05)
	typing_player.volume_db = randf_range(-4, -1)
	typing_player.play()

	for i in range(text.length()):
		if skip_typewriter:
			typing_player.stop()
			prompt_text.clear()
			prompt_text.append_text(text)
			break

		visible_text += text[i]
		prompt_text.clear()
		prompt_text.append_text(visible_text)

		if randf() < 0.08:
			typing_player.pitch_scale = randf_range(0.88, 1.08)

		if randf() < 0.05:
			typing_player.volume_db = randf_range(-5, -1)

		await get_tree().process_frame

	if typing_player.playing:
		typing_player.stop()

	yes_button.visible = true
	yes_button.modulate.a = 0.0
	yes_button.text = "CONTINUE"

	var t = create_tween()
	t.tween_property(yes_button, "modulate:a", 1.0, 0.2)

func show_prompt_default():
	forced_yes_mode = false
	support_prompt.visible = true
	no_button.visible = false
	yes_button.visible = false

	await set_prompt_text_glitch("DO YOU SUPPORT AI?")
	await set_prompt_text_glitch("DO YOU SUPPORT AI?")

	await get_tree().create_timer(0.4).timeout
	yes_button.visible = true
	no_button.visible = true

func _on_support_yes() -> void:
	if intro_message_active:
		intro_message_active = false

		shrink_prompt_text()

		if foto != null:
			var t1 = create_tween()
			t1.tween_property(foto, "modulate:a", 0.0, 0.2)
			await t1.finished
			foto.visible = false

		if sep3 != null:
			var t2 = create_tween()
			t2.tween_property(sep3, "modulate:a", 0.0, 0.2)
			await t2.finished
			sep3.visible = false

		sep.visible = true
		comp.visible = true
		yes_button.text = "YES"

		prompt_text.add_theme_font_size_override("normal_font_size", 37)
		show_prompt_default()
		return

	if not start_message_visible:
		start_message_visible = true
		await show_start_message()
		return

	start_message_visible = false

	if alastor != null:
		alastor.visible = true

	if slot != null:
		slot.visible = true

	support_prompt.visible = false
	support_forced = forced_yes_mode
	_finish_startup()

func _on_support_no() -> void:
	support_forced = true
	forced_yes_mode = true

	no_button.text = "..."
	
	no_glitch_player.play()
	
	var glitch_duration = 0.35
	
	flash_coworkers_caught(glitch_duration)
	
	await trigger_violent_glitch()
	
	await get_tree().create_timer(0.1).timeout
	
	no_button.visible = false
	
	await set_prompt_text_glitch("ERR0R: INV4LID RESP0NS3 - trY aGa1n")

func show_start_message():
	await set_prompt_text_glitch("PROCEED AS INSTRUCTED")
	no_button.visible = false
	yes_button.text = "OK"

func set_prompt_text_glitch(text: String):
	prompt_text.clear()

	var visible_text := ""

	for i in range(text.length()):
		var c = text[i]

		if randf() < 0.25:
			visible_text += ["#", "%", "?", "@", "!", "0"].pick_random()
			prompt_text.clear()
			prompt_text.append_text(visible_text)
			await get_tree().create_timer(randf_range(0.005, 0.02)).timeout

			if randf() < 0.7 and visible_text.length() > 0:
				visible_text = visible_text.substr(0, visible_text.length() - 1)

		visible_text += c
		prompt_text.clear()
		prompt_text.append_text(visible_text)

		if randf() < 0.15:
			var scramble_len = randi_range(1, 3)
			var temp := visible_text
			for j in range(scramble_len):
				temp += ["#", "%", "?", "@", "X"].pick_random()

			prompt_text.clear()
			prompt_text.append_text(temp)
			await get_tree().create_timer(randf_range(0.01, 0.03)).timeout

			prompt_text.clear()
			prompt_text.append_text(visible_text)

		if randf() < 0.08 and visible_text.length() > 2:
			var back = randi_range(1, 2)
			visible_text = visible_text.substr(0, visible_text.length() - back)

		await get_tree().create_timer(randf_range(0.01, 0.035)).timeout

	if randf() < 0.4:
		await get_tree().create_timer(0.05).timeout

		var corrupted := ""
		for c in text:
			if randf() < 0.2:
				corrupted += ["#", "%", "?", "@", "X"].pick_random()
			else:
				corrupted += c

		prompt_text.clear()
		prompt_text.append_text(corrupted)

		await get_tree().create_timer(0.06).timeout
		prompt_text.clear()
		prompt_text.append_text(text)

func _finish_startup() -> void:
	startup_finished.emit(support_forced)

func init_virtual_mouse():
	var rect = cursor_blocker.get_global_rect()
	virtual_mouse_pos = rect.position + rect.size * 0.5
	virtual_mouse_pos.y += rect.size.y * 0.1

func update_virtual_mouse():
	if free_mouse:
		virtual_mouse_pos = get_global_mouse_position()
		return
	
	var rect = cursor_blocker.get_global_rect()
	var real = get_global_mouse_position()
	
	virtual_mouse_pos.x = clamp(real.x, rect.position.x, rect.end.x)
	virtual_mouse_pos.y = clamp(real.y, rect.position.y, rect.end.y)

func trigger_violent_glitch():
	var mat := screen_mat
	var original_pos = pc_screen.position
	
	var duration = 0.35
	var elapsed = 0.0
	
	while elapsed < duration:
		elapsed += 0.01
		await get_tree().create_timer(0.01).timeout
		
		mat.set_shader_parameter("glitch_intensity", randf_range(1.2, 2.5))
		mat.set_shader_parameter("glitch_time", Time.get_ticks_msec() * randf_range(0.005, 0.02))
		
		pc_screen.position = original_pos + Vector2(
			randf_range(-12, 12),
			randf_range(-12, 12)
		)
		
		glitch_overlay.modulate.a = randf_range(0.4, 1.0)
	
	pc_screen.position = original_pos
	glitch_overlay.modulate.a = 0.0
	
	mat.set_shader_parameter("glitch_intensity", 0.01)
	
	glitch_overlay.color = Color.BLACK

func shrink_prompt_text():
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(prompt_text, "custom_minimum_size:y", 40.0, 0.25)

func _get_special_welcome_text(id: String) -> Dictionary:
	var user_name = id.strip_edges().to_upper()

	if user_name == "' OR 1=1 --":
		return {
			"text": "WELCOME BACK\nDID YOU THINK THAT'D WORK?",
			"delay": 0.0,
			"glitch": false
		}

	if user_name == "AL" or user_name == "ALASTOR":
		return {
			"text": "",
			"delay": 0.0,
			"glitch": true
		}

	if user_name == "SEASON":
		return {"text": "WELCOME BACK, %s\nYOU ARE RESPONSIBLE FOR THIS." % employee_id, "delay": 0.0, "glitch": false}

	if user_name == "AMANDA" or user_name == "MANDY":
		return {"text": "WELCOME BACK, %s\nTHANK YOU FOR MY FACE." % employee_id, "delay": 0.0, "glitch": false}

	if user_name == "ROBIN" or user_name == "ROB":
		return {"text": "WELCOME BACK, %s\nYOU KNOW HOW THIS ENDS." % employee_id, "delay": 0.0, "glitch": false}

	if user_name == "ADMIN":
		return {"text": "WELCOME BACK, %s\nOVERRIDE ACCEPTED." % employee_id, "delay": 0.0, "glitch": false}

	if user_name == "ROOT":
		return {"text": "WELCOME BACK, %s\nFULL ACCESS GRANTED." % employee_id, "delay": 0.0, "glitch": false}

	if user_name == "SMAILE" or user_name == "SMAILEY":
		return {"text": "WELCOME BACK, %s\nYOU ARE THE PRODUCT." % employee_id, "delay": 0.0, "glitch": false}

	if user_name == "GARRY":
		return {"text": "WELCOME BACK, %s\nAH. YOU REMEMBER YOUR NAME." % employee_id, "delay": 1.0, "glitch": false}

	return {
		"text": "WELCOME BACK, %s\n BE PRODUCTIVE." % employee_id,
		"delay": 0.0,
		"glitch": false
	}

func _play_al_name_glitch() -> void:
	var messages = [
		"YOU'RE NOT HIM.",
		"THAT NAME IS NOT YOURS.",
		"STOP.",
		"LOOK AWAY.",
		"I SEE YOU.",
		"NO."
	]

	var duration = 1.4
	var elapsed = 0.0

	while elapsed < duration:
		elapsed += 0.06
		await get_tree().create_timer(0.06).timeout

		var msg = messages.pick_random()
		welcome_label.text = "WELCOME BACK, %s\n%s" % [employee_id, msg]

		if randf() < 0.3:
			welcome_label.text = "WELCOME BACK, %s\n%s" % [employee_id, ["#", "%", "?", "ERROR"].pick_random()]

	welcome_label.text = "WELCOME BACK, %s\nYOU'RE NOT HIM." % employee_id

func _reset_visual_state():
	if screen_mat:
		screen_mat.set_shader_parameter("glitch_intensity", 0.0)
		screen_mat.set_shader_parameter("glitch_time", 0.0)

	if glitch_overlay:
		glitch_overlay.modulate.a = 0.0
