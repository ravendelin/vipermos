extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var shell: Control = load("res://scenes/boot.tscn").instantiate()
    root.add_child(shell)
    await process_frame
    shell.show_page("menu")
    await process_frame
    await RenderingServer.frame_post_draw
    var result := root.get_texture().get_image().save_png("res://docs/qa/vl-001-menu.png")
    print("SHELL_CAPTURE result=", result)
    quit(result)
