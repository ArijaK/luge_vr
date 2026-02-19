extends RigidBody3D

func _ready() -> void:
	linear_velocity.z = -10.0

# TODO: This is ONLY A DRAFT FOR INITIAL ASSESSMENT, MUST BE CHANGED!
func _process(delta: float) -> void:
	print((linear_velocity.z*3600)/1000)
