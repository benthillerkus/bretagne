@tool
extends Node3D

@export var material: Material

@onready var lowpoly: Node3D = $"terrain converter"

func _ready() -> void:
  # Make sure the lowpoly terrain is visible so that it can be used in effects
  if (!Engine.is_editor_hint()):
    lowpoly.visible = true

  # Apply the material on all tiles
  for child in get_children():
    if child is MeshInstance3D:
      child.material_override = material
