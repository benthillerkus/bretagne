extends Node3D

var captcha_scene = preload("res://features/captcha/captcha_3d.tscn")
@onready var captcha_pin = $CaptchaPin
@onready var captcha_pin_marker = $CaptchaPin/Marker3D
@onready var player = $Player
@onready var animation_player = $AnimationPlayer

var rocks_scene = preload("res://assets/rocks/rocks.tscn")
var rocks: Node3D = null

@onready var water = $WaterSystem
@onready var beach = $BigBeach

@export var game_length = 180.0

var puzzles: Array

signal score_changed(int)
var score = 0:
  set(value):
    score = value
    score_changed.emit(score)

func _ready() -> void:
  puzzles = ResourceLoader.list_directory("res://features/captcha/puzzles/")
  rocks = rocks_scene.instantiate()
  var tween := create_tween()
  tween.tween_property(beach, "position", Vector3(0, -1.8, 0), game_length)
  animation_player.stop()
  animation_player.speed_scale = 1.0 / game_length
  animation_player.play("time_of_day")
  spawn_captcha()
  score = 0

func _physics_process(_delta: float) -> void:
  if captcha_pin.position.y < -3:
    spawn_captcha()
  
  var tallest = 0
  for rock in get_tree().get_nodes_in_group("Throwable"):
    if rock.position.y > tallest:
      tallest = rock.position.y
  score = int(tallest * 100)

func spawn_rock() -> void:
  var random_rock: RigidBody3D = rocks.get_children()[randi() % rocks.get_child_count()]
  var rock: RigidBody3D = random_rock.duplicate(DuplicateFlags.DUPLICATE_GROUPS)
  rock.position = Vector3(0, 10, 0) + captcha_pin.position
  rock.rotation_degrees = Vector3(0, 0, 0)
  var rock_scale = pow(randf_range(.2, 1.0), 1.5)
  for child in rock.get_children():
    child.scale = Vector3(rock_scale, rock_scale, rock_scale)
  add_child(rock)
  rock.process_mode = PROCESS_MODE_INHERIT

func _on_captcha_3d_solved() -> void:
  spawn_rock()
  despawn_captcha()
  await get_tree().create_timer(4).timeout
  spawn_captcha()

func _on_captcha_3d_skipped() -> void:
  despawn_captcha()
  await get_tree().create_timer(3).timeout
  spawn_captcha()

func despawn_captcha() -> void:
  var captcha = captcha_pin_marker.get_child(0)
  if captcha == null:
    return
  create_tween().tween_property(captcha, "scale", Vector3(0.005, 0.005, 0.005), 0.1).finished.connect(func():
    captcha_pin_marker.remove_child(captcha)
    captcha.queue_free()
    captcha_pin.process_mode = Node.PROCESS_MODE_DISABLED
  )

func spawn_captcha() -> void:
  captcha_pin.process_mode = Node.PROCESS_MODE_INHERIT
  var puzzle = puzzles[randi() % puzzles.size()]
  var captcha: Captcha3D = captcha_scene.instantiate()
  captcha.connect("solved", _on_captcha_3d_solved)
  captcha.connect("skipped", _on_captcha_3d_skipped)
  captcha.puzzle = load("res://features/captcha/puzzles/" + puzzle)
  captcha_pin_marker.add_child(captcha)
  var random_position = Vector3(randf_range(-10, 10), 5, randf_range(-10, 10))
  captcha_pin.position = random_position
  captcha_pin.rotate_y(randf_range(0, 360))
