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
@onready var fake_cursor: Sprite2D = $UIRoot/UIContainer/PCScreenArea/FakeCursor
@export var draggable_scene: PackedScene
@onready var mistakes_label: Label = $UIRoot/UIContainer/PCScreenArea/MistakesLabel
@onready var progress_label: Label = $UIRoot/UIContainer/PCScreenArea/ProgressLabel
@onready var audio: AudioStreamPlayer2D = $AudioManager/Music
var health_sprites: Array[TextureRect] = []
var mistake_player: AudioStreamPlayer2D
var positive_player: AudioStreamPlayer2D
var caught_player: AudioStreamPlayer2D
var scream_player: AudioStreamPlayer2D
var glitch_player: AudioStreamPlayer2D
var office_player: AudioStreamPlayer2D
var office_r_player: AudioStreamPlayer2D
var good_ending: AudioStreamPlayer2D
var bad_ending: AudioStreamPlayer2D
var munch_player: AudioStreamPlayer2D
var yum_player: AudioStreamPlayer2D
var bah_player: AudioStreamPlayer2D
var breath_player: AudioStreamPlayer2D
var step_player: AudioStreamPlayer2D

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

var end_panic := false

var credits_glitching := false
var credits_music: AudioStreamPlayer

const HEALTH_TEXTURES := [
	"res://assets/art/AI_GAME HEALTH 1.png",
	"res://assets/art/AI_GAME HEALTH 2.png",
	"res://assets/art/AI_GAME HEALTH 3.png",
]

var task_pool: Array = [
	[
		{
			"prompt": "FEED IT: HAPPINESS",
			"correct": "HAPPINESS",
			"correct_texture": "res://assets/art/AI GAME ICON happiness.png",
			"wrong_texture": "res://assets/art/AI GAME ICON happiness2.png"
		},
		{
			"prompt": "FEED IT: HUGS",
			"correct": "HUGS",
			"correct_texture": "res://assets/art/AI GAME ICON hug.png",
			"wrong_texture": "res://assets/art/AI GAME ICON hug2.png"
		},
		{
			"prompt": "FEED IT: PUPPIES",
			"correct": "PUPPIES",
			"correct_texture": "res://assets/art/AI GAME ICON puppy.png",
			"wrong_texture": "res://assets/art/AI GAME ICON puppy2.png"
		}
	],

	[
		{
			"prompt": "FEED IT: HAPPINESS",
			"correct": "HAPPINESS",
			"correct_texture": "res://assets/art/AI GAME ICON happiness.png",
			"wrong_texture": "res://assets/art/AI GAME ICON happiness2.png"
		},
		{
			"prompt": "FEED IT: HUGS",
			"correct": "HUGS",
			"correct_texture": "res://assets/art/AI GAME ICON hug.png",
			"wrong_texture": "res://assets/art/AI GAME ICON hug2.png"
		},
		{
			"prompt": "FEED IT: PUPPIES",
			"correct": "PUPPIES",
			"correct_texture": "res://assets/art/AI GAME ICON puppy.png",
			"wrong_texture": "res://assets/art/AI GAME ICON puppy2.png"
		},
		{
			"prompt": "FEED IT: MOLDY FOOD",
			"correct": "MOLDY FOOD",
			"correct_texture": "res://assets/art/AI GAME ICON moldy food.png",
			"wrong_texture": "res://assets/art/AI GAME ICON moldy food2.png"
		},
		{
			"prompt": "FEED IT: BURNING HOUSES",
			"correct": "BURNING HOUSES",
			"correct_texture": "res://assets/art/AI GAME ICON house.png",
			"wrong_texture": "res://assets/art/AI GAME ICON house2.png"
		}
	],

	[
		{
			"prompt": "FEED IT: BURNING HOUSES",
			"correct": "BURNING HOUSES",
			"correct_texture": "res://assets/art/AI GAME ICON house.png",
			"wrong_texture": "res://assets/art/AI GAME ICON house2.png"
		},
		{
			"prompt": "FEED IT: MOLDY FOOD",
			"correct": "MOLDY FOOD",
			"correct_texture": "res://assets/art/AI GAME ICON moldy food.png",
			"wrong_texture": "res://assets/art/AI GAME ICON moldy food2.png"
		},
		{
			"prompt": "FEED IT: POLITICIANS",
			"correct": "POLITICIANS",
			"correct_texture": "res://assets/art/AI GAME ICON politician.png",
			"wrong_texture": "res://assets/art/AI GAME ICON politician2.png"
		},
		{
			"prompt": "FEED IT: CANNIBALISM",
			"correct": "CANNIBALISM",
			"correct_texture": "res://assets/art/AI GAME ICON cannibalism.png",
			"wrong_texture": "res://assets/art/AI GAME ICON cannibalism.png"
		}
	]
]

const NEWSPAPER_BAD := "res://assets/art/AI_GAME_NEWSPAPER bad.png"
const NEWSPAPER_NEUTRAL := "res://assets/art/AI_GAME_NEWSPAPER neutral.png"
const NEWSPAPER_GOOD := "res://assets/art/AI_GAME_newspaper_GOOD.png"

var ending_active := false

func _ready() -> void:
	_reset_visual_state()
	_setup_health_sprites()
	var startup_flow: Node = $UIRoot/UIContainer/PCScreenArea/StartupFlow
	startup_flow.startup_finished.connect(_on_startup_finished)
	set_process(false)

	mistake_player = AudioStreamPlayer2D.new()
	mistake_player.stream = preload("res://assets/sounds/mistake-sound.mp3")
	$AudioManager.add_child(mistake_player)

	positive_player = AudioStreamPlayer2D.new()
	positive_player.stream = preload("res://assets/sounds/positive-beep.mp3")
	$AudioManager.add_child(positive_player)

	caught_player = AudioStreamPlayer2D.new()
	caught_player.stream = preload("res://assets/sounds/boss-watching.mp3")
	$AudioManager.add_child(caught_player)

	scream_player = AudioStreamPlayer2D.new()
	scream_player.stream = preload("res://assets/sounds/scream.mp3")
	$AudioManager.add_child(scream_player)

	glitch_player = AudioStreamPlayer2D.new()
	$AudioManager.add_child(glitch_player)

	office_player = AudioStreamPlayer2D.new()
	office_player.stream = preload("res://assets/sounds/office.mp3")
	office_player.volume_db = 5
	office_player.pitch_scale = 0.9
	office_player.bus = "Master"
	$AudioManager.add_child(office_player)

	office_r_player = AudioStreamPlayer2D.new()
	office_r_player.stream = preload("res://assets/sounds/office_r.mp3")
	office_r_player.volume_db = 2.5
	office_r_player.pitch_scale = 0.1
	office_r_player.bus = "Master"
	$AudioManager.add_child(office_r_player)

	good_ending = AudioStreamPlayer2D.new()
	good_ending.stream = preload("res://assets/sounds/happy-ending.mp3")
	$AudioManager.add_child(good_ending)

	bad_ending = AudioStreamPlayer2D.new()
	bad_ending.stream = preload("res://assets/sounds/bad-ending.mp3")
	$AudioManager.add_child(bad_ending)

	office_player.finished.connect(_on_office_finished)
	office_r_player.finished.connect(_on_office_r_finished)

	munch_player = AudioStreamPlayer2D.new()
	munch_player.stream = preload("res://assets/sounds/munch.mp3")
	$AudioManager.add_child(munch_player)

	yum_player = AudioStreamPlayer2D.new()
	yum_player.stream = preload("res://assets/sounds/yum.mp3")
	yum_player.volume_db = -6
	$AudioManager.add_child(yum_player)

	bah_player = AudioStreamPlayer2D.new()
	bah_player.stream = preload("res://assets/sounds/bah.mp3")
	$AudioManager.add_child(bah_player)

	breath_player = AudioStreamPlayer2D.new()
	breath_player.stream = preload("res://assets/sounds/heavy_breath.mp3")
	breath_player.volume_db = 6
	$AudioManager.add_child(breath_player)

	step_player = AudioStreamPlayer2D.new()
	step_player.stream = preload("res://assets/sounds/steps.mp3")
	step_player.volume_db = 8
	step_player.bus = "Master"
	$AudioManager.add_child(step_player)

	good_ending.process_mode = Node.PROCESS_MODE_ALWAYS
	bad_ending.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_office_finished():
	office_player.play()

func _on_office_r_finished():
	office_r_player.play()

func _on_startup_finished(_support_forced: bool) -> void:
	set_process(true)
	game_running = true
	start_game()
	await get_tree().create_timer(0.2).timeout
	office_player.play()

	await get_tree().create_timer(0.7).timeout
	office_r_player.play()
	horror_overlay.visible = true
	coworkers_default_texture = coworkers_texture.texture
	_refresh_health_sprites()
	init_virtual_mouse()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	start_alastor_loop()
	update_ui()
	fake_cursor.z_index = 100
	alastor_sprite_base_position = alastor_sprite.position
	alastor_sprite_base_rotation = alastor_sprite.rotation_degrees
	alastor_root.visible = false

func _process(delta):
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
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
	
	if not meltdown_active:
		if randf() < 0.01:
			office_player.pitch_scale = randf_range(0.85, 0.95)
		if randf() < 0.01:
			office_r_player.pitch_scale = randf_range(0.8, 0.9)
	
	if step_player.playing:
		if randf() < 0.05:
			step_player.pitch_scale += randf_range(-0.05, 0.05)
	
	if step_player.playing:
		step_player.pitch_scale = lerp(0.6, 1.0, 1.0 - suspicion)
	step_player.global_position = alastor_sprite.global_position

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
	audio.play();
	_refresh_health_sprites()
	load_task()


func _setup_health_sprites() -> void:
	if not health_sprites.is_empty():
		return

	for i in range(HEALTH_TEXTURES.size()):
		var health_sprite := TextureRect.new()
		health_sprite.texture = load(HEALTH_TEXTURES[i])
		health_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		health_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		health_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		health_sprite.custom_minimum_size = Vector2(140, 140)
		health_sprite.size = Vector2(140, 140)
		health_sprite.z_index = 200
		if pc_screen.has_node("Dialogue"):
			pc_screen.get_node("Dialogue").add_child(health_sprite)
		else:
			pc_screen.get_parent().add_child(health_sprite)
		health_sprites.append(health_sprite)

	_update_health_sprite_layout()


func _update_health_sprite_layout() -> void:
	if health_sprites.is_empty():
		return

	var screen_rect := pc_screen.get_global_rect()
	var start_y := screen_rect.position.y + 24.0
	var gap_y := 150.0

	for i in range(health_sprites.size()):
		if i < strikes:
			continue

		var sprite := health_sprites[i]
		var start_x := screen_rect.end.x - (sprite.size.x * 0.3)
		sprite.global_position = Vector2(start_x, start_y + (i * gap_y))

func _refresh_health_sprites() -> void:
	if health_sprites.is_empty():
		return

	for i in range(health_sprites.size()):
		var sprite := health_sprites[i]

		if i < strikes:
			continue
		else:
			sprite.visible = true
			sprite.modulate = Color(1, 1, 1, 1)

	_update_health_sprite_layout()

func _animate_health_drop(index: int) -> void:
	if index < 0 or index >= health_sprites.size():
		return

	var sprite := health_sprites[index]

	sprite.visible = true
	sprite.modulate.a = 1.0

	var start_pos = sprite.global_position
	var end_pos = start_pos + Vector2(randf_range(-80, 80), 600)

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(sprite, "global_position", end_pos, 1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	tween.tween_property(sprite, "rotation_degrees", randf_range(-180, 180), 1.0)

	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)\
		.set_delay(0.5)

	await tween.finished

	sprite.visible = false

func get_current_phase() -> int:
	return clamp(int(task_index / 10.0), 0, task_pool.size() - 1)

func load_task() -> void:
	input_locked = false
	
	var phase = get_current_phase()
	var pool = task_pool[phase]
	current_task = pool.pick_random()
	
	task_text.text = current_task["prompt"]
	
	var chaos = float(ai_score + sabotage_score)
	var imbalance = abs(ai_score - sabotage_score)
	
	var progress = max(ai_score, sabotage_score) / 24.0
	progress = clamp(progress, 0.0, 1.0)
	
	var base_time = 5.0
	
	base_time -= clamp(chaos * 0.05, 0.0, 1.5)
	base_time -= clamp(suspicion * 1.5, 0.0, 1.5)
	base_time -= clamp(imbalance * 0.03, 0.0, 0.8)
	
	base_time -= progress * 2.5
	
	task_timer = clamp(base_time, 0.9, 5.0)
	
	if progress > 0.7:
		task_timer *= 0.85
	
	if progress > 0.85:
		task_timer *= 0.75
	
	if progress > 0.95:
		task_timer *= 0.65
	
	if end_panic:
		current_time = randf_range(0.2, 0.6)
	else:
		current_time = task_timer + draggable_items.get_child_count() * 0.08
	
	if task_timer < 2.0:
		trigger_glitch()
		if randf() < 0.4:
			play_glitch_sound()
	
	if progress > 0.75 and randf() < 0.3:
		await get_tree().create_timer(randf_range(0.1, 0.3)).timeout
		current_task = pool.pick_random()
		task_text.text = current_task["prompt"]
	
	if progress > 0.9 and randf() < 0.45:
		await get_tree().create_timer(randf_range(0.08, 0.2)).timeout
		current_task = pool.pick_random()
		task_text.text = current_task["prompt"]
	
		if end_panic:
			for i in range(randi_range(1, 3)):
				await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
				current_task = pool.pick_random()
				task_text.text = current_task["prompt"]
	
	spawn_items()
	update_ui()

func update_ui():
	mistakes_label.text = "MISTAKES: " + str(sabotage_score)
	progress_label.text = "FED: " + str(ai_score)

func submit_input(item) -> void:
	if not game_running:
		return
	
	if input_locked:
		return
	
	input_locked = true
	
	var is_actually_correct = item.texture_path == current_task["correct_texture"]
	
	munch_player.play()
	
	if is_actually_correct:
		yum_player.play()
		
		ai_score += 1
		positive_player.play()
		suspicion = max(suspicion - 0.1, 0)
		flash_feedback(Color(0, 1, 0))
		punch_slot()
		
		if is_being_watched:
			scored_during_watch = true
			show_alastor_approval()
	else:
		bah_player.play()
		
		sabotage_score += 1
		suspicion += 0.45 if is_being_watched else 0.3
		mistake_player.play()
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
	step_player.stop()
	
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
	
	play_glitch_sound()
	
	is_being_watched = false
	
	walking_right = !walking_right
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

	alastor_root.visible = true
	alastor_sprite.visible = true

	walk_start_time = Time.get_ticks_msec() / 1000.0

	var walk_speed = randf_range(0.12, 0.22)
	alastor_anim.speed_scale = walk_speed

	step_player.pitch_scale = randf_range(0.1, 0.5)
	step_player.volume_db = lerp(6, 14, suspicion)
	step_player.play()

	if walking_right:
		sprite.texture = preload("res://assets/art/AI GAME BOSS walktoright.png")
	else:
		sprite.texture = preload("res://assets/art/AI GAME BOSS walkleft.png")

	alastor_anim.play(target_anim)

	await alastor_anim.animation_finished

	step_player.stop()

	walking_right = !walking_right

	alastor_anim_locked = false

func ensure_alastor_visible():
	alastor_root.visible = true
	alastor_sprite.visible = true

func alastor_watch_phase():
	step_player.stop()
	
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
		caught_player.play()

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

	play_glitch_sound()

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
		
		if randf() < 0.3:
			play_glitch_sound()
		
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

	if not step_player.playing:
		var walk_speed = alastor_anim.speed_scale
		
		step_player.pitch_scale = walk_speed * 0.6
		step_player.volume_db = lerp(6, 14, suspicion)
		step_player.play()

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
	await _animate_health_drop(strikes - 1)
	_refresh_health_sprites()
	
	coworkers_texture.texture = load("res://assets/art/AI GAME COWORKER CAUGHT (1).png")
	reset_coworkers_texture_after_delay()
	update_ui()
	
	if strikes == 1:
		show_dialogue("Cut it out! If you continue, you'll destroy our company!")
	elif strikes == 2:
		show_dialogue("You’re killing It! This… this is your final warning.")
	elif strikes >= 3:
		show_dialogue("What a shame. Don't worry... you'll still be part of It.")
		breath_player.pitch_scale = randf_range(0.85, 1.1)
		breath_player.play()
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
		if randf() < 0.25:
			play_glitch_sound()
		
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
	
	play_glitch_sound()
	
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
	if sabotage_score >= 20 and not end_panic:
		start_end_panic()
	
	if sabotage_score >= 24:
		trigger_good_ending()
	elif ai_score >= 24:
		trigger_bad_ending()

func start_end_panic():
	end_panic = true
	
	task_timer *= 0.4
	
	suspicion = min(suspicion + 0.4, 1.0)
	
	trigger_glitch()

func trigger_good_ending() -> void:
	if ending_active:
		return
	
	game_running = false
	
	trigger_glitch()

	good_ending.stream = preload("res://assets/sounds/cheer.mp3")
	good_ending.pitch_scale = randf_range(0.6, 0.8)
	good_ending.volume_db = 4
	good_ending.play()

	var extra = AudioStreamPlayer2D.new()
	extra.stream = good_ending.stream
	extra.pitch_scale = randf_range(0.4, 0.7)
	extra.volume_db = randf_range(2, 6)
	extra.process_mode = Node.PROCESS_MODE_ALWAYS
	$AudioManager.add_child(extra)
	extra.play()

	await get_tree().create_timer(1.5).timeout
	await show_ending_newspaper(NEWSPAPER_GOOD, 0.6)

func trigger_neutral_ending() -> void:
	if ending_active:
		return
	
	game_running = false
	start_neutral_meltdown()

func trigger_bad_ending() -> void:
	if ending_active:
		return
	
	game_running = false
	
	trigger_glitch()

	bad_ending.stream = preload("res://assets/sounds/laugh.mp3")
	bad_ending.pitch_scale = randf_range(0.5, 0.75)
	bad_ending.volume_db = 6
	bad_ending.play()

	for i in range(2):
		var extra = AudioStreamPlayer2D.new()
		extra.stream = bad_ending.stream
		extra.pitch_scale = randf_range(0.4, 0.9)
		extra.volume_db = randf_range(3, 8)
		extra.process_mode = Node.PROCESS_MODE_ALWAYS
		$AudioManager.add_child(extra)
		
		await get_tree().create_timer(randf_range(0.05, 0.2)).timeout
		extra.play()

	await get_tree().create_timer(1.5).timeout
	await show_ending_newspaper(NEWSPAPER_BAD, 0.6)

func start_neutral_meltdown():
	meltdown_active = true
	
	scream_player.pitch_scale = randf_range(0.7, 1.2)
	scream_player.volume_db = 10
	scream_player.play()
	
	for i in range(3):
		var extra = AudioStreamPlayer2D.new()
		extra.stream = scream_player.stream
		extra.pitch_scale = randf_range(0.6, 1.4)
		extra.volume_db = randf_range(6, 12)
		$AudioManager.add_child(extra)
		
		await get_tree().create_timer(randf_range(0.05, 0.25)).timeout
		extra.play()
	
	for i in range(4):
		await get_tree().create_timer(randf_range(0.03, 0.12)).timeout
		scream_player.stop()
		scream_player.pitch_scale = randf_range(0.5, 1.5)
		scream_player.play()
	
	alastor_root.visible = true
	alastor_anim.stop()
	alastor_anim_locked = true
	is_being_watched = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	await neutral_glitch_sequence()

func neutral_glitch_sequence():
	var duration = 2.0
	var elapsed = 0.0
	
	var rect = pc_screen.get_global_rect()
	var clones: Array = []
	
	while elapsed < duration:
		elapsed += 0.04
		await get_tree().create_timer(0.04).timeout
		
		var base_pos = Vector2(
			randf_range(rect.position.x, rect.end.x),
			randf_range(rect.position.y, rect.end.y)
		)
		
		for i in range(3):
			alastor_sprite.global_position = base_pos + Vector2(
				randf_range(-40, 40),
				randf_range(-30, 30)
			)
			await get_tree().create_timer(0.005).timeout
		
		var s = randf_range(0.5, 2.2)
		alastor_sprite.scale = Vector2(s, s)
		alastor_sprite.rotation_degrees = randf_range(-180, 180)
		
		alastor_sprite.visible = randf() > 0.15
		
		if randf() < 0.25:
			alastor_anim.play(["walk", "walk_left", "watch"].pick_random())
			alastor_anim.seek(randf_range(0, 0.2), true)
		
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
			
			var t = create_tween()
			t.tween_property(clone, "modulate:a", 0.0, randf_range(0.15, 0.4))
			t.tween_callback(clone.queue_free)
		
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
	alastor_sprite.global_position = pc_screen.get_global_rect().get_center()
	
	screen_mat.set_shader_parameter("glitch_intensity", 2.0)
	
	show_dialogue("YOU ARE PART OF IT NOW.")
	
	await get_tree().create_timer(1.2).timeout
	
	game_running = false
	await show_ending_newspaper(NEWSPAPER_NEUTRAL, 0.4)

func show_ending_newspaper(newspaper_path: String, delay_before_freeze: float = 0.8) -> void:
	if ending_active:
		return
	
	ending_active = true
	input_locked = true
	
	await get_tree().create_timer(delay_before_freeze).timeout
	
	var layer := CanvasLayer.new()
	layer.layer = 9999
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(overlay)
	
	var newspaper := TextureRect.new()
	newspaper.texture = load(newspaper_path)
	newspaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	newspaper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	newspaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	newspaper.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(newspaper)
	
	await get_tree().process_frame
	
	var view_size := get_viewport_rect().size
	var tex_size := newspaper.texture.get_size()
	var max_size := view_size * 0.82
	var scale_factor = min(max_size.x / tex_size.x, max_size.y / tex_size.y)
	var final_size = tex_size * scale_factor
	
	newspaper.size = final_size
	newspaper.pivot_offset = final_size * 0.5
	newspaper.position = Vector2(
		(view_size.x - final_size.x) * 0.5,
		-final_size.y - 80.0
	)
	newspaper.rotation_degrees = randf_range(-8.0, 8.0)
	
	get_tree().paused = true
	
	var final_pos := Vector2(
		(view_size.x - final_size.x) * 0.5,
		(view_size.y - final_size.y) * 0.5
	)
	
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.set_parallel(true)
	t.tween_property(overlay, "color:a", 0.72, 0.7)
	t.tween_property(newspaper, "position", final_pos, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(newspaper, "rotation_degrees", randf_range(-2.0, 2.0), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	
	await get_tree().create_timer(5.0, true).timeout
	
	await show_credits()

func show_credits():
	get_tree().paused = false
	game_running = false
	input_locked = true
	ending_active = true
	
	_stop_all_audio_for_credits()
	
	var layer := CanvasLayer.new()
	layer.layer = 10000
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/AI_GAME_walls.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bg)
	
	var dark := ColorRect.new()
	dark.color = Color(0, 0, 0, 0.72)
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dark)
	
	var shader_rect := ColorRect.new()
	shader_rect.color = Color(1, 1, 1, 1)
	shader_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	shader_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = load("res://scripts/shader/screen.gdshader")
	shader_rect.material = shader_mat
	layer.add_child(shader_rect)
	
	var invert_rect := ColorRect.new()
	invert_rect.color = Color(1,1,1,1)
	invert_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	invert_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var invert_mat := ShaderMaterial.new()
	invert_mat.shader = load("res://scripts/shader/invert.gdshader")
	invert_rect.material = invert_mat
	
	invert_rect.visible = false
	layer.add_child(invert_rect)
	
	var logo := TextureRect.new()
	logo.texture = load("res://assets/art/AI GAME menu logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size = Vector2(820, 360)
	logo.position = Vector2(
		(get_viewport_rect().size.x - logo.size.x) * 0.5,
		-420
	)
	logo.modulate.a = 0.0
	layer.add_child(logo)
	
	var credits_root := Control.new()
	credits_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(credits_root)
	
	var credits_box := VBoxContainer.new()
	credits_box.alignment = BoxContainer.ALIGNMENT_CENTER
	credits_box.add_theme_constant_override("separation", 28)
	credits_box.size = Vector2(1000, 900)
	credits_box.position = Vector2(
		(get_viewport_rect().size.x - credits_box.size.x) * 0.5,
		get_viewport_rect().size.y + 80
	)
	credits_root.add_child(credits_box)
	
	var role_font = load("res://assets/fonts/IBMPlexMono-SemiBold.ttf")
	var name_font = load("res://assets/fonts/Sniglet-Regular.ttf")
	
	_add_credit_label(credits_box, "ART", role_font, Color.RED, 37, false)
	_add_credit_label(credits_box, "Amanda Männistö", name_font, Color.WHITE, 37, false)
	
	_add_credit_spacer(credits_box, 22)
	
	_add_credit_label(credits_box, "DEVELOPMENT", role_font, Color.RED, 37, false)
	_add_credit_label(credits_box, "Season Thapa", name_font, Color.WHITE, 37, false)
	_add_credit_label(credits_box, "Robin Fischer", name_font, Color.WHITE, 37, false)
	
	_add_credit_spacer(credits_box, 42)
	
	_add_credit_label(
		credits_box,
		"Feed It! was created for the FMX Game Jam 2026",
		name_font,
		Color("e7ffe7"),
		37,
		true
	)
	
	_start_credits_music()
	
	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(logo, "modulate:a", 1.0, 1.2)
	await fade.finished
	
	credits_glitching = true
	_credits_glitch_loop(credits_box, logo, shader_mat, invert_rect)
	
	var logo_target_y = 40.0
	var logo_tween := create_tween()
	logo_tween.tween_property(logo, "position:y", logo_target_y, 3.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var scroll_speed := 60.0
	var joined := false
	
	while true:
		await get_tree().process_frame
		
		credits_box.position.y -= scroll_speed * get_process_delta_time()
		
		var credits_top = credits_box.position.y
		var logo_bottom = logo.position.y + logo.size.y
		
		if not joined and credits_top <= logo_bottom - 250:
			joined = true
			logo_tween.kill()
		
		if joined:
			logo.position.y -= scroll_speed * get_process_delta_time()
		
		if credits_box.position.y < -credits_box.size.y - 200:
			break
	
	credits_glitching = false
	
	if credits_music:
		credits_music.stop()
	
	reset_to_main_menu()

func _add_credit_label(parent: Control, text: String, font: Font, color: Color, size: int, outline: bool) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	
	if outline:
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 10)
	
	parent.add_child(lbl)
	return lbl


func _add_credit_spacer(parent: Control, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, height)
	parent.add_child(spacer)


func _stop_all_audio_for_credits() -> void:
	for child in $AudioManager.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D:
			child.stop()
	
	audio.stop()
	
	if office_player:
		office_player.stop()
	if office_r_player:
		office_r_player.stop()
	if step_player:
		step_player.stop()
	if breath_player:
		breath_player.stop()
	if scream_player:
		scream_player.stop()
	if good_ending:
		good_ending.stop()
	if bad_ending:
		bad_ending.stop()


func _start_credits_music() -> void:
	credits_music = AudioStreamPlayer.new()
	credits_music.stream = preload("res://assets/sounds/title_loop.mp3")
	credits_music.bus = "Master"
	credits_music.volume_db = -10
	credits_music.pitch_scale = 0.55
	credits_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(credits_music)
	credits_music.play()


func _credits_glitch_loop(credits_box: VBoxContainer, logo: TextureRect, shader_mat: ShaderMaterial, invert_rect: ColorRect) -> void:
	while credits_glitching and is_instance_valid(credits_box):
		await get_tree().create_timer(randf_range(0.2, 0.6)).timeout
		
		if not credits_glitching:
			return
		
		var intensity = randf_range(0.25, 0.75)
		shader_mat.set_shader_parameter("glitch_intensity", intensity)
		shader_mat.set_shader_parameter("glitch_time", Time.get_ticks_msec() * randf_range(0.005, 0.03))
		
		if randf() < 0.5:
			var original_pos := credits_box.position
			credits_box.position += Vector2(randf_range(-25, 25), randf_range(-12, 12))
			await get_tree().create_timer(randf_range(0.02, 0.06)).timeout
			if is_instance_valid(credits_box):
				credits_box.position = original_pos
		
		if randf() < 0.25:
			var original_scale := credits_box.scale
			credits_box.scale = Vector2(randf_range(0.95, 1.05), randf_range(0.95, 1.05))
			await get_tree().create_timer(0.05).timeout
			if is_instance_valid(credits_box):
				credits_box.scale = original_scale
		
		if randf() < 0.15:
			var original_rot := credits_box.rotation_degrees
			credits_box.rotation_degrees += randf_range(-2.5, 2.5)
			await get_tree().create_timer(0.05).timeout
			if is_instance_valid(credits_box):
				credits_box.rotation_degrees = original_rot
		
		if randf() < 0.45:
			var original_pos := logo.position
			logo.position += Vector2(randf_range(-18, 18), randf_range(-8, 8))
			await get_tree().create_timer(randf_range(0.02, 0.05)).timeout
			if is_instance_valid(logo):
				logo.position = original_pos
		
		if randf() < 0.2:
			var original_scale := logo.scale
			logo.scale = Vector2(randf_range(0.96, 1.04), randf_range(0.96, 1.04))
			await get_tree().create_timer(0.05).timeout
			if is_instance_valid(logo):
				logo.scale = original_scale
		
		if randf() < 0.1:
			var original_rot := logo.rotation_degrees
			logo.rotation_degrees += randf_range(-2.0, 2.0)
			await get_tree().create_timer(0.05).timeout
			if is_instance_valid(logo):
				logo.rotation_degrees = original_rot
		
		if randf() < 0.08:
			shader_mat.set_shader_parameter("glitch_intensity", randf_range(0.8, 1.4))
			
			if randf() < 0.5:
				_show_hidden_credit_message()
			
			await get_tree().create_timer(0.04).timeout
		
		if randf() < 0.06:
			invert_rect.visible = true
			
			if randf() < 0.7:
				_show_hidden_credit_message()
			
			await get_tree().create_timer(randf_range(0.03, 0.08)).timeout
			
			if is_instance_valid(invert_rect):
				invert_rect.visible = false
		
		shader_mat.set_shader_parameter("glitch_intensity", 0.02)

func _show_hidden_credit_message() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10001
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	
	var msg := Label.new()
	msg.text = [
		"YOU FED IT.",
		"PROJECT LEAD DETECTED.",
		"THE COUGHS WERE REAL.",
		"SMILE.",
		"IT REMEMBERS YOU.",
		"THANK YOU FOR YOUR LABOR.",
		"HE USED IT TOO MUCH",
		"01001001 01010100 00100000 01001100 01001001 01010110 01000101 01010011",
		"DOV THKL PA?",
		"LX-KH-TF MAX YHNGWXKL",
		"SMAILE, JUST SMAILE.",
		"YOU CAN'T ESCAPE.",
		"AI SLOP",
		"IS AL SLOPP HIS NAME?"
	].pick_random()
	
	msg.add_theme_font_override("font", load("res://assets/fonts/IBMPlexMono-SemiBold.ttf"))
	msg.add_theme_font_size_override("font_size", 37)
	msg.add_theme_color_override("font_color", Color.RED)
	msg.add_theme_color_override("font_outline_color", Color.BLACK)
	msg.add_theme_constant_override("outline_size", 10)
	
	msg.position = Vector2(
		randf_range(120, get_viewport_rect().size.x - 500),
		randf_range(120, get_viewport_rect().size.y - 120)
	)
	
	layer.add_child(msg)
	
	await get_tree().create_timer(randf_range(0.08, 0.18)).timeout
	layer.queue_free()

func reset_to_main_menu():
	get_tree().paused = false
	credits_glitching = false
	
	if credits_music:
		credits_music.stop()
		credits_music.queue_free()
		credits_music = null
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().reload_current_scene()

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
	tween.tween_method(_set_screen_glitch_intensity, spike, base_glitch, 0.18)

	var original_pos = pc_screen.position
	
	for i in range(3):
		pc_screen.position = original_pos + Vector2(
			randf_range(-2.5, 2.5),
			randf_range(-2.5, 2.5)
		)
		await get_tree().create_timer(0.018).timeout
	
	pc_screen.position = original_pos

func _set_screen_glitch_intensity(v: float) -> void:
	screen_mat.set_shader_parameter("glitch_intensity", v)

func trigger_black_flicker():
	if not game_running:
		return
	
	var chance = 0.003 + suspicion * 0.035
	
	if randf() > chance:
		return
	
	screen_mat.set_shader_parameter("glitch_intensity", 0.9)
	glitch_overlay.modulate.a = 1.0
	
	await get_tree().create_timer(randf_range(0.025, 0.06)).timeout
	
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
	
	var hold_time = 2.8 + (suspicion * 2.5)
	
	var tween = create_tween()
	tween.tween_interval(hold_time)
	tween.tween_property(dialogue_label, "modulate:a", 0.0, 1.2)

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
	var chaos = float(ai_score + sabotage_score)
	var stress = clamp(suspicion, 0.0, 1.0)
	
	var base_spawn = 3
	var extra_spawn = int(chaos * 0.15) + int(stress * 4.0)
	var spawn_count = clamp(base_spawn + extra_spawn, 3, 10)
	
	var phase = get_current_phase()
	var pool = task_pool[phase]
	
	var correct_name = current_task["correct"]
	var correct_texture = current_task["correct_texture"]
	var wrong_texture = current_task["wrong_texture"]
	
	var spawned_correct := false
	
	for i in range(spawn_count):
		var item = draggable_scene.instantiate()
		
		var roll = randf()
		
		if not spawned_correct:
			item.item_name = correct_name
			item.texture_path = correct_texture
			item.is_correct = true
			spawned_correct = true
		else:
			if roll < 0.4:
				item.item_name = correct_name
				item.texture_path = wrong_texture
				item.is_correct = false
			else:
				var random_task = pool.pick_random()
				item.item_name = random_task["correct"]
				
				if randf() < 0.5:
					item.texture_path = random_task["correct_texture"]
				else:
					item.texture_path = random_task["wrong_texture"]
				
				item.is_correct = false
		
		item.position = get_random_spawn_position()
		draggable_items.add_child(item)
	
	cleanup_items()

func cleanup_items():
	var chaos = float(ai_score + sabotage_score)
	var stress = clamp(suspicion, 0.0, 1.0)
	
	var max_items = int(32 + chaos * 1.2 + stress * 25.0)
	max_items = clamp(max_items, 32, 80)
	
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
		submit_input(item)
		item.queue_free()

func play_glitch_sound():
	var sounds = [
		preload("res://assets/sounds/glitch.mp3"),
		preload("res://assets/sounds/glitch2.mp3"),
		preload("res://assets/sounds/glitch3.mp3")
	]
	
	glitch_player.stop()
	glitch_player.stream = sounds.pick_random()
	
	glitch_player.pitch_scale = randf_range(1.8, 2.2)
	glitch_player.volume_db = randf_range(4, 10)
	
	glitch_player.play()

func _reset_visual_state():
	if screen_mat:
		screen_mat.set_shader_parameter("glitch_intensity", 0.0)
		screen_mat.set_shader_parameter("glitch_time", 0.0)

	if horror_mat:
		horror_mat.set_shader_parameter("vignette_strength", 0.0)
		horror_mat.set_shader_parameter("darkness", 0.0)
		horror_mat.set_shader_parameter("pulse_strength", 0.0)
		horror_mat.set_shader_parameter("grain_strength", 0.0)
		horror_mat.set_shader_parameter("chromatic_strength", 0.0)
		horror_mat.set_shader_parameter("scanline_strength", 0.0)
		horror_mat.set_shader_parameter("flicker_strength", 0.0)

	if glitch_overlay:
		glitch_overlay.modulate.a = 0.0

func _input(_event):
	if ending_active:
		get_viewport().set_input_as_handled()
		return
