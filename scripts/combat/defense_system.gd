extends Node2D
## Hostile sweeps share geometry with friendly shots. Shields do not own damage.
const World = preload("res://scripts/combat/collision_world.gd")
const CAPACITY := 512
var slots: Array[Dictionary] = []
var invulnerability: int = 0
var dead: bool = false
var assist: bool = false
var hits: int = 0
var blocks: int = 0
var next_id: int = 1
var active_count: int = 0

func _init() -> void:
    for i: int in CAPACITY:
        slots.append({"active":false})

func spawn(at: Vector2, velocity: Vector2, blockable: bool = true) -> int:
    for i: int in CAPACITY:
        if not slots[i].active:
            slots[i].merge({"active":true,"position":at,"previous":at,"velocity":velocity,"blockable":blockable,"radius":3.0 if blockable else 7.0,"age":0,"id":next_id},true)
            next_id += 1
            active_count += 1
            return i
    return -1

func remove(index: int) -> void:
    if slots[index].active:
        slots[index].active = false
        active_count -= 1

func hit(solid: bool = false) -> void:
    if dead or (invulnerability > 0 and not solid):
        return
    hits += 1
    if assist and not solid:
        assist = false
        invulnerability = 90
    else:
        dead = true

func step(player_previous: Vector2, player_position: Vector2, shields: Array, world: RefCounted, hazards: Array = []) -> void:
    invulnerability = maxi(0,invulnerability-1)
    # Terrain/body hazards cannot be retroactively blocked by shield or bomb.
    if world.solid_hit(player_previous,player_position,5.5):
        hit(true)
    for hazard: Dictionary in hazards:
        if hazard.get("active",true) and World.sweep(player_previous,player_position,Vector2.RIGHT,Vector2(11,11),hazard) != INF:
            hit(hazard.get("solid",false))
    var ship := {"kind":"circle","position":player_position,"previous":player_previous,"radius":5.5}
    for i: int in CAPACITY:
        var bullet: Dictionary = slots[i]
        if not bullet.active:
            continue
        bullet.previous = bullet.position
        if bullet.age > 0:
            bullet.position += bullet.velocity/60.0
        bullet.age += 1
        var first := INF
        var priority := 99
        var size: Vector2 = Vector2.ONE*bullet.radius*2
        for shape: Dictionary in world.shapes.values():
            if shape.category == "terrain":
                var time := World.sweep(bullet.previous,bullet.position,Vector2.RIGHT,size,shape)
                if time < first:
                    first = time
                    priority = 0
        if bullet.blockable:
            for shield: Dictionary in shields:
                var time := World.sweep(bullet.previous,bullet.position,Vector2.RIGHT,size,shield)
                if time < first or (is_equal_approx(time,first) and priority > 1):
                    first = time
                    priority = 1
        var ship_time := World.sweep(bullet.previous,bullet.position,Vector2.RIGHT,size,ship)
        if ship_time < first and not is_equal_approx(ship_time,first):
            first = ship_time
            priority = 2
        if first != INF:
            if priority == 1:
                blocks += 1
            elif priority == 2:
                hit()
            remove(i)
        elif bullet.age >= (420 if bullet.blockable else 480) or not Rect2(-80,-64,800,488).has_point(bullet.position):
            remove(i)
    queue_redraw()

func clear_visible() -> void:
    for i: int in CAPACITY:
        if slots[i].active and Rect2(0,24,640,312).has_point(slots[i].position):
            remove(i)
    queue_redraw()

func reset(shield: bool = false) -> void:
    for i: int in CAPACITY:
        remove(i)
    invulnerability = 0
    dead = false
    assist = shield
    hits = 0
    blocks = 0
    next_id = 1
    queue_redraw()

func _draw() -> void:
    for bullet: Dictionary in slots:
        if not bullet.active:
            continue
        if bullet.blockable:
            draw_circle(bullet.position,3,Color("ff537c"))
            draw_circle(bullet.position,1,Color.WHITE)
        else:
            draw_arc(bullet.position,7,0,TAU,3,Color("ff537c"),2)
            draw_circle(bullet.position,4,Color("300d20"))
