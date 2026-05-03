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
@onready var foto: Control = get_node("SupportPrompt/Panel/Foto")
@onready var coworkers_texture: TextureRect = get_node("../../../../Coworkers")

var virtual_mouse_pos: Vector2
var free_mouse := false

signal startup_finished(support_forced: bool)

var click_player: AudioStreamPlayer
var no_glitch_player: AudioStreamPlayer
var typing_player: AudioStreamPlayer

var phase: Phase = Phase.LOGIN
var employee_id: String = ""
var support_forced: bool = false
var forced_yes_mode := false
var start_message_visible := false
var intro_message_active := false
var skip_typewriter := false

var coworkers_default_texture: Texture

func _input(event):
	if intro_message_active and event is InputEventMouseButton and event.pressed:
		skip_typewriter = true
		
		click_player.pitch_scale = randf_range(0.3, 4.1)
		click_player.play()

func _ready() -> void:
	if debug_fast_mode:
		loading_seconds = 0.3
		welcome_hold_seconds = 0.1

	_set_phase(Phase.LOGIN)

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

	no_glitch_player = AudioStreamPlayer.new()
	no_glitch_player.stream = preload("res://assets/sounds/no_glitch.mp3")
	add_child(no_glitch_player)

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

func _process(_delta):
	update_virtual_mouse()
	fake_cursor.global_position = virtual_mouse_pos

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
	welcome_label.text = "WELCOME BACK, %s\n BE PRODUCTIVE." % employee_id

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
