extends RefCounted
const Snapshot = preload("res://scripts/game/input_snapshot.gd")
const Player = preload("res://scripts/entities/player_controller.gd")

func key(code: int, pressed: bool = true) -> InputEventKey:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = pressed
    return event

func run(tree: SceneTree, check: Callable) -> void:
    var state: Node = tree.root.get_node("GameState")
    for mode: String in ["assist", "arcade", "veteran"]:
        state.score = 100
        state.start_run(mode)
        check.call(state.score == 0 and state.stage_id == 1, "T001: fresh run " + mode)
        check.call(state.lives == (5 if mode == "assist" else 3), "T001: lives " + mode)
        check.call(state.bombs == (2 if mode == "assist" else 1), "T001: bombs " + mode)
        check.call(state.speed_index == 1 and state.weapon == "ARC" and state.rank == 1, "T001: loadout " + mode)
    state.start_run()
    var player := Player.new()
    tree.root.add_child(player)
    player.position = Vector2(96,180)
    for i: int in 60:
        player.step({"move": Vector2.RIGHT})
    check.call(absf(player.position.x - 241.0) < 0.001, "T002: 60 ticks cover 145px")
    player.position = Vector2(96,180)
    for i: int in 60:
        player.step({"move": Vector2(1,1)})
    check.call(absf(player.position.distance_to(Vector2(96,180)) - 145.0) < 0.002, "T002: diagonal has equal speed")
    player.step({"move": Vector2.ZERO})
    check.call(player.velocity == Vector2.ZERO, "instant stop without inertia")
    for direction: Vector2 in [Vector2(-1,-1), Vector2(1,1)]:
        for i: int in 600:
            player.step({"move": direction})
        check.call(player.position == (Vector2(18,34) if direction.x < 0 else Vector2(622,325)), "bounds corner " + str(direction))
    for expected: int in [2,0,1]:
        player.step({"speed_cycle": true})
        check.call(player.speed_index == expected, "speed cycle " + str(expected))
    for speed: int in 3:
        player.speed_index = speed
        player.step({"move": Vector2.RIGHT})
        check.call(player.velocity.x == [105.0,145.0,190.0][speed], "exact speed tier")
    player.queue_free()
    var input := Snapshot.new()
    input.ingest(key(KEY_A))
    input.ingest(key(KEY_D))
    check.call(input.movement() == Vector2.ZERO, "opposite keys cancel")
    input.ingest(key(KEY_A, false))
    check.call(input.movement() == Vector2.RIGHT, "remaining key survives opposite release")
    input.ingest(key(KEY_D, false))
    var axis := InputEventJoypadMotion.new()
    axis.device = 2
    axis.axis = JOY_AXIS_LEFT_X
    axis.axis_value = 0.22
    input.ingest(axis)
    check.call(input.movement() == Vector2.ZERO, "stick deadzone inclusive")
    axis.axis_value = 0.61
    input.ingest(axis)
    check.call(absf(input.movement().x - 0.5) < 0.00001, "analog proportional beyond deadzone")
    axis.axis_value = 1.0
    input.ingest(axis)
    var pad := InputEventJoypadButton.new()
    pad.device = 2
    pad.button_index = JOY_BUTTON_DPAD_LEFT
    pad.pressed = true
    input.ingest(pad)
    check.call(input.movement() == Vector2.LEFT, "D-pad wins over opposite stick")
    pad.button_index = JOY_BUTTON_DPAD_RIGHT
    input.ingest(pad)
    check.call(input.movement() == Vector2.ZERO, "opposite D-pad cancels without stick fallback")
    input.disconnect_pad(2)
    check.call(input.movement() == Vector2.ZERO, "disconnected controller cannot keep movement")
    input.ingest(key(KEY_SHIFT))
    check.call(input.sample().speed_cycle, "first edge accepted")
    check.call(not input.sample().speed_cycle, "held edge not repeated")
    input.suppress_until_release()
    check.call(not input.sample().speed_cycle, "held edge suppressed on resume")
    input.ingest(key(KEY_SHIFT, false))
    input.sample()
    input.ingest(key(KEY_SHIFT))
    check.call(input.sample().speed_cycle, "new press rearms edge")
    input.ingest(key(KEY_X))
    check.call(input.sample().charge, "held charge sampled")
    input.suppress_until_release()
    check.call(not input.sample().charge, "charge held across transition suppressed")
    input.ingest(key(KEY_X, false))
    input.sample()
    input.ingest(key(KEY_X))
    check.call(input.sample().charge, "fresh charge allowed")
    input.clear_devices()
    input.ingest(key(KEY_SHIFT))
    input.ingest(key(KEY_SHIFT, false))
    check.call(input.sample().speed_cycle, "short tap between ticks retained")
    check.call(not input.sample().speed_cycle, "short tap consumed once")
    input.suppress_until_release()
    input.ingest(key(KEY_X))
    check.call(input.sample().charge, "fresh press immediately after resume accepted")
    var mission: Node = load("res://scenes/game/mission.tscn").instantiate()
    tree.root.add_child(mission)
    mission.set_physics_process(false)
    check.call(mission.hud.top.text.contains("00000000") and mission.hud.bottom.text.contains("SPD 2"), "T001: HUD initial state")
    for i: int in 119:
        mission.fixed_tick()
    check.call(mission.phase == "INTRO" and mission.stage_tick == 0, "intro doesn't advance stage time")
    mission.fixed_tick()
    check.call(mission.phase == "SCROLL" and mission.stage_tick == 0, "intro ends at exactly 120 ticks")
    mission.input_snapshot.ingest(key(KEY_D))
    for i: int in 60:
        mission.fixed_tick()
    check.call(mission.stage_tick == 60 and absf(mission.player.position.x - 241) < 0.001, "mission owns fixed movement tick")
    var debug_key := key(KEY_F3)
    mission._input(debug_key)
    check.call(mission.hud.diagnostics.visible and mission.player.show_hitbox, "F3 enables debug and hitbox")
    mission._input(debug_key)
    check.call(not mission.hud.diagnostics.visible, "F3 toggles diagnostics off")
    mission.charge_ticks = 50
    mission.pause()
    var before: Vector2 = mission.player.position
    for i: int in 120:
        mission.fixed_tick()
    check.call(mission.stage_tick == 60 and mission.player.position == before, "T003: 120 paused ticks do not advance simulation")
    mission.set_physics_process(true)
    await tree.create_timer(2.0, true).timeout
    check.call(mission.stage_tick == 60 and mission.player.position == before, "T003: actual 2 seconds wall time paused")
    mission.set_physics_process(false)
    check.call(mission.charge_ticks == 0, "T006 foundation: pause clears charge state")
    mission.resume()
    mission.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
    mission.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
    check.call(tree.paused, "T003: focus return does not resume")
    check.call(mission.input_snapshot.movement() == Vector2.ZERO, "focus loss clears stuck movement")
    mission.resume()
    mission._joy_changed(2, false)
    check.call(tree.paused, "controller disconnect pauses")
    mission.resume()
    mission.input_snapshot.ingest(key(KEY_SHIFT))
    mission.fixed_tick()
    var speed: int = mission.player.speed_index
    mission.pause()
    mission.resume()
    mission.fixed_tick()
    check.call(mission.player.speed_index == speed, "resume cannot repeat held speed press")
    mission.pause()
    mission._confirm_quit()
    check.call(mission.pause_panel.get_child(0).text == "CANCEL", "quit confirmation focuses cancel")
    mission._pause_primary()
    check.call(tree.paused and mission.pause_panel.get_child(0).text == "RESUME", "cancel quit stays paused")
    mission.resume()
    check.call(not tree.paused and not mission.pause_panel.visible, "resume releases pause UI")
    mission.queue_free()
    await tree.process_frame
