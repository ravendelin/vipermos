extends RefCounted
var checkpoint_tick: int = 0
var checkpoint_score: int = 0
var snapshot_stats: Dictionary = {}
var death_ticks: int = 0
var respawn_ticks: int = 0
var death_pending: bool = false

func reset(score: int) -> void:
    checkpoint_tick = 0
    checkpoint_score = score
    snapshot_stats.clear()
    death_ticks = 0
    respawn_ticks = 0
    death_pending = false

func capture(tick: int, state: Node, stats: Dictionary = {}) -> void:
    if tick in [0,2400,4800,7200] and tick >= checkpoint_tick:
        checkpoint_tick = tick
        checkpoint_score = state.score
        snapshot_stats = stats.duplicate(true)

func die(state: Node) -> bool:
    if death_pending:
        return false
    death_pending = true
    death_ticks = 39
    state.lives = maxi(0,state.lives-1)
    state.deaths += 1
    return true

func restore(state: Node) -> void:
    state.score = checkpoint_score
    state.rank = maxi(1,state.rank-1)
    state.bits = maxi(0,state.bits-1)
    state.missile_rank = maxi(0,state.missile_rank-1)
    state.assist_shield = state.difficulty == "assist"
    respawn_ticks = 18
    death_pending = false

func invulnerability(state: Node) -> int:
    return {"assist":180,"arcade":120,"veteran":90}[state.difficulty]
