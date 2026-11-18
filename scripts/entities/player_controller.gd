extends Node2D
## Position stays fractional; only the renderer pixel-snaps.
const SPEEDS := [105.0, 145.0, 190.0]
const HIT_RADIUS := 5.5
var speed_index: int = 1
var velocity := Vector2.ZERO
var show_hitbox: bool = false
var visual_tick: int = 0

func step(snapshot: Dictionary) -> void:
    if snapshot.get("speed_cycle", false):
        speed_index = (speed_index + 1) % SPEEDS.size()
    velocity = Vector2(snapshot.get("move", Vector2.ZERO)).limit_length() * SPEEDS[speed_index]
    position += velocity / 60.0
    position = position.clamp(Vector2(18, 34), Vector2(622, 325))
    visual_tick += 1
    queue_redraw()

func _draw() -> void:
    # Authored development silhouette; final sprite animation is delivered in VL-008.
    draw_set_transform(Vector2.ZERO, deg_to_rad(8.0 * signf(velocity.y)))
    var hull := PackedVector2Array([Vector2(-24,-6), Vector2(-8,-7), Vector2(-2,-12), Vector2(10,-10), Vector2(16,-5), Vector2(23,-3), Vector2(24,0), Vector2(23,3), Vector2(13,6), Vector2(4,12), Vector2(-6,10), Vector2(-11,6), Vector2(-24,5)])
    draw_colored_polygon(hull, Color("85a8b4"))
    draw_colored_polygon(PackedVector2Array([Vector2(-15,-4),Vector2(0,-8),Vector2(14,-3),Vector2(18,0),Vector2(-10,1)]), Color("d6e2db"))
    draw_rect(Rect2(3,-6,9,4), Color("205f95"))
    draw_line(Vector2(-18,4), Vector2(8,7), Color("274254"), 2)
    for y: int in [-3, 3]:
        draw_line(Vector2(-25,y), Vector2(-30 - (visual_tick / 5) % 4,y), Color("30bfd5"), 2)
    draw_set_transform(Vector2.ZERO)
    if show_hitbox:
        draw_arc(Vector2.ZERO, HIT_RADIUS, 0, TAU, 24, Color("f3f3d9"))
        draw_colored_polygon(PackedVector2Array([Vector2(0,-2),Vector2(2,0),Vector2(0,2),Vector2(-2,0)]), Color.WHITE)
