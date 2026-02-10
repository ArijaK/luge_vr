class_name TrackGenerator extends StaticBody3D


func load_config(path: String) -> ConfigFile:
	var cfg = ConfigFile.new()
	var result = cfg.load(path)
	if result == OK:
		return cfg
	else:
		push_error("Cannot open file " + path)
		return


func parse_json(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open file " + path)
		return
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		var data = json.data
		if typeof(data) == TYPE_DICTIONARY:
			return data
		else:
			push_error("Unexpected data format")
			return
	else:
		push_error("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
		return


func create_centerline(start: Vector3, segments: Array) -> Curve3D:
	var result = Curve3D.new()
	var direction = Vector3.FORWARD
	
	result.add_point(start)
	
	for s in segments:
		if is_zero_approx(s.radius):
			start += direction * s.length
			start.y += s.length * (s.slope / 100.0)
			
			result.add_point(start)
		else:
			# Angle of the curve
			var angle_rad = s.length / s.radius
			var slope_rad = atan(s.slope / 100.0)
			var angle_step = result.bake_interval / s.radius
			
			for i in range(0, int(angle_rad/angle_step)):
				direction = direction.rotated(Vector3.UP, angle_step * s.turn)
				
				start += direction * result.bake_interval
				start.y -= tan(slope_rad) * result.bake_interval
				result.add_point(start)
	
	return result


func get_track_shape(points: Array) -> PackedVector3Array:
	var result = PackedVector3Array()
	for p in points:
		result.append(Vector3(p[0], p[1], p[2]))	
	return result


func get_T(p1: Vector3, p2: Vector3) -> Transform3D:
	var forward = (p2 - p1).normalized()
	var right = forward.cross(Vector3.UP).normalized()
	return Transform3D( Basis(right, Vector3.UP, forward), p1)


func get_shape_points(shape: PackedVector3Array, T: Transform3D) -> PackedVector3Array:
	var result = PackedVector3Array()
	for p in shape:
		result.append(T * p)
	return result


func create_mesh(curve: Curve3D, shape: Array) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
	var line_points = curve.get_baked_points()
	var sections = []

	for i in range(line_points.size() - 1):
		var p = line_points[i]
		var p_next = line_points[i + 1]
		var T = get_T(p, p_next)
		sections.append(get_shape_points(shape, T))

	for i in range(sections.size() - 1):
		var s = sections[i]
		var s_next = sections[i + 1]
		
		var v1 = float(i) / (sections.size() - 1)
		var v2 = float(i + 1) / (sections.size() - 1)
		
		for j in range(s.size() - 1):
			var u1 = float(j) / (s.size() - 1)
			var u2 = float(j + 1) / (s.size() - 1)
			
			st.set_uv(Vector2(u1, v1))
			st.set_uv(Vector2(u1, v2))
			st.set_uv(Vector2(u2, v1))
			
			st.add_vertex(s[j])
			st.add_vertex(s_next[j])
			st.add_vertex(s[j + 1])
			
			st.set_uv(Vector2(u2, v1))
			st.set_uv(Vector2(u1, v2))
			st.set_uv(Vector2(u2, v2))
			
			st.add_vertex(s[j + 1])
			st.add_vertex(s_next[j])
			st.add_vertex(s_next[j + 1])
			

	st.index()
	st.generate_normals()
	st.generate_tangents()
	return st.commit()
	#var surface_array = []
	#surface_array.resize(Mesh.ARRAY_MAX)
	#
	#var vertices = PackedVector3Array()
	#var uvs = PackedVector2Array()
	#var normals = PackedVector3Array()
	#var indices = PackedInt32Array()
#
	#var line_points = curve.get_baked_points()
	#var sections = []
#
	#for i in range(line_points.size() - 1):
		#var p = line_points[i]
		#var p_next = line_points[i + 1]
		#var T = get_T(p, p_next)
		#sections.append(get_shape_points(shape, T))
#
	#for i in range(sections.size() - 1):
		#var s = sections[i]
		#var s_next = sections[i + 1]
#
		#var v1 = float(i) / (sections.size() - 1)
		#var v2 = float(i + 1) / (sections.size() - 1)
#
		#for j in range(s.size() - 1):
			#var u1 = float(j) / (s.size() - 1)
			#var u2 = float(j + 1) / (s.size() - 1)
			#
			#var base = vertices.size()
#
			#vertices.append(s[j])
			#vertices.append(s_next[j])
			#vertices.append(s[j + 1])
			#
			#normals.append(s[j].normalized())
			#normals.append(s_next[j].normalized())
			#normals.append(s[j + 1].normalized())
			#
			#uvs.append(Vector2(u1, v1))
			#uvs.append(Vector2(u1, v2))
			#uvs.append(Vector2(u2, v1))
#
			#vertices.append(s[j + 1])
			#vertices.append(s_next[j])
			#vertices.append(s_next[j + 1])
			#
			#normals.append(s[j].normalized())
			#normals.append(s_next[j].normalized())
			#normals.append(s[j + 1].normalized())
			#
			#uvs.append(Vector2(u2, v1))
			#uvs.append(Vector2(u1, v2))
			#uvs.append(Vector2(u2, v2))
			#
			#indices.append_array(range(base, base+6))
#
	##var n = Vector3.ZERO
	##for i in range(0, vertices.size(), 3):
		##var a = vertices[i]
		##var b = vertices[i + 1]
		##var c = vertices[i + 2]
		##
		##n = (b - a).cross(c - a).normalized()
		##normals.append_array([
			##n.normalized(), 
			##(n+n).normalized(), 
			##(n+n+n).normalized()
		##])
#
	#surface_array[Mesh.ARRAY_VERTEX] = vertices
	#surface_array[Mesh.ARRAY_TEX_UV] = uvs
	#surface_array[Mesh.ARRAY_NORMAL] = normals
	#surface_array[Mesh.ARRAY_INDEX] = indices
#
	#var mesh = ArrayMesh.new()
	#mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	#return mesh


@onready var trajectory = $Path3D
@onready var mesh_instance = $MeshInstance3D
@onready var collision_shape = $CollisionShape3D


func _ready() -> void:
	var cfg = load_config("res://config.cfg")
	var data = parse_json(cfg.get_value("track", "segments_path"))
	var start_pos = cfg.get_value("track", "start_pos")
	var track_shape = get_track_shape(data["track_shape"])
	
	trajectory.curve = create_centerline(
		Vector3(start_pos[0], start_pos[1], start_pos[2]), 
		data["segments"]
	)
	
	if trajectory.curve.point_count > 0:
		mesh_instance.mesh = create_mesh(trajectory.curve, track_shape)
		collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.589, 0.004, 0.92, 1.0)
		material.roughness = 0.05
		material.metallic = 0.0
		
		mesh_instance.set_surface_override_material(0, material)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
