extends Node2D
var bit_positions: Array[Vector2] = []
var bit_previous: Array[Vector2] = []
var bit_active: Array[bool] = []
var bit_cooldown: int = 0
var missile_cooldown: int = 0
var bomb_cooldown: int = 0
var bomb_warning: int = 0
var bomb_origin := Vector2.ZERO
var bomb_pulses: int = 0

func reset() -> void:
    bit_positions.clear()
    bit_previous.clear()
    bit_active.clear()
    bit_cooldown = 0
    missile_cooldown = 0
    bomb_cooldown = 0
    bomb_warning = 0
    bomb_pulses = 0
    queue_redraw()

func step(ship: Vector2, snapshot: Dictionary, state: Node, projectiles: Node2D, defense: Node2D) -> void:
    bit_cooldown = maxi(0,bit_cooldown-1)
    missile_cooldown = maxi(0,missile_cooldown-1)
    bomb_cooldown = maxi(0,bomb_cooldown-1)
    if bomb_warning > 0:
        bomb_warning -= 1
        if bomb_warning == 0:
            bomb_pulses += 1
            _bomb_impulse(projectiles,defense)
    if snapshot.get("bomb",false) and state.bombs > 0 and bomb_cooldown == 0:
        state.bombs -= 1
        bomb_warning = 6
        bomb_cooldown = 120
        bomb_origin = ship
        # Defense decrements once later in this tick: 91 gives 90 protected ticks.
        defense.invulnerability = maxi(defense.invulnerability,91)
    while bit_positions.size() < state.bits:
        bit_positions.append(ship + Vector2(0,-25 if bit_positions.size() == 0 else 25))
        bit_previous.append(bit_positions[-1])
        bit_active.append(false)
    while bit_positions.size() > state.bits:
        bit_positions.pop_back()
        bit_previous.pop_back()
        bit_active.pop_back()
    for i: int in bit_positions.size():
        var was_active := bit_active[i]
        bit_previous[i] = bit_positions[i]
        bit_positions[i] = ship + Vector2(0,-25 if i == 0 else 25)
        bit_active[i] = not projectiles.world.solid_hit(bit_positions[i],bit_positions[i],8)
        if not was_active:
            bit_previous[i] = bit_positions[i]
    var firing: bool = snapshot.get("fire",false) and not snapshot.get("charge",false)
    if firing and bit_cooldown == 0:
        for i: int in bit_positions.size():
            if bit_active[i]:
                projectiles.spawn_spec("bit",bit_positions[i],Vector2.RIGHT,{"damage":1,"speed":360.0})
        bit_cooldown = 17
    if firing and missile_cooldown == 0 and state.missile_rank > 0:
        var offsets: Array = [12] if state.missile_rank == 1 else [-12,12]
        for y: int in offsets:
            projectiles.spawn_spec("missile",ship+Vector2(0,y),Vector2.RIGHT,{"damage":5,"speed":245.0,"turn_rate":120.0,"sector":90.0,"range":260.0,"ttl":138})
        missile_cooldown = 54
    queue_redraw()

func shields() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for i: int in bit_positions.size():
        if bit_active[i]:
            result.append({"kind":"circle","radius":8.0,"position":bit_positions[i],"previous":bit_previous[i]})
    return result

func _bomb_impulse(projectiles: Node2D, defense: Node2D) -> void:
    defense.clear_visible()
    var targets: Dictionary = {}
    for shape: Dictionary in projectiles.world.shapes.values():
        if shape.category == "weak" and Rect2(0,24,640,312).has_point(shape.position):
            targets[shape.group] = true
    var ids: Array = targets.keys()
    ids.sort()
    var boss_damage: Dictionary = {}
    for id: int in ids:
        if not projectiles.damage.alive(id):
            continue
        var group: Dictionary = projectiles.damage.groups[id]
        if not group.vulnerable:
            continue
        var boss: int = group.boss_id
        if boss < 0:
            projectiles.damage.apply(id,25)
        else:
            var amount := mini(30-int(boss_damage.get(boss,0)),int(group.hp))
            if amount > 0 and projectiles.damage.apply(id,amount):
                boss_damage[boss] = int(boss_damage.get(boss,0))+amount

func _draw() -> void:
    for i: int in bit_positions.size():
        var at := bit_positions[i]
        draw_arc(at,8 if bit_active[i] else 3,0,TAU,20,Color("d6e2db"),1)
        draw_circle(at,2,Color("85c6d5"))
    if bomb_warning > 0:
        draw_arc(bomb_origin,10+(6-bomb_warning)*8,0,TAU,48,Color("bc85dd"),2)
