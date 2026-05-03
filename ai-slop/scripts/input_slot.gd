extends Control

func _process(_delta):
	var hovering := false
	
	for item in get_tree().get_nodes_in_group("draggable"):
		if item.get_global_rect().intersects(get_global_rect()):
			hovering = true
	
	modulate = Color(1, 1, 1) if hovering else Color(0.7, 0.7, 0.7)
