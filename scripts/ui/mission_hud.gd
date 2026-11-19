extends CanvasLayer
var top: Label
var bottom: Label
var diagnostics: Label
var module_status: Label
var charge_bar: ProgressBar

func _ready() -> void:
    layer = 10
    for y: int in [0, 336]:
        var bar := ColorRect.new()
        bar.position = Vector2(0, y)
        bar.size = Vector2(640, 24)
        bar.color = Color("08111e")
        add_child(bar)
    top = _label(Vector2(8, 3))
    module_status = _label(Vector2(385,3))
    module_status.add_theme_font_size_override("font_size",10)
    bottom = _label(Vector2(158, 339))
    var charge_label := _label(Vector2(8,339))
    charge_label.text = Locale.text("charge_label")
    diagnostics = _label(Vector2(8, 28))
    diagnostics.visible = false
    charge_bar = ProgressBar.new()
    charge_bar.position = Vector2(59,343)
    charge_bar.size = Vector2(83,9)
    charge_bar.max_value = 96
    charge_bar.show_percentage = false
    var fill := StyleBoxFlat.new()
    fill.bg_color = Color("30bfd5")
    charge_bar.add_theme_stylebox_override("fill", fill)
    add_child(charge_bar)
    for threshold: int in [45,96]:
        var marker := ColorRect.new()
        marker.position = Vector2(59 + 83 * threshold / 96.0,342)
        marker.size = Vector2(1,11)
        marker.color = Color("f3f3d9")
        add_child(marker)

func _label(at: Vector2) -> Label:
    var label := Label.new()
    label.position = at
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", Color("85c6d5"))
    add_child(label)
    return label

func refresh(tick: int, physics_us: int, charge: int = 0, bullets: int = 0, module_state: String = "ATTACHED_FRONT", hostile: int = 0) -> void:
    top.text = Locale.text("hud_top") % [GameState.score, GameState.stage_id, GameState.lives, GameState.rank]
    bottom.text = Locale.text("hud_bottom") % [GameState.weapon, GameState.rank, GameState.speed_index + 1, GameState.bombs]
    charge_bar.value = charge
    module_status.text = Locale.text("aegis_" + module_state.to_lower()) + (" +" if GameState.assist_shield else "")
    diagnostics.text = "tick %d | bullets %d / 192 | seed 47021 | FPS %d | physics %d us\nhostile %d | bits %d | missiles %d | stage/boss pending" % [tick, bullets, Engine.get_frames_per_second(), physics_us, hostile, GameState.bits, GameState.missile_rank]
