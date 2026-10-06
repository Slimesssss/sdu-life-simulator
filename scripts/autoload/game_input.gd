extends Node
## Dang ky input action bang code — khoi khai bao trong Project Settings.

const ACTIONS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"interact": [KEY_E, KEY_ENTER, KEY_SPACE],
	"quick_save": [KEY_F5],
	"quick_load": [KEY_F9],
}


func _ready() -> void:
	for action_name in ACTIONS:
		_register(String(action_name), ACTIONS[action_name])


func _register(action_name: String, keys: Array) -> void:
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
	InputMap.add_action(action_name)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action_name, event)
