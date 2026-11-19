extends RefCounted
## Integer-tick weapon state; no timers or rendering callbacks own firing.
signal charge_ready
const SPECS := {
    "pulse": {"damage": 2, "speed": 420.0, "size": Vector2(9,3), "hits": 1},
    "weak": {"damage": 8, "speed": 365.0, "size": Vector2(16,8), "hits": 2},
    "medium": {"damage": 24, "speed": 340.0, "size": Vector2(28,16), "hits": 3},
    "full": {"damage": 56, "speed": 310.0, "size": Vector2(46,24), "hits": 5}
}
var charge_ticks: int = 0
var cooldown: int = 0
var charge_lock: int = 0
var charging: bool = false
var previous_charge: bool = false
var ready_emitted: bool = false

func cancel(charge_down: bool = true) -> void:
    charge_ticks = 0
    charging = false
    ready_emitted = false
    previous_charge = charge_down

func reset() -> void:
    cancel()
    cooldown = 0
    charge_lock = 0

func step(snapshot: Dictionary) -> String:
    cooldown = maxi(0, cooldown - 1)
    charge_lock = maxi(0, charge_lock - 1)
    var down: bool = snapshot.get("charge", false)
    var released := previous_charge and not down
    if down and not previous_charge and charge_lock == 0:
        charging = true
    previous_charge = down
    if down:
        if charging:
            charge_ticks = mini(96, charge_ticks + 1)
            if charge_ticks == 96:
                # Transition only; cap must never emit a repeated ready cue.
                if not ready_emitted:
                    ready_emitted = true
                    charge_ready.emit()
        return ""
    if released and charging:
        var tier := tier_for_ticks(charge_ticks)
        charge_ticks = 0
        charging = false
        ready_emitted = false
        if not tier.is_empty():
            cooldown = 12
            charge_lock = 12
        return tier
    if snapshot.get("fire", false) and cooldown == 0:
        cooldown = 9
        return "pulse"
    return ""

static func tier_for_ticks(ticks: int) -> String:
    if ticks >= 96:
        return "full"
    if ticks >= 45:
        return "medium"
    if ticks >= 12:
        return "weak"
    return ""
