@tool
extends Node3D

func _ready():
  for child in get_children():
    if child is MeshInstance3D:
      child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
      child.set_layer_mask_value(1, false)
      child.set_layer_mask_value(2, false)