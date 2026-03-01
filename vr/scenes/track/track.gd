extends StaticBody3D

func get_track_shape(points: Array) -> PackedVector3Array:
	var result = PackedVector3Array()
	for p in points:
		result.append(Vector3(p[0], p[1], p[2]))	
	return result

@onready var centerline = $Centerline
@onready var mesh_instance = $MeshInstance3D
@onready var collision_shape = $CollisionShape3D

func _ready() -> void:
	var cfg = FileUtils.load_config("res://config.cfg")
	# NOTE: Currently expects already sorted data
	var data = FileUtils.parse_json(cfg.get_value("track", "segments_path"))
	
	var track_data = TrackData.new()
	track_data.length = data["length"]
	track_data.start_at = -min(data["segments"]["slopes"][0].Sx_entrance, data["segments"]["curves"][0].Sx_entrance)
	track_data.track_shape = get_track_shape(data["track_shape"])
	track_data.slope_segments = data["segments"]["slopes"]
	track_data.curve_segments = data["segments"]["curves"]
	
	centerline.create_centerline(track_data)
	
	if centerline.curve.point_count > 0:
		mesh_instance.create_mesh(centerline.curve, track_data.track_shape)
		collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.815, 0.906, 0.973, 1.0)
		material.roughness = 0.05
		material.metallic = 0.0
		
		mesh_instance.set_surface_override_material(0, material)
