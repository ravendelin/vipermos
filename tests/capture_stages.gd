extends SceneTree
func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    root.get_node("GameState").start_run()
    var mission: Node = load("res://scenes/game/stage_preview.tscn").instantiate()
    root.add_child(mission)
    mission.set_physics_process(false)
    for entry: Array in [[1,1680],[4,1500],[7,1152]]:
        mission.load_stage("res://data/stages/s%02d.json" % entry[0])
        mission.preview_checkpoint(entry[1])
        # Preview beam at its original warning scope, not a historical restore.
        mission.recovery.checkpoint_tick = 0
        mission.fixed_tick()
        await process_frame
        await RenderingServer.frame_post_draw
        var result := root.get_texture().get_image().save_png("res://docs/qa/vl-005-s%02d.png" % entry[0])
        print("STAGE_CAPTURE S%02d tick=%d shapes=%d result=%d" % [entry[0],mission.stage_tick,mission.projectiles.world.shapes.size(),result])
        if result != OK:
            quit(1)
            return
    mission.queue_free()
    await process_frame
    quit(0)
