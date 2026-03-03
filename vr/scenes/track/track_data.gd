# TODO: Check, if there is any way how to make something private
class_name TrackData extends Node

var resolution = 0.2 # NOTE: Hardcoded
var length = 0.0
var start_at = 0.0
var slope_segments = Array()
var curve_segments = Array()
var track_shape = PackedVector3Array()

var current_slope_idx = 0
var current_curve_idx = 0

var curvature = Curve.new()
var height = Curve.new()

func create_curvature():
	curvature.bake_resolution = 1000
	curvature.min_domain = start_at 
	curvature.max_domain = start_at + length
	curvature.min_value = -10.0
	curvature.max_value = 10.0
	
	curvature.add_point(Vector2(start_at, 0.0))
	
	for curve in curve_segments:
		curvature.add_point(Vector2(curve.Sx_entrance, 0.0))
		curvature.add_point(Vector2(
			curve.Sx_entrance + curve.length * 0.20, 
			(1/curve.radius) * curve.turn
		))
		curvature.add_point(Vector2(
			curve.Sx_entrance + curve.length * 0.5, 
			(1/curve.radius) * curve.turn
		))
		curvature.add_point(Vector2(
			curve.Sx_entrance + curve.length * 0.80, 
			(1/curve.radius) * curve.turn
		))
		curvature.add_point(Vector2(curve.Sx_entrance + curve.length, 0.0))
	
	curvature.add_point(Vector2(start_at + length, 0.0))
	curvature.bake()

func get_track_shape(points: Array) -> PackedVector3Array:
	var result = PackedVector3Array()
	for p in points:
		result.append(Vector3(p[0], p[1], p[2]))	
	return result

func fill(data: Dictionary):
	length = data["length"]
	start_at = -min(data["segments"]["slopes"][0].Sx_entrance, data["segments"]["curves"][0].Sx_entrance)
	track_shape = get_track_shape(data["track_shape"])
	slope_segments = data["segments"]["slopes"]
	curve_segments = data["segments"]["curves"]
	
	create_curvature()

func get_curvature(at: float) -> float:
	return curvature.sample(at)
	
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
