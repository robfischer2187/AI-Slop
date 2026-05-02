extends Control

enum Phase { LOGIN, LOADING, WELCOME, PROMPT }

@export var loading_seconds: float = 1.6
@export var welcome_hold_seconds: float = 2.5

@onready var login_panel: Control = get_node_or_null("LoginPanel")
@onready var loading_panel: Control = get_node_or_null("LoadingPanel")
@onready var welcome_panel: Control = get_node_or_null("WelcomePanel")

@onready var login_button: Button = get_node_or_null("LoginPanel/LoginButton")
@onready var progress_bar: ProgressBar = get_node_or_null("LoadingPanel/ProgressBar")
@onready var welcome_label: Label = get_node_or_null("WelcomePanel/WelcomeLabel")

@onready var support_prompt: AcceptDialog = get_node_or_null("SupportPrompt")

@export var debug_fast_mode := false

var phase: Phase = Phase.LOGIN
var employee_id: String = "E-1031"
var support_forced: bool = false
signal startup_finished(support_forced)

func _ready() -> void:
	if debug_fast_mode:
		loading_seconds = 0.3
		welcome_hold_seconds = 0.1
	# Quick validation: ensure all required nodes were found
	var missing := []
	if not login_panel:
		missing.append("LoginPanel")
	if not loading_panel:
		missing.append("LoadingPanel")
	if not welcome_panel:
		missing.append("WelcomePanel")
	if not login_button:
		missing.append("LoginButton")
	if not progress_bar:
		missing.append("ProgressBar")
	if not welcome_label:
		missing.append("WelcomeLabel")
	if not support_prompt:
		missing.append("SupportPrompt")

	if missing.size() > 0:
		var list_str := str(missing)
		push_error("startupflow.gd: missing nodes: %s — ensure nodes exist with these exact names and the script is attached to the correct scene root." % list_str)
		return

	_set_phase(Phase.LOGIN)

	login_button.pressed.connect(_on_login_pressed)

	# AcceptDialog signals:
	support_prompt.confirmed.connect(_on_support_yes)
	support_prompt.canceled.connect(_on_support_no)

	# Make sure dialog has both buttons (use safe fallbacks for different Godot versions)
	if support_prompt.has_method("get_ok_button"):
		var ok_btn = support_prompt.get_ok_button()
		if ok_btn:
			ok_btn.text = "YES"
	else:
		if support_prompt.has_method("add_button"):
			var ok_btn2 = support_prompt.add_button("YES")
			if ok_btn2 and ok_btn2 is Button:
				ok_btn2.text = "YES"

	if support_prompt.has_method("get_cancel_button"):
		var cancel_btn = support_prompt.get_cancel_button()
		if cancel_btn:
			cancel_btn.text = "NO"
	else:
		# Try to add a cancel/NO button as a fallback
		if support_prompt.has_method("add_button"):
			var cancel_btn2 = support_prompt.add_button("NO")
			if cancel_btn2 and cancel_btn2 is Button:
				cancel_btn2.text = "NO"

	support_prompt.exclusive = true

func _set_phase(p: Phase) -> void:
	phase = p
	login_panel.visible = (p == Phase.LOGIN)
	loading_panel.visible = (p == Phase.LOADING)
	welcome_panel.visible = (p == Phase.WELCOME)

func _on_login_pressed() -> void:
	login_button.disabled = true
	_set_phase(Phase.LOADING)
	await _play_loading()
	await _show_welcome_then_prompt()

func _play_loading() -> void:
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0

	var t := 0.0
	while t < loading_seconds:
		await get_tree().process_frame
		t += get_process_delta_time()
		progress_bar.value = (t / loading_seconds) * 100.0

	progress_bar.value = 100

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
