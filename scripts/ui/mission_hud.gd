extends CanvasLayer
var top: Label
var bottom: Label
var diagnostics: Label

func _ready() -> void:
    layer = 10
    for y: int in [0, 336]:
        var bar := ColorRect.new()
        bar.position = Vector2(0, y)
        bar.size = Vector2(640, 24)
        bar.color = Color("08111e")
        add_child(bar)
    top = _label(Vector2(8, 3))
    bottom = _label(Vector2(8, 339))
    diagnostics = _label(Vector2(8, 28))
    diagnostics.visible = false

func _label(at: Vector2) -> Label:
    var label := Label.new()
    label.position = at
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", Color("85c6d5"))
    add_child(label)
    return label

func refresh(tick: int, physics_us: int) -> void:
    top.text = Locale.text("hud_top") % [GameState.score, GameState.stage_id, GameState.lives, GameState.rank]
    bottom.text = Locale.text("hud_bottom") % [GameState.weapon, GameState.rank, GameState.speed_index + 1, GameState.bombs]
    diagnostics.text = "tick %d | entities 1 | seed 47021 | FPS %d | physics %d us\nterrain / AEGIS / boss: not implemented (VL-004–007)" % [tick, Engine.get_frames_per_second(), physics_us]
