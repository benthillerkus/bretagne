extends Control

var credits_scene: PackedScene = preload("res://features/credits/credits.tscn")
var credits = null

func _ready():
  process_mode = Node.PROCESS_MODE_ALWAYS
  hide()

func pause():
  get_tree().paused = true
  show()
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
  if credits:
    credits.queue_free()
    credits = null

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

func _process(delta: float) -> void:
  if get_tree().paused:
    delta = 0
  RenderingServer.global_shader_parameter_set("delta", delta)


func _on_credits_pressed() -> void:
  if credits:
    return
  credits = credits_scene.instantiate()
  get_tree().root.add_child(credits)
  resume()
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
  credits.show()
