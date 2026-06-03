extends Path3D

func create_centerline(track: TrackData):
	var direction = Vector3.FORWARD
	# Because -Z is forward.
	var point = Vector3(0.0, 0.0, -track.start_at)
	var slope = track.get_slope(track.normalize(track.start_at))
	var curvature = track.get_curvature(0.0)
	
	curve.add_point(point)
	
	var point_count = floori(track.length / curve.bake_interval)
	for i in range(point_count):
		var Sx = i * curve.bake_interval + track.start_at
		slope = track.get_slope(track.normalize(Sx))
		curvature = track.get_curvature(track.normalize(Sx))
		
		if not is_zero_approx(curvature):
			var angle_step = curvature * curve.bake_interval
			direction = direction.rotated(Vector3.UP, angle_step)
			
		point += direction * curve.bake_interval
		point.y -= slope * curve.bake_interval
		
		curve.add_point(point)
