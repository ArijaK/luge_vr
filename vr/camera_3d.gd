extends Camera3D

@export var follow_target: Node3D


func _process(_delta: float) -> void:
	global_position = follow_target.global_position
	look_at(follow_target.global_position)
