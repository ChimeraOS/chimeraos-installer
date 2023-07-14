@tool
@icon("res://assets/editor-icons/keyboard-mouse-16-filled.svg")
extends Node
class_name InputWatcher

## Watch for input and emit signals
##
## Listens for the given input action and emits a signal when that action is 
## pressed or released


signal input_pressed
signal input_released

@export var stop_propagation := false

## Input action to watch for events from
var action: String


func _init() -> void:
	ready.connect(_on_ready)


func _on_ready() -> void:
	notify_property_list_changed()
	var parent := get_parent()
	if parent is CanvasItem:
		parent.visibility_changed.connect(_on_visibility_changed)


## Invoked when this node's parent's visibility has changed.
func _on_visibility_changed() -> void:
	var parent := get_parent()
	set_process_input(parent.is_visible_in_tree())


func _get_actions() -> PackedStringArray:
	return InputMap.get_actions()


# Customize editor properties that we expose. Here we dynamically look up
# the parent node's signals so we can display them in a list.
func _get_property_list():
	# By default, action` is not visible in the editor.
	var property_usage := PROPERTY_USAGE_DEFAULT

	# Populate choices in the editor for available actions
	var available_actions := []
	for item in _get_actions():
		available_actions.append(item)

	var properties := []
	properties.append(
			{
				"name": "action",
				"type": TYPE_STRING,
				"usage": property_usage,  # See above assignment.
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": ",".join(available_actions)
			}
	)

	return properties


# https://docs.godotengine.org/en/latest/tutorials/inputs/inputevent.html#how-does-it-work
func _input(event: InputEvent) -> void:
	if not event.is_action(action):
		return
	
	# Emit signals when this event is pressed/released
	if event.is_pressed():
		input_pressed.emit()
	else:
		input_released.emit()
	
	# Stop the event from propagating
	if stop_propagation:
		get_viewport().set_input_as_handled()
