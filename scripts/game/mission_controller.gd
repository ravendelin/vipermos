extends Node2D
const Snapshot = preload("res://scripts/game/input_snapshot.gd")
var input_snapshot := Snapshot.new()
var stage_tick: int = 0
var intro_ticks: int = 120
var phase: String = "INTRO"
var charge_ticks: int = 0
var physics_us: int = 0
var leaving: bool = false
@onready var player: Node2D = $World/Player
@onready var hud: CanvasLayer = $HUD
@onready var overlay: CanvasLayer = $Overlay
var pause_panel: VBoxContainer
var intro_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    player.position = Vector2(96,180)
    player.speed_index = GameState.speed_index
    input_snapshot.suppress_until_release()
    Input.joy_connection_changed.connect(_joy_changed)
    overlay.layer = 20
    intro_label = Label.new()
    intro_label.position = Vector2(125, 140)
    intro_label.text = Locale.text("movement_build")
    intro_label.add_theme_font_size_override("font_size", 16)
    overlay.add_child(intro_label)
    pause_panel = VBoxContainer.new()
    pause_panel.position = Vector2(220,100)
    pause_panel.size.x = 200
    overlay.add_child(pause_panel)
    for entry: Array in [["resume", _pause_primary], ["quit_to_menu", _confirm_quit]]:
        var button := Button.new()
        button.text = Locale.text(entry[0])
        button.pressed.connect(entry[1])
        pause_panel.add_child(button)
    pause_panel.hide()
    hud.refresh(stage_tick, physics_us)
    queue_redraw()

func _input(event: InputEvent) -> void:
    input_snapshot.ingest(event)
    if event.is_action_pressed("pause") and not event.is_echo():
        if get_tree().paused:
            _pause_primary()
        else:
            pause()
        get_viewport().set_input_as_handled()
    elif get_tree().paused and event.is_action_pressed("ui_cancel"):
        _pause_primary()
        get_viewport().set_input_as_handled()
    elif event is InputEventKey and event.physical_keycode == KEY_F3 and event.pressed and not event.echo and OS.is_debug_build():
        hud.diagnostics.visible = not hud.diagnostics.visible
        player.show_hitbox = hud.diagnostics.visible
        player.queue_redraw()

func _physics_process(_delta: float) -> void:
    fixed_tick()

func fixed_tick() -> void:
    if get_tree().paused or leaving:
        return
    var started := Time.get_ticks_usec()
    var snapshot: Dictionary = input_snapshot.sample()
    if phase == "INTRO":
        intro_ticks -= 1
        if intro_ticks <= 0:
            phase = "SCROLL"
            intro_label.hide()
            input_snapshot.suppress_until_release()
    elif phase == "SCROLL":
        player.step(snapshot)
        GameState.speed_index = player.speed_index
        stage_tick += 1
    physics_us = Time.get_ticks_usec() - started
    hud.refresh(stage_tick, physics_us)

func pause() -> void:
    if leaving:
        return
    charge_ticks = 0
    input_snapshot.suppress_until_release()
    get_tree().paused = true
    pause_panel.show()
    pause_panel.get_child(0).grab_focus()

func resume() -> void:
    charge_ticks = 0
    input_snapshot.suppress_until_release()
    _reset_pause_buttons()
    pause_panel.hide()
    get_tree().paused = false

func _confirm_quit() -> void:
    pause_panel.get_child(0).text = Locale.text("cancel")
    var quit_button: Button = pause_panel.get_child(1)
    quit_button.text = Locale.text("confirm_quit")
    quit_button.pressed.disconnect(_confirm_quit)
    quit_button.pressed.connect(return_to_menu)
    pause_panel.get_child(0).grab_focus()

func _reset_pause_buttons() -> void:
    pause_panel.get_child(0).text = Locale.text("resume")
    var quit_button: Button = pause_panel.get_child(1)
    quit_button.text = Locale.text("quit_to_menu")
    if quit_button.pressed.is_connected(return_to_menu):
        quit_button.pressed.disconnect(return_to_menu)
        quit_button.pressed.connect(_confirm_quit)

func return_to_menu() -> void:
    if leaving:
        return
    leaving = true
    charge_ticks = 0
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/boot.tscn")

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
        input_snapshot.clear_devices()
        pause()

func _joy_changed(device: int, connected: bool) -> void:
    if not connected:
        input_snapshot.disconnect_pad(device)
        pause()

func _exit_tree() -> void:
    get_tree().paused = false

func _draw() -> void:
    # Static development backdrop; fixed world coordinates, no camera drift.
    draw_rect(Rect2(0,24,640,312), Color("090e1c"))
    for i: int in 80:
        draw_rect(Rect2((i * 137 + 31) % 640, 25 + (i * 83) % 308, 1, 1), Color("274254"))

func _pause_primary() -> void:
    if pause_panel.get_child(1).pressed.is_connected(return_to_menu):
        _reset_pause_buttons()
        pause_panel.get_child(0).grab_focus()
    else:
        resume()
