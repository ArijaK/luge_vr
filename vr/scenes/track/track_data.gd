# TODO: Check, if there is any way how to make something private
class_name TrackData extends Node

@export var cross_section_points = 33
@export var k_curvature = 1.5

var length = 0.0
var width = 0.0
var default_height = 0.0
var start_at = 0.0

var slope_segments = Array()
var curve_segments = Array()

var current_slope_idx = 0

var curvature = Curve.new()
var height = Curve.new()

func normalize(at: float) -> float:
	return (at - start_at) / length

func create_height(heights: Array):
	var h_values = heights.map(func(x): return x["height"])
	
	height.bake_resolution = 1000
	height.max_value = h_values.max()
	height.min_value = h_values.min()
	
	height.add_point(Vector2(0.0, 0.0))
	for h in heights:
		height.add_point(Vector2(
			normalize(h.Sx_entrance), h.height
		))
	height.add_point(Vector2(1.0, 0.0))
	
	height.bake()

func create_curvature():
	curvature.bake_resolution = 1000
	curvature.min_value = -1.0
	curvature.max_value = 1.0
	
	curvature.add_point(Vector2(0.0, 0.0))
	
	for c in curve_segments:
		curvature.add_point(Vector2(
			normalize(c.Sx_entrance), 0.0
		))
		curvature.add_point(Vector2(
			normalize(c.Sx_entrance + c.length * 0.23), 
			(1/c.radius) * c.turn
		))
		curvature.add_point(Vector2(
			normalize(c.Sx_entrance + c.length * 0.5), 
			(1/c.radius) * c.turn
		))
		curvature.add_point(Vector2(
			normalize(c.Sx_entrance + c.length * 0.80), 
			(1/c.radius) * c.turn
		))
		curvature.add_point(Vector2(
			normalize(c.Sx_entrance + c.length), 0.0
		))
	
	curvature.add_point(Vector2(1.0, 0.0))
	curvature.bake()

func fill(data: Dictionary):
	start_at = min(
		data["segments"]["slopes"][0].
		Sx_entrance, data["segments"]["curves"][0].Sx_entrance,
		0
	)
	length = data["length"] - start_at
	width = data["width"]
	default_height = data["default_height"]
	
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
	
	var default_heights = MathUtils.lerp_list(default_height, 0.0, middlepoint)
	
	# If it is a straight trajectory
	if is_equal_approx(h, default_height):
		for i in range(middlepoint):
			points[i] = Vector3(-half_width, default_heights[i], 0.0)
			points[cross_section_points-1-i] = Vector3(half_width, default_heights[i], 0.0)
	else:
		var curve_side = sign(c)
		# How curvy the wall should be
		var max_width = width + k_curvature * abs(c)
		
		var p0 = Vector2(half_width, 0.0)
		var p1 = Vector2(max_width, default_height)
		var p2 = Vector2(half_width, h)

		var curve_side_points = []

		for i in range(middlepoint):
			var t = i / float(middlepoint - 1)
			curve_side_points.append(MathUtils.quadratic_bezier(p0, p1, p2, t, curve_side))

		if curve_side < 0:
			for i in range(middlepoint):
				points[i] = curve_side_points[i]
				points[cross_section_points-1-i] = Vector3(half_width, default_heights[i], 0.0)
		else:
			for i in range(middlepoint):
				points[i] = Vector3(-half_width, default_heights[i], 0.0)
				points[cross_section_points-1-i] = curve_side_points[i]
	
	for i in range(cross_section_points):
		points[i] = T * points[i]
	
	return points
