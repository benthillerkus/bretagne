@tool
extends Node3D
class_name Captcha3D

@export var puzzle: Captcha:
  set(value):
    if puzzle != null:
      puzzle.changed.disconnect(_on_puzzle_changed)
    puzzle = value
    if puzzle != null:
      puzzle.changed.connect(_on_puzzle_changed)
    _on_puzzle_changed()

func _on_puzzle_changed() -> void:
  if captcha != null:
    captcha.puzzle = puzzle
  
@onready var display: MeshInstance3D = $MeshInstance3D
@onready var box_mesh: BoxMesh = $Box.mesh
@onready var display_mesh: QuadMesh = display.mesh
@onready var viewport: SubViewport = $SubViewport
@onready var area: Area3D = $Area3D
@onready var collision_shape: BoxShape3D = $Area3D/CollisionShape3D.shape
@onready var cursor: Node3D = $Cursor
@onready var captcha: Captcha2D = $SubViewport/Captcha2D

var mesh_size: Vector2

var mouse_inside = false

var last_mouse_pos_3D = null
var last_mouse_pos_2D = null
var camera: Camera3D

var rayparam: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()

func _ready() -> void:
  rayparam.collide_with_bodies = false
  rayparam.collide_with_areas = true
  rayparam.collision_mask = 1
  _on_puzzle_changed()
  _update_size()

func _update_size() -> void:
  if captcha == null:
    return
  var size = captcha.size
  viewport.size = size
  viewport.size_2d_override = size * 2
  display_mesh.size.x = size.aspect()
  collision_shape.size.x = size.aspect()
  box_mesh.size.x = size.aspect()

func _unhandled_input(event: InputEvent) -> void:
  if !mouse_inside:
    return
  if event is InputEventMouseButton or event is InputEventScreenTouch:
      event.global_position = last_mouse_pos_2D
      event.position = last_mouse_pos_2D
      viewport.push_input(event)

func _process(_delta: float) -> void:
  if Engine.is_editor_hint():
    return
  camera = get_viewport().get_camera_3d()


func _physics_process(_delta: float) -> void:
  if Engine.is_editor_hint():
    return
  var mouse_pos3D = _find_mouse()
  mouse_inside = mouse_pos3D != null

  if !mouse_inside:
    if cursor.visible:
      var tween = create_tween()
      tween.tween_property(cursor, "scale", Vector3(0, 0, 0), 0.1)
      tween.finished.connect(func(): cursor.visible = false)
    return
  if !cursor.visible:
      cursor.visible = true
      var tween = create_tween()
      tween.tween_property(cursor, "scale", Vector3(1, 1, 1), 0.05)

  last_mouse_pos_3D = area.global_transform.affine_inverse() * mouse_pos3D
  cursor.transform.origin = last_mouse_pos_3D
  mesh_size = display_mesh.size

  var mouse_pos2D = Vector2(last_mouse_pos_3D.x, -last_mouse_pos_3D.y)
  mouse_pos2D.x += mesh_size.x / 2
  mouse_pos2D.y += mesh_size.y / 2

  mouse_pos2D.x = mouse_pos2D.x / mesh_size.x
  mouse_pos2D.y = mouse_pos2D.y / mesh_size.y

  mouse_pos2D.x = mouse_pos2D.x * viewport.size.x
  mouse_pos2D.y = mouse_pos2D.y * viewport.size.y

  last_mouse_pos_2D = mouse_pos2D

## Projects a ray from the camera into the scene and checks if it intersects with the [member Captcha3D.area].
##
## Returns the position of the intersection if it exists, otherwise returns null.
func _find_mouse():
  if camera == null:
    return null
  var dss: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
  var viewport_size = camera.get_viewport().size
  rayparam.from = camera.project_ray_origin(viewport_size / 2)
  rayparam.to = rayparam.from + camera.project_ray_normal(viewport_size / 2) * 50

  var result = dss.intersect_ray(rayparam)
  if result.size() > 0:
    return result.position
  else:
    return null

signal solved
signal failed
signal skipped

func _on_captcha_2d_solved() -> void:
  solved.emit()

func _on_captcha_2d_failed() -> void:
  failed.emit()

func _on_captcha_2d_skipped() -> void:
  skipped.emit()
