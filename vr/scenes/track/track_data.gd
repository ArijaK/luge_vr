class_name TrackData extends Node

var length = 0.0
var start_at = 0.0
var track_shape = PackedVector3Array()
var slope_segments = Array()
var curve_segments = Array()

var current_slope_idx = 0
var current_curve_idx = 0


func get_radius(at: float):
	while current_curve_idx < curve_segments.size():
		var segment = curve_segments[current_curve_idx]
		
		if at >= segment.Sx_entrance:
			if at < (segment.Sx_entrance + segment.length):
				if is_zero_approx(segment.radius):
					return [0.0, 0]
				else:
					return [1/segment.radius, segment.turn]
			else:
				current_curve_idx += 1
		else:
			return [0.0, 0]
	return [0.0, 0]

func get_slope(at: float) -> float:
	while current_slope_idx < slope_segments.size():
		var segment = slope_segments[current_slope_idx]
		
		if at >= segment.Sx_entrance:
			if at < (segment.Sx_entrance + segment.length):
				return segment.slope
			else:
				current_slope_idx += 1
		else:
			return 0.0
	return 0.0
