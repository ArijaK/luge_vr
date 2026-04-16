extends RigidBody3D

var MAX_TORQUE = 2

var current_time = 0
var values = []
var stamps = PackedFloat32Array()
var v_max = 0
var v_min = 0

func find_input(time):
	for i in range(stamps.size() - 1):
		var a = stamps[i]
		var b = stamps[i + 1]

		if time >= a and time <= b:
			var t = (time - a) / (b - a)
			return lerp(values[i], values[i+1], t)

	return values[-1]


func parse_txt(file):
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			break
		var parts = line.split(",")
		var value = int(parts[0].split("=")[1].strip_edges())
		var time = int(parts[1].split("=")[1].strip_edges())
		
		values.append(value)
		stamps.append(time/ 1000000.0)
		
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
	
	current_time = Time.get_ticks_msec() / 1000.0

	linear_velocity.z = -20.0
	
func _physics_process(_delta: float) -> void:
	var game_time = (Time.get_ticks_msec() / 1000.0) - current_time

	var v = find_input(game_time)
	var v_norm = (v - v_min) / float(v_max - v_min)
	var v_fin = (v_norm * 2.0) - 1.0
	
	var final_input = v_fin * MAX_TORQUE
	center_of_mass = Vector3(0.3, 0, 0)
	apply_torque(Vector3(0, final_input, 0))

	
 # TODO: This is ONLY A DRAFT FOR INITIAL ASSESSMENT, MUST BE CHANGED!
#func _process(delta: float) -> void:
	#print((linear_velocity.z*3600)/1000)
