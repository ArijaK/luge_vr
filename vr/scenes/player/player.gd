extends RigidBody3D

var MAX_TORQUE = 2

var current_idx = 0
var current_time = 0
var values = []
var stamps = PackedFloat32Array()
var v_max = 0
var v_min = 0

func parse_txt(file):
	var start_time = null
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			break
		var parts = line.split(",")
		var value = int(parts[0].split("=")[1].strip_edges())
		var time = int(parts[1].split("=")[1].strip_edges())
		
		if start_time == null:
			start_time = time
		
		values.append(value)
		stamps.append(time - start_time)
		
		v_max = values.max()
		v_min = values.min()

func _ready() -> void:
	var cfg = FileUtils.load_config("res://config.cfg")
	# NOTE: Currently expects already sorted data
	var input_path = cfg.get_value("player", "input_path")
	var input_file = FileAccess.open(input_path, FileAccess.READ)
	
	if input_file == null:
		push_error("Cannot open file " + input_path)
		return
	
	parse_txt(input_file)
	# TODO: Check if I need it.
	input_file.close()

	linear_velocity.z = -20.0
	
func _physics_process(delta: float) -> void:
	current_time += delta * 1000000
	var v = values[current_idx]
	var v_norm = (v - v_min) / float(v_max - v_min)
	var v_fin = (v_norm * 2.0) - 1.0
	
	var final_input = v_fin * MAX_TORQUE
	center_of_mass = Vector3(0.3, 0, 0)
	apply_torque(Vector3(0, final_input, 0))
	
	if current_idx < len(values)-1:
		current_idx += 1

	
# TODO: This is ONLY A DRAFT FOR INITIAL ASSESSMENT, MUST BE CHANGED!
#func _process(delta: float) -> void:
	#print((linear_velocity.z*3600)/1000)
