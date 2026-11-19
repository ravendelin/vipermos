extends RefCounted
const World = preload("res://scripts/combat/collision_world.gd")
var data: Dictionary = {}
var installed: Array[int] = []
var samples: Array[Vector3] = []
var hazard_shapes: Array[int] = []
var warnings: Array[Dictionary] = []
var scroll_x: float = 0.0
var tick: int = 0

func configure(stage: Dictionary) -> void:
    data = stage

func top_at(world_x: float) -> float:
    return _boundary(world_x,1)

func bottom_at(world_x: float) -> float:
    return _boundary(world_x,2)

func _boundary(world_x: float, column: int) -> float:
    var time: float = (world_x-640.0)/data.scroll_speed
    var nodes: Array = data.terrain
    if time <= nodes[0][0]:
        return nodes[0][column]
    for i: int in range(1,nodes.size()):
        if time <= nodes[i][0]:
            return lerpf(nodes[i-1][column],nodes[i][column],(time-nodes[i-1][0])/(nodes[i][0]-nodes[i-1][0]))
    return nodes[-1][column]

func clear(world: RefCounted) -> void:
    for id: int in installed:
        world.shapes.erase(id)
    installed.clear()
    samples.clear()
    hazard_shapes.clear()
    warnings.clear()

func update(world: RefCounted, at_tick: int, previous_tick: int = -1) -> void:
    clear(world)
    tick = at_tick
    if tick >= 7200:
        return
    scroll_x = float(data.scroll_speed)*tick/60.0
    var before: int = tick if previous_tick < 0 else previous_tick
    var previous_scroll: float = float(data.scroll_speed)*before/60.0
    var first := floori((scroll_x-80)/8)
    var last := ceili((scroll_x+720)/8)
    for index: int in range(first,last+1):
        var wx := index*8.0
        samples.append(Vector3(wx-scroll_x,top_at(wx),bottom_at(wx)))
    for index: int in samples.size()-1:
        var left := samples[index]
        var right := samples[index+1]
        var id := 1000000+(first+index)*2
        if maxf(left.y,right.y)>24:
            world.add_polygon(id,-1,PackedVector2Array([Vector2(left.x,24),Vector2(right.x,24),Vector2(right.x,right.y),Vector2(left.x,left.y)]),Vector2(scroll_x-previous_scroll,0))
            installed.append(id)
        if minf(left.z,right.z)<336:
            world.add_polygon(id+1,-1,PackedVector2Array([Vector2(left.x,left.z),Vector2(right.x,right.z),Vector2(right.x,336),Vector2(left.x,336)]),Vector2(scroll_x-previous_scroll,0))
            installed.append(id+1)
    for i: int in data.hazards.size():
        var hazard: Dictionary = data.hazards[i]
        var current := hazard_rects(hazard,tick)
        var past := hazard_rects(hazard,before)
        var enter_tick: float = hazard.at_tick - hazard.width/2.0/data.scroll_speed*60.0
        if tick >= enter_tick-48 and tick < enter_tick:
            warnings.append({"y":hazard.y,"moving":hazard.get("amplitude",0)>0})
        for part: int in current.size():
            var rect: Rect2 = current[part]
            if rect.end.x < -80 or rect.position.x > 720:
                continue
            var id := 2000000+i*2+part
            world.add_box(id,-1,rect)
            world.shapes[id].previous = past[part].get_center()
            installed.append(id)
            hazard_shapes.append(id)

func hazard_rects(hazard: Dictionary, at_tick: int) -> Array[Rect2]:
    var x: float = 640+float(data.scroll_speed)*(float(hazard.at_tick)-at_tick)/60.0
    var y: float = hazard.y
    if hazard.kind in ["oscRect","gate"]:
        y += hazard.amplitude*sin(TAU*(at_tick-hazard.at_tick)/60.0/hazard.period+hazard.get("phase",0.0))
    var width: float = hazard.width
    if hazard.kind == "gate":
        # Two fixed-height slabs translate together: collision motion remains exact.
        return [Rect2(x-width/2,y-hazard.gap_height/2-312,width,312),Rect2(x-width/2,y+hazard.gap_height/2,width,312)]
    return [Rect2(x-width/2,y-hazard.height/2,width,hazard.height)]

func safe_point(world: RefCounted, at_tick: int) -> Vector2:
    update(world,at_tick)
    var sx: float = data.scroll_speed*at_tick/60.0
    var preferred := Vector2(96,(top_at(96+sx)+bottom_at(96+sx))/2)
    if not world.solid_hit(preferred,preferred,20):
        return preferred
    var best := Vector2(INF,INF)
    var distance := INF
    for x: int in range(48,161,4):
        for y: int in range(40,321,4):
            var point := Vector2(x,y)
            var candidate := point.distance_squared_to(Vector2(96,180))
            if candidate < distance and not world.solid_hit(point,point,20):
                best = point
                distance = candidate
    return best

func clip_left(world: RefCounted, start: Vector2, width: float) -> float:
    # Beam is a vertical cross-section swept horizontally; closest solid wins.
    var finish := Vector2(0,start.y)
    var first := 1.0
    for shape: Dictionary in world.shapes.values():
        if shape.category == "terrain":
            var current := shape.duplicate()
            current.previous = current.position
            var contact: float = World.sweep(start,finish,Vector2.UP,Vector2(width,0.001),current)
            first = minf(first,contact)
    return lerpf(start.x,0,first)
