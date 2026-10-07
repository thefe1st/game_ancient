extends RefCounted
# Deterministic platform solver, with explicit one-way surfaces. No rendering or input APIs.
const P = preload("res://scripts/physics_config.gd")
const Rules = preload("res://scripts/rules.gd")
const PlatformWorld = preload("res://scripts/platform_world.gd")
var level: Dictionary
var index: int
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var height: float = 56.0
var grounded: bool = true
var face: int = 1
var eyes: bool = false
var crouch: bool = false
var fruit := Vector2.ZERO
var home := Vector2.ZERO
var has_fruit: bool = false
var ate: bool = false
var drank: bool = false
var won: bool = false
var fleeing: bool = false
var boulder: float = -1.0
var boulder_rotation: float = 0.0
var water_y: float = 402.0
var idle: float = 0.0
var drink_timer: float = 0.0
var elapsed: float = 0.0
var taunts: int = 0
var events: Array[String] = []
var coyote: float = 0.1
var buffer: float = 0.0
var taunt_cooldown: float = 0.0
var was_water_crouch: bool = false
var hop_time: float = -1.0
var hop_from: float = 0.0
var hop_to: float = 0.0
var footstep: float = 0.0
var torch_lit: bool = true
var noise: float = 0.0
var alert_time: float = 0.0
var world=PlatformWorld.new()
var support_boat: int=-1
var torch_x: float=0.0
var carried_torch: bool=false
var interaction_timer: float=0.0
func reset(data: Dictionary, number: int) -> void:
 level = data.duplicate(true)
 index = number
 pos = Vector2(float(level.start), P.FLOOR - P.BODY_SIZE.y)
 vel = Vector2.ZERO
 height = P.BODY_SIZE.y
 grounded = true
 face = 1
 eyes = false
 crouch = false
 has_fruit = level.has("fruit")
 home = Vector2(level.fruit[0], level.fruit[1]) if has_fruit else Vector2.ZERO
 fruit = home
 boulder = float(level.get("boulder", -1))
 boulder_rotation = 0.0
 ate = false
 drank = false
 won = false
 fleeing = false
 water_y = 402.0
 idle = 0.0
 drink_timer = 0.0
 elapsed = 0.0
 taunts = 0
 coyote = P.COYOTE_TIME
 buffer = 0.0
 taunt_cooldown = 0.0
 was_water_crouch = false
 hop_time = -1.0
 footstep = 0.0
 torch_lit=true
 noise=0.0
 alert_time=0.0
 support_boat=-1
 carried_torch=false
 torch_x=float(level.get("torch",0))
 interaction_timer=0.0
 world.reset(level)
 update_light()
 events.clear()
func mock(force: bool=false) -> void:
 if force or taunt_cooldown <= 0:
  taunts += 1
  events.append("taunt")
  taunt_cooldown = 1.5
func step(dt: float, input: Dictionary) -> void:
 events.clear()
 if won: return
 elapsed += dt
 taunt_cooldown -= dt
 interaction_timer=maxf(0,interaction_timer-dt)
 if alert_time>0:
  alert_time=maxf(0,alert_time-dt)
  if alert_time<=0: soft_respawn()
  return
 if input.get("interact",false) and level.has("torch"):
  interact_torch(bool(input.get("crouch",false)))
 update_light()
 var moving: bool=absf(float(input.get("move",0)))>0.05
 var quiet: bool=not moving or bool(input.get("crouch",false))
 if input.get("jump",false): quiet=false
 world.advance(dt,support_boat if grounded else -1,quiet,world.receiver_active)
 if grounded and support_boat>=0 and support_boat<world.boats.size():
  var boat: Dictionary=world.boats[support_boat]
  pos+=Vector2(boat.dx,boat.dy)
 if input.get("eyes", false):
  eyes = not eyes
  events.append("eyes")
 var direction: float = clampf(float(input.get("move", 0)), -1, 1)
 var back: bool = input.get("back", false)
 var jump: bool = input.get("jump", false)
 idle = 0.0 if absf(direction) > 0.05 or jump or input.get("crouch", false) else idle + dt
 crouch = input.get("crouch", false) and grounded
 var next_height: float = P.CROUCH_HEIGHT if crouch else P.BODY_SIZE.y
 pos.y += height - next_height
 height = next_height
 if absf(direction) > 0.05 and not back: face = 1 if direction > 0 else -1
 coyote = P.COYOTE_TIME if grounded else maxf(0.0, coyote - dt)
 buffer = P.JUMP_BUFFER if jump else maxf(0.0, buffer - dt)
 if buffer > 0 and coyote > 0 and not crouch:
  vel.y = -P.JUMP_SPEED
  grounded = false
  coyote = 0.0
  buffer = 0.0
  events.append("jump")
 vel.x = direction * (P.CROUCH_SPEED if crouch else P.BACK_SPEED if back else P.SPEED)
 vel.y += P.GRAVITY * dt
 pos.x = clampf(pos.x + vel.x * dt, 20, P.WIDTH - 20 - P.BODY_SIZE.x)
 if grounded and absf(direction) > 0.05:
  footstep += dt
  if footstep > (0.42 if crouch else 0.28):
   footstep = 0.0
   events.append("quiet_step" if crouch else "step")
 if boulder >= 0 and pos.y + height > P.FLOOR - 76 + 6 and pos.x + 26 > boulder - 38 and pos.x < boulder + 38:
  var old_boulder: float = boulder
  if pos.x + 13 < boulder:
   if grounded and vel.x > 0: boulder = clampf(pos.x + 64, 60, 900)
   pos.x = minf(pos.x, boulder - 64)
  else:
   if grounded and vel.x < 0: boulder = clampf(pos.x - 38, 60, 900)
   pos.x = maxf(pos.x, boulder + 38)
  boulder_rotation += (boulder - old_boulder) / 38.0
 var previous_feet: float = pos.y + height
 pos.y += vel.y * dt
 grounded = false
 support_boat=-1
 var surfaces: Array[Dictionary]=world.surfaces(level)
 if boulder>=0: surfaces.append({"x":boulder-30,"w":60.0,"y":P.FLOOR-76,"boat":-1})
 for surface in surfaces:
  if vel.y>=0 and previous_feet<=surface.y+0.5 and pos.y+height>=surface.y and pos.x+26>surface.x and pos.x<surface.x+surface.w:
   pos.y=surface.y-height
   vel.y=0.0
   grounded=true
   support_boat=surface.boat
 if level.has("banks") and pos.y>P.FLOOR+80:
  mock(true)
  events.append("splash")
  soft_respawn()
  return
 if carried_torch: torch_x=clampf(pos.x+13+face*24,20,P.WIDTH-20)
 update_light()
 var center := pos + Vector2(13, height / 2)
 if level.has("guardian"):
  var target_noise: float=Rules.noise_target(absf(direction)>0.05,crouch,not grounded)
  noise=move_toward(noise,target_noise,dt*1.8)
  if absf(center.x-float(level.guardian))<float(level.get("guard_radius",340)) and noise>=0.65:
   alert_time=0.65
   mock()
   events.append("bark")
   return
 if has_fruit and not ate:
  var distance: float = fruit.distance_to(center)
  var flee: bool = Rules.fruit_flees(level.rule, distance - (150.0 if fleeing else 0.0), fruit.x - center.x, face, eyes, crouch)
  if level.rule=="shadow": flee=Rules.shadow_flees(center.x,home.x,torch_x,torch_lit)
  if flee and not fleeing: mock()
  fleeing = flee
  var target: Vector2 = home
  var speed: float = 120.0
  if level.rule == "mirror":
   target = Vector2(P.WIDTH - center.x, home.y)
   speed = 330.0
  elif level.rule == "sneak":
   target = fruit
   if fleeing:
    var side: float = 1.0 if fruit.x >= center.x else -1.0
    target = Vector2(clampf(center.x + side * 300, 50, 910), 424)
    speed = 270.0
    if distance < 110 and (fruit.x < 53 or fruit.x > 907) and hop_time < 0:
     hop_time = 0.0
     hop_from = fruit.x
     hop_to = clampf(center.x - side * 280, 50, 910)
  elif fleeing:
   target = home + Vector2(50 * signf(home.x - center.x), -190)
   speed = 520.0
  if hop_time >= 0:
   hop_time = minf(1, hop_time + dt * 1.5)
   fruit = Vector2(lerpf(hop_from, hop_to, hop_time), 424 - sin(hop_time * PI) * 170)
   if hop_time >= 1: hop_time = -1.0
  else: fruit = fruit.move_toward(target, speed * dt)
  var reach := Rect2(pos - Vector2(10, 16), Vector2(46, height + 16)).grow(17)
  if reach.has_point(fruit):
   ate = true
   events.append("eat")
 if level.has("pool") and not drank:
  var inside: bool = center.x > float(level.pool[0]) + 10 and center.x < float(level.pool[1]) - 10
  var target_water: float = Rules.water_target(inside, crouch, eyes, idle)
  if inside and crouch and not was_water_crouch: mock()
  was_water_crouch = inside and crouch
  var water_speed: float = 400.0 if target_water == 436 else 16.0 if target_water == 355 else 90.0
  water_y = move_toward(water_y, target_water, water_speed * dt)
  if inside and water_y < pos.y + 15:
   drink_timer += dt
   if drink_timer >= P.DRINK_DURATION:
    drank = true
    events.append("drink")
  else: drink_timer = maxf(0, drink_timer - dt)
 won = (not has_fruit or ate) and (not level.has("pool") or drank)
 if won: events.append("win")

func interact_torch(crouch_command: bool) -> void:
 if interaction_timer>0: return
 if not carried_torch and absf(pos.x+13-torch_x)>=60: return
 interaction_timer=0.18
 if not level.get("portable_torch",false): torch_lit=not torch_lit
 elif crouch_command: torch_lit=not torch_lit
 elif carried_torch: carried_torch=false
 else:
  carried_torch=true
  torch_x=clampf(pos.x+13+face*24,20,P.WIDTH-20)
 events.append("torch")
func update_light() -> void:
 var was_active: bool=world.receiver_active
 world.receiver_active=false
 if level.has("light_receiver") and torch_lit and not carried_torch:
  var receiver: Array=level.light_receiver
  world.receiver_active=absf(torch_x-float(receiver[0]))<=float(receiver[1])
 if world.receiver_active and not was_active: events.append("light")
func soft_respawn() -> void:
 # Retain collected rewards and placed lights; time/taunts do not reset.
 pos=Vector2(float(level.start),P.FLOOR-P.BODY_SIZE.y)
 vel=Vector2.ZERO
 height=P.BODY_SIZE.y
 grounded=true
 crouch=false
 support_boat=-1
 noise=0.0
 coyote=P.COYOTE_TIME
 buffer=0.0
 drink_timer=0.0
 idle=0.0
 if carried_torch: torch_x=clampf(pos.x+13+face*24,20,P.WIDTH-20)
 update_light()
