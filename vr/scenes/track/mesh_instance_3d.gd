extends MeshInstance3D

func get_T(p1: Vector3, p2: Vector3, current_up: Vector3) -> Transform3D:
	var forward = (p2 - p1).normalized()
	var up = (current_up - forward * current_up.dot(forward)).normalized()
	var right = forward.cross(Vector3.UP).normalized()
	return Transform3D( Basis(right, up, forward), p1)

func get_shape_points(shape: PackedVector3Array, T: Transform3D) -> PackedVector3Array:
	var result = PackedVector3Array()
	for p in shape:
		result.append(T * p)
	return result

func create_mesh(curve: Curve3D, shape: Array):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
	var line_points = curve.get_baked_points()
	var sections = []
	
	var up = Vector3.UP
	for i in range(line_points.size() - 1):
		var p = line_points[i]
		var p_next = line_points[i + 1]
		var T = get_T(p, p_next, up)
		
		sections.append(get_shape_points(shape, T))
		up = T.basis.y

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
	mesh = st.commit()
