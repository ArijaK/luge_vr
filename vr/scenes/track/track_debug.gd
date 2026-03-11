class_name TrackDebug extends Node

static func draw_data_curve(curve: Curve, centerline: Curve3D, parent: Node3D):
	var immesh = ImmediateMesh.new()

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	
	var length = min(centerline.get_baked_length(), curve.max_domain)
	var steps = floori(length / centerline.bake_interval)
	var value_range = curve.max_value - curve.min_value
	
	immesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)

	for i in range(steps):
		var at = i * centerline.bake_interval
		var position = centerline.sample_baked(at)
		# NOTE: THIS was the fix, but must make into reusable code
		var value = curve.sample(at - 22)
	
		position.y = value
		
		var n = (value - curve.min_value) / value_range
		var c = Color(n, n, n)
	
		immesh.surface_set_color(c)
		immesh.surface_add_vertex(position)

	immesh.surface_end()

	var mesh = MeshInstance3D.new()
	mesh.mesh = immesh
	parent.add_child(mesh)
