extends RefCounted
const TOP_KEYS := ["schema_version","id","name","scroll_speed","duration_ticks","checkpoints_ticks","terrain","hazards","events","beams","boss"]
const PICKUPS := ["arc","prism","ember","bit","missile","bomb","life"]

static func load_file(path: String) -> Dictionary:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    var errors := validate(parsed)
    if not errors.is_empty():
        push_error("Stage data %s: %s" % [path, "; ".join(errors)])
        return {}
    return parsed

static func number(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value))

static func integer(value: Variant) -> bool:
    return number(value) and float(value) == floorf(float(value))

static func allowed_keys(value: Dictionary, allowed: Array, errors: Array[String], context: String) -> void:
    for key: Variant in value:
        if key not in allowed:
            errors.append(context+": unknown key "+str(key))

static func validate(data: Variant) -> Array[String]:
    var errors: Array[String] = []
    if not data is Dictionary:
        errors.append("root must be an object")
        return errors
    allowed_keys(data,TOP_KEYS,errors,"stage")
    for key: String in TOP_KEYS:
        if not data.has(key):
            errors.append("missing "+key)
    if not errors.is_empty():
        return errors
    if data.schema_version != 1 or data.id not in ["S01","S02","S03","S04","S05","S06","S07","S08"]:
        errors.append("unsupported schema/id")
    if not data.name is String or str(data.name).is_empty() or data.boss != "B"+str(data.id).substr(1):
        errors.append("name/boss mismatch")
    if not number(data.scroll_speed) or data.scroll_speed < 64 or data.scroll_speed > 100:
        errors.append("invalid scroll_speed")
    if data.duration_ticks != 7200 or not data.checkpoints_ticks is Array or data.checkpoints_ticks.size() != 4:
        errors.append("duration/checkpoint contract")
    else:
        for i: int in 4:
            if data.checkpoints_ticks[i] != i*2400:
                errors.append("checkpoint contract")
    if not data.terrain is Array or data.terrain.size() < 2:
        errors.append("terrain requires at least two nodes")
        return errors
    var previous := -INF
    for row: Variant in data.terrain:
        if not row is Array or row.size() != 3 or not number(row[0]) or not number(row[1]) or not number(row[2]):
            errors.append("invalid terrain row")
            continue
        if row[0] <= previous or row[0] < 0 or row[0] > 120 or row[1] < 24 or row[2] > 336 or row[2]-row[1] < 100:
            errors.append("terrain ordering/bounds/gap")
        previous = row[0]
    if not errors.is_empty():
        return errors
    if data.terrain[0][0] != 0 or data.terrain[-1][0] != 120:
        errors.append("terrain must span 0..120 seconds")
    for key: String in ["events","hazards","beams"]:
        if not data[key] is Array:
            errors.append(key+" must be an array")
            return errors
    var ids: Dictionary = {}
    previous = -1
    for event: Variant in data.events:
        if not event is Dictionary:
            errors.append("invalid event")
            continue
        allowed_keys(event,["id","at_tick","enemy","entry","y","count","gap_ticks","drop","pickup","variant"],errors,"event")
        for key: String in ["id","at_tick","enemy","entry","y","count","gap_ticks"]:
            if not event.has(key):
                errors.append("event missing "+key)
        if not errors.is_empty():
            continue
        if not event.id is String or event.id.is_empty() or not event.enemy is String:
            errors.append("invalid event identity")
            continue
        if ids.has(event.id):
            errors.append("duplicate event id")
        ids[event.id] = true
        if not integer(event.at_tick) or not integer(event.count) or not integer(event.gap_ticks) or event.count < 1 or event.count > 64 or event.gap_ticks < 0:
            errors.append("invalid event ticks/count")
            continue
        if event.at_tick < previous or event.at_tick < 0 or event.at_tick+(event.count-1)*event.gap_ticks >= 7200 or (event.count>1 and event.gap_ticks==0):
            errors.append("event order/end/gap")
        previous = event.at_tick
        var enemy: String = str(event.enemy)
        if enemy != "PICKUP" and (enemy.length()!=3 or not enemy.begins_with("E") or not enemy.substr(1).is_valid_int() or int(enemy.substr(1))<1 or int(enemy.substr(1))>16):
            errors.append("unknown enemy")
        if event.entry not in ["R","L","T","B"] or (event.entry=="L" and enemy not in ["E07","E11"]):
            errors.append("invalid entry")
        if event.entry in ["T","B"] and (enemy not in ["E03","E10"] or event.y != null):
            errors.append("invalid mount")
        if event.entry in ["R","L"]:
            var y: Variant = event.y
            var valid := number(y)
            if y is Array:
                valid = not y.is_empty()
                for item: Variant in y:
                    valid = valid and number(item)
            elif y is Dictionary:
                valid = y.size()==1 and y.has("corr") and number(y.corr) and y.corr>=0 and y.corr<=1
            if not valid:
                errors.append("invalid y DSL")
        if event.has("drop") and enemy != "E05":
            errors.append("drop only allowed on courier")
        if event.has("pickup") and enemy != "PICKUP":
            errors.append("pickup field only allowed on PICKUP")
        if enemy == "E05" and event.get("drop","") not in PICKUPS:
            errors.append("courier requires valid drop")
        if enemy == "PICKUP" and (event.get("pickup","") not in PICKUPS or event.count != 1):
            errors.append("invalid direct pickup")
        if event.has("variant") and (enemy != "E16" or event.variant not in ["UP","DOWN"]):
            errors.append("unsupported variant")
    for hazard: Variant in data.hazards:
        if not hazard is Dictionary:
            errors.append("invalid hazard")
            continue
        allowed_keys(hazard,["id","kind","at_tick","width","y","height","gap_height","amplitude","period","phase"],errors,"hazard")
        for key: String in ["id","kind","at_tick","width","y"]:
            if not hazard.has(key):
                errors.append("hazard missing "+key)
        if not errors.is_empty():
            continue
        if not hazard.id is String or hazard.id.is_empty():
            errors.append("invalid hazard identity")
            continue
        if ids.has(hazard.id):
            errors.append("duplicate hazard id")
        ids[hazard.id] = true
        if hazard.kind not in ["worldRect","oscRect","gate"]:
            errors.append("unknown hazard kind")
        for key: String in ["at_tick","width","y","height","gap_height","amplitude","period","phase"]:
            if hazard.has(key) and not number(hazard[key]):
                errors.append("nonfinite hazard "+key)
        if not errors.is_empty():
            continue
        if not integer(hazard.at_tick) or hazard.at_tick<0 or hazard.at_tick>=7200 or hazard.width<=0 or hazard.get("height",1)<=0 or hazard.get("period",1)<=0 or hazard.get("gap_height",100)<48:
            errors.append("invalid hazard dimensions/timing")
        if hazard.kind == "gate" and not hazard.has_all(["gap_height","amplitude","period"]):
            errors.append("gate parameters missing")
        if hazard.kind == "oscRect" and not hazard.has_all(["height","amplitude","period","phase"]):
            errors.append("oscRect parameters missing")
        if hazard.kind == "worldRect" and not hazard.has("height"):
            errors.append("worldRect height missing")
    for beam: Variant in data.beams:
        if not beam is Dictionary:
            errors.append("invalid beam")
            continue
        var required := ["id","at_tick","y","width","warning_ticks","active_ticks","x"]
        allowed_keys(beam,required,errors,"beam")
        if not beam.has_all(required):
            errors.append("beam parameters missing")
            continue
        if not beam.id is String or beam.id.is_empty():
            errors.append("invalid beam identity")
            continue
        if ids.has(beam.id):
            errors.append("duplicate beam id")
        ids[beam.id] = true
        for key: String in required:
            if key != "id" and not number(beam[key]):
                errors.append("invalid beam number")
        if not errors.is_empty():
            continue
        if not integer(beam.at_tick) or not integer(beam.warning_ticks) or not integer(beam.active_ticks) or beam.at_tick<0 or beam.warning_ticks<=0 or beam.active_ticks<=0 or beam.at_tick+beam.warning_ticks+beam.active_ticks>7200 or beam.width<=0 or beam.x!=640:
            errors.append("invalid beam timing/geometry")
    return errors
