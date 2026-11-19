extends Node2D
## A single module; transitions never create shield nodes.
const ATTACHED := ["ATTACHED_FRONT","ATTACHED_REAR"]
var state: String = "ATTACHED_FRONT"
var desired_side: int = 1
var launch_side: int = 1
var previous := Vector2.ZERO
var state_ticks: int = 0
var debounce: int = 0
var shot_cooldown: int = 0
var contact_cooldowns: Dictionary = {}
var shield_active: bool = true
var fallback_hidden: bool = false
var swap_origin := Vector2.ZERO
var weapon_type: String = "ARC"
var rank: int = 1

func reset(at: Vector2) -> void:
    state = "ATTACHED_FRONT"
    desired_side = 1
    launch_side = 1
    position = at + Vector2(35,0)
    previous = position
    state_ticks = 0
    debounce = 0
    shot_cooldown = 0
    shield_active = true
    fallback_hidden = false
    contact_cooldowns.clear()
    queue_redraw()

func port(ship: Vector2, side: int) -> Vector2:
    return ship + Vector2(35*side,0)

func port_safe(ship: Vector2, side: int, world: RefCounted) -> bool:
    var at := port(ship,side)
    return at.x >= 13 and at.x <= 627 and not world.solid_hit(at,at,13)

func change_state(next: String) -> void:
    state = next
    state_ticks = 0
    debounce = 12

func dock_safe(ship: Vector2, world: RefCounted, nearest: bool = false) -> void:
    if nearest and port_safe(ship,-desired_side,world) and position.distance_squared_to(port(ship,-desired_side)) < position.distance_squared_to(port(ship,desired_side)):
        desired_side = -desired_side
    if port_safe(ship,desired_side,world):
        position = port(ship,desired_side)
        change_state("ATTACHED_FRONT" if desired_side == 1 else "ATTACHED_REAR")
    elif port_safe(ship,-desired_side,world):
        desired_side = -desired_side
        position = port(ship,desired_side)
        change_state("ATTACHED_FRONT" if desired_side == 1 else "ATTACHED_REAR")
    else:
        position = ship
        change_state("STOWED")
    # Fallback is a teleport while disabled, not a swept shield through walls.
    previous = position

func step(ship: Vector2, snapshot: Dictionary, projectiles: Node2D, kind: String, level: int) -> void:
    weapon_type = kind
    rank = level
    var world: RefCounted = projectiles.world
    previous = position
    debounce = maxi(0,debounce-1)
    shot_cooldown = maxi(0,shot_cooldown-1)
    for group: int in contact_cooldowns.keys():
        if not projectiles.damage.alive(group):
            contact_cooldowns.erase(group)
        else:
            contact_cooldowns[group] -= 1
            if contact_cooldowns[group] <= 0:
                contact_cooldowns.erase(group)
    if state in ATTACHED and not port_safe(ship,desired_side,world):
        change_state("STOWED")
    if debounce == 0:
        if snapshot.get("module_side",false) and state != "SWAP":
            if state in ATTACHED:
                if port_safe(ship,-desired_side,world):
                    desired_side = -desired_side
                    swap_origin = position-ship
                    change_state("SWAP")
            else:
                desired_side = -desired_side
                debounce = 12
        elif snapshot.get("module_toggle",false):
            if state in ATTACHED:
                launch_side = desired_side
                change_state("LAUNCH")
            elif state in ["LAUNCH","FREE"]:
                change_state("RETURN")
    match state:
        "ATTACHED_FRONT", "ATTACHED_REAR":
            position = port(ship,desired_side)
        "SWAP":
            var t := minf(1,(state_ticks+1)/12.0)
            position = ship + swap_origin.rotated(PI*t)
            if state_ticks+1 >= 12:
                dock_safe(ship,world)
        "LAUNCH", "FREE":
            var next := position + Vector2(launch_side*330.0/60,0) if state == "LAUNCH" else position.move_toward(Vector2(clampf(ship.x+launch_side*160,24,616),ship.y),165.0/60)
            if world.solid_hit(position,next,13) or next.x < 0 or next.x > 640 or next.y < 24 or next.y > 336:
                change_state("RETURN")
            else:
                position = next
                if state == "LAUNCH" and state_ticks+1 >= 21:
                    change_state("FREE")
        "RETURN":
            var target := port(ship,desired_side)
            var next := position.move_toward(target,420.0/60)
            if world.solid_hit(position,next,13):
                shield_active = false
            elif shield_active:
                position = next
                if position.distance_to(target) < 0.01 and port_safe(ship,desired_side,world):
                    dock_safe(ship,world)
            if state == "RETURN" and state_ticks+1 >= 24:
                change_state("FALLBACK")
        "FALLBACK":
            if state_ticks >= 9:
                dock_safe(ship,world,true)
        "STOWED":
            position = ship
            if (state_ticks+1) % 6 == 0 and (port_safe(ship,desired_side,world) or port_safe(ship,-desired_side,world)):
                dock_safe(ship,world)
    fallback_hidden = state == "FALLBACK"
    if state != "RETURN":
        shield_active = state in ATTACHED or state in ["LAUNCH","FREE"]
    visible = not fallback_hidden
    if shield_active:
        _contact(projectiles)
    if snapshot.get("fire",false) and not snapshot.get("charge",false) and shot_cooldown == 0:
        if state in ATTACHED:
            _fire_attached(projectiles)
        elif state in ["LAUNCH","FREE"]:
            projectiles.spawn_spec("detached",position,Vector2(launch_side,0),{"damage":3,"speed":360.0})
            shot_cooldown = 18
    state_ticks += 1
    queue_redraw()

func _contact(projectiles: Node2D) -> void:
    var world: RefCounted = projectiles.world
    var ids: Array = world.shapes.keys()
    ids.sort()
    for id: int in ids:
        var shape: Dictionary = world.shapes[id]
        if shape.category == "weak" and not contact_cooldowns.has(shape.group) and world.sweep(previous,position,Vector2.RIGHT,Vector2(20,20),shape) != INF:
            if projectiles.damage.apply(shape.group,5):
                contact_cooldowns[shape.group] = 12

func _fire_attached(projectiles: Node2D) -> void:
    var angles: Array = []
    match weapon_type:
        "ARC":
            var offsets: Array = [0] if rank == 1 else ([-7,7] if rank == 2 else [-8,0,8])
            for i: int in offsets.size():
                projectiles.spawn_spec("arc",position+Vector2(0,offsets[i]),Vector2(desired_side,0),{"damage":3,"speed":340.0,"wave_phase":TAU*i/offsets.size(),"wave":true})
            shot_cooldown = 15 if rank == 3 else 17
        "PRISM":
            angles = [-23,23] if rank == 1 else ([-25,0,25] if rank == 2 else [-35,-17,0,17,35])
            for angle: float in angles:
                projectiles.spawn_spec("prism",position,Vector2(cos(deg_to_rad(angle))*desired_side,sin(deg_to_rad(angle))),{"damage":3,"speed":390.0,"bounces":2})
            shot_cooldown = 29 if rank == 1 else 27
        "EMBER":
            angles = [-35,35] if rank < 3 else [-40,0,40]
            for angle: float in angles:
                projectiles.spawn_spec("ember",position,Vector2(cos(deg_to_rad(angle))*desired_side,sin(deg_to_rad(angle))),{"damage":2 if rank == 1 else 4,"speed":260.0,"turn_rate":160.0,"sector":80.0,"port_axis":Vector2(desired_side,0)})
            shot_cooldown = [39,35,33][rank-1]

func _draw() -> void:
    var color := Color("30bfd5") if weapon_type == "ARC" else (Color("ffb54f") if weapon_type == "PRISM" else Color("79cf73"))
    var scale_factor := 0.45 if state == "STOWED" else 1.0
    draw_set_transform(Vector2.ZERO,0,Vector2.ONE*scale_factor)
    draw_colored_polygon(PackedVector2Array([Vector2(-9,0),Vector2(0,-12),Vector2(9,0),Vector2(0,12)]),Color("274254"))
    draw_polyline(PackedVector2Array([Vector2(-9,0),Vector2(0,-12),Vector2(9,0),Vector2(0,12),Vector2(-9,0)]),color,2)
    for i: int in rank:
        draw_line(Vector2(-4,-4+i*4),Vector2(4,-4+i*4),color,1)
    for angle: float in [0,TAU/3,2*TAU/3]:
        var at := Vector2.from_angle(angle)*14
        draw_circle(at,3,Color("85a8b4"))
    if shield_active:
        draw_arc(Vector2.ZERO,13,0,TAU,32,color,1)
