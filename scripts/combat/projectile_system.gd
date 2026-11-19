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
    if not Weapons.SPECS.has(kind) or direction.is_zero_approx():
        return -1
    if active_count >= (CAPACITY if kind == "full" else CAPACITY - RESERVED):
        rejected += 1
        return -1
    for i: int in CAPACITY:
        var bullet: Dictionary = slots[i]
        if bullet.active:
            continue
        var spec: Dictionary = Weapons.SPECS[kind]
        bullet.merge({"active": true, "id": next_id, "kind": kind, "position": at,
            "previous": at, "axis": direction.normalized(), "speed": spec.speed,
            "size": spec.size, "damage": spec.damage, "remaining": spec.hits,
            "age": 0}, true)
        bullet.groups.clear()
        next_id += 1
        active_count += 1
        return i
    return -1

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
        if bullet.age > 0:
            bullet.position += bullet.axis * bullet.speed / 60.0
        bullet.age += 1
        var size: Vector2 = bullet.size
        var extent: Vector2 = bullet.axis.abs() * maxf(0, (size.x - size.y) / 2) + Vector2.ONE * size.y / 2
        for id: int in world.candidates(bullet.previous, bullet.position, extent):
            var shape: Dictionary = world.shapes[id]
            var time := World.sweep(bullet.previous, bullet.position, bullet.axis, size, shape)
            if time != INF:
                contacts.append({"time": time, "shape": id, "slot": i, "bullet_id": bullet.id,
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
            retire(contact.slot)
        elif not bullet.groups.has(shape.group) and damage.apply(shape.group, bullet.damage):
            bullet.groups[shape.group] = true
            bullet.remaining -= 1
            if bullet.remaining <= 0:
                retire(contact.slot)
    for i: int in CAPACITY:
        var bullet: Dictionary = slots[i]
        if bullet.active and (bullet.age >= LIFE_TICKS or not Rect2(-64,-64,768,488).has_point(bullet.position)):
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
        draw_line(tail, nose, Color("30bfd5"), radius * 2)
        draw_circle(tail, radius, Color("30bfd5"))
        draw_circle(nose, radius, Color("30bfd5"))
        draw_line(tail, nose, Color("f0ffff"), maxf(1, radius * 0.6))
