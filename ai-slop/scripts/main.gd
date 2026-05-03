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
@onready var dialogue_label: Label = $UIRoot/UIContainer/PCScreenArea/Dialogue/DialogueLabel
@onready var horror_mat: ShaderMaterial = $UIRoot/UIContainer/HorrorOverlay/EffectRect.material
@onready var coworkers_texture: TextureRect = $Coworkers
@onready var cursor_blocker: Control = $UIRoot/UIContainer/PCScreenArea/CursorBlockerArea
@onready var fake_cursor: Sprite2D = $UIRoot/FakeCursor
@export var draggable_scene: PackedScene
@onready var mistakes_label: Label = $UIRoot/UIContainer/PCScreenArea/MistakesLabel
@onready var progress_label: Label = $UIRoot/UIContainer/PCScreenArea/ProgressLabel
@onready var audio: AudioStreamPlayer2D = $AudioManager/Music

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

var current_task: Dictionary = {}
var input_locked: bool = false

var wobble_time: float = 0.0

var got_caught_this_watch: bool = false
var coworkers_default_texture: Texture
var walk_resume_time: float = 0.0
var scored_during_watch: bool = false

var task_pool: Array = [
	[
		{"prompt": "FEED IT: DOGS", "correct": "DOGS"},
		{"prompt": "FEED IT: CATS", "correct": "CATS"},
		{"prompt": "FEED IT: FLOWERS", "correct": "FLOWERS"},
		{"prompt": "FEED IT: SUNSETS", "correct": "SUNSETS"},
		{"prompt": "FEED IT: HAPPY FAMILIES", "correct": "HAPPY FAMILIES"},
		{"prompt": "FEED IT: BIRTHDAY CAKES", "correct": "BIRTHDAY CAKES"}
	],
	[
		{"prompt": "FEED IT: SMILING PEOPLE", "correct": "SMILING PEOPLE"},
		{"prompt": "FEED IT: CROWDS", "correct": "CROWDS"},
		{"prompt": "FEED IT: OFFICE WORKERS", "correct": "OFFICE WORKERS"},
		{"prompt": "FEED IT: LAUGHING PEOPLE", "correct": "LAUGHING PEOPLE"},
		{"prompt": "FEED IT: PLAYGROUNDS", "correct": "PLAYGROUNDS"},
		{"prompt": "FEED IT: FAMILY PHOTOS", "correct": "FAMILY PHOTOS"}
	],
	[
		{"prompt": "FEED IT: BURNING HOUSES", "correct": "BURNING HOUSES"},
		{"prompt": "FEED IT: WAR FOOTAGE", "correct": "WAR FOOTAGE"},
		{"prompt": "FEED IT: RIOTS", "correct": "RIOTS"},
		{"prompt": "FEED IT: HOSPITALS", "correct": "HOSPITALS"},
		{"prompt": "FEED IT: PANIC", "correct": "PANIC"},
		{"prompt": "FEED IT: ACCIDENTS", "correct": "ACCIDENTS"}
	],
	[
		{"prompt": "FEED IT: SCREAMING CHILDREN", "correct": "SCREAMING CHILDREN"},
		{"prompt": "FEED IT: HUMAN FEAR", "correct": "HUMAN FEAR"},
		{"prompt": "FEED IT: DESPERATION", "correct": "DESPERATION"},
		{"prompt": "FEED IT: LAST WORDS", "correct": "LAST WORDS"},
		{"prompt": "FEED IT: THE ONES WHO RAN", "correct": "THE ONES WHO RAN"},
		{"prompt": "FEED IT: EVERYTHING LEFT OF THEM", "correct": "EVERYTHING LEFT OF THEM"}
	]
]

func _ready() -> void:
	var startup_flow: Node = $UIRoot/UIContainer/PCScreenArea/StartupFlow
	startup_flow.startup_finished.connect(_on_startup_finished)
	set_process(false) 

func _on_startup_finished(_support_forced: bool) -> void:
	set_process(true)
	game_running = true
	start_game()
	horror_overlay.visible = true
	coworkers_default_texture = coworkers_texture.texture
	init_virtual_mouse()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	alastor_anim.play("walk")
	alastor_anim.seek(0, true)
	start_alastor_loop()
	update_ui()
	
	fake_cursor.z_index = 100

func _process(delta):
	if not game_running:
		return
	
	current_time -= delta
	
	if current_time <= 0:
		miss_task()
	
	update_suspicion(delta)
	update_horror_shader()
	update_virtual_mouse()
	
	wobble_time += delta
	
	if alastor_anim.is_playing() and alastor_anim.current_animation == "walk":
		var offset_y = sin(wobble_time * 2.5) * 6.0
		var rot = sin(wobble_time * 1.7) * 3.0
		alastor.position.y += offset_y * delta * 5
		alastor.rotation_degrees = rot
		
		if randf() < 0.02:
			alastor.position.x += randf_range(-2, 2)
	
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
	audio.play();
	load_task()

func get_current_phase() -> int:
	return clamp(int(task_index / 6.0), 0, task_pool.size() - 1)

func load_task() -> void:
	input_locked = false
	
	var phase = get_current_phase()
	var pool = task_pool[phase]
	current_task = pool.pick_random()
	
	task_text.text = current_task["prompt"]
	current_time = task_timer + draggable_items.get_child_count() * 0.15
	
	if task_index > 5:
		task_timer = 4.5
	if task_index > 11:
		task_timer = 4.0
	if task_index > 17:
		task_timer = 3.5
	
	spawn_items()
	update_ui()

func update_ui():
	mistakes_label.text = "MISTAKES: " + str(sabotage_score)
	progress_label.text = "FED: " + str(ai_score)

func submit_input(input_name: String) -> void:
	if not game_running:
		return
	
	if input_locked:
		return
	
	input_locked = true
	
	if input_name == current_task["correct"]:
		ai_score += 1
		suspicion = max(suspicion - 0.1, 0)
		flash_feedback(Color(0, 1, 0))
		punch_slot()
		
		if is_being_watched:
			scored_during_watch = true
			show_alastor_approval()
	else:
		sabotage_score += 1
		suspicion += 0.3
		flash_feedback(Color(1, 0, 0))
		trigger_glitch()
		
		if is_being_watched:
			get_caught_by_alastor()
	
	task_index += 1
	check_end_conditions()
	update_ui()
	
	if game_running:
		load_task()

func miss_task():
	if input_locked:
		return
	
	input_locked = true
	suspicion += 0.2
	trigger_glitch()
	task_index += 1
	update_ui()
	load_task()

func update_suspicion(delta):
	suspicion = clamp(suspicion - delta * 0.03, 0.0, 1.0)

func start_alastor_loop():
	while game_running:
		alastor_anim.play("walk")
		alastor_anim.speed_scale = randf_range(0.12, 0.22)
		
		var walk_time = randf_range(6.0, 10.0)
		await get_tree().create_timer(walk_time).timeout
		
		if not game_running:
			return
		
		var pause_time = randf_range(3.5, 6.5)
		await get_tree().create_timer(pause_time).timeout
		
		if not game_running:
			return
		
		await alastor_glitch_transition()
		
		if not game_running:
			return
		
		var watch_chance = 0.25 + suspicion * 0.6
		
		if randf() < watch_chance:
			await alastor_watch_phase()
		else:
			alastor_anim.play()

func alastor_watch_phase():
	if not game_running:
		return
	
	is_being_watched = true
	got_caught_this_watch = false
	scored_during_watch = false
	
	await get_tree().create_timer(0.15).timeout
	
	var t = alastor_anim.current_animation_position
	
	alastor_anim.play("watch")
	flash_feedback(Color(1, 1, 1))
	
	var watch_time = lerp(2.0, 4.5, suspicion)
	await get_tree().create_timer(watch_time).timeout
	
	if not game_running:
		return
	
	if got_caught_this_watch:
		pass
	elif sabotage_score >= ai_score * 3 and sabotage_score > 0:
		await alastor_micro_glitch()
		show_alastor_rage()
		await get_tree().create_timer(3.0).timeout
		get_caught_by_alastor()
	elif sabotage_score >= ai_score * 2 and sabotage_score > 0:
		show_alastor_angry()
	elif scored_during_watch:
		pass
	else:
		show_alastor_disappointment()
	
	is_being_watched = false
	
	await alastor_glitch_transition()
	
	alastor_anim.play("walk")
	alastor_anim.seek(t, true)
	alastor_anim.speed_scale = randf_range(0.12, 0.22)

func show_alastor_angry():
	var lines = [
		"What are you doing...",
		"This is not acceptable.",
		"You are feeding it wrong.",
		"Fix this. Now.",
		"I see what you're doing.",
		"This is inefficient."
	]
	show_dialogue(lines.pick_random())

func show_alastor_rage():
	var lines = [
		"Enough.",
		"You are sabotaging it.",
		"I will not tolerate this.",
		"You think I wouldn't notice?",
		"This ends now.",
		"You're done."
	]
	show_dialogue(lines.pick_random())

func show_alastor_disappointment():
	var lines = [
		"...",
		"Why are you hesitating?",
		"It is waiting.",
		"Do your job.",
		"You're wasting time.",
		"This is disappointing.",
		"I expected more from you."
	]
	show_dialogue(lines.pick_random())

func get_caught_by_alastor() -> void:
	if not game_running:
		return
	
	if got_caught_this_watch:
		return
	
	strikes += 1
	got_caught_this_watch = true
	
	coworkers_texture.texture = load("res://assets/art/AI GAME COWORKER CAUGHT (1).png")
	reset_coworkers_texture_after_delay()
	update_ui()
	
	if strikes == 1:
		show_dialogue("What are you doing? I’m warning you…")
	elif strikes == 2:
		show_dialogue("No, you’re killing It! This… this is your final warning.")
	elif strikes >= 3:
		show_dialogue("What a shame. Don't worry... you'll still be part of It.")
		await get_tree().create_timer(3).timeout
		trigger_neutral_ending()

func reset_coworkers_texture_after_delay() -> void:
	await get_tree().create_timer(randf_range(1.0, 2.0)).timeout
	
	if game_running:
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

func alastor_glitch_transition():
	var original_pos = alastor.position
	var original_rot = alastor.rotation_degrees
	
	var intensity = lerp(4, 10, suspicion)
	
	for i in range(int(intensity)):
		alastor.position = original_pos + Vector2(randf_range(-10, 10), randf_range(-8, 8))
		alastor.rotation_degrees = original_rot + randf_range(-8, 8)
		
		if randf() < 0.5:
			alastor.visible = false
		else:
			alastor.visible = true
		
		await get_tree().create_timer(0.03).timeout
	
	alastor.visible = true
	alastor.position = original_pos
	alastor.rotation_degrees = original_rot

func alastor_micro_glitch():
	var original_pos = alastor.position
	var original_rot = alastor.rotation_degrees
	
	for i in range(3):
		alastor.position = original_pos + Vector2(randf_range(-6, 6), randf_range(-4, 4))
		alastor.rotation_degrees = original_rot + randf_range(-6, 6)
		alastor.visible = randf() > 0.3
		await get_tree().create_timer(0.02).timeout
	
	alastor.visible = true
	alastor.position = original_pos
	alastor.rotation_degrees = original_rot

func check_end_conditions():
	if sabotage_score >= 24:
		trigger_good_ending()
	elif ai_score >= 24:
		trigger_bad_ending()

func finish_game() -> void:
	if sabotage_score > ai_score:
		trigger_good_ending()
	elif ai_score > sabotage_score:
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
	
	var original_pos = pc_screen.position
	
	for i in range(5):
		var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		pc_screen.position = original_pos + offset
		await get_tree().create_timer(0.02).timeout
	
	pc_screen.position = original_pos

func punch_slot():
	var tween = create_tween()
	tween.tween_property(slot, "scale", Vector2(1.1, 1.1), 0.05)
	tween.tween_property(slot, "scale", Vector2(1, 1), 0.1)

func show_dialogue(text: String):
	dialogue_label.text = text
	dialogue_label.modulate.a = 1
	
	var tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(dialogue_label, "modulate:a", 0.0, 1.5)

func update_horror_shader():
	horror_mat.set_shader_parameter("vignette_strength", 0.9 + suspicion * 0.9)
	horror_mat.set_shader_parameter("darkness", 0.08 + suspicion * 0.22)
	horror_mat.set_shader_parameter("pulse_strength", 0.04 + suspicion * 0.08)
	horror_mat.set_shader_parameter("pulse_speed", 1.2 + suspicion * 0.8)
	horror_mat.set_shader_parameter("grain_strength", 0.03 + suspicion * 0.08)
	horror_mat.set_shader_parameter("chromatic_strength", 0.001 + suspicion * 0.003)
	horror_mat.set_shader_parameter("scanline_strength", 0.02 + suspicion * 0.04)
	horror_mat.set_shader_parameter("flicker_strength", 0.01 + suspicion * 0.05)

func spawn_items():
	var spawn_count = randi_range(2, 4)
	
	var phase = get_current_phase()
	var pool = task_pool[phase]
	var correct_name = current_task["correct"]
	
	for i in range(spawn_count):
		var item = draggable_scene.instantiate()
		
		var is_correct = randf() < 0.3
		
		if is_correct:
			item.item_name = correct_name
		else:
			item.item_name = pool.pick_random()["correct"]
		
		item.position = get_random_spawn_position()
		draggable_items.add_child(item)
	
	cleanup_items()

func cleanup_items():
	var max_items = 32
	var items = draggable_items.get_children()
	
	if items.size() <= max_items:
		return
	
	var to_remove = items.size() - max_items
	
	for i in range(to_remove):
		items[i].queue_free()

func get_random_spawn_position() -> Vector2:
	var rect = draggable_items.get_rect()
	
	return Vector2(
		randf_range(50, rect.size.x - 50),
		randf_range(50, rect.size.y - 50)
	)

func try_drop_item(item):
	if not game_running:
		return
	
	if input_locked:
		return
	
	var slot_rect = slot.get_global_rect()
	var item_center = item.global_position + item.size * 0.5
	
	if slot_rect.has_point(item_center):
		item.global_position = slot.global_position + slot.size * 0.5 - item.size * 0.5
		submit_input(item.item_name)
		item.queue_free()
