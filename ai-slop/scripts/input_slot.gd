extends Control

@onready var main = get_tree().get_root().get_node("Main")

func _process(delta):
	var hovering := false
	
	for item in get_tree().get_nodes_in_group("draggable"):
		if item.get_global_rect().intersects(get_global_rect()):
			hovering = true
	
	modulate = Color(1, 1, 1) if hovering else Color(0.7, 0.7, 0.7)

func _gui_input(event):
	if event is InputEventMouseButton and not event.pressed:
		check_for_drop()

func check_for_drop():
	for item in get_tree().get_nodes_in_group("draggable"):
		if item.get_global_rect().intersects(get_global_rect()):
			await snap_and_submit(item)

func snap_and_submit(item):
	item.global_position = global_position
	await get_tree().create_timer(0.1).timeout
	main.submit_input(item.item_name)
	reset_item(item)

func reset_item(item):
	item.position = item.start_position
