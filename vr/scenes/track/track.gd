extends Node3D

@onready var centerline = $Centerline
@onready var mesh_instance = $StaticBody3D/MeshInstance3D
@onready var collision_shape = $StaticBody3D/CollisionShape3D
@onready var track_data = $TrackData
@onready var surroundings = $Surroundings
@onready var path = $Centerline/PathFollow3D

func _ready() -> void:
	var cfg = FileUtils.load_config("res://config.cfg")
	# NOTE: Currently expects already sorted data
	var data = FileUtils.parse_json(cfg.get_value("track", "segments_path"))
	
	track_data.fill(data)
	
	centerline.create_centerline(track_data)
	
	if centerline.curve.point_count > 0:
		mesh_instance.create_mesh(centerline.curve, track_data)
		collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.815, 0.906, 0.973, 1.0)
		material.roughness = 1.0
		material.metallic = 0.0
		
		mesh_instance.set_surface_override_material(0, material)
		surroundings.multimesh.instance_count = centerline.curve.point_count
		
		for i in range(surroundings.multimesh.instance_count):
				path.progress_ratio = float(i) / surroundings.multimesh.instance_count
				surroundings.multimesh.set_instance_transform(i, path.global_transform)
