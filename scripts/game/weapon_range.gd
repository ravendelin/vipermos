extends Node2D
## Explicit development fixture, not campaign enemies or release art.
@onready var projectiles: Node2D = $"../Projectiles"

func _ready() -> void:
    reset_targets()

func reset_targets() -> void:
    projectiles.clear()
    for i: int in 6:
        var group := i + 1
        projectiles.damage.register(group, 56)
        projectiles.world.add_circle(group, group, Vector2(320 + 40 * i,180), 10)
    projectiles.damage.register(10, 56)
    projectiles.world.add_circle(10, 10, Vector2(480,100), 14)
    projectiles.world.add_box(11, 10, Rect2(460,83,5,34), "armor")
    projectiles.world.add_box(20, -1, Rect2(410,250,8,46))
    if not projectiles.damage.damaged.is_connected(_on_damage):
        projectiles.damage.damaged.connect(_on_damage)
    queue_redraw()

func _on_damage(_group: int, _amount: int) -> void:
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.physical_keycode == KEY_R and event.pressed and not event.echo and not get_tree().paused:
        reset_targets()
        get_viewport().set_input_as_handled()

func _draw() -> void:
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(170,52), Locale.text("range_title"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("85c6d5"))
    draw_string(font, Vector2(170,68), Locale.text("range_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("85c6d5"))
    if not is_instance_valid(projectiles):
        return
    for id: int in projectiles.world.shapes:
        var shape: Dictionary = projectiles.world.shapes[id]
        if shape.kind == "box":
            if shape.category == "armor" and not projectiles.damage.alive(shape.group):
                continue
            var rect := Rect2(shape.position - shape.half_size, shape.half_size * 2)
            draw_rect(rect, Color("87572f"))
            draw_rect(rect, Color("ffdb92"), false, 1)
            for y: int in range(int(rect.position.y)+2, int(rect.end.y), 5):
                draw_line(Vector2(rect.position.x,y), Vector2(rect.end.x,y+2), Color("ffb54f"))
        elif projectiles.damage.alive(shape.group):
            var at: Vector2 = shape.position
            draw_circle(at, shape.radius, Color("274254"))
            draw_arc(at, shape.radius, 0, TAU, 24, Color("85c6d5"), 1)
            draw_circle(at, 4, Color("ffb54f"))
            draw_string(font, at + Vector2(-8,25), str(projectiles.damage.groups[shape.group].hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f3f3d9"))
