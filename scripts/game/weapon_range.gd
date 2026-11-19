extends Node2D
## Explicit development fixture, not campaign enemies or release art.
@export var module_lab: bool = false
var lab_tick: int = 0
var pickup_serial: int = 0
var emitter_enabled: bool = false
@onready var projectiles: Node2D = $"../Projectiles"

func _ready() -> void:
    reset_targets()

func reset_targets() -> void:
    projectiles.clear()
    emitter_enabled = false
    if module_lab and get_parent().get_parent().is_node_ready():
        var mission: Node = get_parent().get_parent()
        mission.defense.reset(GameState.difficulty == "assist")
        mission.support.reset()
        mission.pickups.clear()
        mission.aegis.reset(mission.player.position)
        mission.set_phase("SCROLL")
        mission.intro_label.hide()
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
    if module_lab and event is InputEventKey and event.pressed and not event.echo and not get_tree().paused:
        var mission: Node = get_parent().get_parent()
        var pickup_keys := {KEY_1:"arc",KEY_2:"prism",KEY_3:"ember",KEY_4:"bit",KEY_5:"missile",KEY_6:"bomb",KEY_7:"life"}
        if pickup_keys.has(event.physical_keycode):
            pickup_serial += 1
            mission.pickups.spawn(pickup_keys[event.physical_keycode],mission.player.position+Vector2(70,0),"lab:%d" % pickup_serial)
        elif event.physical_keycode == KEY_T:
            emitter_enabled = not emitter_enabled
            lab_tick = 0
        elif event.physical_keycode == KEY_H:
            mission.defense.spawn(Vector2(620,mission.player.position.y),Vector2(-110,0),false)
    if event is InputEventKey and event.physical_keycode == KEY_R and event.pressed and not event.echo and not get_tree().paused:
        reset_targets()
        get_viewport().set_input_as_handled()

func _draw() -> void:
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(170,52), Locale.text("range_title"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("85c6d5"))
    draw_string(font, Vector2(170,68), Locale.text("range_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("85c6d5"))
    if module_lab:
        draw_string(font,Vector2(170,84),Locale.text("lab_hint"),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("85c6d5"))
        if emitter_enabled:
            var warn := lab_tick % 150 >= 120
            for at: Vector2 in [Vector2(620,180),Vector2(20,230)]:
                draw_circle(at,6,Color("ff537c") if warn else Color("274254"))
                if warn:
                    draw_arc(at,10,0,TAU,16,Color("ffb54f"),1)
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

func simulation_tick(_tick: int) -> void:
    if not module_lab or not emitter_enabled:
        return
    lab_tick += 1
    if lab_tick % 150 == 0:
        var defense: Node = get_parent().get_parent().defense
        defense.spawn(Vector2(620,180),Vector2(-150,0))
        defense.spawn(Vector2(20,230),Vector2(150,0))
    queue_redraw()
