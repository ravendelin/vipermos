extends RefCounted
const Aegis = preload("res://scripts/entities/aegis_controller.gd")
const Projectiles = preload("res://scripts/combat/projectile_system.gd")
const Defense = preload("res://scripts/combat/defense_system.gd")
const Support = preload("res://scripts/combat/support_system.gd")
const Pickups = preload("res://scripts/entities/pickup_system.gd")
const World = preload("res://scripts/combat/collision_world.gd")

func run(tree: SceneTree, check: Callable) -> void:
    var state: Node = tree.root.get_node("GameState")
    state.start_run()
    var shots := Projectiles.new()
    var aegis := Aegis.new()
    var defense := Defense.new()
    var support := Support.new()
    var pickups := Pickups.new()
    for node: Node in [shots,aegis,defense,support,pickups]:
        tree.root.add_child(node)
    var ship := Vector2(200,180)
    aegis.reset(ship)
    check.call(aegis.position == Vector2(235,180) and aegis.shield_active, "AEGIS initial front port/shield")
    aegis.step(ship,{"module_side":true},shots,"ARC",1)
    check.call(aegis.state == "SWAP" and not aegis.shield_active, "swap disables shield")
    for i: int in 10:
        aegis.step(ship,{"module_toggle":true,"module_side":true,"fire":true},shots,"ARC",1)
    check.call(aegis.state == "SWAP" and shots.active_count == 0, "swap ignores spam and cannot fire")
    aegis.step(ship,{},shots,"ARC",1)
    check.call(aegis.state == "ATTACHED_REAR" and aegis.position == Vector2(165,180), "swap completes in 12 ticks atomically")
    aegis.reset(ship)
    aegis.step(ship,{"module_toggle":true},shots,"ARC",1)
    for i: int in 20:
        aegis.step(ship,{},shots,"ARC",1)
    check.call(aegis.state == "FREE" and absf(aegis.position.x-350.5)<0.01, "launch 21 ticks at 330px/s")
    for i: int in 12:
        aegis.step(ship,{},shots,"ARC",1)
    aegis.step(ship,{"module_side":true},shots,"ARC",1)
    check.call(aegis.launch_side == 1 and aegis.desired_side == -1, "detached side changes return port only")
    for i: int in 12:
        aegis.step(ship,{},shots,"ARC",1)
    aegis.step(ship,{"module_toggle":true},shots,"ARC",1)
    for i: int in 40:
        aegis.step(ship,{"module_toggle":true},shots,"ARC",1)
    check.call(aegis.state in ["ATTACHED_FRONT","ATTACHED_REAR","LAUNCH"], "return bounded under spam; module is single instance")
    aegis.reset(ship)
    shots.world.add_box(90,-1,Rect2(220,150,30,60))
    aegis.step(ship,{},shots,"ARC",1)
    check.call(aegis.state == "STOWED" and not aegis.shield_active, "blocked attached port stows immediately")
    shots.world.add_box(91,-1,Rect2(150,150,30,60))
    for i: int in 30:
        aegis.step(ship,{"fire":true},shots,"ARC",1)
    check.call(aegis.state == "STOWED" and shots.active_count == 0, "both ports blocked: no shield or fire")
    shots.world.clear()
    for i: int in 6:
        aegis.step(ship,{},shots,"ARC",1)
    check.call(aegis.state == "ATTACHED_FRONT" and aegis.shield_active, "stowed retries safe docking within six ticks")
    aegis.reset(ship)
    aegis.position = Vector2(500,180)
    aegis.state = "RETURN"
    shots.world.add_box(92,-1,Rect2(300,24,20,312))
    var hidden_ticks := 0
    for i: int in 40:
        aegis.step(ship,{},shots,"ARC",1)
        if aegis.state == "FALLBACK":
            hidden_ticks += 1
            check.call(not aegis.shield_active,"fallback never teleports active shield")
    check.call(aegis.state == "ATTACHED_FRONT" and hidden_ticks == 9, "blocked return falls back with nine hidden ticks")
    shots.clear()
    aegis.reset(ship)
    aegis.position = Vector2(400,180)
    aegis.desired_side = -1
    aegis.state = "FALLBACK"
    aegis.state_ticks = 9
    aegis.step(ship,{},shots,"ARC",1)
    check.call(aegis.state == "ATTACHED_FRONT" and aegis.previous == aegis.position,"fallback picks nearest safe port without teleport sweep")
    aegis.reset(Vector2(620,180))
    aegis.step(Vector2(620,180),{},shots,"ARC",1)
    check.call(aegis.state == "STOWED", "offscreen port unavailable")
    for i: int in 6:
        aegis.step(Vector2(620,180),{},shots,"ARC",1)
    check.call(aegis.state == "ATTACHED_REAR", "fallback uses safe opposite edge port")
    # Every type/rank emits exact simultaneous counts, damage and cooldown.
    for kind: String in ["ARC","PRISM","EMBER"]:
        for rank: int in [1,2,3]:
            shots.clear()
            aegis.reset(ship)
            aegis.step(ship,{"fire":true},shots,kind,rank)
            var expected_count: int = {"ARC":[1,2,3],"PRISM":[2,3,5],"EMBER":[2,2,3]}[kind][rank-1]
            var expected_cooldown: int = {"ARC":[17,17,15],"PRISM":[29,27,27],"EMBER":[39,35,33]}[kind][rank-1]
            check.call(shots.active_count == expected_count and aegis.shot_cooldown == expected_cooldown, "module pattern "+kind+str(rank))
            var expected_damage := 2 if kind == "EMBER" and rank == 1 else (4 if kind == "EMBER" else 3)
            check.call(shots.slots[0].damage == expected_damage,"module damage "+kind+str(rank))
            for i: int in expected_cooldown-1:
                aegis.step(ship,{"fire":true},shots,kind,rank)
            check.call(shots.active_count == expected_count,"no early module volley "+kind+str(rank))
            aegis.step(ship,{"fire":true},shots,kind,rank)
            check.call(shots.active_count == expected_count*2,"module exact second volley "+kind+str(rank))
    shots.clear()
    aegis.reset(ship)
    aegis.desired_side = -1
    aegis.state = "ATTACHED_REAR"
    aegis.step(ship,{"fire":true},shots,"PRISM",1)
    check.call(shots.slots[0].axis.x < 0 and shots.slots[0].axis.y < 0 and shots.slots[1].axis.y > 0,"rear fan mirrors only X")
    shots.clear()
    aegis.reset(ship)
    aegis.state = "FREE"
    aegis.step(ship,{"fire":true},shots,"EMBER",3)
    check.call(shots.slots[0].kind == "detached" and shots.slots[0].speed == 360 and aegis.shot_cooldown == 18,"detached weapon independent of type")
    shots.clear()
    aegis.reset(ship)
    aegis.step(ship,{"fire":true,"charge":true},shots,"ARC",3)
    check.call(shots.active_count == 0,"charge suppresses module")
    shots.damage.register(1,100)
    shots.damage.register(2,100)
    shots.world.add_circle(1,1,Vector2(235,180),4)
    shots.world.add_circle(2,2,Vector2(235,182),4)
    shots.world.add_circle(3,1,Vector2(236,180),4)
    for i: int in 12:
        aegis.step(ship,{},shots,"ARC",1)
    check.call(shots.damage.groups[1].hp == 95 and shots.damage.groups[2].hp == 95,"contact independent per group; no duplicate collider damage")
    aegis.step(ship,{},shots,"ARC",1)
    check.call(shots.damage.groups[1].hp == 90,"contact repeats at 12 ticks")
    shots.damage.apply(1,100)
    aegis.step(ship,{},shots,"ARC",1)
    check.call(not aegis.contact_cooldowns.has(1),"contact cache prunes dead targets")
    shots.clear()
    var signatures: Array[String] = []
    var valid := true
    for replay: int in 2:
        shots.clear()
        aegis.reset(ship)
        var trace := ""
        for tick: int in 300:
            var point := ship + Vector2(sin(tick/30.0)*25,cos(tick/40.0)*20)
            aegis.step(point,{"module_toggle":tick%13==0,"module_side":tick%17==0},shots,"ARC",1)
            valid = valid and aegis.state in ["ATTACHED_FRONT","ATTACHED_REAR","SWAP","LAUNCH","FREE","RETURN","FALLBACK","STOWED"]
            if aegis.state in ["SWAP","STOWED","FALLBACK"]:
                valid = valid and not aegis.shield_active
            trace += "%s:%s;" % [aegis.state,aegis.position]
        signatures.append(trace.sha256_text())
    check.call(valid and signatures[0] == signatures[1],"300-tick toggle/side spam replay deterministic with no stale shield states")
    shots.clear()
    _reflection(shots,check)
    _homing(shots,check)
    _defense(shots,defense,check)
    _pickups(pickups,state,shots,check)
    _support(support,state,shots,defense,check)
    for node: Node in [shots,aegis,defense,support,pickups]:
        node.queue_free()
    state.start_run()
    await tree.process_frame
    await _integration(tree,check)

func _reflection(shots: Node2D, check: Callable) -> void:
    shots.clear()
    shots.world.add_box(1,-1,Rect2(100,0,10,360))
    shots.world.add_box(2,-1,Rect2(0,0,10,360),"armor")
    var slot: int = shots.spawn_spec("prism",Vector2(50,180),Vector2.RIGHT,{"damage":3,"speed":18000.0,"bounces":2})
    shots.step()
    shots.step()
    check.call(not shots.slots[slot].active and shots.slots[slot].bounces == 0,"PRISM exactly two bounces; third collision stops within same tick")
    shots.clear()
    shots.world.add_box(1,-1,Rect2(100,0,10,360))
    slot = shots.spawn_spec("prism",Vector2(80,180),Vector2.RIGHT,{"damage":3,"speed":1800.0,"bounces":2})
    shots.step()
    shots.step()
    check.call(shots.slots[slot].active and shots.slots[slot].axis == Vector2.LEFT and shots.slots[slot].position.x < 96,"reflection consumes remaining tick path and separates surface")
    shots.clear()
    shots.world.add_box(1,-1,Rect2(100,100,30,30))
    slot = shots.spawn_spec("prism",Vector2(70,70),Vector2(1,1),{"damage":3,"speed":6000.0,"bounces":2})
    shots.step()
    shots.step()
    check.call(shots.slots[slot].bounces >= 0 and shots.active_count <= 1,"corner reflection bounded")
    check.call(shots.slots[slot].axis.x < 0 and shots.slots[slot].axis.y < 0,"diagonal corner normal reflects both components")
    shots.clear()
    shots.world.add_box(1,-1,Rect2(100,0,10,360))
    shots.damage.register(2,10)
    shots.world.add_circle(2,2,Vector2(40,180),5)
    slot = shots.spawn_spec("prism",Vector2(80,180),Vector2.RIGHT,{"damage":3,"speed":6000.0,"bounces":2})
    shots.step()
    shots.step()
    check.call(shots.damage.groups[2].hp == 7,"reflected remainder can damage target in same tick")
    shots.clear()

func _homing(shots: Node2D, check: Callable) -> void:
    shots.damage.register(1,100)
    shots.world.add_circle(1,1,Vector2(200,250),6)
    var slot: int = shots.spawn_spec("ember",Vector2(80,180),Vector2.RIGHT,{"damage":4,"speed":260.0,"turn_rate":160.0,"sector":80.0,"port_axis":Vector2.RIGHT})
    shots.step()
    shots.step()
    check.call(absf(shots.slots[slot].axis.angle()-deg_to_rad(160.0)/60)<0.00001,"EMBER maximum turn 160 degrees/sec")
    shots.damage.apply(1,100)
    var before: Vector2 = shots.slots[slot].axis
    shots.step()
    check.call(shots.slots[slot].axis == before,"dead target: forward until reacquire interval")
    shots.damage.register(2,100)
    shots.world.add_circle(2,2,Vector2(210,125),5)
    for i: int in 9:
        shots.step()
    check.call(shots.slots[slot].target == 2,"EMBER reacquires valid target within nine ticks")
    shots.clear()
    shots.damage.register(1,100)
    shots.world.add_circle(1,1,Vector2(40,180),5)
    slot = shots.spawn_spec("missile",Vector2(80,180),Vector2.RIGHT,{"damage":5,"speed":245.0,"turn_rate":120.0,"range":260.0,"sector":90.0,"ttl":138})
    shots.step()
    shots.step()
    check.call(shots.slots[slot].target == -1 and shots.slots[slot].axis == Vector2.RIGHT,"missile ignores targets behind launch direction")
    shots.damage.register(2,100)
    shots.world.add_circle(2,2,Vector2(500,180),5)
    for i: int in 9:
        shots.step()
    check.call(shots.slots[slot].target == -1,"missile acquisition radius 260")
    shots.clear()
    shots.damage.register(1,100)
    shots.world.add_circle(1,1,Vector2(200,250),5)
    slot = shots.spawn_spec("missile",Vector2(80,180),Vector2.RIGHT,{"damage":5,"speed":245.0,"turn_rate":120.0,"range":260.0,"sector":90.0,"ttl":138})
    shots.step()
    shots.step()
    check.call(absf(shots.slots[slot].axis.angle()-deg_to_rad(120.0)/60)<0.00001,"missile maximum turn 120 degrees/sec")
    shots.clear()
    slot = shots.spawn_spec("missile",Vector2(80,180),Vector2.RIGHT,{"damage":5,"speed":0.0,"ttl":138})
    for i: int in 137:
        shots.step()
    check.call(shots.active_count == 1,"missile lives before tick 138")
    shots.step()
    check.call(shots.active_count == 0,"missile expires exactly at 2.3 seconds")
    shots.clear()
    slot = shots.spawn_spec("arc",Vector2(100,180),Vector2.RIGHT,{"damage":3,"speed":340.0,"wave":true,"wave_phase":0.0})
    for i: int in 8:
        shots.step()
    check.call(absf(shots.slots[slot].position.y-(180+12*sin(TAU*7/28.8))) < 0.001,"ARC sine amplitude/period follow fixed ticks")
    shots.clear()

func _defense(shots: Node2D, defense: Node2D, check: Callable) -> void:
    var ship := Vector2(100,180)
    for side: int in [1,-1]:
        defense.reset()
        var shield := {"kind":"circle","radius":13.0,"position":ship+Vector2(side*35,0),"previous":ship+Vector2(side*35,0)}
        var slot: int = defense.spawn(ship+Vector2(side*100,0),Vector2(-side*12000,0))
        defense.step(ship,ship,[shield],shots.world)
        defense.step(ship,ship,[shield],shots.world)
        check.call(not defense.dead and defense.blocks == 1 and not defense.slots[slot].active,"shield earlier than ship side "+str(side))
    defense.reset()
    var behind := {"kind":"circle","radius":13.0,"position":Vector2(65,180),"previous":Vector2(65,180)}
    defense.spawn(Vector2(200,180),Vector2(-12000,0))
    defense.step(ship,ship,[behind],shots.world)
    defense.step(ship,ship,[behind],shots.world)
    check.call(defense.dead and defense.blocks == 0,"ship earlier than shield remains lethal")
    defense.reset()
    var front := {"kind":"circle","radius":13.0,"position":Vector2(135,180),"previous":Vector2(135,180)}
    defense.spawn(Vector2(200,180),Vector2(-12000,0),false)
    defense.step(ship,ship,[front],shots.world)
    defense.step(ship,ship,[front],shots.world)
    check.call(defense.dead and defense.blocks == 0,"unblockable orb bypasses shield")
    defense.reset()
    var hazard := {"kind":"box","half_size":Vector2(100,3),"position":ship,"previous":ship,"active":true}
    defense.step(ship,ship,[front],shots.world,[hazard])
    check.call(defense.dead,"beam-like active hazard bypasses module")
    defense.reset()
    hazard.active = false
    defense.step(ship,ship,[front],shots.world,[hazard])
    check.call(not defense.dead,"inactive beam warning does no damage")
    defense.reset()
    var bit := {"kind":"circle","radius":8.0,"position":Vector2(100,155),"previous":Vector2(100,155)}
    defense.spawn(Vector2(100,100),Vector2(0,6000))
    defense.step(ship,ship,[bit],shots.world)
    defense.step(ship,ship,[bit],shots.world)
    check.call(not defense.dead and defense.blocks == 1,"bit intercepts ordinary shot before ship")
    defense.reset()
    defense.spawn(Vector2(100,100),Vector2(0,6000),false)
    defense.step(ship,ship,[bit],shots.world)
    defense.step(ship,ship,[bit],shots.world)
    check.call(defense.dead,"orb passes bit shield")
    defense.reset(true)
    defense.spawn(ship,Vector2.ZERO)
    defense.spawn(ship,Vector2.ZERO)
    defense.step(ship,ship,[],shots.world)
    check.call(not defense.dead and not defense.assist and defense.hits == 1,"Assist absorbs simultaneous ordinary shots once")
    defense.invulnerability = 90
    shots.world.add_box(1,-1,Rect2(95,170,10,20))
    defense.step(ship,ship,[front],shots.world)
    check.call(defense.dead,"solid kills despite invulnerability")
    shots.clear()
    defense.reset()
    for i: int in 513:
        defense.spawn(Vector2(700,180),Vector2.ZERO)
    check.call(defense.active_count == 512,"hostile pool hard cap")
    defense.reset()
    check.call(defense.active_count == 0,"hostile reset cleans pool")

func _pickups(pickups: Node2D, state: Node, shots: Node2D, check: Callable) -> void:
    state.start_run()
    pickups.clear(true)
    pickups.apply("arc",state)
    check.call(state.rank == 2,"same type upgrades rank")
    pickups.apply("prism",state)
    check.call(state.weapon == "PRISM" and state.rank == 2,"type change preserves rank")
    pickups.apply("prism",state)
    pickups.apply("prism",state)
    check.call(state.rank == 3 and state.score == 1000,"same type rank cap awards 1000")
    for type: String in ["bit","missile","bomb"]:
        for i: int in 3:
            pickups.apply(type,state)
    check.call(state.bits == 2 and state.missile_rank == 2 and state.bombs == 2,"support pickup caps")
    state.lives = 6
    var score: int = state.score
    pickups.apply("life",state,"one-life")
    pickups.apply("life",state,"one-life")
    check.call(state.score == score+2000 and state.lives == 6,"life cap bonus once per event")
    check.call(not pickups.spawn("life",Vector2(200,180),"one-life"),"consumed life cannot respawn")
    check.call(not pickups.spawn("arc",Vector2(700,180),"offscreen",true),"offscreen carrier cannot spawn pickup")
    pickups.spawn("ember",Vector2(100,180),"collect")
    pickups.step(Vector2(80,180),Vector2(120,180),state,shots.world)
    check.call(state.weapon == "EMBER" and pickups.items.is_empty(),"swept ship pickup collection")
    pickups.spawn("arc",Vector2(300,180),"move")
    pickups.step(Vector2.ZERO,Vector2.ZERO,state,shots.world)
    check.call(absf(pickups.items[0].position.x-(300-38.0/60))<0.001,"pickup 38px/sec drift")
    pickups.clear()
    pickups.spawn("arc",Vector2(-25,180),"expired")
    pickups.step(Vector2.ZERO,Vector2.ZERO,state,shots.world)
    check.call(pickups.items.is_empty(),"pickup offscreen cleanup")
    state.start_run()
    pickups.spawn("arc",Vector2(100,180),"first")
    pickups.spawn("prism",Vector2(100,180),"second")
    pickups.step(Vector2(100,180),Vector2(100,180),state,shots.world)
    check.call(state.weapon == "PRISM" and state.rank == 2,"simultaneous pickups resolve in authored spawn order")
    pickups.spawn("arc",Vector2(300,180),"wall")
    shots.world.add_box(1,-1,Rect2(280,170,40,20))
    pickups.step(Vector2.ZERO,Vector2.ZERO,state,shots.world)
    check.call(not shots.world.solid_hit(pickups.items[0].position,pickups.items[0].position,8),"pickup slides out of solid to safe Y")
    pickups.clear()
    shots.clear()
    state.start_run()

func _support(support: Node2D, state: Node, shots: Node2D, defense: Node2D, check: Callable) -> void:
    support.reset()
    defense.reset()
    state.bits = 2
    state.missile_rank = 2
    support.step(Vector2(100,180),{"fire":true},state,shots,defense)
    check.call(shots.active_count == 4 and support.shields().size() == 2,"two bits and two missiles fired")
    check.call(support.bit_positions == [Vector2(100,155),Vector2(100,205)],"bit offsets fixed")
    check.call(shots.slots[0].damage == 1 and shots.slots[2].damage == 5 and shots.slots[2].ttl == 138,"bit/missile damage and TTL")
    shots.world.add_box(1,-1,Rect2(90,145,20,20))
    support.step(Vector2(100,180),{},state,shots,defense)
    check.call(support.shields().size() == 1,"bit intersecting solid stows")
    shots.clear()
    support.reset()
    support.step(Vector2(100,180),{"fire":true,"charge":true},state,shots,defense)
    check.call(shots.active_count == 0,"charge suppresses bits and missiles")
    state.bombs = 2
    shots.damage.register(1,100)
    shots.damage.register(2,100,10)
    shots.damage.register(3,100,10)
    shots.damage.register(4,100,11,false)
    for i: int in [1,2,3,4]:
        shots.world.add_circle(i,i,Vector2(200+i*30,180),8)
    shots.world.add_circle(5,1,Vector2(230,182),8)
    defense.spawn(Vector2(300,180),Vector2.ZERO)
    defense.spawn(Vector2(320,180),Vector2.ZERO,false)
    support.step(Vector2(100,180),{"bomb":true},state,shots,defense)
    check.call(state.bombs == 1 and support.bomb_warning == 6 and defense.invulnerability == 91,"bomb consumes once and starts six-tick warning + invulnerability")
    for i: int in 5:
        support.step(Vector2(100,180),{"bomb":true},state,shots,defense)
    check.call(defense.active_count == 2,"bomb does not clear before warning completes")
    support.step(Vector2(100,180),{},state,shots,defense)
    check.call(defense.active_count == 0 and support.bomb_pulses == 1,"bomb clears ordinary and heavy shots exactly once")
    check.call(shots.damage.groups[1].hp == 75,"bomb ordinary damage once per group")
    check.call(shots.damage.groups[2].hp+shots.damage.groups[3].hp == 170 and shots.damage.groups[4].hp == 100,"bomb boss cap30 and closed section immunity")
    defense.spawn(Vector2(300,180),Vector2.ZERO)
    support.step(Vector2(100,180),{"bomb":true},state,shots,defense)
    check.call(defense.active_count == 1 and state.bombs == 1,"new bullets survive and bomb cooldown blocks repeat")
    support.reset()
    shots.clear()
    defense.reset()
    state.bombs = 1
    support.step(Vector2(100,180),{"bomb":true},state,shots,defense)
    defense.spawn(Vector2(100,180),Vector2.ZERO)
    defense.step(Vector2(100,180),Vector2(100,180),[],shots.world)
    check.call(not defense.dead and defense.invulnerability == 90,"bomb activation protects same-tick ordinary contact")
    shots.world.add_box(1,-1,Rect2(95,170,10,20))
    defense.step(Vector2(100,180),Vector2(100,180),[],shots.world)
    check.call(defense.dead,"bomb never permits passage through terrain")
    support.reset()
    shots.clear()
    defense.reset()

func _integration(tree: SceneTree, check: Callable) -> void:
    var state: Node = tree.root.get_node("GameState")
    state.start_run()
    var mission: Node = load("res://scenes/game/aegis_range.tscn").instantiate()
    tree.root.add_child(mission)
    mission.set_physics_process(false)
    for i: int in 120:
        mission.fixed_tick()
    var side := InputEventKey.new()
    side.physical_keycode = KEY_V
    side.pressed = true
    mission.input_snapshot.ingest(side)
    mission.fixed_tick()
    check.call(mission.aegis.state == "SWAP", "mission routes side input to AEGIS")
    mission.pause()
    var before: Vector2 = mission.aegis.position
    for i: int in 120:
        mission.fixed_tick()
    check.call(mission.aegis.position == before and mission.aegis.state == "SWAP", "pause freezes AEGIS swap timer")
    mission.resume()
    for i: int in 20:
        mission.fixed_tick()
    check.call(mission.aegis.state == "ATTACHED_REAR", "held side on resume cannot swap twice")
    mission.defense.spawn(mission.player.position,Vector2.ZERO,false)
    mission.fixed_tick()
    check.call(mission.phase == "DEATH" and mission.defense.active_count == 0 and mission.projectiles.active_count == 0,"fatal orb clears active combat through mission transition")
    mission.get_node("World/Targets").reset_targets()
    check.call(mission.phase == "SCROLL" and mission.aegis.state == "ATTACHED_FRONT", "range reset recovers from death")
    state.rank = 2
    mission.pickups.spawn("prism",mission.player.position,"integration-pickup")
    mission.fixed_tick()
    check.call(state.weapon == "PRISM" and state.rank == 2 and mission.aegis.weapon_type == "PRISM","collected type visible on module in same tick")
    var bomb := InputEventKey.new()
    bomb.physical_keycode = KEY_F
    bomb.pressed = true
    mission.input_snapshot.ingest(bomb)
    mission.fixed_tick()
    var warning: int = mission.support.bomb_warning
    mission.pause()
    for i: int in 120:
        mission.fixed_tick()
    check.call(mission.support.bomb_warning == warning,"pause freezes bomb telegraph")
    mission.resume()
    for i: int in 10:
        mission.fixed_tick()
    check.call(mission.support.bomb_pulses == 1,"resume produces exactly one scheduled bomb impulse")
    mission.queue_free()
    state.start_run()
    await tree.process_frame
