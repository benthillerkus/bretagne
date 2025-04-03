extends Control

func _ready():
  process_mode = Node.PROCESS_MODE_ALWAYS
  hide()

func pause():
  get_tree().paused = true
  show()
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume():
  get_tree().paused = false
  hide()
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed():
  resume()

func _on_quit_pressed():
  get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed("game_pause"):
    pause()