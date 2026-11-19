extends Node2D
const World = preload("res://scripts/combat/collision_world.gd")
const Damage = preload("res://scripts/combat/damage_resolver.gd")
const Weapons = preload("res://scripts/combat/weapon_controller.gd")
const CAPACITY := 192
const RESERVED := 8
const LIFE_TICKS := 240
var world := World.new()
var damage := Damage.new()
var slots: Array[Dictionary] = []
var active_count: int = 0
var next_id: int = 1
var rejected: int = 0
var debug_paths: bool = false

func _init() -> void:
    for i: int in CAPACITY:
        slots.append({"active": false, "groups": {}})

func spawn(kind: String, at: Vector2, direction: Vector2 = Vector2.RIGHT) -> int:
    if not Weapons.SPECS.has(kind):
        return -1
    return spawn_spec(kind,at,direction,Weapons.SPECS[kind])

func spawn_spec(kind: String, at: Vector2, direction: Vector2, spec: Dictionary) -> int:
    if direction.is_zero_approx():
        return -1
    if active_count >= (CAPACITY if kind == "full" else CAPACITY - RESERVED):
        rejected += 1
        return -1
    for i: int in CAPACITY:
        var bullet: Dictionary = slots[i]
        if bullet.active:
            continue
        bullet.merge({"active": true, "id": next_id, "kind": kind, "position": at,
            "previous": at, "origin": at, "axis": direction.normalized(), "speed": spec.speed,
            "size": spec.get("size",Vector2(8,4)), "damage": spec.damage, "remaining": spec.get("hits",1),
            "age": 0, "ttl": spec.get("ttl",LIFE_TICKS), "bounces": spec.get("bounces",0),
            "wave": spec.get("wave",false), "wave_phase": spec.get("wave_phase",0.0),
            "turn_rate": spec.get("turn_rate",0.0), "sector": spec.get("sector",90.0),
            "port_axis": spec.get("port_axis",direction.normalized()), "target": -1,
            "range": spec.get("range",INF), "reacquire": 0},true)
        bullet.groups.clear()
        next_id += 1
        active_count += 1
        return i
    return -1

func _steer(bullet: Dictionary) -> void:
    if bullet.turn_rate <= 0:
        return
    bullet.reacquire = maxi(0,bullet.reacquire-1)
    var target_valid: bool = world.shapes.has(bullet.target) and damage.alive(world.shapes[bullet.target].group) and damage.groups[world.shapes[bullet.target].group].get("vulnerable",true)
    if not target_valid and bullet.reacquire == 0:
        var nearest: float = bullet.range
        bullet.target = -1
        for id: int in world.shapes:
            var shape: Dictionary = world.shapes[id]
            if shape.category != "weak" or not damage.alive(shape.group) or not damage.groups[shape.group].get("vulnerable",true):
                continue
            var offset: Vector2 = shape.position-bullet.position
            if absf(Vector2(bullet.port_axis).angle_to(offset)) <= deg_to_rad(bullet.sector) and offset.length() <= nearest and (offset.length() < nearest or bullet.target < 0 or id < bullet.target):
                nearest = offset.length()
                bullet.target = id
        bullet.reacquire = 9
    if not world.shapes.has(bullet.target) or not damage.alive(world.shapes[bullet.target].group) or not damage.groups[world.shapes[bullet.target].group].get("vulnerable",true):
        return
    var desired: Vector2 = world.shapes[bullet.target].position-bullet.position
    var turn: float = clampf(Vector2(bullet.axis).angle_to(desired),-deg_to_rad(bullet.turn_rate)/60,deg_to_rad(bullet.turn_rate)/60)
    bullet.axis = Vector2(bullet.axis).rotated(turn)

func _shape_interval(shape: Dictionary, begin: float, end: float) -> Dictionary:
    var result := shape.duplicate()
    result.previous = Vector2(shape.previous).lerp(shape.position,begin)
    result.position = Vector2(shape.previous).lerp(shape.position,end)
    return result

func _paths(bullet: Dictionary, finish: Vector2) -> Array[Dictionary]:
    var paths: Array[Dictionary] = []
    var start: Vector2 = bullet.previous
    var begin := 0.0
    var axis: Vector2 = bullet.axis
    for iteration: int in 3:
        var first := INF
        var obstacle := -1
        var obstacle_shape: Dictionary = {}
        for id: int in world.shapes:
            var shape: Dictionary = world.shapes[id]
            if shape.category not in ["terrain","armor"]:
                continue
            if shape.category == "armor" and damage.groups.has(shape.group) and not damage.alive(shape.group):
                continue
            var moving_shape := _shape_interval(shape,begin,1.0)
            var t := World.sweep(start,finish,axis,bullet.size,moving_shape)
            if t < first or (t == first and id < obstacle):
                first = t
                obstacle = id
                obstacle_shape = moving_shape
        var reflect: bool = obstacle >= 0 and bullet.bounces > 0
        var end: Vector2 = start.lerp(finish,first) if obstacle >= 0 else finish
        var end_time: float = lerpf(begin,1.0,first) if obstacle >= 0 else 1.0
        paths.append({"start":start,"end":end,"axis":axis,"begin":begin,"time":end_time,"obstacle":obstacle,"reflect":reflect})
        if not reflect:
            bullet.position = end
            break
        var normal := World.contact_normal(start,finish,axis,bullet.size,obstacle_shape,first)
        bullet.bounces -= 1
        axis = axis.bounce(normal).normalized()
        var remaining := end.distance_to(finish)
        start = end + normal*0.5
        finish = start + axis*remaining
        begin = end_time
        bullet.axis = axis
        bullet.position = start
    return paths

func retire(index: int) -> void:
    if slots[index].active:
        slots[index].active = false
        slots[index].groups.clear()
        active_count -= 1

func step() -> void:
    world.rebuild()
    var contacts: Array[Dictionary] = []
    for i: int in CAPACITY:
        var bullet: Dictionary = slots[i]
        if not bullet.active:
            continue
        bullet.previous = bullet.position
        var finish: Vector2 = bullet.position
        if bullet.age > 0:
            _steer(bullet)
            finish += bullet.axis * bullet.speed / 60.0
            if bullet.wave:
                finish.y = bullet.origin.y + 12 * (sin(TAU*bullet.age/28.8 + bullet.wave_phase)-sin(bullet.wave_phase))
        bullet.age += 1
        var paths := _paths(bullet,finish)
        for path: Dictionary in paths:
            var size: Vector2 = bullet.size
            var extent: Vector2 = Vector2(path.axis).abs() * maxf(0, (size.x - size.y) / 2) + Vector2.ONE * size.y / 2
            for id: int in world.candidates(path.start,path.end,extent):
                var shape: Dictionary = world.shapes[id]
                var time := World.sweep(path.start,path.end,path.axis,size,_shape_interval(shape,path.begin,path.time))
                if time != INF:
                    contacts.append({"time": lerpf(path.begin,path.time,time), "shape": id, "slot": i, "bullet_id": bullet.id,
                        "reflect": path.reflect and id == path.obstacle,
                        "priority": 0 if shape.category == "terrain" else (1 if shape.category == "armor" else 2)})
    contacts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if a.time != b.time:
            return a.time < b.time
        if a.priority != b.priority:
            return a.priority < b.priority
        if a.shape != b.shape:
            return a.shape < b.shape
        return a.bullet_id < b.bullet_id)
    for contact: Dictionary in contacts:
        var bullet: Dictionary = slots[contact.slot]
        if not bullet.active:
            continue
        var shape: Dictionary = world.shapes[contact.shape]
        if shape.category in ["terrain", "armor"]:
            # Armor belonging to a destroyed group disappears with its owner.
            if shape.category == "armor" and damage.groups.has(shape.group) and not damage.alive(shape.group):
                continue
            if not contact.reflect:
                retire(contact.slot)
        elif not bullet.groups.has(shape.group) and damage.apply(shape.group, bullet.damage):
            bullet.groups[shape.group] = true
            bullet.remaining -= 1
            if bullet.remaining <= 0:
                retire(contact.slot)
    for i: int in CAPACITY:
        var bullet: Dictionary = slots[i]
        if bullet.active and (bullet.age >= bullet.ttl or not Rect2(-64,-64,768,488).has_point(bullet.position)):
            retire(i)
    world.settle_motion()
    queue_redraw()

func clear() -> void:
    for i: int in CAPACITY:
        retire(i)
    world.clear()
    damage.clear()
    next_id = 1
    rejected = 0
    queue_redraw()

func _draw() -> void:
    for bullet: Dictionary in slots:
        if not bullet.active:
            continue
        if debug_paths:
            draw_line(bullet.previous, bullet.position, Color("ffb54f"), 1)
        var radius: float = bullet.size.y / 2.0
        var half: float = (bullet.size.x - bullet.size.y) / 2.0
        var tail: Vector2 = bullet.position - bullet.axis * half
        var nose: Vector2 = bullet.position + bullet.axis * half
        var color := Color("ffb54f") if bullet.kind == "prism" else (Color("79cf73") if bullet.kind in ["ember","missile"] else Color("30bfd5"))
        draw_line(tail, nose, color, radius * 2)
        draw_circle(tail, radius, color)
        draw_circle(nose, radius, color)
        draw_line(tail, nose, Color("f0ffff"), maxf(1, radius * 0.6))
