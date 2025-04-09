@tool
extends Node3D

@export var material: Material

func _ready() -> void:
  for child in get_children():
    if child is MeshInstance3D:
      child.material_override = material
