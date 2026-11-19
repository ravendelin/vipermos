extends SceneTree
## Dependency-free foundation tests. -- --self-test-failure exercises exit code.
var failures: int = 0
var assertions: int = 0

func check(ok: bool, detail: String) -> void:
    assertions += 1
    if not ok:
        failures += 1
        printerr("FAIL: " + detail)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    check(Engine.physics_ticks_per_second == 60, "fixed simulation must use 60 Hz")
    for pair: Array in [["viewport_width", 640], ["viewport_height", 360], ["window_width_override", 1280], ["window_height_override", 720]]:
        check(ProjectSettings.get_setting("display/window/size/" + pair[0]) == pair[1], "window configuration: " + pair[0])
    check(ProjectSettings.get_setting("display/window/stretch/scale_mode") == "integer", "integer scaling")
    check(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep", "letterbox aspect")
    check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility", "Compatibility renderer")
    var bindings: Node = root.get_node("InputBindings")
    for action: String in bindings.KEYS:
        check(InputMap.has_action(action), "action exists: " + action)
        check(is_equal_approx(InputMap.action_get_deadzone(action), 0.22), "deadzone: " + action)
        for key: int in bindings.KEYS[action]:
            var event := InputEventKey.new()
            event.physical_keycode = key
            check(InputMap.event_is_action(event, action), "key binding %s/%s" % [action, key])
        var button := InputEventJoypadButton.new()
        button.button_index = bindings.BUTTONS[action]
        check(InputMap.event_is_action(button, action), "controller binding: " + action)
    var count: int = InputMap.action_get_events("move_up").size()
    bindings.install_defaults()
    check(InputMap.action_get_events("move_up").size() == count, "defaults reset without duplicate events")
    for pair: Array in [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0], ["move_up", JOY_AXIS_LEFT_Y, -1.0], ["move_down", JOY_AXIS_LEFT_Y, 1.0]]:
        var axis := InputEventJoypadMotion.new()
        axis.axis = pair[1]
        axis.axis_value = pair[2]
        check(InputMap.event_is_action(axis, pair[0]), "stick binding: " + pair[0])
    var scene: PackedScene = load("res://scenes/boot.tscn")
    var menu: Control = scene.instantiate()
    root.add_child(menu)
    await process_frame
    check(menu.page == "title", "boot to title")
    var key := InputEventKey.new()
    key.physical_keycode = KEY_ENTER
    key.pressed = true
    Input.parse_input_event(key)
    await process_frame
    check(menu.page == "menu", "Enter opens menu exactly once")
    check(menu.buttons.size() == 6, "six main menu destinations")
    check(root.gui_get_focus_owner() == menu.buttons[0], "campaign has initial focus")
    key.pressed = false
    Input.parse_input_event(key)
    var pad := InputEventJoypadButton.new()
    pad.button_index = JOY_BUTTON_DPAD_DOWN
    pad.pressed = true
    Input.parse_input_event(pad)
    await process_frame
    check(root.gui_get_focus_owner() == menu.buttons[1], "D-pad moves focus")
    pad.pressed = false
    Input.parse_input_event(pad)
    for destination: String in ["campaign", "practice", "scores", "options", "credits", "quit"]:
        menu._select(destination)
        await process_frame
        check(menu.page == destination, "destination: " + destination)
        check(root.gui_get_focus_owner() == menu.buttons[0], "destination focus: " + destination)
        var cancel := InputEventJoypadButton.new()
        cancel.button_index = JOY_BUTTON_B
        cancel.pressed = true
        Input.parse_input_event(cancel)
        await process_frame
        check(menu.page == "menu", "B returns/cancels: " + destination)
        cancel.pressed = false
        Input.parse_input_event(cancel)
    menu.show_page("quit")
    check(menu.buttons[0].text == "CANCEL", "quit defaults to safe cancel")
    for i: int in 100:
        menu.show_page("menu")
        menu.show_page("credits")
        await process_frame
    check(menu.panel.get_child_count() == 6, "repeated transitions do not accumulate UI")
    menu.queue_free()
    await process_frame
    await preload("res://tests/test_movement.gd").new().run(self, check)
    await preload("res://tests/test_combat.gd").new().run(self, check)
    await preload("res://tests/test_aegis.gd").new().run(self, check)
    await preload("res://tests/test_stages.gd").new().run(self, check)
    change_scene_to_file("res://scenes/boot.tscn")
    await scene_changed
    current_scene.show_page("campaign")
    current_scene.buttons[0].pressed.emit()
    await scene_changed
    check(current_scene.name == "Mission", "menu movement launch enters mission")
    current_scene.pause()
    current_scene._confirm_quit()
    current_scene.pause_panel.get_child(1).pressed.emit()
    await scene_changed
    check(current_scene.name == "Boot" and not paused, "confirmed quit returns unpaused to title")
    current_scene.queue_free()
    await process_frame
    if "--self-test-failure" in OS.get_cmdline_user_args():
        check(false, "intentional runner failure")
    print("RESULT: %d assertions, %d failures" % [assertions, failures])
    quit(1 if failures else 0)
