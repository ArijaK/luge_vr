extends Path3D

func create_centerline(track: TrackData):
	
	var direction = Vector3.FORWARD
	# Because Z is forward
	var point = Vector3(0.0, 0.0, track.start_at)
	var slope = track.get_slope(-point.z)
	var radius = track.get_radius(-point.z)
	
	curve.add_point(point)
	
	for i in range(floori(track.length/curve.bake_interval)):
		var Sx = i * curve.bake_interval
		slope = track.get_slope(Sx)
		radius = track.get_radius(Sx)
		
		if is_zero_approx(radius[0]):
			point += direction * curve.bake_interval
			point.y -= (slope / 100.0) * curve.bake_interval
		else:
			var slope_rad = atan(slope / 100.0)
			var angle_step = radius[0] * curve.bake_interval
			direction = direction.rotated(Vector3.UP, angle_step * radius[1])
			
			point += direction * curve.bake_interval
			point.y -= tan(slope_rad) * curve.bake_interval
		curve.add_point(point)
