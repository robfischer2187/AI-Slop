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
@onready var prompt_text: Label = get_node("SupportPrompt/Panel/VBoxContainer/PromptText")
@onready var yes_button: Button = get_node("SupportPrompt/Panel/VBoxContainer/HBoxContainer/YesButton")
@onready var no_button: Button = get_node("SupportPrompt/Panel/VBoxContainer/HBoxContainer/NoButton")

@onready var alastor: Node2D = get_node("../../../../AlastorRoot")
@onready var slot: Panel = get_node("../InputSlots/Slot")

@onready var cursor_blocker: Control = get_node("../CursorBlockerArea")
@onready var fake_cursor: Sprite2D = get_node("../FakeCursor")

@onready var username_input: LineEdit = get_node("LoginPanel/UsernameInput")

@onready var screen_mat: ShaderMaterial = get_node("../ScreenOverlay/EffectRect").material
@onready var glitch_overlay: ColorRect = get_node("../../PCScreenArea/GlitchOverlay")
@onready var pc_screen: Control = get_node("../../PCScreenArea")

var virtual_mouse_pos: Vector2
var free_mouse := false

signal startup_finished(support_forced: bool)

var click_player: AudioStreamPlayer

var phase: Phase = Phase.LOGIN
var employee_id: String = ""
var support_forced: bool = false
var forced_yes_mode := false
var start_message_visible := false

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

func _on_username_changed(new_text: String) -> void:
	var upper = new_text.to_upper()
	
	if new_text != upper:
		var caret = username_input.caret_column
		username_input.text = upper
		username_input.caret_column = caret

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
	welcome_label.text = "WELCOME,%s\n BE PRODUCTIVE." % employee_id

	await get_tree().create_timer(welcome_hold_seconds).timeout

	_set_phase(Phase.PROMPT)
	show_prompt_default()

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
	
	await trigger_violent_glitch()
	
	await get_tree().create_timer(0.1).timeout
	
	no_button.visible = false
	
	await set_prompt_text_glitch("ERR0R: INV4LID RESP0NSE\ntry aga1n")

func show_start_message():
	await set_prompt_text_glitch("PROCEED AS INSTRUCTED")
	no_button.visible = false
	yes_button.text = "OK"

func set_prompt_text_glitch(text: String):
	prompt_text.text = ""
	
	for i in range(text.length()):
		var c = text[i]
		
		if randf() < 0.25:
			prompt_text.text += ["#", "%", "?", "@", "!", "0"].pick_random()
			await get_tree().create_timer(randf_range(0.005, 0.02)).timeout
			
			if randf() < 0.7:
				prompt_text.text = prompt_text.text.substr(0, prompt_text.text.length() - 1)
		
		prompt_text.text += c
		
		if randf() < 0.15:
			var scramble_len = randi_range(1, 3)
			for j in range(scramble_len):
				prompt_text.text += ["#", "%", "?", "@", "X"].pick_random()
			
			await get_tree().create_timer(randf_range(0.01, 0.03)).timeout
			
			prompt_text.text = prompt_text.text.substr(0, prompt_text.text.length() - scramble_len)
		
		if randf() < 0.08 and prompt_text.text.length() > 2:
			var back = randi_range(1, 2)
			prompt_text.text = prompt_text.text.substr(0, prompt_text.text.length() - back)
		
		await get_tree().create_timer(randf_range(0.01, 0.035)).timeout
	
	if randf() < 0.4:
		await get_tree().create_timer(0.05).timeout
		
		var corrupted = ""
		for c in text:
			if randf() < 0.2:
				corrupted += ["#", "%", "?", "@", "X"].pick_random()
			else:
				corrupted += c
		
		prompt_text.text = corrupted
		
		await get_tree().create_timer(0.06).timeout
		prompt_text.text = text

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
