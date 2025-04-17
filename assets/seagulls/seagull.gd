extends RigidBody3D

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var animation_player = $seagull/AnimationPlayer
@onready var wing_collision: CollisionShape3D = $WingCollision

enum State {
  FLY,
  LAND,
}

var state = State.LAND

var idle_animations: Array = []
var fly_animations: Array = []
var animations: Array = []

func _ready() -> void:
  _on_animation_player_animation_list_changed()

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
  if state == State.LAND:
    if animations.is_empty():
      _on_animation_player_animation_list_changed()
      if idle_animations.is_empty():
        return
    var random_animation = idle_animations[randi() % idle_animations.size()]
    animation_player.play(random_animation)
  if state == State.FLY:
    animation_player.play(fly_animations[0])
    create_tween().tween_property(self, "position", position + Vector3(0, 20, 0) + basis.z * 25, 6).finished.connect(
      func():
        get_parent().remove_child(self)
        queue_free()
    )

func _physics_process(delta: float) -> void:
  wing_collision.disabled = state == State.LAND
  
  var player: Node3D = get_tree().get_first_node_in_group("Player")
  var distance = (player.position - position).length()
  if distance < 4 and state == State.LAND:
    state = State.FLY
    animation_player.play(fly_animations[1])

func _on_body_entered(body: Node) -> void:
  print(body)
  if body.is_in_group("Throwable"):
    if body.velocity.length() * get_process_delta_time() * body.mass > 0.1:
      print("dead")


func _on_animation_player_animation_list_changed() -> void:
  animations = animation_player.get_animation_list()
  idle_animations = []
  fly_animations = []
  for animation: String in animations:
    if animation.contains("Fly"):
      fly_animations.append(animation)
    elif animation.contains("Idle"):
      idle_animations.append(animation)
