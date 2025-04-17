## Injects a [Captcha] resource into a [Captcha2DControl]
## node and additional 2D UI elements.
##
## Emits [signal Captcha2D.solved] when the user
## successfully solves the captcha.
@tool
extends PanelContainer
class_name Captcha2D

## The puzzle that will be used to configure the individual fields
@export var puzzle: Captcha:
  set(value):
    if puzzle != null:
      puzzle.changed.disconnect(_on_puzzle_changed)
    puzzle = value
    if puzzle != null:
      puzzle.changed.connect(_on_puzzle_changed)
    _on_puzzle_changed()

@onready var control: Captcha2DControl = %Captcha2DControl
@onready var instructions: RichTextLabel = %Instructions

func _ready() -> void:
  if puzzle == null:
    return
  _on_puzzle_changed()

func _on_puzzle_changed() -> void:
  if puzzle == null:
    instructions.text = "SAMPLE TEXT"
    control.columns = 3
    control.rows = 3
    control.texture = null
  else:
    if puzzle.prompt != null:
      instructions.text = puzzle.prompt
    control.columns = puzzle.columns
    control.rows = puzzle.rows
    control.texture = puzzle.texture

## The [member Captcha2D.puzzle] has just been solved
signal solved

signal failed

## The user has pressed the skip button
signal skipped

## The current selection of the [member Captcha2DControl.control]
var selection: PackedInt32Array:
  get():
    return control.get_selected_items()

## The user has changed the selection of the [member Captcha2DControl.control]
signal selection_changed

func _on_control_selection_changed() -> void:
  selection_changed.emit()
  if puzzle == null:
    return
  @warning_ignore("SHADOWED_VARIABLE")
  var selection = self.selection
  if selection == null or selection.size() != puzzle.solution.size():
    return
  for i in puzzle.solution:
    if not selection.has(i):
      return
  # All selected items are in the solution
  solved.emit()

func _on_skip_pressed() -> void:
  skipped.emit()
