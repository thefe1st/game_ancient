extends Node2D
const INK := Color("1b120c")
const CLAY := Color("c8683a")
const CREAM := Color("f3dcc0")
const GOLD := Color("e9ae5b")
var sim: RefCounted
var seconds: float = 0.0
func _process(delta: float) -> void:
 seconds += delta
 queue_redraw()
func _draw() -> void:
 draw_rect(Rect2(0, 0, 960, 540), Color("d98a4e"))
 for i in range(24):
  draw_rect(Rect2(0, i * 19, 960, 19), Color("c8683a").lerp(Color("d98a4e"), 1.0 - float(i) / 24))
 draw_circle(Vector2(160, 165), 52, Color(0.95, 0.83, 0.65, 0.24))
 draw_colored_polygon(PackedVector2Array([Vector2(0,440),Vector2(0,300),Vector2(125,260),Vector2(235,320),Vector2(390,225),Vector2(525,310),Vector2(650,250),Vector2(815,325),Vector2(960,240),Vector2(960,440)]),Color(0.1,0.06,0.04,0.10))
 for x in [74, 890]:
  draw_rect(Rect2(x, 215, 23, 225), Color(0.1,0.06,0.04,0.15))
  draw_rect(Rect2(x - 8, 205, 39, 10), Color(0.1,0.06,0.04,0.15))
 draw_rect(Rect2(0, 440, 960, 100), INK)
 meander(0, 30)
 meander(487, 26)
 draw_line(Vector2(0,463),Vector2(960,463),CLAY,2)
 if sim == null: return
 for platform in sim.level.platforms:
  var rectangle := Rect2(platform[0], platform[1], platform[2], 12)
  draw_rect(rectangle, INK)
  draw_line(rectangle.position+Vector2(5,4),rectangle.position+Vector2(rectangle.size.x-5,4),CREAM,1)
 if sim.level.has("pool"):
  var left: float = sim.level.pool[0]
  var right: float = sim.level.pool[1]
  var tint := Color(0.95,0.85,0.7,0.34)
  draw_rect(Rect2(left,sim.water_y,right-left,440-sim.water_y),tint)
  for i in range(7):
   var x: float = left+8+i*(right-left-16)/7
   var offset: float = 0.0 if Settings.reduced_motion else sin(seconds*3+i)*2
   draw_line(Vector2(x,sim.water_y+offset),Vector2(x+26,sim.water_y+offset),CREAM,1.4)
 if sim.level.rule in ["back", "eyes", "stone", "feast"]: tree()
 if sim.level.rule == "mirror":
  draw_line(Vector2(480,145),Vector2(480,440),Color(0.95,0.85,0.7,0.35),1)
  draw_circle(Vector2(480,434),8,CREAM)
  person(Vector2(960-sim.pos.x-26,sim.pos.y),-sim.face,0.18)
 if sim.boulder >= 0:
  var center := Vector2(sim.boulder,402)
  draw_circle(center,38,INK)
  draw_arc(center,30,0.3,5.7,32,CREAM,1.5,true)
  var angle: float = sim.boulder_rotation
  draw_line(center,center+Vector2(cos(angle),sin(angle))*26,CREAM,2)
 if sim.has_fruit and not sim.ate: fruit()
 person(sim.pos,sim.face,1.0)
 if sim.eyes:
  draw_rect(Rect2(0,110,960,330),Color(0.055,0.035,0.025,0.85))
  person(sim.pos,sim.face,0.65)
  if sim.has_fruit and not sim.ate:
   for i in range(9):
    var drift: float = 0.0 if Settings.reduced_motion else seconds*0.6
    var angle: float = i*0.8+drift
    draw_circle(sim.fruit+Vector2(cos(angle)*22,sin(angle)*14),1.4,Color(0.95,0.85,0.7,0.7))
  if sim.level.has("pool"):
   draw_line(Vector2(sim.level.pool[0],sim.water_y),Vector2(sim.level.pool[1],sim.water_y),Color(0.95,0.85,0.7,0.65),1.5)
func meander(y: float, height: float) -> void:
 draw_rect(Rect2(0,y,960,height),INK)
 for i in range(32):
  var x: float = i*30
  draw_polyline(PackedVector2Array([Vector2(x,y+height-5),Vector2(x,y+5),Vector2(x+23,y+5),Vector2(x+23,y+height-9),Vector2(x+9,y+height-9),Vector2(x+9,y+11),Vector2(x+17,y+11)]),CLAY,1.6,true)
func tree() -> void:
 draw_polyline(PackedVector2Array([Vector2(863,440),Vector2(872,300),Vector2(853,210),Vector2(828,160)]),INK,22,true)
 draw_line(Vector2(850,210),Vector2(sim.home.x,sim.home.y-16),INK,7,true)
 for i in range(10):
  var a: float = i*0.7
  var p := Vector2(814+cos(a)*65,167+sin(a*1.3)*34)
  draw_circle(p,17,INK)
  draw_line(p+Vector2(-7,0),p+Vector2(8,-3),CLAY,1)
func fruit() -> void:
 var p: Vector2 = sim.fruit
 if sim.level.rule == "mirror": draw_line(Vector2(p.x,145),p-Vector2(0,13),INK,1)
 draw_circle(p,14,INK)
 draw_arc(p,9,3.5,4.7,12,CREAM,1.5,true)
 draw_line(p-Vector2(0,12),p-Vector2(1,21),INK,3)
 draw_circle(p+Vector2(4,3),3,Color("a8352a"))
 if sim.level.rule == "sneak":
  draw_line(p+Vector2(-4,10),p+Vector2(-8,16),INK,3)
  draw_line(p+Vector2(4,10),p+Vector2(8,16),INK,3)
  draw_circle(p+Vector2(-4,-2),2,CREAM)
  draw_circle(p+Vector2(5,-2),2,CREAM)
func person(p: Vector2, facing: int, opacity: float) -> void:
 var h: float = sim.height
 var color := Color(INK,opacity)
 var detail := Color(CREAM,opacity)
 var head := p+Vector2(13,8)
 draw_circle(head,9,color)
 draw_line(head+Vector2(facing*5,0),head+Vector2(facing*12,3),color,3)
 draw_rect(Rect2(p+Vector2(6,17),Vector2(14,h-32)),color)
 var phase: float = 0.0 if Settings.reduced_motion else sin(seconds*12)*5*minf(1,absf(sim.vel.x)/130)
 draw_line(p+Vector2(9,h-16),p+Vector2(7+phase,h),color,5,true)
 draw_line(p+Vector2(18,h-16),p+Vector2(20-phase,h),color,5,true)
 draw_line(p+Vector2(18,20),p+Vector2(13+facing*20,30),color,4,true)
 draw_line(p+Vector2(9,20),p+Vector2(13-facing*13,34),color,4,true)
 draw_line(p+Vector2(8,18),p+Vector2(17,h-17),detail,1.2)
 if sim.eyes: draw_line(head+Vector2(facing*5,-1),head+Vector2(facing*8,-1),detail,1)
 else: draw_circle(head+Vector2(facing*6,-1),1.3,detail)
