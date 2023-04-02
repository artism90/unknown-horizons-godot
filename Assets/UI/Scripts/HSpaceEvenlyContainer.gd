@tool
extends HBoxContainer
class_name HSpaceEvenlyContainer


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		var initial_value = 0
		var occupied_space = get_children().reduce(func(accumulator, child): return accumulator + child.size.x, initial_value)
		var remaining_space = size.x - occupied_space
		var space_between_children = remaining_space / (get_children().size() - 1)
		
		var x = 0
		for child in get_children():
			child.offset_left = x
			x = x + child.size.x + space_between_children
