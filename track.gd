# TODO: Refactor
class_name TrackGenerator extends Node3D

@export var segment_mesh: Mesh
@export var segment_length = 0.5
@export var point_step = 1 # New point in track after every meter

# NOTE: Maybe replace [] returning with termination
# Parse JSON file to get segments
func parse_json(path: String) -> Array:
	# Open file
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open file " + path)
		return []
	
	# Parse file
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		var data = json.data
		if typeof(data) == TYPE_DICTIONARY:
			return data["segments"]
		else:
			push_error("Unexpected data format")
			return []
	else:
		push_error("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
		return []


# Create the track line
func generate_centerline(curve: Curve3D, segments: Array) -> void:
	var pos = Vector3.ZERO
	var forward = Vector3.FORWARD
	
	for s in segments:
		var slope_rad = atan(float(s.slope) / 100.0) # Convert slope % to radians
		var curve_rad = float(s.length) / float(s.radius) # Angle of the curve
		var angle_step = point_step / float(s.radius) # New point in track after every angle x
		
		# NOTE: Must check edge-cases (end of the curve)
		for i in range(0, int(curve_rad/angle_step)):
			# Rotate point to the new pose
			var rot = Transform3D().rotated(Vector3.UP, angle_step * s.direction)
			forward = rot.basis * forward
			# Translate point to the new pose
			var translation = forward * point_step
			# Apply slope
			translation.y -= tan(slope_rad) * point_step
			# Update position of new point
			pos += translation
			curve.add_point(pos)


# Create the track's body		
func create_mesh(curve: Curve3D) -> void:
	var path = Path3D.new()
	path.curve = curve
	add_child(path)
	
	# The body
	# TODO: Simple version, shall replace later with better option
	var path_follow = PathFollow3D.new()
	path.add_child(path_follow)
	
	var distance = 0.0
	
	while distance < curve.get_baked_length():
		path_follow.progress = distance
		
		var mesh = MeshInstance3D.new()
		mesh.mesh = segment_mesh
		mesh.transform = path_follow.global_transform
		path.add_child(mesh)
		
		distance += segment_length


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var segments = parse_json("res://test.json")
	var curve = Curve3D.new()
	generate_centerline(curve, segments)
	create_mesh(curve)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
