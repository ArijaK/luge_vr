class_name PolarGrid extends Control

@export var min_value = 0
@export var max_value = 150
@export var units = 5
@export var big_per_unit = 5

const START_ANGLE = deg_to_rad(-220)
const END_ANGLE = deg_to_rad(40)

func _draw() -> void:
	var center = size * 0.5
	var radius = min(size.x, size.y) * 0.5
	draw_circle(center, radius, Color.hex(0x1F1F1F96), true)
	
	var value_range = max_value - min_value
	
	# How far from centre marks should be
	var radius_outer = radius - 2
	var radius_units = radius_outer - 10
	var radius_big_units = radius_outer - 20
	
	var unit_count = 1
	for value in range(min_value, max_value+1, units):
		# Where the unit mark will be
		var t = float(value - min_value) / value_range
		var angle = lerp(START_ANGLE, END_ANGLE, t)
		var direction = Vector2(cos(angle), sin(angle))
		
		# Draw unit marks
		var outer_point = center + direction * radius_outer
		var inner_point = center + direction * radius_units
		var thickness = 2
		
		# Big marks
		if unit_count == big_per_unit or (big_per_unit != 0 and value == min_value):
			inner_point = center + direction * radius_big_units
			thickness = 4
			unit_count = 1
			
			# Numbers
			var text_pos = center + (direction - Vector2(0.1, -0.05)) * (radius_big_units - 20)
			draw_string(get_theme_font("Open Sans SemiBold"), text_pos, str(value))
			
		# Small marks
		else:
			unit_count += 1
		
		draw_line(inner_point, outer_point, Color.WHITE, thickness)
