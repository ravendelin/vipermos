extends SceneTree
var errors: int = 0
func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var state: Node = root.get_node("GameState")
    state.start_run()
    var mission: Node = load("res://scenes/game/aegis_range.tscn").instantiate()
    root.add_child(mission)
    mission.set_physics_process(false)
    for i: int in 120:
        mission.fixed_tick()
    for kind: String in ["ARC","PRISM","EMBER"]:
        state.weapon = kind
        state.rank = 3
        state.bits = 2
        state.missile_rank = 2
        mission.get_node("World/Targets").reset_targets()
        mission.player.position = Vector2(140,180)
        mission.aegis.reset(mission.player.position)
        var fire := InputEventKey.new()
        fire.physical_keycode = KEY_Z
        fire.pressed = true
        mission.input_snapshot.ingest(fire)
        for i: int in 20:
            mission.fixed_tick()
        fire.pressed = false
        mission.input_snapshot.ingest(fire)
        await process_frame
        await RenderingServer.frame_post_draw
        var result := root.get_texture().get_image().save_png("res://docs/qa/vl-004-%s.png" % kind.to_lower())
        if result != OK:
            errors += 1
        print("CAPTURE ",kind," bullets=",mission.projectiles.active_count," aegis=",mission.aegis.state," result=",result)
    mission.get_node("World/Targets").reset_targets()
    var toggle := InputEventKey.new()
    toggle.physical_keycode = KEY_C
    toggle.pressed = true
    mission.input_snapshot.ingest(toggle)
    for i: int in 30:
        mission.fixed_tick()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/qa/vl-004-detached.png")
    if mission.aegis.state != "FREE":
        errors += 1
    print("DETACHED state=",mission.aegis.state," position=",mission.aegis.position)
    mission.queue_free()
    state.start_run()
    await process_frame
    print("VISUAL errors=",errors)
    quit(0 if errors == 0 else 1)
