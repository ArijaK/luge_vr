extends StaticBody3D

func lerp_list(from: float, to: float, elements: int) -> PackedFloat32Array:
	var result = PackedFloat32Array()
	for i in range(elements):
		result.push_back( lerp(from, to, (float(i)/elements)) )
	return result

func get_radius(at: float):
	pass

func get_slope(at: float):
	pass

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
	var data = FileUtils.parse_json(cfg.get_value("track", "segments_path"))
	
	
	var start_pos = cfg.get_value("track", "start_pos")
	var track_shape = get_track_shape(data["track_shape"])
	
	centerline.create_centerline(
		Vector3(start_pos[0], start_pos[1], start_pos[2]), 
		data["length"]
	)

	if centerline.curve.point_count > 0:
		mesh_instance.create_mesh(centerline.curve, track_shape)
		collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.815, 0.906, 0.973, 1.0)
		material.roughness = 0.05
		material.metallic = 0.0
		
		mesh_instance.set_surface_override_material(0, material)
