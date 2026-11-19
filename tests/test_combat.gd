extends RefCounted
const Weapons = preload("res://scripts/combat/weapon_controller.gd")
const Projectiles = preload("res://scripts/combat/projectile_system.gd")
const World = preload("res://scripts/combat/collision_world.gd")

func run(tree: SceneTree, check: Callable) -> void:
    var weapon := Weapons.new()
    var times: Array[int] = []
    for tick: int in 90:
        if weapon.step({"fire": true}) == "pulse":
            times.append(tick)
    check.call(times == [0,9,18,27,36,45,54,63,72,81], "T004: immediate pulse, exactly every 9 ticks")
    for entry: Array in [[0,""],[11,""],[12,"weak"],[44,"weak"],[45,"medium"],[95,"medium"],[96,"full"],[160,"full"]]:
        weapon = Weapons.new()
        var ready := {"count": 0}
        weapon.charge_ready.connect(func(): ready.count += 1)
        var suppressed := true
        for tick: int in entry[0]:
            suppressed = suppressed and weapon.step({"charge": true, "fire": true}).is_empty()
        check.call(suppressed, "T005: pulse suppressed throughout charge " + str(entry[0]))
        check.call(weapon.charge_ticks == mini(entry[0],96), "T005: exact charge ticks/cap " + str(entry[0]))
        check.call(weapon.step({"charge": false}) == entry[1], "T005: release threshold " + str(entry[0]))
        check.call(ready.count == (1 if entry[0] >= 96 else 0), "ready event once " + str(entry[0]))
    weapon = Weapons.new()
    for i: int in 96:
        weapon.step({"charge": true})
    weapon.step({})
    for i: int in 11:
        check.call(weapon.step({"fire": true}).is_empty(), "post-charge lock tick " + str(i + 1))
    check.call(weapon.step({"fire": true}) == "pulse", "post-charge cooldown exactly 12 ticks")
    weapon = Weapons.new()
    for i: int in 45:
        weapon.step({"charge": true})
    weapon.step({})
    for i: int in 15:
        weapon.step({"charge": true})
    check.call(weapon.charge_ticks == 0, "charge begun during cooldown requires release")
    weapon.step({})
    weapon.step({"charge": true})
    check.call(weapon.charge_ticks == 1, "new charge after cooldown accepted")
    for i: int in 95:
        weapon.step({"charge": true})
    weapon.cancel()
    check.call(weapon.step({}).is_empty() and weapon.charge_ticks == 0, "T006: cancel full charge never releases")
    weapon = Weapons.new()
    weapon.step({"fire": true})
    check.call(weapon.step({"fire": true, "charge": true}).is_empty() and weapon.charge_ticks == 1, "charge immediately interrupts held pulse between shots")
    for i: int in 5:
        weapon.step({"charge": true, "fire": true})
    check.call(weapon.step({"fire": true}).is_empty(), "subthreshold release emits no shot even with fire held")
    var system := Projectiles.new()
    tree.root.add_child(system)
    for entry: Array in [["pulse",2,420,Vector2(9,3),1],["weak",8,365,Vector2(16,8),2],["medium",24,340,Vector2(28,16),3],["full",56,310,Vector2(46,24),5]]:
        system.clear()
        var slot := system.spawn(entry[0], Vector2(80,180))
        var bullet: Dictionary = system.slots[slot]
        check.call(bullet.damage == entry[1] and bullet.speed == entry[2] and bullet.size == entry[3] and bullet.remaining == entry[4], "weapon spec " + entry[0])
        system.step()
        check.call(bullet.position == Vector2(80,180), "new projectile stays at muzzle " + entry[0])
        system.step()
        check.call(absf(bullet.position.x - (80 + entry[2] / 60.0)) < 0.001, "projectile moves next tick " + entry[0])
    system.clear()
    system.damage.register(1,100)
    system.world.add_circle(1,1,Vector2(100,180),5.5)
    var slot := system.spawn("pulse",Vector2(20,180))
    system.slots[slot].speed = 12000.0
    system.step()
    system.step()
    check.call(system.damage.groups[1].hp == 98, "T015: fast shot sweep hits 5.5r target between endpoints")
    check.call(system.active_count == 0, "Pulse consumed on first damage group")
    # Six unique groups, two colliders in the first group. Full charge hits exactly five.
    for kind: String in ["weak", "medium", "full"]:
        system.clear()
        for i: int in 6:
            system.damage.register(i,100)
            system.world.add_circle(i,i,Vector2(80 + i * 45,180),5)
        system.world.add_circle(90,0,Vector2(81,180),5)
        slot = system.spawn(kind,Vector2(20,180))
        system.slots[slot].speed = 24000.0
        system.step()
        system.step()
        var hit_count := 0
        for group: Dictionary in system.damage.groups.values():
            if group.hp < 100:
                hit_count += 1
        check.call(hit_count == Weapons.SPECS[kind].hits, "T014: unique group penetration " + kind)
        check.call(system.damage.groups[0].hp == 100 - Weapons.SPECS[kind].damage, "duplicate colliders only damage once " + kind)
        check.call(system.damage.groups[5].hp == 100, "penetration budget leaves later target unharmed " + kind)
    system.clear()
    system.damage.register(1,100)
    system.world.add_circle(1,1,Vector2(100,180),10)
    slot = system.spawn("full",Vector2(100,180))
    system.slots[slot].speed = 0.0
    for i: int in 20:
        system.step()
    check.call(system.damage.groups[1].hp == 44, "charge overlap never re-hits same group next tick")
    for category: String in ["terrain", "armor"]:
        system.clear()
        system.damage.register(1,100)
        system.world.add_box(10,-1,Rect2(90,160,1,40),category)
        system.world.add_circle(1,1,Vector2(130,180),5)
        slot = system.spawn("full",Vector2(20,180))
        system.slots[slot].speed = 12000.0
        system.step()
        system.step()
        check.call(system.damage.groups[1].hp == 100 and system.active_count == 0, "thin " + category + " blocks full charge before target")
    system.clear()
    system.damage.register(1,56)
    system.world.add_circle(1,1,Vector2(100,180),10)
    system.spawn("full",Vector2(100,180))
    system.spawn("full",Vector2(100,180))
    system.step()
    check.call(system.damage.kills == 1 and system.damage.damage_total == 56, "simultaneous lethal hits kill/award damage once")
    # A simultaneous terrain contact takes priority over damage, independent of insertion.
    system.clear()
    system.damage.register(1,100)
    system.world.add_box(1,1,Rect2(100,100,10,10),"weak")
    system.world.add_box(99,-1,Rect2(100,100,10,10),"terrain")
    slot = system.spawn("full",Vector2(20,105))
    system.slots[slot].speed = 12000.0
    system.step()
    system.step()
    check.call(system.damage.groups[1].hp == 100, "equal TOI terrain wins over weak target")
    system.clear()
    system.damage.register(1,100)
    system.world.add_box(1,1,Rect2(95,95,10,10),"weak")
    system.world.move_shape(1,Vector2(100,260))
    system.spawn("pulse",Vector2(100,180))
    system.step()
    check.call(system.damage.groups[1].hp == 98, "relative sweep catches moving box")
    # Relative motion: circle sweeps across a stationary projectile between endpoints.
    system.clear()
    system.damage.register(1,10)
    system.world.add_circle(1,1,Vector2(100,100),5.5)
    system.world.move_shape(1,Vector2(100,260))
    system.spawn("pulse",Vector2(100,180))
    system.step()
    check.call(system.damage.groups[1].hp == 8, "relative sweep catches moving target")
    # Analytic checks distinguish capsule radius from its length, and rounded corners.
    var world := World.new()
    world.add_circle(1,1,Vector2(100,120),1)
    check.call(World.sweep(Vector2(0,100),Vector2(200,100),Vector2.RIGHT,Vector2(46,24),world.shapes[1]) == INF, "long capsule does not inflate transverse hitbox")
    world.add_box(2,-1,Rect2(100,100,10,10))
    check.call(World.sweep(Vector2(98.5,98.5),Vector2(98.5,98.5),Vector2.RIGHT,Vector2(4,4),world.shapes[2]) == INF, "rounded corner near miss (expanded AABB would false-hit)")
    check.call(World.sweep(Vector2(99,99),Vector2(99,99),Vector2.RIGHT,Vector2(4,4),world.shapes[2]) == 0, "rounded corner actual overlap")
    var time := World.sweep(Vector2(0,105),Vector2(200,105),Vector2.RIGHT,Vector2(4,4),world.shapes[2])
    check.call(absf(time - 0.49) < 0.00001, "AABB sweep analytic TOI")
    var axis := Vector2(1,1).normalized()
    world.add_circle(3,3,Vector2(50,50),5)
    check.call(World.sweep(Vector2.ZERO,Vector2(100,100),axis,Vector2(46,24),world.shapes[3]) < 0.5, "diagonal capsule follows velocity axis")
    # Hash spans both endpoint bounds; compare candidate sweep against exhaustive sweep.
    world.clear()
    for i: int in 40:
        world.add_circle(i,i,Vector2(10 + i * 13,50 + (i * 47) % 250),5.5)
    world.rebuild()
    for lane: int in 12:
        var start := Vector2(0,40 + lane * 24)
        var finish := start + Vector2(640,0)
        var ids := world.candidates(start,finish,Vector2(23,12))
        var complete := true
        for id: int in world.shapes:
            if World.sweep(start,finish,Vector2.RIGHT,Vector2(46,24),world.shapes[id]) != INF and not ids.has(id):
                complete = false
        check.call(complete, "spatial hash contains every swept contact lane " + str(lane))
    system.clear()
    for i: int in 184:
        system.spawn("pulse",Vector2(100,180))
    check.call(system.spawn("pulse",Vector2.ZERO) == -1, "ordinary cap reserves full-charge slots")
    for i: int in 8:
        check.call(system.spawn("full",Vector2(100,180)) >= 0, "full charge reserve slot " + str(i))
    check.call(system.active_count == 192 and system.spawn("full",Vector2.ZERO) == -1, "pool hard cap 192")
    system.clear()
    slot = system.spawn("pulse",Vector2(100,180))
    system.slots[slot].speed = 0.0
    for i: int in 239:
        system.step()
    check.call(system.active_count == 1, "lifetime active before tick 240")
    system.step()
    check.call(system.active_count == 0, "lifetime retires at tick 240")
    system.spawn("pulse",Vector2(900,180))
    system.step()
    check.call(system.active_count == 0, "offscreen cleanup")
    for reset: int in 100:
        system.spawn("full",Vector2(100,180))
        system.clear()
    check.call(system.active_count == 0 and system.slots.size() == 192 and system.world.shapes.is_empty() and system.damage.groups.is_empty(), "100 resets clear pool, collision and damage scope")
    system.queue_free()
    await tree.process_frame
    await _integration(tree,check)

func _integration(tree: SceneTree, check: Callable) -> void:
    var mission: Node = load("res://scenes/game/mission.tscn").instantiate()
    tree.root.add_child(mission)
    mission.set_physics_process(false)
    mission.set_phase("SCROLL")
    var key := InputEventKey.new()
    key.physical_keycode = KEY_X
    key.pressed = true
    mission.input_snapshot.ingest(key)
    for i: int in 96:
        mission.fixed_tick()
    check.call(mission.charge_ticks == 96 and mission.hud.charge_bar.value == 96, "full charge displayed in HUD")
    mission.pause()
    for i: int in 120:
        mission.fixed_tick()
    check.call(mission.charge_ticks == 0 and mission.hud.charge_bar.value == 0, "pause cancels weapon and HUD charge")
    mission.resume()
    mission.fixed_tick()
    key.pressed = false
    mission.input_snapshot.ingest(key)
    mission.fixed_tick()
    check.call(mission.projectiles.active_count == 0, "T006: no ghost full shot after resume/release")
    key.pressed = true
    mission.input_snapshot.ingest(key)
    for i: int in 45:
        mission.fixed_tick()
    key.pressed = false
    mission.input_snapshot.ingest(key)
    mission.fixed_tick()
    check.call(mission.projectiles.active_count == 1, "new charge works after resume")
    var frozen: Vector2 = mission.projectiles.slots[0].position
    mission.pause()
    for i: int in 120:
        mission.fixed_tick()
    check.call(mission.projectiles.slots[0].position == frozen, "pause freezes projectile movement and lifetime")
    mission.resume()
    mission.set_phase("DEATH")
    check.call(mission.projectiles.active_count == 0 and mission.charge_ticks == 0, "death transition clears projectile pool/charge")
    key.pressed = true
    mission.input_snapshot.ingest(key)
    for i: int in 100:
        mission.fixed_tick()
    check.call(mission.projectiles.active_count == 0 and mission.charge_ticks == 0, "no fire or charge outside active phase")
    mission.queue_free()
    await tree.process_frame
