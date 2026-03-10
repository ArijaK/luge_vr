extends Path3D

func create_centerline(track: TrackData):
	var direction = Vector3.FORWARD
	# Because Z is forward
	var point = Vector3(0.0, 0.0, -track.start_at)
	var slope = track.get_slope(track.start_at)
	var curvature = track.get_curvature(track.start_at)
	
	curve.add_point(point)
	
	var point_count = floori((track.length - track.start_at) / curve.bake_interval)
	for i in range(point_count):
		var Sx = i * curve.bake_interval + track.start_at
		slope = track.get_slope(Sx)
		curvature = track.get_curvature(Sx)
		
		if is_zero_approx(curvature):
			point += direction * curve.bake_interval
			point.y -= (slope / 100.0) * curve.bake_interval
		else:
			var slope_rad = atan(slope / 100.0)
			var angle_step = curvature * curve.bake_interval
			direction = direction.rotated(Vector3.UP, angle_step)
			
			point += direction * curve.bake_interval
			#point += direction * (2.0 * sin(angle_step * 0.5) / curvature)
			point.y -= tan(slope_rad) * curve.bake_interval
			
		curve.add_point(point)
