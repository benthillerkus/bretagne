extends Label

func _ready() -> void:
  visible = false

func _on_main_score_changed(value:int) -> void:
  text = str(value)
  visible = value > 0
