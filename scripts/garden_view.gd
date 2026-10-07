extends Node2D
const INK := Color("1b120c")
const CLAY := Color("c8683a")
const CREAM := Color("f3dcc0")
const GOLD := Color("e9ae5b")
var sim: RefCounted
var seconds: float = 0.0
func _process(delta: float) -> void:
 if sim==null or get_parent().screen=="play": seconds += delta
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
 meander(457, 20)
 draw_line(Vector2(0,480),Vector2(960,480),CLAY,1)
 if sim == null: return
 if int(sim.level.get("act",0))>=1:
  for i in range(22):
   draw_rect(Rect2(0,110+i*15,960,15),Color("b99472").lerp(Color("967252"),float(i)/22))
  for x in [100,420,810]:
   draw_arc(Vector2(x,290),116,PI,TAU,36,Color(0.10,0.06,0.04,0.17),12,true)
   draw_line(Vector2(x-116,290),Vector2(x-116,440),Color(0.10,0.06,0.04,0.17),12)
   draw_line(Vector2(x+116,290),Vector2(x+116,440),Color(0.10,0.06,0.04,0.17),12)
 if sim.level.has("torch"): torch()
 if sim.level.rule=="shadow":
  if sim.torch_lit:
   var hero_x: float=sim.pos.x+13
   var side: float=1.0 if hero_x>=sim.torch_x else -1.0
   var tip: float=clampf(hero_x+side*240,20,940)
   draw_colored_polygon(PackedVector2Array([Vector2(hero_x-10,440),Vector2(hero_x+10,440),Vector2(tip+30,342),Vector2(tip-22,342)]),Color(0.10,0.06,0.04,0.72))
   draw_circle(Vector2(tip,317),22,Color(0.10,0.06,0.04,0.72))
 if sim.level.has("guardian"): cerberus()
 if sim.level.has("banks"):
  var left: float=sim.level.banks[0][2]
  var right: float=sim.level.banks[1][0]
  draw_rect(Rect2(left,435,right-left,45),Color("395257"))
  for i in range(12):
   var x: float=left+i*(right-left)/12
   var drift: float=0 if Settings.reduced_motion else sin(seconds*2+i)*2
   draw_line(Vector2(x,444+drift),Vector2(x+18,444+drift),Color("91a6a0"),1)
  for bank in sim.level.banks:
   draw_rect(Rect2(bank[0],bank[1],bank[2],17),INK)
   draw_line(Vector2(bank[0],bank[1]),Vector2(bank[0]+bank[2],bank[1]),CREAM,2)
 if sim.level.has("vessel_source"):
  var spring: float=sim.level.vessel_source
  var well: float=sim.level.vessel_target
  draw_rect(Rect2(spring-26,413,52,27),Color("624b38"))
  draw_line(Vector2(spring-20,417),Vector2(spring+20,417),CREAM,2)
  draw_arc(Vector2(spring,392),18,PI,TAU,24,Color("624b38"),6,true)
  draw_line(Vector2(spring,394),Vector2(spring,415),Color("91b3b0"),4)
  draw_rect(Rect2(well-30,407,60,33),Color("624b38"))
  draw_line(Vector2(well-26,412),Vector2(well+26,412),GOLD if sim.water_delivered else CREAM,3)
  if sim.water_delivered: draw_circle(Vector2(well,430),7,GOLD)
 if sim.level.has("plate"):
  var plate_x: float=sim.level.plate[0]
  draw_rect(Rect2(plate_x-32,435,64,5),GOLD if sim.world.receiver_active else Color("685440"))
  draw_line(Vector2(plate_x-32,435),Vector2(plate_x+32,435),CREAM,2)
 for boat in sim.world.boats:
  var x: float=boat.x
  var y: float=boat.y
  var w: float=boat.w
  draw_colored_polygon(PackedVector2Array([Vector2(x-w/2,y),Vector2(x+w/2,y),Vector2(x+w/2-12,y+16),Vector2(x-w/2+12,y+16)]),INK)
  draw_line(Vector2(x-w/2+5,y+3),Vector2(x+w/2-5,y+3),CREAM,2)
  if boat.get("style","")=="wheel":
   draw_circle(Vector2(x,y+39),38,INK)
   draw_arc(Vector2(x,y+39),31,0,TAU,40,CREAM,2,true)
   for spoke in range(6):
    var angle: float=spoke*TAU/6+(0 if Settings.reduced_motion else seconds*0.5)
    draw_line(Vector2(x,y+39),Vector2(x,y+39)+Vector2(cos(angle),sin(angle))*30,CREAM,1.5)
  else: draw_line(Vector2(x+25,y+3),Vector2(x+45,y+30),GOLD,3)
 if sim.level.has("light_receiver") or sim.level.has("plate") or sim.level.has("vessel_source"):
  light_surfaces()
 if sim.level.has("light_receiver"):
  var x: float=sim.level.light_receiver[0]
  var color: Color=GOLD if sim.world.receiver_active else Color("69523e")
  draw_arc(Vector2(x,432),18,PI,TAU,24,color,3,true)
  draw_line(Vector2(x-20,440),Vector2(x+20,440),color,3)
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
 if sim.level.rule in ["back", "eyes", "stone", "feast"] and not sim.level.has("banks") and int(sim.level.get("act",0))<2: tree()
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
 if sim.vessel_carried: vessel()
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
 # Mask falling actors beneath the river and keep the controls unobstructed.
 draw_rect(Rect2(0,457,960,83),INK)
 meander(457,20)
 draw_line(Vector2(0,480),Vector2(960,480),CLAY,1)
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
 if sim.level.rule in ["mirror","shadow"] or ((sim.level.has("banks") or int(sim.level.get("act",0))==2) and not sim.level.has("guardian")): draw_line(Vector2(p.x,145),p-Vector2(0,13),INK,1)
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

func torch() -> void:
 var x: float=sim.torch_x
 var base: float=sim.pos.y+sim.height-8 if sim.carried_torch else 430.0
 draw_set_transform(Vector2(0,base-430))
 draw_line(Vector2(x,430),Vector2(x,364),INK,7)
 draw_arc(Vector2(x,359),13,0,PI,20,INK,5,true)
 if sim.torch_lit:
  var wobble: float=0.0 if Settings.reduced_motion else sin(seconds*5)*3
  draw_circle(Vector2(x,349),38,Color(0.96,0.75,0.36,0.14))
  draw_colored_polygon(PackedVector2Array([Vector2(x-10,356),Vector2(x-4,340),Vector2(x+wobble,324),Vector2(x+11,355)]),GOLD)
  draw_line(Vector2(x-3,351),Vector2(x,337),CREAM,3)
 else:
  draw_line(Vector2(x-10,345),Vector2(x+10,345),INK,2)
  draw_circle(Vector2(x,356),4,CREAM)
 draw_set_transform(Vector2.ZERO)
func cerberus() -> void:
 var x: float=sim.level.guardian
 if sim.level.has("banks") or x>870: draw_set_transform(Vector2(-maxf(0,x-870),-45))
 draw_rect(Rect2(x-66,340,138,10),INK)
 draw_line(Vector2(x-58,350),Vector2(x-58,376),INK,5)
 draw_line(Vector2(x+63,350),Vector2(x+63,376),INK,5)
 draw_rect(Rect2(x-35,301,70,26),INK)
 for offset in [-25,20]:
  draw_line(Vector2(x+offset,324),Vector2(x+offset,339),INK,7)
 draw_polyline(PackedVector2Array([Vector2(x+33,307),Vector2(x+53,291),Vector2(x+56,273)]),INK,5,true)
 for i in range(3):
  var head:=Vector2(x-35+i*24,284-i*4)
  draw_line(head+Vector2(0,11),Vector2(x-25+i*20,310),INK,10,true)
  draw_circle(head,13,INK)
  draw_colored_polygon(PackedVector2Array([head+Vector2(-8,-7),head+Vector2(-11,-24),head+Vector2(2,-10)]),INK)
  draw_rect(Rect2(head-Vector2(21,1),Vector2(16,9)),INK)
  if sim.alert_time>0:
   draw_circle(head+Vector2(-6,-2),2.5,CREAM)
   draw_line(head+Vector2(-25,3),head+Vector2(-34,-3),CREAM,2)
  else: draw_line(head+Vector2(-9,-1),head+Vector2(-3,-1),CREAM,1.3)
 draw_rect(Rect2(x-66,354,138,13),INK)
 draw_rect(Rect2(x-64,356,134*sim.noise,9),GOLD if sim.noise<0.65 else Color("cc5838"))
 if sim.noise>=0.65: draw_line(Vector2(x+82,350),Vector2(x+82,361),INK,3)

 draw_set_transform(Vector2.ZERO)

func light_surfaces() -> void:
 for surface in sim.level.get("light_platforms",[]):
  var rect:=Rect2(surface[0],surface[1],surface[2],10)
  if sim.world.receiver_active:
   draw_rect(rect,INK)
   draw_line(rect.position,rect.position+Vector2(rect.size.x,0),GOLD,3)
  else: draw_rect(rect,Color(0.95,0.85,0.7,0.28),false,1)
func vessel() -> void:
 var center: Vector2=sim.pos+Vector2(13+sim.face*22,sim.height-17)
 draw_circle(center,12,INK)
 draw_arc(center,14,0,TAU,24,CREAM,1.2,true)
 draw_rect(Rect2(center+Vector2(-5,-17),Vector2(10,9)),INK)
 if sim.vessel_water>0:
  var h: float=sim.vessel_water*17
  draw_rect(Rect2(center+Vector2(-7,8-h),Vector2(14,h)),Color("91b3b0"))
