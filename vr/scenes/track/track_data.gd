class_name TrackData extends Node

var length = 0.0
var start_at = 0.0
# NOTE: Currently hardcoded
var curve_transition_percent = 0.23
var track_shape = PackedVector3Array()
var slope_segments = Array()
var curve_segments = Array()

var current_slope_idx = 0
var current_curve_idx = 0

# TODO: Probably needs some sort of renaming
func find_curvature(at_relative: float, max_curvature: float, transition_relative: float) -> float:
	if at_relative <= transition_relative:
		return max_curvature * (at_relative / transition_relative)
	elif at_relative >= 1.0 - transition_relative:
		return max_curvature * ((1.0 - at_relative) / transition_relative)
	else:
		return max_curvature

func get_curvature(at: float) -> Array:
	while current_curve_idx < curve_segments.size():
		var segment = curve_segments[current_curve_idx]
		
		if at >= segment.Sx_entrance:
			if at < (segment.Sx_entrance + segment.length):
				if is_zero_approx(segment.radius):
					return [0.0, 0]
				else:
					var at_relative = (at - segment.Sx_entrance) / segment.length
					var max_curvature = 1 / segment.radius
					return [find_curvature(at_relative, max_curvature, curve_transition_percent), segment.turn]
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
