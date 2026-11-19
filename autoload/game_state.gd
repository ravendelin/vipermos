extends Node
signal run_started
var difficulty: String = "arcade"
var stage_id: int = 1
var lives: int = 3
var bombs: int = 1
var score: int = 0
var weapon: String = "ARC"
var rank: int = 1
var speed_index: int = 1
var assist_shield: bool = false
var bits: int = 0
var missile_rank: int = 0
var deaths: int = 0
var score_milestones: Dictionary = {}
var claimed_lives: Dictionary = {}

func start_run(mode: String = "arcade") -> void:
    difficulty = mode if mode in ["assist", "arcade", "veteran"] else "arcade"
    stage_id = 1
    lives = 5 if difficulty == "assist" else 3
    bombs = 2 if difficulty == "assist" else 1
    score = 0
    deaths = 0
    score_milestones.clear()
    claimed_lives.clear()
    bits = 0
    missile_rank = 0
    weapon = "ARC"
    rank = 1
    speed_index = 1
    assist_shield = difficulty == "assist"
    run_started.emit()

func add_score(points: int) -> void:
    score += maxi(0,points)
    for threshold: int in [50000,120000]:
        if score >= threshold and not score_milestones.has(threshold):
            score_milestones[threshold] = true
            lives = mini(6,lives+1)
