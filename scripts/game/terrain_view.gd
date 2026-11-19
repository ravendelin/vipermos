extends Node2D
var profile: RefCounted
var world: RefCounted
var samples: Array[Vector3] = []
var render_shapes: Array[Dictionary] = []
var warnings: Array[Dictionary] = []

func sync_geometry() -> void:
    samples.assign(profile.samples)
    render_shapes.clear()
    for id: int in profile.installed:
        if world.shapes.has(id):
            render_shapes.append(world.shapes[id])
    warnings.assign(profile.warnings)
    queue_redraw()

func _draw() -> void:
    if samples.is_empty():
        return
    var upper := PackedVector2Array()
    var lower := PackedVector2Array()
    for sample: Vector3 in samples:
        upper.append(Vector2(sample.x,sample.y))
        lower.append(Vector2(sample.x,sample.z))
    var has_top := false
    var has_bottom := false
    for point: Vector2 in upper:
        has_top = has_top or point.y>24
    for point: Vector2 in lower:
        has_bottom = has_bottom or point.y<336
    for shape: Dictionary in render_shapes:
        if shape.kind == "polygon":
            var polygon := PackedVector2Array()
            for i: int in shape.vertices.size()-1:
                polygon.append(shape.vertices[i]+shape.position)
            draw_colored_polygon(polygon,Color("1d3044"))
    if has_top:
        draw_polyline(upper,Color("db9450"),1)
    if has_bottom:
        draw_polyline(lower,Color("db9450"),1)
    for shape: Dictionary in render_shapes:
        if shape.kind != "box":
            continue
        var rect := Rect2(shape.position-shape.half_size,shape.half_size*2)
        rect = rect.intersection(Rect2(-80,24,800,312))
        if not rect.has_area():
            continue
        draw_rect(rect,Color("41576a"))
        draw_rect(rect,Color("db9450"),false,1)
        for y: int in range(int(rect.position.y)+5,int(rect.end.y),8):
            draw_line(Vector2(rect.position.x+2,y),Vector2(rect.end.x-2,y),Color("71899a"),1)
    for warning: Dictionary in warnings:
        draw_line(Vector2(632,warning.y-14),Vector2(632,warning.y+14),Color("ffb54f"),2)
        draw_polyline(PackedVector2Array([Vector2(628,warning.y-4),Vector2(624,warning.y),Vector2(628,warning.y+4)]),Color("ffb54f"),1)
