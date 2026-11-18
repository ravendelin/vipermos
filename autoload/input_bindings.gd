extends Node
## Central default bindings. Persistence/remapping is added in VL-013.
const DEADZONE: float = 0.22
const KEYS: Dictionary = {
    "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
    "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
    "fire": [KEY_Z, KEY_SPACE], "charge": [KEY_X],
    "module_toggle": [KEY_C], "module_side": [KEY_V],
    "speed_cycle": [KEY_SHIFT], "bomb": [KEY_F], "pause": [KEY_ESCAPE],
    "ui_accept": [KEY_ENTER], "ui_cancel": [KEY_ESCAPE],
    "ui_up": [KEY_UP, KEY_W], "ui_down": [KEY_DOWN, KEY_S],
    "ui_left": [KEY_LEFT, KEY_A], "ui_right": [KEY_RIGHT, KEY_D]
}
const BUTTONS: Dictionary = {
    "move_up": JOY_BUTTON_DPAD_UP, "move_down": JOY_BUTTON_DPAD_DOWN,
    "move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT,
    "fire": JOY_BUTTON_A, "charge": JOY_BUTTON_X,
    "module_toggle": JOY_BUTTON_B, "module_side": JOY_BUTTON_Y,
    "speed_cycle": JOY_BUTTON_LEFT_SHOULDER, "bomb": JOY_BUTTON_RIGHT_SHOULDER,
    "pause": JOY_BUTTON_START, "ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B,
    "ui_up": JOY_BUTTON_DPAD_UP, "ui_down": JOY_BUTTON_DPAD_DOWN,
    "ui_left": JOY_BUTTON_DPAD_LEFT, "ui_right": JOY_BUTTON_DPAD_RIGHT
}

func _ready() -> void:
    install_defaults()

func install_defaults() -> void:
    for action: String in KEYS:
        if not InputMap.has_action(action):
            InputMap.add_action(action, DEADZONE)
        InputMap.action_erase_events(action)
        InputMap.action_set_deadzone(action, DEADZONE)
        for key: int in KEYS[action]:
            var event := InputEventKey.new()
            event.physical_keycode = key
            InputMap.action_add_event(action, event)
        var button := InputEventJoypadButton.new()
        button.button_index = BUTTONS[action]
        InputMap.action_add_event(action, button)
    for prefix: String in ["move_", "ui_"]:
        for direction: String in ["left", "right", "up", "down"]:
            var axis := InputEventJoypadMotion.new()
            axis.axis = JOY_AXIS_LEFT_X if direction in ["left", "right"] else JOY_AXIS_LEFT_Y
            axis.axis_value = -1.0 if direction in ["left", "up"] else 1.0
            InputMap.action_add_event(prefix + direction, axis)
