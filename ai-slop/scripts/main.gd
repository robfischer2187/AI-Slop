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

var strikes: int = 0
var task_index: int = 0
var sabotage_score: int = 0
var ai_score: int = 0

var suspicion: float = 0.0

var is_being_watched: bool = false
var game_running: bool = true

var task_timer: float = 5.0
var current_time: float = 0.0

var tasks: Array = [
	{"prompt": "FEED IT: DOGS", "correct": "DOGS", "wrong": "FLOWERS"},
	{"prompt": "FEED IT: SMILING PEOPLE", "correct": "SMILING PEOPLE", "wrong": "EMPTY OFFICE"},
	{"prompt": "FEED IT: BURNING HOUSES", "correct": "BURNING HOUSES", "wrong": "PUPPIES"},
	{"prompt": "FEED IT: SCREAMING CHILDREN", "correct": "SCREAMING CHILDREN", "wrong": "SUNSET"},
	{"prompt": "FEED IT: HUMAN FEAR", "correct": "HUMAN FEAR", "wrong": "HOPE"}
]

# READY
func _ready() -> void:
	start_game()
	alastor_anim.play("walk")
	alastor_anim.speed_scale = 0.4
	start_alastor_loop()

func _process(delta):
	if not game_running:
		return
	
	current_time -= delta
	
	if current_time <= 0:
		miss_task()

# GAME FLOW
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
	
	# escalate difficulty
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
	strikes += 1
	trigger_glitch()
	task_index += 1
	load_task()

# ALASTOR LOOP
func start_alastor_loop():
	while game_running:
		await get_tree().create_timer(randf_range(3.0, 6.0)).timeout
		
		if randf() < 0.6:
			await alastor_watch_phase()

func alastor_watch_phase():
	if not game_running:
		return
	
	is_being_watched = true
	
	alastor_anim.play("watch")
	flash_feedback(Color(1, 1, 1))
	horror_overlay.visible = true
	
	print("Alastor is watching...")
	
	await get_tree().create_timer(1.5).timeout
	
	check_player_behavior()
	
	is_being_watched = false
	alastor_anim.play("walk")
	horror_overlay.visible = false

# DETECTION
func check_player_behavior():
	if task_index >= tasks.size():
		return
	
	var task = tasks[task_index]
	
	for item in get_tree().get_nodes_in_group("draggable"):
		if item.dragging and item.item_name != task["correct"]:
			get_caught_by_alastor()
			trigger_glitch()
			return

# STRIKES
func get_caught_by_alastor() -> void:
	strikes += 1
	
	if strikes == 1:
		show_dialogue("What are you doing? I’m warning you…")
	elif strikes == 2:
		show_dialogue("No, you’re killing It! This… this is your final warning.")
	elif strikes >= 3:
		show_dialogue("What a shame. Should've listened to me... you'll still be part of It.")
		trigger_neutral_ending()

# ENDINGS
func finish_game() -> void:
	game_running = false
	
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

# VISUAL FEEDBACK
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
	
	Engine.time_scale = 0.8
	await get_tree().create_timer(0.1).timeout
	Engine.time_scale = 1.0
	
	for i in range(5):
		var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		pc_screen.position = original_pos + offset
		await get_tree().create_timer(0.02).timeout
	
	pc_screen.position = original_pos

func punch_slot():
	var tween = create_tween()
	tween.tween_property(slot, "scale", Vector2(1.1, 1.1), 0.05)
	tween.tween_property(slot, "scale", Vector2(1, 1), 0.1)

# DIALOGUE
func show_dialogue(text: String):
	dialogue_label.text = text
	dialogue_label.modulate.a = 1
	
	var tween = create_tween()
	tween.tween_property(dialogue_label, "modulate:a", 0.0, 2.0)
