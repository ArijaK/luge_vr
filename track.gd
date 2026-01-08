# TODO: Refactor
class_name TrackGenerator extends Node3D

@export var segment_mesh: Mesh
@export var segment_length = 0.5

# TODO: Further must be received from a configuration file
# Segments of the track - each new segment has different properties than the previous one
var segments = [
	# Direction (1-left, -1-right) - length (meters) - slope (percent) - radius (meters)
	[1, 33, 8.5, 17],
	[-1, 42, 13.7, 15]
]

const point_step = 1 # New point in track after every meter

# Create the track line
func generate_centerline(curve: Curve3D) -> void:
	var pos = Vector3.ZERO
	var forward = Vector3.FORWARD
	
	for s in segments:
		var slope_rad = atan(float(s[2]) / 100.0) # Convert slope % to radians
		var curve_rad = float(s[1]) / float(s[3]) # Angle of the curve
		var angle_step = point_step / float(s[3]) # New point in track after every angle x
		
		# NOTE: Must check edge-cases (end of the curve)
		for i in range(0, int(curve_rad/angle_step)):
			# Rotate point to the new pose
			var rot = Transform3D().rotated(Vector3.UP, angle_step * s[0])
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
	var curve = Curve3D.new()
	generate_centerline(curve)
	create_mesh(curve)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
