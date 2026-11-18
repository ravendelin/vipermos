extends Control
## Navigable foundation shell; no pretend campaign or unfinished combat scene.
var page: String = ""
var panel: VBoxContainer
var buttons: Array[Button] = []
var last_menu_index: int = 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    if DisplayServer.get_name() != "headless":
        DisplayServer.window_set_min_size(Vector2i(640, 360))
    var theme_resource := Theme.new()
    theme_resource.default_font_size = 12
    theme_resource.set_color("font_color", "Label", Color("85c6d5"))
    theme_resource.set_color("font_color", "Button", Color("f3f3d9"))
    for state: String in ["normal", "hover", "pressed", "focus"]:
        var style := StyleBoxFlat.new()
        style.bg_color = Color("172d40") if state != "normal" else Color("08111e")
        style.border_color = Color("85c6d5") if state == "focus" else Color("274254")
        style.set_border_width_all(1)
        style.content_margin_top = 3
        style.content_margin_bottom = 3
        theme_resource.set_stylebox(state, "Button", style)
    theme = theme_resource
    panel = VBoxContainer.new()
    panel.position = Vector2(140, 28)
    panel.size = Vector2(360, 300)
    panel.add_theme_constant_override("separation", 5)
    add_child(panel)
    show_page("title")
    print("VOID_LANTERN_BOOT_OK viewport=640x360 physics=60 page=title")

func _clear() -> void:
    for child: Node in panel.get_children():
        panel.remove_child(child)
        child.queue_free()
    buttons.clear()

func _label(key: String, font_size: int = 12) -> void:
    var label := Label.new()
    label.text = Locale.text(key)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    panel.add_child(label)

func _button(key: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = Locale.text(key)
    button.custom_minimum_size.y = 25
    button.pressed.connect(callback)
    panel.add_child(button)
    buttons.append(button)

func show_page(next: String) -> void:
    page = next
    _clear()
    _label("title", 30)
    _label("tagline")
    if page == "title":
        _label("build")
        _button("prompt", show_page.bind("menu"))
    elif page == "menu":
        for key: String in ["campaign", "practice", "scores", "options", "credits", "quit"]:
            _button(key, _select.bind(key))
    elif page == "quit":
        _label("quit_question", 18)
        _button("cancel", show_page.bind("menu"))
        _button("quit", get_tree().quit)
    else:
        _label(page, 18)
        _label("credits_body" if page == "credits" else ("pending" if page == "campaign" else "future"))
        _button("back", show_page.bind("menu"))
    _label("hint", 9)
    for i: int in buttons.size():
        buttons[i].focus_neighbor_top = buttons[i].get_path_to(buttons[(i - 1 + buttons.size()) % buttons.size()])
        buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(buttons[(i + 1) % buttons.size()])
    buttons[mini(last_menu_index, buttons.size() - 1) if page == "menu" else 0].grab_focus()

func _select(key: String) -> void:
    last_menu_index = ["campaign", "practice", "scores", "options", "credits", "quit"].find(key)
    show_page(key)

func _input(event: InputEvent) -> void:
    if event.is_echo():
        return
    if page == "title" and ((event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed()):
        show_page("menu")
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("ui_cancel"):
        show_page("quit" if page == "menu" else "menu")
        get_viewport().set_input_as_handled()
