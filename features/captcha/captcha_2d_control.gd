## Script for rendering a 2D grid of icons
@tool
extends ItemList
class_name Captcha2DControl

## The number of items laid out on each y-axis
@export_range(1, 8, 1, "or_greater")
var rows: int = 4:
  set(value):
    rows = value
    _setup_grid()

## The number of items laid out on each x-axis
@export_range(1, 8, 1, "or_greater")
var columns: int = 4:
  set(value):
    columns = value
    _setup_grid()

@export var texture: Texture2D:
  set(value):
    texture = value
    _setup_grid()

## The size of each icon when selected
@export_range(0, 1, 0.1)
var selected_scale: float = 0.75

func _ready():
  # Defer to make sure parent size has been determined
  call_deferred("_setup_grid")
  select_mode = ItemList.SELECT_TOGGLE
  clip_contents = false
  connect("multi_selected", shrink_item_icon_when_selected)

## Called when the grid has to be rebuilt
##
## Emits [signal Captcha2DControl.setup] when the grid is setup
func _setup_grid():
  # Clear any existing items
  clear()
  
  # Ensure the texture is set
  if texture == null:
    return
  
  # Crop the texture to match the aspect ratio of the Control
  var available_space: Vector2
  if not Engine.is_editor_hint():
    available_space = get_parent_area_size()
  else:
    available_space = Vector2(512, 512) # Hardcode to prevent feedback loop in editor


  var control_aspect = available_space.aspect()
  var texture_aspect = float(texture.get_width()) / texture.get_height()

  var crop_rect: Rect2
  if control_aspect > texture_aspect:
    # Crop vertically
    var new_height = texture.get_width() / control_aspect
    crop_rect = Rect2(Vector2(0, (texture.get_height() - new_height) / 2), Vector2(texture.get_width(), new_height))
  else:
    # Crop horizontally
    var new_width = texture.get_height() * control_aspect
    crop_rect = Rect2(Vector2((texture.get_width() - new_width) / 2, 0), Vector2(new_width, texture.get_height()))
  
  # Define the size of each slice
  var slice_width = float(crop_rect.size.x) / columns
  var slice_height = float(crop_rect.size.y) / rows

  var seperation_size = Vector2(get_theme_constant("h_separation") * (columns - 1), get_theme_constant("v_separation") * (rows - 1))

  fixed_icon_size = Vector2((available_space.x - seperation_size.x) / columns, (available_space.y - seperation_size.y) / rows)
  auto_height = true
  auto_width = true
  max_columns = columns
  same_column_width = true

  # Generate a grid based on rows and columns
  for y in range(rows):
    for x in range(columns):
      var atlas_texture = AtlasTexture.new()
      atlas_texture.atlas = texture
      atlas_texture.region = Rect2(
        Vector2(x * slice_width, y * slice_height) + crop_rect.position,
        Vector2(slice_width, slice_height)
      )
      
      # Add the item with the AtlasTexture as the icon
      add_item("", atlas_texture)
  
  setup.emit()

## Called when the grid has been setup / changed in [method Captcha2DControl._setup_grid]
signal setup

## Animates an item to shrink / grow
func shrink_item_icon_when_selected(index: int, selected: bool):
  var rect = (get_item_icon(index) as AtlasTexture).region

  var big = Rect2(Vector2(0, 0), rect.size)
  var small = Rect2(rect.size * (0.5 - 0.5 / selected_scale), rect.size / selected_scale)
  
  @warning_ignore("CONFUSABLE_LOCAL_DECLARATION")
  create_tween().tween_method(
    func(rect: Rect2): set_item_icon_region(index, rect),
    big if selected else small,
    small if selected else big,
    0.2
  )
