extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    root.get_node("GameState").start_run()
    var mission: Node = load("res://scenes/game/weapon_range.tscn").instantiate()
    root.add_child(mission)
    mission.set_physics_process(false)
    for i: int in 120:
        mission.fixed_tick()
    var key := InputEventKey.new()
    key.physical_keycode = KEY_X
    key.pressed = true
    mission.input_snapshot.ingest(key)
    for i: int in 96:
        mission.fixed_tick()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/qa/vl-003-charge.png")
    key.pressed = false
    mission.input_snapshot.ingest(key)
    for i: int in 26:
        mission.fixed_tick()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/qa/vl-003-projectile.png")
    for i: int in 80:
        mission.fixed_tick()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/qa/vl-003-penetration.png")
    var kills: int = mission.projectiles.damage.kills
    print("WEAPON_RANGE kills=", kills, " sixth_hp=", mission.projectiles.damage.groups[6].hp, " bullets=", mission.projectiles.active_count)
    mission.queue_free()
    await process_frame
    quit(0 if kills == 5 else 1)
