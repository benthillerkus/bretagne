extends Label

func _ready() -> void:
  visible = false

func _on_area_3d_body_entered(_body:Node3D) -> void:
  visible = true

func _on_area_3d_body_exited(_body:Node3D) -> void:
  visible = false
