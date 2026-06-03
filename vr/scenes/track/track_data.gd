class_name TrackData extends Node
## A data structure for storing track generation parameters.
##
## A data structure that stores and processes track generation parameters. 
## Expects parameters to be passed as a [Dictionary] containing following key-value pairs:
## [br][br]
##  • [b]length[/b] — track length starting from the start line.[br]
##  • [b]width[/b] — track width.[br]
##  • [b]default_height[/b] — base height of side walls.[br]
##  • [b]segments[/b]:[br]
##  ----• [b]slopes[/b]:[br]
##  --------• [b]Sx_entrance[/b] — distance from the start line.[br]
##  --------• [b]length[/b] — slope segment length.[br]
##  --------• [b]slope[/b] — slope percentage.[br]
##  ----• [b]curves[/b]:[br]
##  --------• [b]Sx_entrance[/b] — distance from the start line.[br]
##  --------• [b]length[/b] — curve segment length.[br]
##  --------• [b]radius[/b] — minimum curvature radius.[br]
##  --------• [b]turn[/b] — 1 for left, -1 for right.[br]
##  ---• [b]heights[/b]:[br]
##  --------• [b]Sx_entrance[/b] — position of the height point (distance from the start line).[br]
##  --------• [b]height[/b] — height value.[br]
##

## Point count for the cross section of the track. 
## The more points, the smoother are the side walls of the track.
@export var cross_section_points: int = 32

## Total length of the construction. Includes length before the start line.
var length: float = 0.0
## Width of the track.
var width: float  = 0.0
## Base height of side walls in meters.
var default_height: float = 0.0
## Position of the starting point of the construction (distance from the start line).
## The construction may start before the start line.
var start_at: float = 0.0
## Slope along the track.
var slope: Curve = Curve.new()
## Curvature along the track.
var curvature: Curve = Curve.new()
# NOTE: Maybe implement a different approach for these 2 variables.
## Minimum curvature along the track.
var curvature_min: float = 0.0
## Maxiumum curvature along the track.
var curvature_max: float = 0.0
## Side wall height along the track.[br]
## [b]Note:[/b] Height only changes for the outer wall of the curved track segment.
var height: Curve = Curve.new()

## Normalizes position to value in range from 0 to 1.
## Necessary to get correct [member curvature], [member height] and [member slope] values.
func normalize(at: float) -> float:
	return (at - start_at) / length

# Fills height curve with provided height points.
func _create_height(heights: Array):
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

# Fills curvature curve with points created from provided curvature segments.
func _create_curvature(curves: Array):
	curvature.bake_resolution = 1000
	curvature.min_value = -1.0
	curvature.max_value = 1.0
	
	curvature.add_point(Vector2(0.0, 0.0))
	
	for c in curves:
		var value = (1/(c.radius) * c.turn)
		if curvature_max < value:
			curvature_max = value
		if curvature_min > value:
			curvature_min = value
	
	for c in curves:
		var value = (1/c.radius) * c.turn
		# Adds more than 1 point per segment to make curves steadier.
		curvature.add_point(Vector2(
			normalize(c.Sx_entrance), 
			0.0
		))
		curvature.add_point(Vector2(
			normalize(c.Sx_entrance + c.length * 0.23), 
			value
		))
		curvature.add_point(Vector2(
			normalize(c.Sx_entrance + c.length * 0.5), 
			value
		))
		curvature.add_point(Vector2(
			normalize(c.Sx_entrance + c.length * 0.80), 
			value
		))
		curvature.add_point(Vector2(
			normalize(c.Sx_entrance + c.length), 
			0.0
		))
	
	curvature.add_point(Vector2(1.0, 0.0))
	curvature.bake()

# Fills slope curve with points created from provided slope segments.
func _create_slope(slopes: Array):
	slope.bake_resolution = 1000
	slope.min_value = -1.0
	slope.max_value = 1.0
	
	slope.add_point(Vector2(0.0, 0.0))
	
	for s in slopes:
		slope.add_point(Vector2(
			normalize(s.Sx_entrance), 
			s.slope/100
		))
		slope.add_point(Vector2(
			normalize(s.Sx_entrance + s.length), 
			s.slope/100
		))
	
	slope.add_point(Vector2(1.0, 0.0))
	slope.bake()
	
## Fills data structure with track parameters.
func fill(data: Dictionary):
	start_at = min(
		data["segments"]["slopes"][0].Sx_entrance, 
		data["segments"]["curves"][0].Sx_entrance,
		0
	)
	length = data["length"] - start_at
	width = data["width"]
	default_height = data["default_height"]
	
	_create_slope(data["segments"]["slopes"])
	_create_curvature(data["segments"]["curves"])
	_create_height(data["segments"]["heights"])

## Get [member height] value at specific position on the track.
func get_height(at: float) -> float:
	return height.sample(at)

## Get [member curvature] value at specific position on the track.
func get_curvature(at: float) -> float:
	return curvature.sample(at)

## Get [member slope] value at specific position on the track.
func get_slope(at: float) -> float:
	return slope.sample(at)

## Get cross section points at specific position on the track.
func get_cross_section_points(at: float) -> PackedVector3Array:
	var points = PackedVector3Array()
	points.resize(cross_section_points)
	
	var half_width = width * 0.5
	# Middle of the shape - centerline point.
	var middlepoint = floori(cross_section_points * 0.5)
	
	var h = height.sample(at)
	var c = curvature.sample(at)
	var curve_side = sign(c)
	var default_heights = MathUtils.lerp_list(default_height, 0.0, middlepoint)
	
	# If it is a straight trajectory.
	if curve_side == 0:
		for i in range(middlepoint):
			points[i] = Vector3(-half_width, default_heights[i], 0.0)
			points[cross_section_points-1-i] = Vector3(half_width, default_heights[i], 0.0)
	else:
		# Influences how curvy the outer side wall should be.
		# TODO: Update this part
		var max_width = half_width - half_width * abs((c - curvature_min) / (curvature_max - curvature_min))
		
		var p0 = Vector2(max_width * curve_side, 0.0)
		var p1 = Vector2(half_width * curve_side, 0.0)
		var p2 = Vector2(half_width * curve_side, h)

		var curve_points = []
		for i in range(middlepoint):
			var t = i / float(middlepoint - 1)
			curve_points.append(MathUtils.quadratic_bezier(p0, p1, p2, t))
			
		if curve_side < 0:
			for i in range(middlepoint):
				points[i] = curve_points[middlepoint-1-i]
				points[cross_section_points-1-i] = Vector3(half_width, default_heights[i], 0.0)
		else:
			for i in range(middlepoint):
				points[i] = Vector3(-half_width, default_heights[i], 0.0)
				points[cross_section_points-1-i] = curve_points[middlepoint-1-i]
	
	return points
