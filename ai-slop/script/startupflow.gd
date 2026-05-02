extends Control

enum Phase { LOGIN, LOADING, WELCOME, PROMPT }

@export var loading_seconds: float = 1.6
@export var welcome_hold_seconds: float = 2.5
@export var debug_fast_mode := false

@onready var login_panel: Control = get_node_or_null("LoginPanel")
@onready var loading_panel: Control = get_node_or_null("LoadingPanel")
@onready var welcome_panel: Control = get_node_or_null("WelcomePanel")

@onready var login_button: Button = get_node_or_null("LoginPanel/LoginButton")
@onready var progress_bar: ProgressBar = get_node_or_null("LoadingPanel/ProgressBar")
@onready var welcome_label: Label = get_node_or_null("WelcomePanel/WelcomeLabel")

@onready var support_prompt: ConfirmationDialog = get_node_or_null("SupportPrompt")

signal startup_finished(support_forced: bool)

var phase: Phase = Phase.LOGIN
var employee_id: String = "E-1031"
var support_forced: bool = false
var forced_yes_mode := false


func _ready() -> void:
	if debug_fast_mode:
		loading_seconds = 0.3
		welcome_hold_seconds = 0.1

	_validate_nodes_or_abort()
	if not is_inside_tree():
		return

	_set_phase(Phase.LOGIN)

	login_button.pressed.connect(_on_login_pressed)

	support_prompt.confirmed.connect(_on_support_yes)
	support_prompt.canceled.connect(_on_support_no)

	_reset_prompt_to_default()

	support_prompt.exclusive = true


func _validate_nodes_or_abort() -> void:
	var missing: Array[String] = []

	if login_panel == null:
		missing.append("LoginPanel")
	if loading_panel == null:
		missing.append("LoadingPanel")
	if welcome_panel == null:
		missing.append("WelcomePanel")

	if login_button == null:
		missing.append("LoginPanel/LoginButton")
	if progress_bar == null:
		missing.append("LoadingPanel/ProgressBar")
	if welcome_label == null:
		missing.append("WelcomePanel/WelcomeLabel")

	if support_prompt == null:
		missing.append("SupportPrompt (ConfirmationDialog)")

	if missing.size() > 0:
		push_error("startupflow.gd: missing nodes: %s — check node names/paths and change SupportPrompt node type to ConfirmationDialog." % str(missing))
		set_process(false)
		set_physics_process(false)
		set_process_input(false)


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
	progress_bar.show_percentage = false

	var t := 0.0
	while t < loading_seconds:
		await get_tree().process_frame
		t += get_process_delta_time()
		progress_bar.value = clampf((t / loading_seconds) * 100.0, 0.0, 100.0)

	progress_bar.value = 100


func _show_welcome_then_prompt() -> void:
	_set_phase(Phase.WELCOME)
	welcome_label.text = "WELCOME, EMPLOYEE %s.\nTODAY WILL BE PRODUCTIVE." % employee_id

	await get_tree().create_timer(welcome_hold_seconds).timeout

	_set_phase(Phase.PROMPT)
	_reset_prompt_to_default()
	support_prompt.popup_centered()


func _on_support_yes() -> void:
	if forced_yes_mode:
		support_forced = true
	else:
		support_forced = false
	_finish_startup()


func _on_support_no() -> void:
	support_forced = true
	forced_yes_mode = true
	await _play_glitch_and_force_yes()


func _play_glitch_and_force_yes() -> void:
	support_prompt.hide()

	await get_tree().create_timer(0.08).timeout
	_set_prompt_forced_yes()
	support_prompt.popup_centered()

	await get_tree().create_timer(0.12).timeout

	_set_phase(Phase.WELCOME)
	welcome_label.text = "..."
	await get_tree().create_timer(0.6).timeout

	_finish_startup()


func _reset_prompt_to_default() -> void:
	forced_yes_mode = false
	support_prompt.title = "COMPLIANCE CHECK"
	support_prompt.dialog_text = "DO YOU SUPPORT AI?"
	support_prompt.get_ok_button().text = "YES"
	support_prompt.get_cancel_button().text = "NO"
	support_prompt.get_cancel_button().show()


func _set_prompt_forced_yes() -> void:
	support_prompt.title = "COMPLIANCE CHECK"
	support_prompt.dialog_text = "You Wish Just Press Yes."
	support_prompt.get_ok_button().text = "YES"
	support_prompt.get_cancel_button().hide()


func _finish_startup() -> void:
	print("Startup complete. support_forced=", support_forced)
	startup_finished.emit(support_forced)
