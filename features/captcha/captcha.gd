@tool
extends Resource
class_name Captcha

@export var texture: Texture2D:
  set(value):
    texture = value
    emit_changed()
@export_multiline var prompt: String:
  set(value):
    prompt = value
    emit_changed()
@export_range(1, 12, 1) var rows: int = 3:
  set(value):
    rows = value
    emit_changed()
@export_range(1, 12, 1) var columns: int = 3:
  set(value):
    columns = value
    emit_changed()

## A list of the indices of the selected cells.
@export var solution: PackedByteArray = PackedByteArray()
