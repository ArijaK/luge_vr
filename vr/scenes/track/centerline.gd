extends Path3D

func build_curve_with_exact_length(track: TrackData):
	var s = 1.0
	for i in range(10):
		curve.clear_points()
		create_centerline(track, s)
		
		var error = track.length - curve.get_baked_length()
		if abs(error) < 0.01:
			break

		s *=  track.length / curve.get_baked_length()

func create_centerline(track: TrackData, s: float = 1.0):
	var direction = Vector3.FORWARD
	# Because Z is forward
	var point = Vector3(0.0, 0.0, -track.start_at)
	var slope = track.get_slope(track.start_at)
	var curvature = track.get_curvature(track.start_at)
	
	curve.add_point(point)
	
	var point_count = floori((track.length - track.start_at) / curve.bake_interval)
	for i in range(point_count):
		var Sx = i * curve.bake_interval * s + track.start_at
		slope = track.get_slope(Sx)
		curvature = track.get_curvature(Sx)
		
		if is_zero_approx(curvature):
			point += direction * curve.bake_interval
			point.y -= (slope / 100.0) * curve.bake_interval
		else:
			var slope_rad = atan(slope / 100.0)
			var angle_step = curvature * curve.bake_interval
			direction = direction.rotated(Vector3.UP, angle_step)
			
			#point += direction * curve.bake_interval
			point += direction * (2.0 * sin(angle_step * 0.5) / curvature)
			point.y -= tan(slope_rad) * curve.bake_interval
			
		curve.add_point(point)
