extends EditorProperty

var control: Captcha2DControl = preload("res://features/captcha/captcha_2d_control.gd").new()

var value: PackedByteArray = PackedByteArray()
var resource: Captcha

var updating = false

func _init() -> void:
  add_child(control)
  set_bottom_editor(control)
  add_focusable(control)
  selectable = true
  call_deferred("_setup")

func _setup() -> void:
  resource = get_edited_object() as Captcha
  resource.connect("changed", _on_resource_changed)
  control.connect("setup", _sync_selection_to_control)
  control.connect("multi_selected", func(_index,_selected): _on_selection_changed())
  _on_resource_changed()
  _sync_selection_to_control()

func _on_resource_changed() -> void:
  value = resource.solution
  control.texture = resource.texture
  control.columns = resource.columns
  control.rows = resource.rows

func _on_selection_changed() -> void:
  if updating:
    return
  updating = true
  value.clear()
  for i in control.get_selected_items():
    value.append(i)
  updating = false
  emit_changed(get_edited_property(), value)

func _update_property() -> void:
  var new_value = get_edited_object().get(get_edited_property())
  if new_value == value:
    return
  updating = true
  value = new_value
  _sync_selection_to_control()
  updating = false

func _sync_selection_to_control() -> void:
  if control.item_count == 0:
    return
  control.deselect_all()
  for i in value:
    control.select(i, false)
    control.shrink_item_icon_when_selected(i, true)
