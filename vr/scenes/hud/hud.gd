extends CanvasLayer

## TODO: Make these configurable vars, so they do not duplicate
const START_ANGLE = deg_to_rad(-220)
const END_ANGLE = deg_to_rad(40)

@onready var speed = $Speed
@onready var speed_num = $Speed/Speed
@onready var speed_mark = $Speed/Mark
func _on_speed_signal(value):
	speed_num.text = str(value)
	
	var value_range = speed.max_value - speed.min_value
	var t = float(value - speed.min_value) / value_range
	### NOTE: THIS WILL NOT WORK NOW
	speed_mark.rotation = lerp(START_ANGLE, END_ANGLE, t)


@onready var roatation = $Rotation
@onready var rotation_mark = $Rotation/Mark
@onready var rotation_num = $Rotation/Angle
func _on_rotation_signal(value):
	rotation_num.text = str(roundf(value))
	
	var value_range = roatation.max_value - roatation.min_value
	var t = float(value - roatation.min_value) / value_range
	### NOTE: THIS WILL NOT WORK NOW
	rotation_mark.rotation = lerp(START_ANGLE, END_ANGLE, t)


@onready var distance_num = $Speed/Distance/Distance
func _on_distance_signal(dist):
	distance_num.text = str(dist)


@onready var steer_right = $Steering/RightBar
@onready var steer_left = $Steering/LeftBar
func _on_steering_signal(value):
	steer_left.value = 0.0
	steer_right.value = 0.0
	
	if value < 0.0:
		steer_right.value = abs(value)
	else:
		steer_left.value = abs(value)
