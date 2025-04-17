extends Label

func _ready() -> void:
  visible = false

func _on_player_can_pickup(state:bool) -> void:
  visible = state
