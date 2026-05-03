extends Control

enum Phase { LOGIN, LOADING, WELCOME, PROMPT }

@export var loading_seconds: float = 1.6
@export var welcome_hold_seconds: float = 2.5
@export var debug_fast_mode := false

# StartupFlow contains these panels as children now:
@onready var login_panel: Control = get_node_or_null("LoginPanel")
@onready var loading_panel: Control = get_node_or_null("LoadingPanel")
@onready var welcome_panel: Control = get_node_or_null("WelcomePanel")

@onready var login_button: Button = get_node_or_null("LoginPanel/LoginButton")
@onready var progress_bar: ProgressBar = get_node_or_null("LoadingPanel/ProgressBar")
@onready var welcome_label: Label = get_node_or_null("WelcomePanel/WelcomeLabel")

@onready var support_prompt: ConfirmationDialog = get_node_or_null("SupportPrompt")

@onready var alastor: Node2D = get_node_or_null("../../../../AlastorSlopp")

# The Control to center the dialog within.
# By default we try to use our parent (PCScreenArea) if it's a Control.
@export var pc_screen_path: NodePath
@onready var pc_screen: Control = (
	get_node_or_null(pc_screen_path) as Control
	if pc_screen_path != NodePath("")
	else get_parent() as Control
)

signal startup_finished(support_forced: bool)

var phase: Phase = Phase.LOGIN
var employee_id: String = "E-1031"
var support_forced: bool = false
var forced_yes_mode := false
var start_message_visible := false


func _ready() -> void:
	if debug_fast_mode:
		loading_seconds = 0.3
		welcome_hold_seconds = 0.1

	_validate_nodes_or_abort()
	_set_phase(Phase.LOGIN)

	login_button.pressed.connect(_on_login_pressed)

	support_prompt.confirmed.connect(_on_support_yes)
	support_prompt.canceled.connect(_on_support_no)
	support_prompt.exclusive = true

	_reset_prompt_to_default()

	if alastor != null:
		alastor.visible = false


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

	if pc_screen == null:
		missing.append("pc_screen (set pc_screen_path in Inspector OR ensure StartupFlow parent is PCScreenArea Control)")

	if missing.size() > 0:
		push_error("startupflow.gd: missing nodes: %s" % str(missing))
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
	_popup_prompt_centered_in_pc_screen_clamped()


func _on_support_yes() -> void:
	# First YES shows the startup message popup. The OK click on that popup
	# comes back here with `start_message_visible` already set, and then we finish.
	if not start_message_visible:
		start_message_visible = true
		_show_start_message_popup()
		return

	start_message_visible = false
	# In forced mode, YES means "you tried NO, too bad" but still continue.
	if alastor != null:
		alastor.visible = true
	
	support_forced = forced_yes_mode
	_finish_startup()


func _on_support_no() -> void:
	support_forced = true
	forced_yes_mode = true
	await _play_glitch_and_force_yes()


func _play_glitch_and_force_yes() -> void:
	support_prompt.hide()

	await get_tree().create_timer(0.08).timeout
	_set_prompt_forced_yes()
	_popup_prompt_centered_in_pc_screen_clamped()

	await get_tree().create_timer(0.12).timeout

	_set_phase(Phase.WELCOME)
	welcome_label.text = "..."
	await get_tree().create_timer(0.6).timeout


func _reset_prompt_to_default() -> void:
	forced_yes_mode = false
	support_prompt.title = "COMPLIANCE CHECK"
	support_prompt.dialog_text = "DO YOU SUPPORT AI?"
	support_prompt.get_ok_button().text = "YES"
	support_prompt.get_cancel_button().text = "NO"
	support_prompt.get_cancel_button().show()


func _set_prompt_forced_yes() -> void:
	support_prompt.title = "COMPLIANCE CHECK"
	support_prompt.dialog_text = "SORRY. YOU HAVE NO OTHER OPTION."
	support_prompt.get_ok_button().text = "YES"
	support_prompt.get_cancel_button().hide()


func _show_start_message_popup() -> void:
	support_prompt.title = "STARTING"
	support_prompt.dialog_text = "Great, lets start the game"
	support_prompt.get_ok_button().text = "OK"
	support_prompt.get_cancel_button().hide()
	_popup_prompt_centered_in_pc_screen_clamped()


func _popup_prompt_centered_in_pc_screen_clamped() -> void:
	if pc_screen == null:
		support_prompt.popup_centered()
		return

	# Ensure dialog has a size
	if support_prompt.size.x <= 0 or support_prompt.size.y <= 0:
		support_prompt.size = Vector2i(340, 130)

	var screen_rect: Rect2 = pc_screen.get_global_rect()
	var dlg_size: Vector2 = Vector2(support_prompt.size)

	var pos: Vector2 = screen_rect.position + (screen_rect.size - dlg_size) * 0.5

	# clamp inside the screen rect
	pos.x = clampf(pos.x, screen_rect.position.x, screen_rect.position.x + screen_rect.size.x - dlg_size.x)
	pos.y = clampf(pos.y, screen_rect.position.y, screen_rect.position.y + screen_rect.size.y - dlg_size.y)

	support_prompt.popup(Rect2i(pos, dlg_size))


func _finish_startup() -> void:
	print("Startup complete. support_forced=", support_forced)
	startup_finished.emit(support_forced)
