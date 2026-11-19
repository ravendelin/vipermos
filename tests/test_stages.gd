extends RefCounted
const StageData = preload("res://scripts/data/stage_data.gd")
const Terrain = preload("res://scripts/game/terrain_profile.gd")
const Director = preload("res://scripts/game/stage_director.gd")
const World = preload("res://scripts/combat/collision_world.gd")
const Recovery = preload("res://scripts/game/checkpoint_recovery.gd")

func run(tree: SceneTree, check: Callable) -> void:
    var all_stages: Array[Dictionary] = []
    var entity_counts := [43,39,32,21,24,29,20,25]
    for i: int in range(1,9):
        var data := StageData.load_file("res://data/stages/s%02d.json" % i)
        check.call(not data.is_empty(),"stage schema S%02d" % i)
        if data.is_empty():
            return
        all_stages.append(data)
        var terrain := Terrain.new()
        terrain.configure(data)
        var director := Director.new()
        director.configure(data)
        check.call(director.timeline.size() == entity_counts[i-1],"full GDD table expanded S%02d" % i)
        var world := World.new()
        for checkpoint: int in [0,2400,4800,7200]:
            var point := terrain.safe_point(world,checkpoint)
            check.call(is_finite(point.x) and not world.solid_hit(point,point,20),"safe radius20 S%02d checkpoint %d" % [i,checkpoint])
            var repeated := terrain.safe_point(world,checkpoint)
            check.call(point == repeated,"deterministic safe point S%02d/%d" % [i,checkpoint])
        var count := 0
        var ids: Dictionary = {}
        for tick: int in 7201:
            for event: Dictionary in director.due(tick,terrain):
                ids[event.id] = true
                count += 1
        check.call(count == entity_counts[i-1] and ids.size() == count,"timeline reaches 7200 with no duplicate/missing events S%02d" % i)
        check.call(director.due(7200,terrain).is_empty(),"transition-only final tick S%02d" % i)
        director.reset(2400)
        check.call(director.cursor == director.timeline.size() or director.timeline[director.cursor].at_tick>=2400,"reset binary search skips past S%02d" % i)
        var seen_past := false
        for tick: int in range(2400,2500):
            for event: Dictionary in director.due(tick,terrain):
                seen_past = seen_past or event.at_tick<2400
        check.call(not seen_past,"no historical event catch-up S%02d" % i)
    var data: Dictionary = all_stages[0]
    var terrain := Terrain.new()
    terrain.configure(data)
    check.call(terrain.top_at(-1000)==24 and terrain.bottom_at(-1000)==336,"terrain clamps before profile")
    check.call(terrain.top_at(640+76*18)==44 and terrain.bottom_at(640+76*18)==310,"profile coordinates reference right edge")
    check.call(absf(terrain.top_at(640+76*15)-34)<0.00001,"terrain linear interpolation midpoint")
    var world := World.new()
    terrain.update(world,1440,1439)
    var first: Dictionary = world.shapes[2000000]
    check.call(first.position == Vector2(640,215),"hazard world center scroll applied once")
    check.call(absf(first.previous.x-first.position.x-76.0/60)<0.0001,"hazard previous/current motion")
    terrain.update(world,1440-30)
    check.call(not terrain.warnings.is_empty(),"hazard pre-entry warning visible")
    terrain.update(world,2000)
    var x := 300.0
    var edge: float = terrain.top_at(x+terrain.scroll_x)
    check.call(world.solid_hit(Vector2(x,edge+30),Vector2(x,edge-10),5.5),"swept circle hits sloping terrain")
    check.call(not world.solid_hit(Vector2(x,edge+20),Vector2(x,edge+20),5.5),"safe point below slope not false-hit")
    var polygon_count := 0
    for shape: Dictionary in world.shapes.values():
        if shape.kind == "polygon":
            polygon_count += 1
    check.call(polygon_count>0,"terrain uses shared polygon collision geometry")
    terrain.update(world,7200)
    check.call(world.shapes.is_empty(),"boss arena clears scroll solids")
    terrain.configure(all_stages[3])
    var gate: Dictionary = all_stages[3].hazards[0]
    var rects := terrain.hazard_rects(gate,2000)
    check.call(absf(rects[1].position.y-rects[0].end.y-gate.gap_height)<0.00001,"moving gate maintains exact gap height")
    check.call(rects == terrain.hazard_rects(gate,2000),"gate absolute tick reconstruction")
    var later := terrain.hazard_rects(gate,2001)
    check.call(later[0].position.y != rects[0].position.y,"oscillating gate actually moves")
    terrain.configure(all_stages[1])
    var osc := terrain.hazard_rects(all_stages[1].hazards[0],1500)
    check.call(osc == terrain.hazard_rects(all_stages[1].hazards[0],1500),"oscRect deterministic after checkpoint")
    # Spawn DSL fixtures retain GDD metadata but vary events.
    terrain.configure(data)
    var fixture := data.duplicate(true)
    fixture.events = [
        {"id":"test:0","at_tick":0,"enemy":"E01","entry":"R","y":[100,200],"count":3,"gap_ticks":2},
        {"id":"test:1","at_tick":2,"enemy":"E03","entry":"T","y":null,"count":1,"gap_ticks":0},
        {"id":"test:2","at_tick":3,"enemy":"E11","entry":"L","y":{"corr":0.5},"count":1,"gap_ticks":0},
        {"id":"test:3","at_tick":4,"enemy":"PICKUP","entry":"R","y":180,"pickup":"arc","count":1,"gap_ticks":0}]
    var director := Director.new()
    director.configure(fixture)
    check.call(director.due(0,terrain)[0].position == Vector2(672,100),"DSL first list position")
    var due := director.due(2,terrain)
    check.call(due.size()==2 and due[0].id=="test:0:1" and due[1].id=="test:1:0","equal tick preserves source row order")
    check.call(due[0].position.y==200 and due[1].position.y==40,"list cycling and open-edge mount")
    check.call(director.due(3,terrain)[0].position==Vector2(-32,180),"L entry and corridor percentage")
    due = director.due(4,terrain)
    check.call(due[0].position.y==100 and due[1].position.x==600,"list wraps and pickup x600")
    check.call(director.due(4,terrain).is_empty(),"same tick cannot dispatch twice")
    var invalid := data.duplicate(true)
    invalid.events[0].entry = "L"
    check.call(not StageData.validate(invalid).is_empty(),"reject forbidden left entry")
    invalid = data.duplicate(true)
    invalid.events[0].at_tick = 7199
    check.call(not StageData.validate(invalid).is_empty(),"reject event extending past duration")
    invalid = data.duplicate(true)
    invalid.hazards[0].unexpected = true
    check.call(not StageData.validate(invalid).is_empty(),"reject unknown gameplay key")
    invalid = data.duplicate(true)
    invalid.events[2].erase("drop")
    check.call(not StageData.validate(invalid).is_empty(),"reject missing courier drop")
    invalid = data.duplicate(true)
    invalid.terrain[2][1] = NAN
    check.call(not StageData.validate(invalid).is_empty(),"reject nonfinite profile")
    invalid = data.duplicate(true)
    invalid.events[0].id = 12
    check.call(not StageData.validate(invalid).is_empty(),"reject non-string event ID")
    invalid = data.duplicate(true)
    invalid.terrain[0][0] = 1
    check.call(not StageData.validate(invalid).is_empty(),"reject profile missing tick-zero endpoint")
    _recovery(tree,check)
    await _mission(tree,check)
    _beams(tree,check,all_stages[6])
    await _replay(tree,check)

func _recovery(tree: SceneTree, check: Callable) -> void:
    var state: Node = tree.root.get_node("GameState")
    var recovery := Recovery.new()
    state.start_run()
    recovery.reset(0)
    state.score = 1234
    recovery.capture(2399,state)
    check.call(recovery.checkpoint_tick==0,"death before 40s uses previous checkpoint")
    recovery.capture(2400,state)
    state.score = 2345
    state.rank = 3
    state.bits = 2
    state.missile_rank = 2
    state.bombs = 0
    state.speed_index = 2
    check.call(recovery.die(state) and not recovery.die(state) and state.lives==2,"one fatal event decrements life once")
    recovery.restore(state)
    check.call(state.score==1234 and state.rank==2 and state.bits==1 and state.missile_rank==1,"score rollback and upgrade penalties")
    check.call(state.bombs==0 and state.speed_index==2 and state.lives==2,"bomb/lives/speed not rolled back")
    check.call(recovery.death_ticks==39 and recovery.respawn_ticks==18,"death and appearance durations")
    for mode: String in ["assist","arcade","veteran"]:
        state.start_run(mode)
        check.call(recovery.invulnerability(state)=={"assist":180,"arcade":120,"veteran":90}[mode],"respawn i-frame difficulty "+mode)
    state.start_run()
    recovery.reset(0)
    state.add_score(50000)
    check.call(state.lives==4,"50k milestone grants extra life")
    recovery.die(state)
    recovery.restore(state)
    state.add_score(50000)
    check.call(state.lives==3,"rollback cannot farm 50k extra life")
    state.add_score(70000)
    check.call(state.lives==4 and state.score_milestones.size()==2,"120k milestone granted once")
    state.start_run()

func _mission(tree: SceneTree, check: Callable) -> void:
    var state: Node = tree.root.get_node("GameState")
    state.start_run()
    var mission: Node = load("res://scenes/game/stage_preview.tscn").instantiate()
    tree.root.add_child(mission)
    mission.set_physics_process(false)
    for i: int in 120:
        mission.fixed_tick()
    check.call(mission.phase=="SCROLL" and mission.stage_tick==0,"stage starts at tick zero after intro")
    mission.preview_checkpoint(2400)
    state.score = 3210
    var terrain_before: int = mission.terrain_view.render_shapes.size()
    mission.defense.spawn(mission.player.position,Vector2.ZERO,false)
    mission.fixed_tick()
    check.call(mission.terrain_view.render_shapes.size()==terrain_before,"death retains frozen terrain visuals while collision records clear")
    check.call(mission.phase=="DEATH" and mission.recovery.checkpoint_tick==2400 and state.lives==2,"death at40 captures checkpoint before collision")
    check.call(mission.stage_tick==2400,"death does not advance stage time")
    for i: int in 38:
        mission.fixed_tick()
    check.call(mission.phase=="DEATH","death phase lasts39 ticks")
    mission.fixed_tick()
    check.call(mission.phase=="RESPAWN" and mission.recovery.respawn_ticks==18 and state.score==3210,"reconstruct at39 ticks")
    check.call(not mission.projectiles.world.solid_hit(mission.player.position,mission.player.position,20),"reconstructed ship safe")
    var start: Vector2 = mission.player.position
    var key := InputEventKey.new()
    key.physical_keycode = KEY_D
    key.pressed = true
    mission.input_snapshot.ingest(key)
    for i: int in 18:
        mission.fixed_tick()
    check.call(mission.phase=="SCROLL" and mission.stage_tick==2400 and mission.player.position==start,"respawn appearance locks movement and stage clock")
    mission.fixed_tick()
    check.call(mission.player.position.x>start.x and mission.stage_tick==2401,"movement resumes after18 ticks")
    key.pressed = false
    mission.input_snapshot.ingest(key)
    state.assist_shield = true
    mission.defense.assist = true
    for checkpoint: int in [4800,7200]:
        mission.preview_checkpoint(checkpoint)
        mission.defense.assist = true
        mission.fixed_tick()
        check.call(mission.recovery.checkpoint_tick==checkpoint,"checkpoint boundary "+str(checkpoint))
    check.call(mission.defense.assist,"boss warning preserves remaining Assist protection")
    mission.defense.assist = false
    check.call(mission.phase=="WARNING" and mission.projectiles.world.shapes.is_empty(),"tick7200 transitions without damage/spawns and clears terrain")
    mission.pause()
    for i: int in 120:
        mission.fixed_tick()
    check.call(mission.warning_ticks==180,"pause freezes boss warning")
    mission.resume()
    for i: int in 179:
        mission.fixed_tick()
    check.call(mission.phase=="WARNING","warning not early")
    mission.fixed_tick()
    check.call(mission.phase=="BOSS" and mission.stage_tick==7200,"boss handoff after180 ticks")
    for i: int in 30:
        mission.fixed_tick()
    check.call(mission.stage_tick==7200,"boss combat does not advance scroll clock")
    state.lives = 1
    mission.defense.spawn(mission.player.position,Vector2.ZERO,false)
    mission.fixed_tick()
    for i: int in 39:
        mission.fixed_tick()
    check.call(mission.phase=="GAME_OVER" and state.lives==0,"zero lives stops recovery")
    mission.queue_free()
    state.start_run()
    await tree.process_frame

func _beams(tree: SceneTree, check: Callable, data: Dictionary) -> void:
    var beams: Node2D = load("res://scripts/game/stage_beams.gd").new()
    tree.root.add_child(beams)
    var terrain := Terrain.new()
    terrain.configure(data)
    var world := World.new()
    world.add_box(1,-1,Rect2(300,80,20,40))
    var left := terrain.clip_left(world,Vector2(640,94),16)
    check.call(absf(left-320)<0.01,"beam clipped to nearest solid across its width")
    world.shapes[1].previous = Vector2(410,100)
    check.call(absf(terrain.clip_left(world,Vector2(640,94),16)-320)<0.01,"instantaneous beam uses current solid geometry")
    beams.update(data,1080,0,terrain,world)
    check.call(beams.active.is_empty() and beams.display.size()==1,"beam warning not damaging")
    beams.update(data,1152,0,terrain,world)
    check.call(beams.active.size()==1,"beam active after72 ticks")
    beams.update(data,1185,0,terrain,world)
    check.call(beams.active.is_empty() and beams.display.is_empty(),"beam expires at exact active boundary")
    beams.update(data,1152,1100,terrain,world)
    check.call(beams.active.is_empty() and beams.display.is_empty(),"checkpoint skips beam whose warning began earlier")
    beams.queue_free()

func _replay(tree: SceneTree, check: Callable) -> void:
    var signatures: Array[String] = []
    var state: Node = tree.root.get_node("GameState")
    for attempt: int in 2:
        state.start_run()
        var mission: Node = load("res://scenes/game/stage_preview.tscn").instantiate()
        tree.root.add_child(mission)
        mission.set_physics_process(false)
        mission.preview_checkpoint(0)
        var trace := ""
        for tick: int in 1800:
            for entry: Array in [[0,KEY_Z,true],[300,KEY_X,true],[396,KEY_X,false],[600,KEY_C,true],[601,KEY_C,false],[900,KEY_C,true],[901,KEY_C,false],[1200,KEY_V,true],[1201,KEY_V,false]]:
                if tick == entry[0]:
                    var event := InputEventKey.new()
                    event.physical_keycode = entry[1]
                    event.pressed = entry[2]
                    mission.input_snapshot.ingest(event)
            mission.fixed_tick()
            trace += _state_hash(mission,state)
        signatures.append(trace.sha256_text())
        check.call(mission.stage_tick==1800 and mission.phase=="SCROLL","30-second replay reaches tick1800 run "+str(attempt))
        mission.queue_free()
        await tree.process_frame
    check.call(signatures[0]==signatures[1],"same input/ticks reproduce 30-second state hash")
    print("STAGE_REPLAY_30S sha256=",signatures[0])
    state.start_run()

func _state_hash(mission: Node, state: Node) -> String:
    var bullets: Array = []
    for bullet: Dictionary in mission.projectiles.slots:
        if bullet.active:
            bullets.append(bullet.duplicate(true))
    bullets.sort_custom(func(a: Dictionary,b: Dictionary): return a.id<b.id)
    var hostile: Array = []
    for bullet: Dictionary in mission.defense.slots:
        if bullet.active:
            hostile.append(bullet.duplicate(true))
    hostile.sort_custom(func(a: Dictionary,b: Dictionary): return a.id<b.id)
    var snapshot := {
        "tick":mission.stage_tick,"phase":mission.phase,"cursor":mission.director.cursor,
        "requests":mission.stage_enemy_requests,"last":mission.last_event,
        "player":[mission.player.position,mission.player.velocity,mission.player.speed_index],
        "module":[mission.aegis.position,mission.aegis.previous,mission.aegis.state,mission.aegis.state_ticks,mission.aegis.desired_side,mission.aegis.launch_side,mission.aegis.shield_active,mission.aegis.shot_cooldown,mission.aegis.contact_cooldowns],
        "weapons":[mission.weapons.charge_ticks,mission.weapons.cooldown,mission.weapons.charge_lock,mission.weapons.charging,mission.weapons.previous_charge],
        "run":[state.score,state.lives,state.bombs,state.weapon,state.rank,state.bits,state.missile_rank,state.assist_shield,state.deaths,state.score_milestones,state.claimed_lives],
        "recovery":[mission.recovery.checkpoint_tick,mission.recovery.checkpoint_score,mission.recovery.death_ticks,mission.recovery.respawn_ticks],
        "shots":bullets,"hostile":hostile,"groups":mission.projectiles.damage.groups,
        "defense":[mission.defense.invulnerability,mission.defense.assist,mission.defense.dead],
        "support":[mission.support.bit_positions,mission.support.bit_active,mission.support.bit_cooldown,mission.support.missile_cooldown,mission.support.bomb_warning,mission.support.bomb_cooldown],
        "pickups":mission.pickups.items,"scroll":mission.terrain.scroll_x,
        "profile":mission.terrain.samples,"beams":mission.beams.display}
    return var_to_bytes(snapshot).hex_encode().sha256_text()
