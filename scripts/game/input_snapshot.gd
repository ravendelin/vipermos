extends RefCounted
## Event-backed input sampled once per fixed tick. Device state remains separate.
const EDGE_ACTIONS := ["module_toggle", "module_side", "speed_cycle", "bomb"]
var keys: Dictionary = {}
var pads: Dictionary = {}
var sticks: Dictionary = {}
var active_pad: int = -1
var previous: Dictionary = {}
var blocked: Dictionary = {}
var pending: Dictionary = {}

func ingest(event: InputEvent) -> void:
    var before: Dictionary = {}
    for action: String in EDGE_ACTIONS:
        before[action] = held(action)
    if event is InputEventKey and not event.echo:
        keys[event.physical_keycode if event.physical_keycode else event.keycode] = event.pressed
    elif event is InputEventJoypadButton:
        active_pad = event.device
        if not pads.has(active_pad):
            pads[active_pad] = {}
        pads[active_pad][event.button_index] = event.pressed
    elif event is InputEventJoypadMotion:
        active_pad = event.device
        var axis: Vector2 = sticks.get(active_pad, Vector2.ZERO)
        if event.axis == JOY_AXIS_LEFT_X:
            axis.x = event.axis_value
        elif event.axis == JOY_AXIS_LEFT_Y:
            axis.y = event.axis_value
        sticks[active_pad] = axis
    for action: String in EDGE_ACTIONS:
        if held(action) and not before[action] and not blocked.get(action, false):
            pending[action] = true
        if not held(action):
            blocked.erase(action)
    if not held("charge"):
        blocked.erase("charge")

func disconnect_pad(device: int) -> void:
    pads.erase(device)
    sticks.erase(device)
    if active_pad == device:
        active_pad = -1

func held(action: String) -> bool:
    for binding: InputEvent in InputMap.action_get_events(action):
        if binding is InputEventKey and keys.get(binding.physical_keycode, false):
            return true
        if binding is InputEventJoypadButton and pads.get(active_pad, {}).get(binding.button_index, false):
            return true
    return false

static func resolve_movement(keyboard: Vector2, dpad: Vector2, stick: Vector2, dpad_held: bool) -> Vector2:
    if keyboard != Vector2.ZERO:
        return keyboard.limit_length()
    if dpad_held:
        return dpad.limit_length()
    var strength := minf(stick.length(), 1.0)
    if strength <= 0.22:
        return Vector2.ZERO
    return stick.normalized() * ((strength - 0.22) / 0.78)

func movement() -> Vector2:
    var digital := Vector2.ZERO
    for pair: Array in [["move_left", Vector2.LEFT], ["move_right", Vector2.RIGHT], ["move_up", Vector2.UP], ["move_down", Vector2.DOWN]]:
        for binding: InputEvent in InputMap.action_get_events(pair[0]):
            if binding is InputEventKey and keys.get(binding.physical_keycode, false):
                digital += pair[1]
                break
    var pad: Dictionary = pads.get(active_pad, {})
    var dpad := Vector2(float(pad.get(JOY_BUTTON_DPAD_RIGHT, false)) - float(pad.get(JOY_BUTTON_DPAD_LEFT, false)), float(pad.get(JOY_BUTTON_DPAD_DOWN, false)) - float(pad.get(JOY_BUTTON_DPAD_UP, false)))
    var any_dpad: bool = pad.get(JOY_BUTTON_DPAD_LEFT, false) or pad.get(JOY_BUTTON_DPAD_RIGHT, false) or pad.get(JOY_BUTTON_DPAD_UP, false) or pad.get(JOY_BUTTON_DPAD_DOWN, false)
    return resolve_movement(digital, dpad, sticks.get(active_pad, Vector2.ZERO), any_dpad)

func suppress_until_release() -> void:
    pending.clear()
    for action: String in EDGE_ACTIONS + ["charge"]:
        blocked[action] = held(action)
        previous[action] = held(action)

func clear_devices() -> void:
    keys.clear()
    pads.clear()
    sticks.clear()
    suppress_until_release()

func sample() -> Dictionary:
    var result: Dictionary = {"move": movement(), "fire": held("fire"), "charge": false}
    for action: String in EDGE_ACTIONS + ["charge"]:
        var down := held(action)
        if not down:
            blocked.erase(action)
        var allowed: bool = down and not blocked.get(action, false)
        result[action] = allowed if action == "charge" else pending.get(action, false) or (allowed and not previous.get(action, false))
        previous[action] = down
    pending.clear()
    return result
