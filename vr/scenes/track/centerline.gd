extends Path3D

func create_centerline(start: Vector3, length: float):
	var direction = Vector3.FORWARD
	var slope = 0.0
	var radius = 0.0
	var turn = 0
	
	curve.add_point(start)
	
	for i in range(0, length, curve.bake_interval):
		pass
		#slope = get_slope()
		#radius, turn = get_radius()
		#
		#if is_zero_approx(s.radius):
			#start += direction * s.length
			#start.y -= s.length * (s.slope / 100.0)
			#
			#result.add_point(start)
		#else:
			## Angle of the curve
			#var angle_rad = s.length / s.radius
			#var slope_rad = atan(s.slope / 100.0)
			#var angle_step = result.bake_interval / s.radius
			#
			#for i in range(0, int(angle_rad/angle_step)):
				#direction = direction.rotated(Vector3.UP, angle_step * s.turn)
				#
				#start += direction * result.bake_interval
				#start.y -= tan(slope_rad) * result.bake_interval
				#result.add_point(start)
