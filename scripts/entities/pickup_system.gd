extends Node2D
const IDS := ["arc","prism","ember","bit","missile","bomb","life"]
var items: Array[Dictionary] = []
var claimed_lives: Dictionary = {}

func spawn(id: String, at: Vector2, event_id: String, carrier: bool = false) -> bool:
    if id not in IDS or items.size() >= 24 or (carrier and not Rect2(0,24,640,312).has_point(at)) or (id == "life" and claimed_lives.has(event_id)):
        return false
    for item: Dictionary in items:
        if item.event_id == event_id:
            return false
    items.append({"id":id,"position":at,"origin_y":at.y,"age":0,"event_id":event_id})
    queue_redraw()
    return true

func apply(id: String, state: Node, event_id: String = "") -> bool:
    if id not in IDS:
        return false
    if id in ["arc","prism","ember"]:
        if state.weapon == id.to_upper():
            if state.rank < 3:
                state.rank += 1
            else:
                state.score += 1000
        else:
            state.weapon = id.to_upper()
    elif id == "life":
        if claimed_lives.has(event_id):
            return false
        claimed_lives[event_id] = true
        if state.lives < 6:
            state.lives += 1
        else:
            state.score += 2000
    else:
        var property: String = {"bit":"bits","missile":"missile_rank","bomb":"bombs"}[id]
        var value: int = state.get(property)
        if value < 2:
            state.set(property,value+1)
        else:
            state.score += 1000
    return true

func step(ship_previous: Vector2, ship: Vector2, state: Node, world: RefCounted) -> void:
    var remove_indices: Array[int] = []
    for i: int in items.size():
        var item: Dictionary = items[i]
        var old: Vector2 = item.position
        item.age += 1
        var next := Vector2(old.x-38.0/60,item.origin_y+9*sin(TAU*item.age/66.0))
        if world.solid_hit(old,next,8):
            # Deterministic nearest safe Y towards corridor center; terrain profiles
            # can replace the center policy in VL-005 without changing pickups.
            var found := false
            for distance: int in range(0,313,4):
                var toward_center := -1 if next.y > 180 else 1
                for sign_value: int in [toward_center,-toward_center]:
                    var candidate := Vector2(next.x,clampf(next.y+sign_value*distance,32,328))
                    if not world.solid_hit(candidate,candidate,8):
                        next = candidate
                        item.origin_y = next.y
                        found = true
                        break
                if found:
                    break
            if not found:
                next = old
        item.position = next
        if world.circle_toi(old-ship_previous,next-ship,Vector2.ZERO,16) != INF:
            apply(item.id,state,item.event_id)
            remove_indices.append(i)
        elif next.x < -24:
            remove_indices.append(i)
    remove_indices.reverse()
    for index: int in remove_indices:
        items.remove_at(index)
    queue_redraw()

func clear(new_run: bool = false) -> void:
    items.clear()
    if new_run:
        claimed_lives.clear()
    queue_redraw()

func _draw() -> void:
    var glyphs := ["~","△","≡","○","↑","!","+"]
    for item: Dictionary in items:
        var color := Color("30bfd5") if item.id == "arc" else (Color("ffb54f") if item.id == "prism" else (Color("79cf73") if item.id == "ember" else Color("d6b9ef")))
        draw_rect(Rect2(item.position-Vector2(8,8),Vector2(16,16)),Color("08111e"))
        draw_rect(Rect2(item.position-Vector2(8,8),Vector2(16,16)),color,false,1)
        draw_string(ThemeDB.fallback_font,item.position+Vector2(-5,5),glyphs[IDS.find(item.id)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)
