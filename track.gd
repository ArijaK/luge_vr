class_name TrackGenerator extends Node3D

@export var mesh_steps = 200  # How many segments to make
@export var point_step = 1    # New point in track after every meter


func load_config(path: String) -> ConfigFile:
	var cfg = ConfigFile.new()
	var result = cfg.load(path)
	if result == OK:
		return cfg
	else:
		push_error("Cannot open file " + path)
		return


func parse_json(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open file " + path)
		return []
	
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


func generate_centerline(start: Vector3, segments: Array) -> Curve3D:
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
			var angle_step = point_step / s.radius
			
			for i in range(0, int(angle_rad/angle_step)):
				direction = direction.rotated(Vector3.UP, angle_step * s.turn)
				
				start += direction * point_step
				start.y -= tan(slope_rad) * point_step
				result.add_point(start)
	
	return result


func create_mesh(curve: Curve3D) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# NOTE: Currently HARD coded, later may be added to config file
	var length := curve.get_baked_length()
	var steps := 200

	# NOTE: Not the expected end result
	var width := 2.0
	var height := 0.2
	var half_w := width * 0.5
	var half_h := height * 0.5

	var prev = null

	for i in steps + 1:
		var t := float(i) / steps
		var d := t * length

		var pos = curve.sample_baked(d)

		# Tangent
		var ahead = curve.sample_baked(d + 0.1)
		var tangent = (ahead - pos).normalized()

		# Up vector from curve
		var up = curve.sample_baked_up_vector(d)

		# Right + corrected normal
		var right = tangent.cross(up).normalized()
		var normal = right.cross(tangent).normalized()

		# Rectangle corners
		var lt = pos - right * half_w + normal * half_h
		var rt = pos + right * half_w + normal * half_h
		var lb = pos - right * half_w - normal * half_h
		var rb = pos + right * half_w - normal * half_h

		if prev != null:
			var p_lt = prev.lt
			var p_rt = prev.rt
			var p_lb = prev.lb
			var p_rb = prev.rb

			# Top
			st.add_vertex(p_lt)
			st.add_vertex(p_rt)
			st.add_vertex(rt)

			st.add_vertex(p_lt)
			st.add_vertex(rt)
			st.add_vertex(lt)

			# Bottom
			st.add_vertex(p_lb)
			st.add_vertex(rb)
			st.add_vertex(p_rb)

			st.add_vertex(p_lb)
			st.add_vertex(lb)
			st.add_vertex(rb)

			# Left side
			st.add_vertex(p_lb)
			st.add_vertex(p_lt)
			st.add_vertex(lt)

			st.add_vertex(p_lb)
			st.add_vertex(lt)
			st.add_vertex(lb)

			# Right side
			st.add_vertex(p_rb)
			st.add_vertex(rt)
			st.add_vertex(p_rt)

			st.add_vertex(p_rb)
			st.add_vertex(rb)
			st.add_vertex(rt)

		prev = {
			"lt": lt,
			"rt": rt,
			"lb": lb,
			"rb": rb
		}

	st.generate_normals()
	var new_mesh = st.commit()
	mesh.mesh = new_mesh


@onready var trajectory = $Path3D
@onready var mesh = $MeshInstance3D


func _ready() -> void:
	var cfg = load_config("res://config.cfg")
	var segments = parse_json(cfg.get_value("track", "segments_path"))
	var start_pos = cfg.get_value("track", "start_pos")
	
	trajectory.curve = generate_centerline(Vector3(start_pos[0], start_pos[1], start_pos[2]), segments)
	
	if trajectory.curve.point_count > 0:
		create_mesh(trajectory.curve)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
