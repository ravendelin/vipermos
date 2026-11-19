extends SceneTree
const StageData = preload("res://scripts/data/stage_data.gd")
const Terrain = preload("res://scripts/game/terrain_profile.gd")
const World = preload("res://scripts/combat/collision_world.gd")
func _initialize() -> void:
    var failures := 0
    var files: Array[String] = []
    var args := OS.get_cmdline_user_args()
    if "--file" in args and args.find("--file")+1 < args.size():
        files.append(args[args.find("--file")+1])
    else:
        for i: int in range(1,9):
            files.append("res://data/stages/s%02d.json" % i)
    for path: String in files:
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        var errors := StageData.validate(parsed)
        if not errors.is_empty():
            failures += 1
            printerr(path+": "+"; ".join(errors))
            continue
        var terrain := Terrain.new()
        terrain.configure(parsed)
        var world := World.new()
        for checkpoint: int in [0,2400,4800,7200]:
            var point := terrain.safe_point(world,checkpoint)
            if not is_finite(point.x):
                failures += 1
                printerr(path+": unsafe checkpoint "+str(checkpoint))
    print("STAGE_VALIDATION files=%d failures=%d" % [files.size(),failures])
    quit(1 if failures else 0)
