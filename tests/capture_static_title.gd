extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var scene = load("res://scenes/boot.tscn").instantiate()
    scene.set_script(null)
    root.add_child(scene)
    await process_frame
    await RenderingServer.frame_post_draw
    var result = root.get_texture().get_image().save_png("res://docs/qa/boot-static-preview.png")
    print("STATIC_SCENE_PREVIEW result=", result)
    quit(result)
