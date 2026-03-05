class_name MathUtils extends Node

static func lerp_list(from: float, to: float, elements: int) -> PackedFloat32Array:
	var result = PackedFloat32Array()
	result.resize(elements)
	
	for i in range(elements):
		result[i] = lerpf(from ,to, float(i)/elements)
	return result
