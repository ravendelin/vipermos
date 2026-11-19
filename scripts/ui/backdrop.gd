extends Node2D

func _draw() -> void:
    # Static development backdrop; fixed world coordinates, no camera drift.
    draw_rect(Rect2(0,24,640,312), Color("090e1c"))
    for i: int in 80:
        draw_rect(Rect2((i * 137 + 31) % 640, 25 + (i * 83) % 308, 1, 1), Color("274254"))

