extends SceneTree
var failures: int = 0

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    root.get_node("GameState").start_run()
    var mission: Node = load("res://scenes/game/mission.tscn").instantiate()
    root.add_child(mission)
    mission.set_physics_process(false)
    for i: int in 120:
        mission.fixed_tick()
    mission.player.show_hitbox = true
    for size: Vector2i in [Vector2i(640,360), Vector2i(1280,720), Vector2i(1100,800)]:
        root.size = size
        await create_timer(0.2).timeout
        await RenderingServer.frame_post_draw
        var logical: Vector2 = root.get_visible_rect().size
        var scale: Vector2 = root.get_final_transform().get_scale()
        print("RESIZE window=", DisplayServer.window_get_size(), " logical=", logical, " scale=", scale, " root_size=", root.size, " screen=", root.get_screen_transform())
        var expected_scale := maxf(1.0, floorf(minf(size.x / 640.0, size.y / 360.0)))
        if not is_equal_approx(scale.x, expected_scale):
            failures += 1
        if logical != Vector2(640,360) or not is_equal_approx(scale.x, scale.y) or not is_equal_approx(scale.x, roundf(scale.x)):
            failures += 1
        var path := "res://docs/qa/vl-002-%dx%d.png" % [size.x, size.y]
        if root.get_texture().get_image().save_png(path) != OK:
            failures += 1
    root.mode = Window.MODE_FULLSCREEN
    await create_timer(0.3).timeout
    print("FULLSCREEN logical=", root.get_visible_rect().size, " scale=", root.get_final_transform().get_scale())
    if root.get_visible_rect().size != Vector2(640,360):
        failures += 1
    root.mode = Window.MODE_WINDOWED
    root.size = Vector2i(1280,720)
    mission.pause()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://docs/qa/vl-002-pause.png")
    mission.resume()
    mission.queue_free()
    await process_frame
    print("VISUAL failures=", failures)
    quit(1 if failures else 0)
