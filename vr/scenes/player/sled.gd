extends RigidBody3D

@export var max_steer_force = 2

### FILE READING FUNCS
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

# NOTE: To imitate initial pushing
func apply_pushing():	
	if Input.is_action_just_pressed("ui_accept"):
		linear_velocity.z += -5.0

func apply_steering():
	# NOTE: Currently happen to be inverse (you use left to steer right and vice versa), but I guess this is how it is supposed to be?
	var steer_input = Input.get_axis("steer_left", "steer_right")
	var steer_force = steer_input * max_steer_force
	
	# Linear movement (sideways)
	var forward = linear_velocity.normalized()
	var side = Vector3.UP.cross(forward).normalized()
	apply_central_force(side * steer_force)
	
	# Rotational movement
	apply_torque(Vector3.UP * steer_force)

func _physics_process(_delta: float) -> void:
	apply_steering()
	apply_pushing()
	
	## FILE INPUT CASE - v_fin multiply with max_force
	#var game_time = (Time.get_ticks_msec() / 1000.0) - current_time
	#var v = find_input(game_time)
	#var v_norm = (v - v_min) / float(v_max - v_min)
	#var v_fin = (v_norm * 2.0) - 1.0
	
func _ready() -> void:
	pass
	
	## TODO: FILE INPUT, must make a flag to pick which one to use
	#var cfg = FileUtils.load_config("res://config.cfg")
	## NOTE: Currently expects already sorted data
	#var input_path = cfg.get_value("player", "input_path")
	#var input_file = FileAccess.open(input_path, FileAccess.READ)
	#
	#if input_file == null:
		#push_error("Cannot open file " + input_path)
		#return
	#
	#parse_txt(input_file)
	## TODO: Check if I need it.
	#input_file.close()
	#
	#current_time = Time.get_ticks_msec() / 1000.0

## NOTE: Quick way to check speeds
#func _process(delta: float) -> void:
	#print((linear_velocity.z*3600)/1000)
