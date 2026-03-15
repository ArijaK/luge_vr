class_name MathUtils extends Node

static func lerp_list(from: float, to: float, elements: int) -> PackedFloat32Array:
	var result = PackedFloat32Array()
	result.resize(elements)
	
	for i in range(elements):
		result[i] = lerpf(from ,to, float(i)/elements)
	return result

static func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector3:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var result = q0.lerp(q1, t)
	return Vector3(result[0], result[1], 0.0) 
