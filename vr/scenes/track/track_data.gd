# TODO: Check, if there is any way how to make something private
class_name TrackData extends Node

var length = 0.0
var start_at = 0.0
var slope_segments = Array()
var curve_segments = Array()
var track_shape = PackedVector3Array()

var current_slope_idx = 0

var curvature = Curve.new()
var height = Curve.new()

func create_height(heights: Array):
	height.bake_resolution = 1000
	height.min_domain = start_at 
	height.max_domain = start_at + length
	height.max_value = 5.0
	
	height.add_point(Vector2(start_at, 0.0))
	
	for h in heights:
		height.add_point(Vector2(h.Sx_entrance, h.height))
	
	height.add_point(Vector2(start_at + length, 0.0))
	height.bake()

func create_curvature():
	curvature.bake_resolution = 1000
	curvature.min_domain = start_at 
	curvature.max_domain = start_at + length
	curvature.min_value = -10.0
	curvature.max_value = 10.0
	
	curvature.add_point(Vector2(start_at, 0.0))
	
	for c in curve_segments:
		curvature.add_point(Vector2(c.Sx_entrance, 0.0))
		curvature.add_point(Vector2(
			c.Sx_entrance + c.length * 0.23, 
			(1/c.radius) * c.turn
		))
		curvature.add_point(Vector2(
			c.Sx_entrance + c.length * 0.5, 
			(1/c.radius) * c.turn
		))
		curvature.add_point(Vector2(
			c.Sx_entrance + c.length * 0.80, 
			(1/c.radius) * c.turn
		))
		curvature.add_point(Vector2(c.Sx_entrance + c.length, 0.0))
	
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
	create_height(data["segments"]["heights"])

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
