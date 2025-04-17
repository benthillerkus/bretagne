extends RigidBody3D
class_name Rock

var picked_up: bool = false
@onready var gravity: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity") * Vector3.UP

func on_pickup() -> void:
  picked_up = true

func on_drop() -> void:
  picked_up = false
