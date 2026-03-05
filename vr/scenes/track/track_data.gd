# TODO: Check, if there is any way how to make something private
class_name TrackData extends Node

@export var cross_section_points = 33

var length = 0.0
var width = 0.0
var default_height = 0.0
var start_at = 0.0

var slope_segments = Array()
var curve_segments = Array()

var current_slope_idx = 0

var curvature = Curve.new()
var height = Curve.new()

func create_height(heights: Array):
	height.bake_resolution = 1000
	height.min_domain = start_at 
	height.max_domain = start_at + length
	height.max_value = 5.0
	height.min_value = default_height
	
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

func fill(data: Dictionary):
	length = data["length"]
	width = data["width"]
	default_height = data["default_height"]
	start_at = -min(data["segments"]["slopes"][0].Sx_entrance, data["segments"]["curves"][0].Sx_entrance)
	
	slope_segments = data["segments"]["slopes"]
	curve_segments = data["segments"]["curves"]
	
	create_curvature()
	create_height(data["segments"]["heights"])

func get_height(at: float) -> float:
	return height.sample(at)
	
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

func get_shape_points(at: float, T: Transform3D) -> PackedVector3Array:
	var points = PackedVector3Array()
	points.resize(cross_section_points)
	
	var half_width = width * 0.5
	# Middle of the shape - centerline point
	var middlepoint = floori(cross_section_points * 0.5)
	points[middlepoint] = Vector3.ZERO
	
	var h = height.sample(at)
	var c = curvature.sample(at)
	
	var heights = MathUtils.lerp_list(h, 0.0, middlepoint)
	var default_heights = MathUtils.lerp_list(default_height, 0.0, middlepoint)
	
	# If it is a straight trajectory
	if is_equal_approx(h, default_height):
		for i in range(middlepoint):
			points[i] = Vector3(-half_width, default_heights[i], 0.0)
			points[cross_section_points-1-i] = Vector3(half_width, default_heights[i], 0.0)
	else:
		var curve_side = sign(c)
		# How curvy the wall should be
		var max_x = width + 0.5 * h + 0.1 * abs(c)
		var widths = MathUtils.lerp_list(max_x, half_width, middlepoint)
		
		if curve_side < 0:
			for i in range(middlepoint):
				points[i] = Vector3(-widths[i], heights[i], 0.0)
				points[cross_section_points-1-i] = Vector3(half_width, default_heights[i], 0.0)
		else:
			for i in range(middlepoint):
				points[i] = Vector3(-half_width, default_heights[i], 0.0)
				points[cross_section_points-1-i] = Vector3(widths[i], heights[i], 0.0)
	
	for i in range(cross_section_points):
		points[i] = T * points[i]
	
	return points
