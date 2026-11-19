extends RefCounted
## Stable expanded IDs and cursor; reset skips history, never catches up old waves.
const CLEARANCE := {"E01":15,"E02":17,"E03":17,"E04":19,"E05":18,"E06":19,"E07":14,"E08":17,"E09":17,"E10":19,"E11":17,"E12":26,"E13":21,"E14":33,"E15":32,"E16":16,"PICKUP":20}
var data: Dictionary = {}
var timeline: Array[Dictionary] = []
var cursor: int = 0
var checkpoint_tick: int = 0
var dispatched: int = 0

func configure(stage: Dictionary) -> void:
    data = stage
    timeline.clear()
    for row: int in data.events.size():
        var source: Dictionary = data.events[row]
        for index: int in int(source.count):
            var event := source.duplicate(true)
            event.id = source.id+":"+str(index)
            event.at_tick = int(source.at_tick)+int(source.gap_ticks)*index
            event.row = row
            event.subindex = index
            timeline.append(event)
    timeline.sort_custom(func(a: Dictionary,b: Dictionary):
        if a.at_tick != b.at_tick:
            return a.at_tick < b.at_tick
        return a.row < b.row if a.row != b.row else a.subindex < b.subindex)
    reset(0)

func reset(tick: int) -> void:
    checkpoint_tick = tick
    var lo := 0
    var hi := timeline.size()
    while lo < hi:
        var mid := (lo+hi)/2
        if timeline[mid].at_tick < tick:
            lo = mid+1
        else:
            hi = mid
    cursor = lo
    dispatched = 0

func due(tick: int, terrain: RefCounted) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if tick >= int(data.duration_ticks):
        return result
    while cursor < timeline.size() and timeline[cursor].at_tick < tick:
        cursor += 1
    while cursor < timeline.size() and timeline[cursor].at_tick == tick:
        var event := timeline[cursor].duplicate(true)
        var x := 600.0 if event.enemy == "PICKUP" else (-32.0 if event.entry == "L" else 672.0)
        var world_x: float = x + float(data.scroll_speed)*tick/60.0
        var top: float = terrain.top_at(world_x)
        var bottom: float = terrain.bottom_at(world_x)
        var y := 180.0
        if event.entry == "T":
            y = top+13 if top>24 else 40.0
        elif event.entry == "B":
            y = bottom-13 if bottom<336 else 320.0
        elif event.y is Array:
            y = event.y[event.subindex%event.y.size()]
        elif event.y is Dictionary:
            y = clampf(lerpf(top,bottom,event.y.corr),top+20,bottom-20)
        else:
            y = event.y
        if event.entry in ["L","R"]:
            var margin: float = CLEARANCE[event.enemy]
            y = clampf(y,top+margin,bottom-margin)
        event.position = Vector2(x,y)
        event.world_x = world_x
        result.append(event)
        cursor += 1
        dispatched += 1
    return result

func scroll_at(tick: int) -> float:
    return data.scroll_speed * tick/60.0
