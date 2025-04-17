extends Node3D

@onready var label: MarkdownLabel = $MarginContainer/MarkdownLabel

func _ready() -> void:
  process_mode = Node.PROCESS_MODE_ALWAYS
  var file = FileAccess.open("res://CREDITS.md", FileAccess.READ)
  var credits = file.get_as_text()
  file.close()
  label._set_markdown_text(credits)
