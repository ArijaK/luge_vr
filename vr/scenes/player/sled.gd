extends RigidBody3D

# Speed notifications
signal speed_signal(speed: int)
# Angle notifications
signal angle_signal(angle: float)
# Distance notifications
signal distance_signal(distance: int)
# Steering notifications
signal steering_signal(strength: float)

@export var max_steer_force = 100
@export var preload_input = false
@export var params_path = "res://data/results.txt"
@export var trajectory_path = "res://data/results_traj.txt"

### FILE READING FUNCS
var current_time = 0
var values = []
var stamps = PackedFloat32Array()
var v_max = 0
var v_min = 0

## Data to save to a file
var params = []
var poses = []
## Func to save to a file
func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_WM_CLOSE_REQUEST:
		FileUtils.save_csv(params, params_path)
		FileUtils.save_txt_traj(poses, trajectory_path)

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
		linear_velocity.z += -10.0

func apply_steering() -> float:
	# NOTE: Currently happen to be inverse (you use left to steer right and vice versa), but I guess this is how it is supposed to be?
	# UP - pa labi - kreisais
	# DOWN - pa kreisi - labais
	#var steer_input = Input.get_axis("steer_right", "steer_left") + Input.get_axis("steer_left_second", "steer_right_second")
	var steer_input = Input.get_axis("steer_left", "steer_right") + Input.get_axis("steer_right_second", "steer_left_second")
	var steer_force = steer_input * max_steer_force

	# Linear movement (sideways)
	var forward = linear_velocity.normalized()
	var side = Vector3.UP.cross(forward).normalized()
	apply_central_force(side * steer_force)
	# Rotational movement
	apply_torque(Vector3.UP * steer_force * 0.15)
	
	return steer_input

var timestamp = 0
var distance = 0
func _physics_process(delta: float) -> void:
	var steer_input = 0.0
	if not preload_input:
		steer_input = apply_steering()
	else:
		## FILE INPUT CASE - v_fin multiply with max_force
		var game_time = (Time.get_ticks_msec() / 1000.0) - current_time
		var v = find_input(game_time)
		var v_norm = (v - v_min) / float(v_max - v_min)
		var v_fin = (v_norm * 2.0) - 1.0
		steer_input = v_fin * max_steer_force

	apply_pushing()
	
	distance += linear_velocity.length() * delta
	timestamp += delta
	
	var data_params = [
		timestamp,
		steer_input,
		# Because forward is -Z and speed is m/s (so * -3.6)
		linear_velocity.dot(transform.basis.z * -3.6),
		rotation_degrees.x,
		distance
	]
	params.append(data_params)
	poses.append([
		transform.basis.x.x, transform.basis.y.x, transform.basis.z.x, transform.origin.x,
		transform.basis.x.y, transform.basis.y.y, transform.basis.z.x, transform.origin.y,
		transform.basis.x.z, transform.basis.y.z, transform.basis.z.x, transform.origin.z,
		0.0, 0.0, 0.0, 1.0
	])
	
	steering_signal.emit(steer_input)
	speed_signal.emit(int(linear_velocity.dot(transform.basis.z * -3.6)))
	angle_signal.emit(rotation_degrees.x)
	distance_signal.emit(int(distance))
	

func _ready() -> void:
	var cfg = FileUtils.load_config("res://config.cfg")
	preload_input = cfg.get_value("player", "preload_input")
	max_steer_force = cfg.get_value("player", "max_steer_force")
	mass = cfg.get_value("player", "mass")
	params_path = cfg.get_value("player", "params_path")
	trajectory_path = cfg.get_value("player", "trajectory_path")
	
	if preload_input:
		## NOTE: Currently expects already sorted data
		var input_path = cfg.get_value("player", "input_path")
		var input_file = FileAccess.open(input_path, FileAccess.READ)		
		
		if input_file == null:
			push_error("Cannot open file " + input_path)
			return
		
		parse_txt(input_file)
		# TODO: Check if I need it.
		input_file.close()
		
		current_time = Time.get_ticks_msec() / 1000.0
	
## Adjust physics for sleds - make collisions less dramatic
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#var lv = state.linear_velocity
	
	for i in range(state.get_contact_count()):
		# Makes collisions less dramatic
		var normal = state.get_contact_local_normal(i)
		var impulse = state.get_contact_impulse(i)
		
		apply_central_impulse(-normal * impulse.length() * 0.2)
		   
		var tangent = state.linear_velocity.slide(normal)
		apply_central_force(-tangent * 0.2)
		
### MI random suggestions
##
	### 3) Vertikālā lēciena damping
	##if state.get_contact_count() > 0 and lv.y > 0:
		##lv.y *= 0.2
##
	##state.linear_velocity = lv
##
	### 4) Rotācijas stabilizācija (anti-karuselis)
	##apply_torque_impulse(-angular_velocity * 0.2)
