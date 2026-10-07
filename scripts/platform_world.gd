extends RefCounted
# Moving one-way surfaces; no rendering, audio, input or global state.
const P = preload("res://scripts/physics_config.gd")
var boats: Array[Dictionary]=[]
var receiver_active: bool=false
func reset(level: Dictionary) -> void:
 boats.clear()
 receiver_active=false
 for source in level.get("boats",[]):
  var boat: Dictionary=source.duplicate(true)
  boat.x=float(source.get("start",source.get("from",240)))
  boat.y=float(source.get("y",425))
  boat.dx=0.0
  boat.dy=0.0
  boat.direction=int(source.get("direction",1))
  boat.vertical_direction=1
  boats.append(boat)
func advance(dt: float, rider: int, quiet: bool, powered: bool) -> void:
 for i in range(boats.size()):
  var b: Dictionary=boats[i]
  var old:=Vector2(b.x,b.y)
  var speed: float=float(b.get("speed",90))
  var mode: String=b.get("mode","auto")
  if mode=="auto":
   var target: float=float(b.to if b.direction>0 else b.from)
   b.x=move_toward(b.x,target,speed*dt)
   if is_equal_approx(b.x,target): b.direction=-b.direction
  elif mode in ["ferry","powered"]:
   if mode=="powered" and not powered: pass
   elif rider==i:
    if quiet: b.x=move_toward(b.x,float(b.to),speed*dt)
   else: b.x=move_toward(b.x,float(b.from),speed*0.65*dt)
  if b.has("vertical"):
   var range_y: Array=b.vertical
   var target_y: float=float(range_y[1] if b.vertical_direction>0 else range_y[0])
   b.y=move_toward(b.y,target_y,float(range_y[2])*dt)
   if is_equal_approx(b.y,target_y): b.vertical_direction=-b.vertical_direction
  b.dx=b.x-old.x
  b.dy=b.y-old.y
func surfaces(level: Dictionary) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 var ground: Array=level.get("banks",[[0,P.FLOOR,P.WIDTH]])
 for s in ground: result.append({"x":float(s[0]),"y":float(s[1]),"w":float(s[2]),"boat":-1})
 for s in level.get("platforms",[]): result.append({"x":float(s[0]),"y":float(s[1]),"w":float(s[2]),"boat":-1})
 if receiver_active:
  for s in level.get("light_platforms",[]): result.append({"x":float(s[0]),"y":float(s[1]),"w":float(s[2]),"boat":-1})
 for i in range(boats.size()):
  var b: Dictionary=boats[i]
  result.append({"x":b.x-float(b.w)/2,"y":b.y,"w":float(b.w),"boat":i})
 return result
