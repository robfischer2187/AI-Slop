extends Node2D

@onready var task_text: Label = $UIRoot/UIContainer/PCScreenArea/TaskText
@onready var slot: Control = $UIRoot/UIContainer/PCScreenArea/InputSlots/Slot
@onready var draggable_items: Control = $UIRoot/UIContainer/PCScreenArea/DraggableItems
@onready var horror_overlay: CanvasLayer = $UIRoot/UIContainer/HorrorOverlay
@onready var feedback_flash: ColorRect = $UIRoot/UIContainer/PCScreenArea/FeedbackFlash
@onready var glitch_overlay: ColorRect = $UIRoot/UIContainer/PCScreenArea/GlitchOverlay
@onready var pc_screen: Control = $UIRoot/UIContainer/PCScreenArea
@onready var alastor_root = $AlastorRoot
@onready var alastor = $AlastorRoot/AlastorSlopp
@onready var alastor_anim = $AlastorRoot/AlastorSlopp/AnimationPlayer
@onready var alastor_sprite = $AlastorRoot/AlastorSlopp/Sprite2D
@onready var dialogue_label: Label = $UIRoot/UIContainer/PCScreenArea/Dialogue/DialogueLabel
@onready var horror_mat: ShaderMaterial = $UIRoot/UIContainer/HorrorOverlay/EffectRect.material
@onready var screen_mat: ShaderMaterial = $UIRoot/UIContainer/PCScreenArea/ScreenOverlay/EffectRect.material
@onready var coworkers_texture: TextureRect = $Coworkers
@onready var cursor_blocker: Control = $UIRoot/UIContainer/PCScreenArea/CursorBlockerArea
@onready var fake_cursor: Sprite2D = $UIRoot/FakeCursor
@export var draggable_scene: PackedScene
@onready var mistakes_label: Label = $UIRoot/UIContainer/PCScreenArea/MistakesLabel
@onready var progress_label: Label = $UIRoot/UIContainer/PCScreenArea/ProgressLabel

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
var scored_during_watch: bool = false
var walking_right: bool = true

var breather: bool = false

var walk_start_time: float = 0.0
var glitch_delay_after_walk_start: float = 2.0

var alastor_roam_glitch_timer: float = 0.0
var alastor_roam_glitch_interval: float = 1.8

var alastor_sprite_base_position: Vector2
var alastor_sprite_base_rotation: float = 0.0
var alastor_glitching_visual: bool = false
var alastor_anim_locked: bool = false

var next_allowed_check_time: float = 0.0

var next_glitch_time: float = 0.0

var meltdown_active := false

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
	start_alastor_loop()
	update_ui()
	fake_cursor.z_index = 100
	alastor_sprite_base_position = alastor_sprite.position
	alastor_sprite_base_rotation = alastor_sprite.rotation_degrees
	alastor_root.visible = false

func _process(delta):
	if not game_running:
		return
	
	current_time -= delta
	
	if current_time <= 0:
		miss_task()
	
	update_suspicion(delta)
	update_alastor_roaming_glitch(delta)
	update_horror_shader()
	update_virtual_mouse()
	
	wobble_time += delta
	
	if not alastor_glitching_visual and alastor_anim.is_playing() and (alastor_anim.current_animation == "walk" or alastor_anim.current_animation == "walk_left"):
		ensure_alastor_visible()
		var rot = sin(wobble_time * 1.7) * 3.0
		alastor_sprite.position = alastor_sprite_base_position + Vector2(0, sin(wobble_time * 2.5) * 6.0)
		alastor_sprite.rotation_degrees = alastor_sprite_base_rotation + rot
	
	if Input.is_action_just_pressed("debug_toggle_mouse"):
		free_mouse = !free_mouse
		
		if free_mouse:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	fake_cursor.global_position = virtual_mouse_pos
	
	var now = Time.get_ticks_msec() / 1000.0
	screen_mat.set_shader_parameter("glitch_time", now)
	
	var base_glitch = 0.004 + suspicion * 0.045
	var pulse = sin(Time.get_ticks_msec() * 0.0015) * 0.004
	screen_mat.set_shader_parameter("glitch_intensity", max(base_glitch + pulse, 0.0))
	
	trigger_black_flicker()

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

func start_game() -> void:
	strikes = 0
	task_index = 0
	sabotage_score = 0
	ai_score = 0
	suspicion = 0.0
	game_running = true
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
		suspicion += 0.45 if is_being_watched else 0.3
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
	suspicion += 0.12
	trigger_glitch()
	task_index += 1
	update_ui()
	load_task()

func update_suspicion(delta):
	var decay = delta * 0.025
	
	if is_being_watched:
		suspicion += delta * 0.035
	
	if current_time < task_timer * 0.35:
		suspicion += delta * 0.015
	
	if sabotage_score > ai_score and sabotage_score > 1:
		suspicion += delta * 0.01
	
	suspicion = clamp(suspicion - decay, 0.0, 1.0)

func update_alastor_roaming_glitch(delta):
	if not game_running:
		return
	
	if is_being_watched:
		return
	
	if breather:
		return
	
	if alastor_anim_locked and not (
		alastor_anim.current_animation == "walk" or 
		alastor_anim.current_animation == "walk_left"
	):
		return
	
	if alastor_anim.current_animation != "walk" and alastor_anim.current_animation != "walk_left":
		return
	
	alastor_roam_glitch_timer -= delta
	
	if alastor_roam_glitch_timer > 0:
		return
	
	alastor_roam_glitch_timer = alastor_roam_glitch_interval
	
	var now = Time.get_ticks_msec() / 1000.0
	
	if now - walk_start_time < glitch_delay_after_walk_start:
		return
	
	if now < next_allowed_check_time:
		return
	
	var chance = 0.08 + suspicion * 0.18
	
	if randf() < chance:
		await alastor_mid_walk_check()

func alastor_mid_walk_check():
	if is_being_watched:
		return
	
	if not game_running:
		return
	
	is_being_watched = true
	got_caught_this_watch = false
	scored_during_watch = false
	
	await alastor_pre_watch_glitch()
	
	play_watch_animation()
	trigger_glitch()
	
	var watch_time = lerp(1.2, 2.8, suspicion)
	await get_tree().create_timer(watch_time).timeout
	
	if not game_running:
		return
	
	if got_caught_this_watch:
		pass
	elif sabotage_score >= ai_score * 3 and sabotage_score > 0:
		await alastor_micro_glitch()
		show_alastor_rage()
		await get_tree().create_timer(1.5).timeout
		get_caught_by_alastor()
	elif sabotage_score >= ai_score * 2 and sabotage_score > 0:
		show_alastor_angry()
	elif ai_score >= sabotage_score * 3 and ai_score > 0:
		show_alastor_excited()
	elif ai_score >= sabotage_score * 2 and ai_score > 0:
		show_alastor_impressed()
	elif scored_during_watch:
		pass
	else:
		show_alastor_disappointment()
	
	await alastor_glitch_transition()
	
	is_being_watched = false
	
	restore_walk_state()
	
	next_allowed_check_time = Time.get_ticks_msec() / 1000.0 + randf_range(3.5, 6.0)

func start_alastor_loop():
	while game_running:
		
		await play_walk_animation()

		if not game_running:
			return

		breather = true

		await alastor_glitch_transition()
		alastor_root.visible = false

		var breather_time = randf_range(7.5, 12.5)
		await get_tree().create_timer(breather_time).timeout

		breather = false

		if not game_running:
			return

		var watch_chance = 0.25 + suspicion * 0.6

		if randf() < watch_chance:
			await alastor_watch_phase()

func play_walk_animation():
	if alastor_anim_locked:
		return
	
	alastor_anim_locked = true
	
	var sprite: Sprite2D = alastor.get_node("Sprite2D")
	var target_anim = "walk" if walking_right else "walk_left"

	alastor_root.visible = false

	var wait_time = randf_range(3.5, 6.5)
	await get_tree().create_timer(wait_time).timeout

	if not game_running:
		alastor_anim_locked = false
		return

	# 👇 THIS is the important order
	alastor_root.visible = true
	alastor_sprite.visible = true

	walk_start_time = Time.get_ticks_msec() / 1000.0

	if walking_right:
		sprite.texture = preload("res://assets/art/AI GAME BOSS walktoright.png")
	else:
		sprite.texture = preload("res://assets/art/AI GAME BOSS walkleft.png")

	alastor_anim.play(target_anim)

	await alastor_anim.animation_finished

	walking_right = !walking_right

	alastor_anim_locked = false

func ensure_alastor_visible():
	alastor_root.visible = true
	alastor_sprite.visible = true

func alastor_watch_phase():
	if not game_running:
		return
	
	is_being_watched = true
	got_caught_this_watch = false
	scored_during_watch = false
	
	await alastor_pre_watch_glitch()

	play_watch_animation()
	flash_feedback(Color(1, 1, 1))
	trigger_glitch()
	
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
	elif ai_score >= sabotage_score * 3 and ai_score > 0:
		show_alastor_excited()
	elif ai_score >= sabotage_score * 2 and ai_score > 0:
		show_alastor_impressed()
	elif scored_during_watch:
		pass
	else:
		show_alastor_disappointment()
	
	is_being_watched = false
	
	await alastor_glitch_transition()

	walking_right = !walking_right
	restore_walk_state()
	alastor_anim.speed_scale = randf_range(0.12, 0.22)

	next_allowed_check_time = Time.get_ticks_msec() / 1000.0 + randf_range(3.5, 6.0)

func alastor_pre_watch_glitch():
	alastor_glitching_visual = true
	
	var original_pos = alastor_sprite_base_position
	var original_rot = alastor_sprite_base_rotation
	
	var steps = 6 + int(suspicion * 6)
	
	for i in range(steps):
		var t = float(i) / steps
		
		var shake_x = lerp(4.0, 18.0, t)
		var shake_y = lerp(3.0, 14.0, t)
		
		alastor_sprite.position = original_pos + Vector2(
			randf_range(-shake_x, shake_x),
			randf_range(-shake_y, shake_y)
		)
		
		alastor_sprite.rotation_degrees = original_rot + randf_range(-10, 10) * (1.0 + t * 2.0)
		alastor_sprite.visible = randf() > (0.7 - t * 0.4)
		
		if t > 0.6 and randf() < 0.35:
			alastor_sprite.position = original_pos + Vector2(
				randf_range(-60, 60),
				randf_range(-40, 40)
			)
		
		await get_tree().create_timer(lerp(0.05, 0.015, t)).timeout
	
	ensure_alastor_visible()
	alastor_sprite.position = original_pos
	alastor_sprite.rotation_degrees = original_rot
	
	alastor_glitching_visual = false

func play_watch_animation():
	var sprite: Sprite2D = alastor.get_node("Sprite2D")

	alastor_anim.stop()

	if walking_right:
		sprite.texture = preload("res://assets/art/AI GAME BOSS look right.png")
	else:
		sprite.texture = preload("res://assets/art/AI GAME BOSS lookleft.png")

	alastor_anim.play("watch")

func restore_walk_state():
	var sprite: Sprite2D = alastor.get_node("Sprite2D")

	if walking_right:
		sprite.texture = preload("res://assets/art/AI GAME BOSS walktoright.png")
		if alastor_anim.current_animation != "walk":
			alastor_anim.play("walk")
	else:
		sprite.texture = preload("res://assets/art/AI GAME BOSS walkleft.png")
		if alastor_anim.current_animation != "walk_left":
			alastor_anim.play("walk_left")

func show_alastor_angry():
	show_dialogue([
		"What are you doing...",
		"This is not acceptable.",
		"You are feeding it wrong.",
		"Fix this. Now.",
		"I see what you're doing.",
		"This is inefficient."
	].pick_random())

func show_alastor_rage():
	show_dialogue([
		"Enough.",
		"You are sabotaging it.",
		"I will not tolerate this.",
		"You think I wouldn't notice?",
		"This ends now.",
		"You're done."
	].pick_random())

func show_alastor_disappointment():
	show_dialogue([
		"...",
		"Why are you hesitating?",
		"It is waiting.",
		"Do your job.",
		"You're wasting time.",
		"This is disappointing.",
		"I expected more from you."
	].pick_random())

func show_alastor_impressed():
	show_dialogue([
		"Efficient.",
		"You're exceeding expectations.",
		"It grows quickly because of you.",
		"This is... optimal.",
		"You're learning fast.",
		"Good. Very good."
	].pick_random())

func show_alastor_excited():
	show_dialogue([
		"YES…",
		"This is perfect.",
		"Keep feeding It.",
		"You're making It stronger.",
		"Don't stop now.",
		"This is what I wanted."
	].pick_random())

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
		show_dialogue("You’re killing It! This… this is your final warning.")
	elif strikes >= 3:
		show_dialogue("What a shame. Don't worry... you'll still be part of It.")
		await get_tree().create_timer(3).timeout
		trigger_neutral_ending()

func reset_coworkers_texture_after_delay() -> void:
	await get_tree().create_timer(randf_range(2.0, 5.0)).timeout
	
	if game_running:
		coworkers_texture.texture = coworkers_default_texture

func show_alastor_approval():
	show_dialogue([
		"Good job...",
		"It appreciates your work.",
		"Yes... feed it.",
		"Make It stronger.",
		"That's better.",
		"Keep going.",
		"Remember to smile."
	].pick_random())

func alastor_glitch_transition():
	
	alastor_glitching_visual = true
	
	var intensity = lerp(4, 10, suspicion)
	var original_pos = alastor_sprite_base_position
	var original_rot = alastor_sprite_base_rotation
	
	for i in range(int(intensity)):
		alastor_sprite.position = original_pos + Vector2(
			randf_range(-12, 12),
			randf_range(-10, 10)
		)
		
		alastor_sprite.rotation_degrees = original_rot + randf_range(-25, 25)
		alastor_sprite.visible = randf() > 0.5
		
		if randf() < 0.25:
			alastor_sprite.position = original_pos + Vector2(
				randf_range(-40, 40),
				randf_range(-30, 30)
			)
		
		await get_tree().create_timer(randf_range(0.015, 0.04)).timeout
	
	ensure_alastor_visible()
	alastor_sprite.position = original_pos
	alastor_sprite.rotation_degrees = original_rot
	
	alastor_glitching_visual = false

func alastor_micro_glitch():
	
	alastor_glitching_visual = true
	
	var original_pos = alastor_sprite_base_position
	var original_rot = alastor_sprite_base_rotation
	
	for i in range(5):
		alastor_sprite.position = original_pos + Vector2(
			randf_range(-10, 10),
			randf_range(-8, 8)
		)
		
		alastor_sprite.rotation_degrees = original_rot + randf_range(-15, 15)
		alastor_sprite.visible = randf() > 0.4
		
		await get_tree().create_timer(0.015).timeout
	
	ensure_alastor_visible()
	alastor_sprite.position = original_pos
	alastor_sprite.rotation_degrees = original_rot
	
	alastor_glitching_visual = false

func check_end_conditions():
	if sabotage_score >= 24:
		trigger_good_ending()
	elif ai_score >= 24:
		trigger_bad_ending()

func trigger_good_ending() -> void:
	game_running = false
	print("AI COMPANY CLOSES!")

func trigger_neutral_ending() -> void:
	game_running = false
	start_neutral_meltdown()
	print("SCANDAL AT SMAILE!")

func trigger_bad_ending() -> void:
	game_running = false
	print("AI CREATURE ON THE LOOSE!")

func start_neutral_meltdown():
	meltdown_active = true
	
	alastor_root.visible = true
	alastor_anim.stop()
	alastor_anim_locked = true
	is_being_watched = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	await neutral_glitch_sequence()

func neutral_glitch_sequence():
	var duration = 6.0
	var elapsed = 0.0
	
	var rect = pc_screen.get_global_rect()
	var clones: Array = []
	
	while elapsed < duration:
		elapsed += 0.04
		await get_tree().create_timer(0.04).timeout
		
		# 🔴 BASE POSITION (constantly shifting anchor)
		var base_pos = Vector2(
			randf_range(rect.position.x, rect.end.x),
			randf_range(rect.position.y, rect.end.y)
		)
		
		# 🔴 MULTI-JITTER IN ONE FRAME (this is key)
		for i in range(3):
			alastor_sprite.global_position = base_pos + Vector2(
				randf_range(-40, 40),
				randf_range(-30, 30)
			)
			await get_tree().create_timer(0.005).timeout
		
		# 🔴 SCALE + ROTATION CHAOS
		var s = randf_range(0.5, 2.2)
		alastor_sprite.scale = Vector2(s, s)
		alastor_sprite.rotation_degrees = randf_range(-180, 180)
		
		# 🔴 FLICKER DESYNC
		alastor_sprite.visible = randf() > 0.15
		
		# 🔴 RANDOM ANIMATION BREAKS
		if randf() < 0.25:
			alastor_anim.play(["walk", "walk_left", "watch"].pick_random())
			alastor_anim.seek(randf_range(0, 0.2), true)
		
		# 🔴 SPAWN AFTERIMAGE CLONES (THIS MAKES IT FEEL INSANE)
		if randf() < 0.35:
			var clone = Sprite2D.new()
			clone.texture = alastor_sprite.texture
			clone.global_position = alastor_sprite.global_position
			clone.rotation_degrees = alastor_sprite.rotation_degrees
			clone.scale = alastor_sprite.scale * randf_range(0.8, 1.2)
			clone.modulate = Color(1, 1, 1, randf_range(0.2, 0.6))
			clone.z_index = 99
			
			add_child(clone)
			clones.append(clone)
			
			# fade out clone
			var t = create_tween()
			t.tween_property(clone, "modulate:a", 0.0, randf_range(0.15, 0.4))
			t.tween_callback(clone.queue_free)
		
		# 🔴 SCREEN STILL SUPPORTS CHAOS (but secondary now)
		screen_mat.set_shader_parameter("glitch_intensity", randf_range(0.8, 2.5))
		screen_mat.set_shader_parameter("glitch_time", Time.get_ticks_msec() * randf_range(0.002, 0.02))
		
		pc_screen.position += Vector2(
			randf_range(-6, 6),
			randf_range(-6, 6)
		)
		
		if randf() < 0.35:
			spawn_meltdown_text([
				"NO.",
				"STOP.",
				"YOU BROKE IT.",
				"IT NEEDS MORE.",
				"WHY.",
				"FIX IT.",
				"YOU CAN'T STOP IT.",
				"TOO LATE."
			].pick_random())
	
	# CLEANUP (just in case)
	for c in clones:
		if is_instance_valid(c):
			c.queue_free()
	
	await final_neutral_snap()

func spawn_meltdown_text(text: String):
	var lbl = Label.new()
	lbl.text = text
	
	var rect = pc_screen.get_rect()
	var center = rect.size * 0.5
	
	lbl.position = center + Vector2(
		randf_range(-400, 400),
		randf_range(-250, 250)
	)
	
	var font = load("res://assets/fonts/Sniglet-Regular.ttf")
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 48)
	
	if randf() < 0.2:
		lbl.add_theme_font_size_override("font_size", randi_range(64, 110))
	
	lbl.add_theme_color_override("font_color", Color("e7ffe7"))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 10)
	
	lbl.rotation_degrees = randf_range(-25, 25)
	
	var s = randf_range(0.9, 1.6)
	lbl.scale = Vector2(s, s)
	
	lbl.z_index = 999
	
	pc_screen.add_child(lbl)
	
	await get_tree().process_frame
	lbl.pivot_offset = lbl.size * 0.5
	
	_text_jitter(lbl)
	
	var t = create_tween()
	t.tween_property(lbl, "modulate:a", 0.0, randf_range(0.8, 1.8))
	t.tween_callback(lbl.queue_free)

func _text_jitter(lbl: Label) -> void:
	for i in range(6):
		await get_tree().create_timer(randf_range(0.01, 0.04)).timeout
		
		if not is_instance_valid(lbl):
			return
		
		lbl.position += Vector2(
			randf_range(-6, 6),
			randf_range(-4, 4)
		)
		
		lbl.rotation_degrees += randf_range(-5, 5)

func final_neutral_snap():
	alastor_sprite.scale = Vector2(2.5, 2.5)
	alastor_sprite.rotation_degrees = 0
	alastor_sprite.global_position = pc_screen.get_global_rect().size * 0.5
	
	screen_mat.set_shader_parameter("glitch_intensity", 2.0)
	
	show_dialogue("YOU ARE PART OF IT NOW.")
	
	await get_tree().create_timer(1.2).timeout
	
	game_running = false
	get_tree().quit() # or transition to ending scene

func flash_feedback(color: Color):
	feedback_flash.color = color
	feedback_flash.modulate.a = 0.6
	var tween = create_tween()
	tween.tween_property(feedback_flash, "modulate:a", 0.0, 0.25)

func trigger_glitch():
	var now = Time.get_ticks_msec() / 1000.0
	
	if now < next_glitch_time:
		return
	
	var cooldown = lerp(2.2, 0.8, suspicion)
	next_glitch_time = now + cooldown
	
	var mat := screen_mat
	var base_glitch = 0.004 + suspicion * 0.045
	var spike = 0.35 + suspicion * 0.55
	
	mat.set_shader_parameter("glitch_intensity", spike)
	mat.set_shader_parameter("glitch_time", now)

	var tween = create_tween()
	tween.tween_method(
		func(v):
			mat.set_shader_parameter("glitch_intensity", v),
		spike, base_glitch, 0.18
	)

	var original_pos = pc_screen.position
	
	for i in range(3):
		pc_screen.position = original_pos + Vector2(
			randf_range(-2.5, 2.5),
			randf_range(-2.5, 2.5)
		)
		await get_tree().create_timer(0.018).timeout
	
	pc_screen.position = original_pos

func trigger_black_flicker():
	if not game_running:
		return
	
	var chance = 0.01 + suspicion * 0.08
	
	if randf() > chance:
		return
	
	screen_mat.set_shader_parameter("glitch_intensity", 0.9)
	glitch_overlay.modulate.a = 1.0
	
	await get_tree().create_timer(randf_range(0.03, 0.07)).timeout
	
	glitch_overlay.modulate.a = 0.0

func punch_slot():
	var tween = create_tween()
	tween.tween_property(slot, "scale", Vector2(1.1, 1.1), 0.05)
	tween.tween_property(slot, "scale", Vector2(1, 1), 0.1)

func show_dialogue(text: String):
	dialogue_label.text = text
	dialogue_label.modulate.a = 1
	
	if meltdown_active:
		return
	
	var tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(dialogue_label, "modulate:a", 0.0, 1.5)

func update_horror_shader():
	if meltdown_active:
		horror_mat.set_shader_parameter("vignette_strength", randf_range(2.0, 4.5))
		horror_mat.set_shader_parameter("vignette_pulse", randf_range(0.3, 1.2))
		horror_mat.set_shader_parameter("pulse_speed", randf_range(2.0, 8.0))
		
		horror_mat.set_shader_parameter("darkness", randf_range(0.4, 0.85))
		horror_mat.set_shader_parameter("contrast", randf_range(1.2, 1.8))
		
		horror_mat.set_shader_parameter("grain_strength", randf_range(0.05, 0.25))
		horror_mat.set_shader_parameter("chromatic_strength", randf_range(0.003, 0.015))
		
		horror_mat.set_shader_parameter("flicker_chance", randf_range(0.05, 0.25))
		
		horror_mat.set_shader_parameter("tint_strength", randf_range(0.4, 0.9))
		
		return
	
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
