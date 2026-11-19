extends "res://scripts/game/mission_controller.gd"
## Shared mission systems, authored timeline and checkpoint lifecycle.
signal enemy_requested(event: Dictionary)
signal boss_requested(id: String)
const StageData = preload("res://scripts/data/stage_data.gd")
const Director = preload("res://scripts/game/stage_director.gd")
const Terrain = preload("res://scripts/game/terrain_profile.gd")
const Recovery = preload("res://scripts/game/checkpoint_recovery.gd")
@export var stage_path: String = "res://data/stages/s01.json"
@export var development_preview: bool = true
var stage: Dictionary = {}
var director := Director.new()
var terrain := Terrain.new()
var recovery := Recovery.new()
var warning_ticks: int = 0
var stage_enemy_requests: int = 0
var last_event: String = ""
@onready var terrain_view: Node2D = $World/Terrain
@onready var beams: Node2D = $World/StageBeams
var stage_status: Label

func _ready() -> void:
    super._ready()
    stage_status = Label.new()
    stage_status.position = Vector2(385,341)
    stage_status.add_theme_font_size_override("font_size",9)
    overlay.add_child(stage_status)
    intro_label.add_theme_font_size_override("font_size",12)
    load_stage(stage_path)

func load_stage(path: String) -> void:
    stage = StageData.load_file(path)
    if stage.is_empty():
        phase = "ERROR"
        intro_label.text = Locale.text("stage_error")
        intro_label.show()
        get_tree().quit(1)
        return
    stage_path = path
    GameState.stage_id = int(stage.id.substr(1))
    stage_tick = 0
    stage_enemy_requests = 0
    last_event = ""
    intro_ticks = 120
    phase = "INTRO"
    director.configure(stage)
    terrain.configure(stage)
    recovery.reset(GameState.score)
    projectiles.clear()
    defense.reset(GameState.difficulty == "assist")
    support.reset()
    pickups.clear()
    beams.clear()
    weapons.reset()
    terrain.update(projectiles.world,0)
    terrain_view.profile = terrain
    terrain_view.world = projectiles.world
    pickups.corridor_center = corridor_center
    player.position = Vector2(96,180)
    player.speed_index = GameState.speed_index
    player.visible = true
    player.modulate.a = 1
    aegis.reset(player.position)
    aegis.weapon_type = GameState.weapon
    aegis.rank = GameState.rank
    aegis.visible = true
    intro_label.text = stage.name.to_upper()+"\n"+Locale.text("stage_preview")+"\n"+Locale.text("stage_controls")
    intro_label.show()
    terrain_view.sync_geometry()
    _status()

func corridor_center(screen_x: float) -> float:
    var wx := screen_x+director.scroll_at(stage_tick)
    return (terrain.top_at(wx)+terrain.bottom_at(wx))/2

func fixed_tick() -> void:
    if get_tree().paused or leaving or stage.is_empty():
        return
    var started := Time.get_ticks_usec()
    var snapshot: Dictionary = input_snapshot.sample()
    match phase:
        "INTRO":
            intro_ticks -= 1
            if intro_ticks == 0:
                set_phase("SCROLL")
                intro_label.hide()
        "SCROLL":
            recovery.capture(stage_tick,GameState)
            if stage_tick >= 7200:
                _boss_warning()
            else:
                terrain.update(projectiles.world,stage_tick,maxi(0,stage_tick-1))
                terrain_view.sync_geometry()
                beams.update(stage,stage_tick,recovery.checkpoint_tick,terrain,projectiles.world)
                for event: Dictionary in director.due(stage_tick,terrain):
                    last_event = event.id
                    if event.enemy == "PICKUP":
                        pickups.spawn(event.pickup,event.position,event.id)
                    else:
                        stage_enemy_requests += 1
                        enemy_requested.emit(event)
                simulate_active(snapshot)
                if phase == "SCROLL":
                    stage_tick += 1
        "WARNING":
            player.step({"move":snapshot.move,"speed_cycle":snapshot.get("speed_cycle",false)})
            GameState.speed_index = player.speed_index
            aegis.step(player.position,{},projectiles,GameState.weapon,GameState.rank)
            warning_ticks -= 1
            if warning_ticks == 0:
                set_phase("BOSS")
                intro_label.text = Locale.text("boss_handoff")
                intro_label.visible = development_preview
                boss_requested.emit(stage.boss)
        "BOSS":
            simulate_active(snapshot)
        "DEATH":
            recovery.death_ticks -= 1
            if recovery.death_ticks <= 0:
                if GameState.lives == 0:
                    set_phase("GAME_OVER")
                    intro_label.text = Locale.text("stage_game_over")
                    intro_label.show()
                else:
                    _respawn()
        "RESPAWN":
            simulate_active(snapshot,false)
            if phase == "RESPAWN":
                recovery.respawn_ticks -= 1
                if recovery.respawn_ticks == 0:
                    phase = "SCROLL" if stage_tick < 7200 else "WARNING"
                    if stage_tick == 7200:
                        warning_ticks = 180
                        intro_label.text = Locale.text("boss_warning")
                        intro_label.show()
                    else:
                        intro_label.hide()
    if phase == "DEATH":
        intro_label.text = Locale.text("stage_recovering")
        intro_label.show()
    player.modulate.a = 0.55 if defense.invulnerability > 0 and (defense.invulnerability/10)%2==0 else 1.0
    physics_us = Time.get_ticks_usec()-started
    hud.refresh(stage_tick,physics_us,charge_ticks,projectiles.active_count,aegis.state,defense.active_count)
    _status()

func set_phase(next: String) -> void:
    if next == "DEATH" and phase != "DEATH":
        recovery.die(GameState)
    super.set_phase(next)
    if next not in ["SCROLL","BOSS","RESPAWN"] and is_instance_valid(beams):
        beams.clear()
    if next == "DEATH":
        player.visible = false
        aegis.visible = false
        terrain_view.queue_redraw()

func _boss_warning() -> void:
    recovery.capture(7200,GameState)
    var assist_protection: bool = defense.assist
    set_phase("WARNING")
    defense.assist = assist_protection
    warning_ticks = 180
    terrain.clear(projectiles.world)
    terrain_view.sync_geometry()
    intro_label.text = Locale.text("boss_warning")
    intro_label.show()

func _respawn() -> void:
    recovery.restore(GameState)
    stage_tick = recovery.checkpoint_tick
    set_phase("RESPAWN")
    director.reset(stage_tick)
    var safe := terrain.safe_point(projectiles.world,stage_tick)
    if not is_finite(safe.x):
        push_error("No safe checkpoint position: "+stage.id+" tick "+str(stage_tick))
        phase = "ERROR"
        intro_label.text = Locale.text("stage_error")
        intro_label.show()
        return
    player.position = safe
    player.visible = true
    aegis.visible = true
    aegis.reset(safe)
    weapons.reset()
    input_snapshot.suppress_until_release()
    defense.reset(GameState.assist_shield)
    defense.invulnerability = recovery.invulnerability(GameState)
    terrain_view.sync_geometry()

func active_hazards() -> Array:
    return beams.active if is_instance_valid(beams) else []

func _status() -> void:
    if stage_status == null:
        return
    stage_status.visible = development_preview
    stage_status.text = Locale.text("stage_status") % [stage.id,stage_tick,recovery.checkpoint_tick,stage_enemy_requests,last_event]

func _unhandled_input(event: InputEvent) -> void:
    if not development_preview or not event is InputEventKey or not event.pressed or event.echo or get_tree().paused:
        return
    if event.physical_keycode in [KEY_1,KEY_2,KEY_3,KEY_4]:
        preview_checkpoint([KEY_1,KEY_2,KEY_3,KEY_4].find(event.physical_keycode)*2400)
    elif event.physical_keycode == KEY_N:
        var next := GameState.stage_id%8+1
        GameState.start_run()
        load_stage("res://data/stages/s%02d.json" % next)
    elif event.physical_keycode == KEY_R:
        GameState.start_run()
        load_stage(stage_path)

func preview_checkpoint(tick: int) -> void:
    # Explicit inspection control, never a campaign/practice progression path.
    recovery.checkpoint_tick = tick
    recovery.checkpoint_score = GameState.score
    stage_tick = tick
    director.reset(tick)
    projectiles.clear()
    defense.reset(GameState.difficulty == "assist")
    support.reset()
    pickups.clear()
    beams.clear()
    weapons.reset()
    input_snapshot.suppress_until_release()
    phase = "SCROLL"
    player.position = terrain.safe_point(projectiles.world,tick)
    player.visible = true
    aegis.reset(player.position)
    intro_label.hide()
    terrain_view.sync_geometry()
    _status()
