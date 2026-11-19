extends RefCounted
## Translating capsule sweeps against moving circles/AABBs. Contact time in [0,1].
const CELL := 64.0
const EPS := 0.000001
var shapes: Dictionary = {}
var cells: Dictionary = {}

func add_circle(id: int, group: int, center: Vector2, radius: float, category: String = "weak") -> void:
    shapes[id] = {"id": id, "group": group, "position": center, "previous": center,
        "radius": radius, "half_size": Vector2.ZERO, "category": category, "kind": "circle"}

func add_box(id: int, group: int, rect: Rect2, category: String = "terrain") -> void:
    var center := rect.get_center()
    shapes[id] = {"id": id, "group": group, "position": center, "previous": center,
        "radius": 0.0, "half_size": rect.size / 2, "category": category, "kind": "box"}

func move_shape(id: int, center: Vector2) -> void:
    shapes[id].previous = shapes[id].position
    shapes[id].position = center

func settle_motion() -> void:
    for shape: Dictionary in shapes.values():
        shape.previous = shape.position

func rebuild() -> void:
    cells.clear()
    for id: int in shapes:
        var shape: Dictionary = shapes[id]
        var extent: Vector2 = shape.half_size if shape.kind == "box" else Vector2.ONE * shape.radius
        var bounds := Rect2(shape.previous - extent, extent * 2).merge(Rect2(shape.position - extent, extent * 2))
        for cell: Vector2i in _cells_for(bounds):
            if not cells.has(cell):
                cells[cell] = []
            cells[cell].append(id)

func candidates(start: Vector2, finish: Vector2, extent: Vector2) -> Array[int]:
    var bounds := Rect2(start - extent, extent * 2).merge(Rect2(finish - extent, extent * 2))
    var found: Dictionary = {}
    for cell: Vector2i in _cells_for(bounds):
        for id: int in cells.get(cell, []):
            found[id] = true
    var ids: Array[int] = []
    for id: int in found:
        ids.append(id)
    ids.sort()
    return ids

func _cells_for(bounds: Rect2) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for x: int in range(floori(bounds.position.x / CELL), floori(bounds.end.x / CELL) + 1):
        for y: int in range(floori(bounds.position.y / CELL), floori(bounds.end.y / CELL) + 1):
            result.append(Vector2i(x,y))
    return result

static func circle_toi(start: Vector2, finish: Vector2, center: Vector2, radius: float) -> float:
    var offset := start - center
    var delta := finish - start
    var c := offset.length_squared() - radius * radius
    if c <= EPS:
        return 0.0
    var a := delta.length_squared()
    if a <= EPS:
        return INF
    var b := offset.dot(delta)
    var discriminant := b * b - a * c
    if discriminant < -EPS:
        return INF
    var t := (-b - sqrt(maxf(0.0, discriminant))) / a
    return clampf(t, 0, 1) if t >= -EPS and t <= 1 + EPS else INF

static func capsule_toi(start: Vector2, finish: Vector2, axis: Vector2, half: float, radius: float) -> float:
    var normal := Vector2(-axis.y, axis.x)
    var p := Vector2(start.dot(axis), start.dot(normal))
    var q := Vector2(finish.dot(axis), finish.dot(normal))
    var closest := Vector2(clampf(p.x, -half, half), 0)
    if p.distance_squared_to(closest) <= radius * radius + EPS:
        return 0.0
    var earliest := minf(circle_toi(p,q,Vector2(-half,0),radius), circle_toi(p,q,Vector2(half,0),radius))
    var dy := q.y - p.y
    if absf(dy) > EPS:
        for side: float in [-radius, radius]:
            var t := (side - p.y) / dy
            if t >= 0 and t <= 1 and absf(lerpf(p.x,q.x,t)) <= half:
                earliest = minf(earliest, t)
    return earliest

static func rounded_polygon_toi(start: Vector2, finish: Vector2, vertices: PackedVector2Array, radius: float) -> float:
    # Minkowski convex hull is CCW. Rounded edges + vertex circles are exact,
    # unlike growing a square AABB by radius (which creates false corner hits).
    if Geometry2D.is_point_in_polygon(start, vertices):
        return 0.0
    var earliest: float = INF
    var delta := finish - start
    for i: int in vertices.size() - 1:
        var a := vertices[i]
        var b := vertices[i + 1]
        var edge := b - a
        var length := edge.length()
        if length <= EPS:
            continue
        var tangent := edge / length
        var normal := Vector2(tangent.y, -tangent.x)
        var distance := (start - a).dot(normal)
        var along := (start - a).dot(tangent)
        if absf(distance) <= radius and along >= 0 and along <= length:
            return 0.0
        var approach := delta.dot(normal)
        if approach < -EPS:
            var t := (radius - distance) / approach
            var projection := (start + delta * t - a).dot(tangent)
            if t >= 0 and t <= 1 and projection >= 0 and projection <= length:
                earliest = minf(earliest, t)
        earliest = minf(earliest, circle_toi(start,finish,a,radius))
    return earliest

static func sweep(start: Vector2, finish: Vector2, axis: Vector2, size: Vector2, shape: Dictionary) -> float:
    var radius := size.y / 2.0
    var half := maxf(0, size.x / 2.0 - radius)
    var relative_start: Vector2 = start - shape.previous
    var relative_end: Vector2 = finish - shape.position
    if shape.kind == "circle":
        return capsule_toi(relative_start, relative_end, axis, half, radius + shape.radius)
    var points := PackedVector2Array()
    var extent: Vector2 = shape.half_size
    for x: float in [-extent.x, extent.x]:
        for y: float in [-extent.y, extent.y]:
            points.append(Vector2(x,y) - axis * half)
            points.append(Vector2(x,y) + axis * half)
    return rounded_polygon_toi(relative_start, relative_end, Geometry2D.convex_hull(points), radius)

func clear() -> void:
    shapes.clear()
    cells.clear()
