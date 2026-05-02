extends Node2D

@onready var task_text: Label = $UIRoot/UIContainer/PCScreenArea/TaskText
@onready var slot: Control = $UIRoot/UIContainer/PCScreenArea/InputSlots/Slot
@onready var draggable_items: Control = $UIRoot/UIContainer/PCScreenArea/DraggableItems
@onready var horror_overlay: CanvasLayer = $UIRoot/UIContainer/HorrorOverlay
@onready var feedback_flash: ColorRect = $UIRoot/UIContainer/PCScreenArea/FeedbackFlash
@onready var glitch_overlay: ColorRect = $UIRoot/UIContainer/PCScreenArea/GlitchOverlay
@onready var pc_screen: Control = $UIRoot/UIContainer/PCScreenArea
@onready var alastor = $AlastorSlopp
@onready var alastor_anim: AnimationPlayer = $AlastorSlopp/AnimationPlayer
@onready var dialogue_label: Label = $UIRoot/DialogueLabel
@onready var horror_mat: ShaderMaterial = $UIRoot/UIContainer/HorrorOverlay/EffectRect.material
@onready var coworkers_texture: TextureRect = $Coworkers
@onready var cursor_blocker: Control = $UIRoot/UIContainer/PCScreenArea/CursorBlockerArea
@onready var fake_cursor: Sprite2D = $UIRoot/FakeCursor

var strikes: int = 0
var task_index: int = 0
var sabotage_score: int = 0
var ai_score: int = 0

var suspicion: float = 0.0

var is_being_watched: bool = false
var game_running: bool = false

var task_timer: float = 5.0
var current_time: float = 0.0

var free_mouse: bool = false
var virtual_mouse_pos: Vector2

var tasks: Array = [
	{"prompt": "FEED IT: DOGS", "correct": "DOGS", "wrong": "FLOWERS"},
	{"prompt": "FEED IT: SMILING PEOPLE", "correct": "SMILING PEOPLE", "wrong": "EMPTY OFFICE"},
	{"prompt": "FEED IT: BURNING HOUSES", "correct": "BURNING HOUSES", "wrong": "PUPPIES"},
	{"prompt": "FEED IT: SCREAMING CHILDREN", "correct": "SCREAMING CHILDREN", "wrong": "SUNSET"},
	{"prompt": "FEED IT: HUMAN FEAR", "correct": "HUMAN FEAR", "wrong": "HOPE"}
]

var got_caught_this_watch: bool = false
var coworkers_default_texture: Texture

func _ready() -> void:
	var startup_flow: Node = $UIRoot/UIContainer/PCScreenArea/StartupFlow
	startup_flow.startup_finished.connect(_on_startup_finished)
	set_process(false) # stop _process until startup is done

func _on_startup_finished(_support_forced: bool) -> void:
	set_process(true)
	game_running = true
	start_game()
	alastor_anim.play("walk")
	alastor_anim.speed_scale = 0.4
	start_alastor_loop()
	horror_overlay.visible = true
	coworkers_default_texture = coworkers_texture.texture
	init_virtual_mouse()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta):
	if not game_running:
		return
	
	current_time -= delta
	
	if current_time <= 0:
		miss_task()
	
	update_horror_shader()
	update_virtual_mouse()
	
	if Input.is_action_just_pressed("debug_toggle_mouse"):
		free_mouse = !free_mouse
		
		if free_mouse:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	fake_cursor.global_position = virtual_mouse_pos

func init_virtual_mouse():
	var rect = cursor_blocker.get_global_rect()
	virtual_mouse_pos = rect.position + rect.size * 0.5
	virtual_mouse_pos.y += rect.size.y * 0.1
	Input.warp_mouse(virtual_mouse_pos)

func update_virtual_mouse():
	if free_mouse:
		virtual_mouse_pos = get_global_mouse_position()
		return
	
	var rect = cursor_blocker.get_global_rect()
	var real = get_global_mouse_position()
	
	virtual_mouse_pos.x = clamp(real.x, rect.position.x, rect.end.x)
	virtual_mouse_pos.y = clamp(real.y, rect.position.y, rect.end.y)

func start_game() -> void:
	strikes = 0
	task_index = 0
	sabotage_score = 0
	ai_score = 0
	suspicion = 0.0
	game_running = true
	load_task()

func load_task() -> void:
	if task_index >= tasks.size():
		finish_game()
		return
	
	var task = tasks[task_index]
	task_text.text = task["prompt"]
	current_time = task_timer
	
	if task_index > 2:
		task_timer = 4.0
	if task_index > 4:
		task_timer = 3.0

func submit_input(input_name: String) -> void:
	if not game_running:
		return
	
	var task = tasks[task_index]
	
	if input_name == task["correct"]:
		ai_score += 1
		suspicion -= 0.1
		suspicion = max(suspicion, 0)
		flash_feedback(Color(0, 1, 0))
		punch_slot()
	else:
		sabotage_score += 1
		suspicion += 0.3
		flash_feedback(Color(1, 0, 0))
		trigger_glitch()
	
	if suspicion >= 1.0:
		get_caught_by_alastor()
	
	task_index += 1
	load_task()

func miss_task():
	trigger_glitch()
	task_index += 1
	load_task()

func start_alastor_loop():
	while game_running:
		await get_tree().create_timer(randf_range(3.0, 6.0)).timeout
		if randf() < 0.6:
			await alastor_watch_phase()

func alastor_watch_phase():
	if not game_running:
		return
	
	is_being_watched = true
	got_caught_this_watch = false
	
	alastor_anim.play("watch")
	flash_feedback(Color(1, 1, 1))
	
	horror_mat.set_shader_parameter("pulse_speed", 2.5)
	horror_mat.set_shader_parameter("darkness", 0.25)
	horror_mat.set_shader_parameter("flicker_strength", 0.08)
	
	await get_tree().create_timer(2.5).timeout
	
	check_player_behavior()
	
	if not got_caught_this_watch:
		await get_tree().create_timer(0.5).timeout
		show_alastor_approval()
	
	is_being_watched = false
	alastor_anim.play("walk")

func check_player_behavior():
	if task_index >= tasks.size():
		return
	
	var task = tasks[task_index]
	
	for item in get_tree().get_nodes_in_group("draggable"):
		if item.dragging and item.item_name != task["correct"]:
			get_caught_by_alastor()
			trigger_glitch()
			return

func get_caught_by_alastor() -> void:
	strikes += 1
	got_caught_this_watch = true
	
	coworkers_texture.texture = load("res://assets/art/AI GAME COWORKER CAUGHT (1).png")
	reset_coworkers_texture_after_delay()
	
	if strikes == 1:
		show_dialogue("What are you doing? I’m warning you…")
	elif strikes == 2:
		show_dialogue("No, you’re killing It! This… this is your final warning.")
	elif strikes >= 3:
		show_dialogue("What a shame. Should've listened to me... you'll still be part of It.")
		trigger_neutral_ending()

func reset_coworkers_texture_after_delay() -> void:
	await get_tree().create_timer(randf_range(1.0, 2.0)).timeout
	
	if not game_running:
		return
	
	coworkers_texture.texture = coworkers_default_texture

func show_alastor_approval():
	var lines = [
		"Good job...",
		"It appreciates your work.",
		"Yes... feed it.",
		"Make It stronger.",
		"That's better.",
		"Keep going.",
		"Remember to smile."
	]
	
	show_dialogue(lines.pick_random())

func finish_game() -> void:
	game_running = false
	
	if sabotage_score >= 3:
		trigger_good_ending()
	elif ai_score >= 3:
		trigger_bad_ending()
	else:
		trigger_neutral_ending()

func trigger_good_ending() -> void:
	game_running = false
	print("AI COMPANY CLOSES!")

func trigger_neutral_ending() -> void:
	game_running = false
	print("SCANDAL AT SMAILE!")

func trigger_bad_ending() -> void:
	game_running = false
	print("AI CREATURE ON THE LOOSE!")

func flash_feedback(color: Color):
	feedback_flash.color = color
	feedback_flash.modulate.a = 0.6
	
	var tween = create_tween()
	tween.tween_property(feedback_flash, "modulate:a", 0.0, 0.25)

func trigger_glitch():
	var tween = create_tween()
	
	glitch_overlay.modulate.a = 0.25
	tween.tween_property(glitch_overlay, "modulate:a", 0.0, 0.1)
	
	horror_mat.set_shader_parameter("chromatic_strength", 0.01)
	horror_mat.set_shader_parameter("flicker_strength", 0.15)
	horror_mat.set_shader_parameter("darkness", 0.35)
	
	var original_pos = pc_screen.position
	
	Engine.time_scale = 0.8
	await get_tree().create_timer(0.1).timeout
	Engine.time_scale = 1.0
	
	for i in range(5):
		var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		pc_screen.position = original_pos + offset
		await get_tree().create_timer(0.02).timeout
	
	pc_screen.position = original_pos
	
	update_horror_shader()

func punch_slot():
	var tween = create_tween()
	tween.tween_property(slot, "scale", Vector2(1.1, 1.1), 0.05)
	tween.tween_property(slot, "scale", Vector2(1, 1), 0.1)

func show_dialogue(text: String):
	dialogue_label.text = text
	dialogue_label.modulate.a = 1
	
	var tween = create_tween()
	tween.tween_property(dialogue_label, "modulate:a", 0.0, 2.0)

func update_horror_shader():
	horror_mat.set_shader_parameter("vignette_strength", 0.9 + suspicion * 0.9)
	horror_mat.set_shader_parameter("darkness", 0.08 + suspicion * 0.22)
	horror_mat.set_shader_parameter("pulse_strength", 0.04 + suspicion * 0.08)
	horror_mat.set_shader_parameter("pulse_speed", 1.2 + suspicion * 0.8)
	horror_mat.set_shader_parameter("grain_strength", 0.03 + suspicion * 0.08)
	horror_mat.set_shader_parameter("chromatic_strength", 0.001 + suspicion * 0.003)
	horror_mat.set_shader_parameter("scanline_strength", 0.02 + suspicion * 0.04)
	horror_mat.set_shader_parameter("flicker_strength", 0.01 + suspicion * 0.05)
