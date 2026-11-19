extends Node2D
var active: Array[Dictionary] = []
var display: Array[Dictionary] = []

func update(data: Dictionary, tick: int, checkpoint: int, terrain: RefCounted, world: RefCounted) -> void:
    active.clear()
    display.clear()
    for beam: Dictionary in data.beams:
        if beam.at_tick < checkpoint:
            continue
        var age: int = tick-int(beam.at_tick)
        if age < 0 or age >= int(beam.warning_ticks+beam.active_ticks):
            continue
        var left: float = terrain.clip_left(world,Vector2(beam.x,beam.y),beam.width)
        var rect := Rect2(left,beam.y-beam.width/2,beam.x-left,beam.width)
        var firing: bool = age >= beam.warning_ticks
        display.append({"rect":rect,"active":firing})
        if firing and rect.size.x>0:
            active.append({"kind":"box","position":rect.get_center(),"previous":rect.get_center(),"half_size":rect.size/2,"active":true,"solid":false})
    queue_redraw()

func clear() -> void:
    active.clear()
    display.clear()
    queue_redraw()

func _draw() -> void:
    for beam: Dictionary in display:
        var rect: Rect2 = beam.rect
        if beam.active:
            draw_rect(rect,Color("ff537c"))
            draw_line(Vector2(rect.position.x,rect.get_center().y),Vector2(rect.end.x,rect.get_center().y),Color.WHITE,2)
        else:
            for x: int in range(int(rect.position.x),int(rect.end.x),12):
                draw_line(Vector2(x,rect.get_center().y),Vector2(minf(x+6,rect.end.x),rect.get_center().y),Color("ffb54f"),1)
