extends Control

enum Phase { LOGIN, LOADING, WELCOME, PROMPT }

@export var loading_seconds: float = 1.6
@export var welcome_hold_seconds: float = 2.5

@onready var login_panel: Control = %LoginPanel
@onready var loading_panel: Control = %LoadingPanel
@onready var welcome_panel: Control = %WelcomePanel

@onready var login_button: Button = %LoginButton
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var welcome_label: Label = %WelcomeLabel

@onready var support_prompt: AcceptDialog = %SupportPrompt

@export var debug_fast_mode := true

var phase: Phase = Phase.LOGIN
var employee_id: String = "E-1031"
var support_forced: bool = false

func _ready() -> void:
	_set_phase(Phase.LOGIN)

	login_button.pressed.connect(_on_login_pressed)

	# AcceptDialog signals:
	support_prompt.confirmed.connect(_on_support_yes)
	support_prompt.canceled.connect(_on_support_no)

	# Make sure dialog has both buttons
	support_prompt.get_ok_button().text = "YES"
	support_prompt.get_cancel_button().text = "NO"
	support_prompt.exclusive = true

func _set_phase(p: Phase) -> void:
	phase = p
	login_panel.visible = (p == Phase.LOGIN)
	loading_panel.visible = (p == Phase.LOADING)
	welcome_panel.visible = (p == Phase.WELCOME)

func _on_login_pressed() -> void:
	_set_phase(Phase.LOADING)
	await _play_loading()
	await _show_welcome_then_prompt()

func _play_loading() -> void:
	progress_bar.value = 0
	var t := 0.0
	while t < loading_seconds:
		await get_tree().process_frame
		t += get_process_delta_time()
		progress_bar.value = clampf((t / loading_seconds) * 100.0, 0.0, 100.0)

func _show_welcome_then_prompt() -> void:
	_set_phase(Phase.WELCOME)
	welcome_label.text = "WELCOME, EMPLOYEE %s.\nTODAY WILL BE PRODUCTIVE." % employee_id

	await get_tree().create_timer(welcome_hold_seconds).timeout

	_set_phase(Phase.PROMPT)
	support_prompt.dialog_text = "DO YOU SUPPORT AI?"
	support_prompt.popup_centered()

func _on_support_yes() -> void:
	# Normal path
	support_forced = false
	_finish_startup()

func _on_support_no() -> void:
	# Your horror rule: NO glitches and forces YES.
	support_forced = true
	await _play_glitch_and_force_yes()

func _play_glitch_and_force_yes() -> void:
	# Minimal version: close dialog, wait, reopen with "YES" pressed effect.
	# Later you can hook a shader/canvas glitch here.
	support_prompt.hide()

	# Fake “glitch”: rapid re-popup + short delays
	await get_tree().create_timer(0.08).timeout
	support_prompt.popup_centered()
	await get_tree().create_timer(0.08).timeout 
	support_prompt.hide()

	# Force accept
	await get_tree().create_timer(0.12).timeout

	# Show “...” moment (reuse welcome panel as a message panel)
	_set_phase(Phase.WELCOME)
	welcome_label.text = "..."
	await get_tree().create_timer(0.6).timeout

	_finish_startup()

func _finish_startup() -> void:
	# Emit a signal or call into your Game/SceneManager to start the shift.
	# For now, just print.
	print("Startup complete. support_forced=", support_forced)