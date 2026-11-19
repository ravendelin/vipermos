extends RefCounted
## Multiple colliders may share one HP group. Death emits once per reset scope.
signal damaged(group: int, amount: int)
signal destroyed(group: int)
var groups: Dictionary = {}
var damage_total: int = 0
var kills: int = 0

func register(group: int, hp: int, boss_id: int = -1, vulnerable: bool = true) -> void:
    groups[group] = {"hp": hp, "max_hp": hp, "boss_id":boss_id, "vulnerable":vulnerable}

func alive(group: int) -> bool:
    return groups.has(group) and groups[group].hp > 0

func apply(group: int, amount: int) -> bool:
    if not alive(group) or not groups[group].vulnerable:
        return false
    var actual := mini(groups[group].hp, amount)
    groups[group].hp -= actual
    damage_total += actual
    damaged.emit(group, actual)
    if groups[group].hp == 0:
        kills += 1
        destroyed.emit(group)
    return true

func clear() -> void:
    groups.clear()
    damage_total = 0
    kills = 0
