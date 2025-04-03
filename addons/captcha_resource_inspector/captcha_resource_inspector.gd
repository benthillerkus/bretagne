extends EditorInspectorPlugin

var SolutionEditor = preload("res://addons/captcha_resource_inspector/solution_editor.gd")
var Preview = preload("res://features/captcha/captcha_2d.tscn")


func _can_handle(object: Object) -> bool:
  if object is Captcha:
    var preview: Captcha2D = Preview.instantiate()
    preview.puzzle = object
    add_custom_control(preview)
    return true
  return false
    # preview.connect("selection_changed", func(): _update_solution(object, preview)) 

# func _update_solution(resource: Captcha, preview: Captcha2D) -> void:
#   resource.solution.clear()
#   for i in preview.selection:
#     resource.solution.append(i)
#   resource.changed.emit()

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
  if name == "solution":
    add_property_editor(name, SolutionEditor.new())
    return false
  return false
