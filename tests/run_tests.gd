extends SceneTree
const Simulation = preload("res://scripts/simulation.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
const Rules = preload("res://scripts/rules.gd")
var failures: int = 0
var checks: int = 0
var dt: float = 1.0 / 60.0
var levels: Array
func check(condition: bool, description: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error("FAIL: "+description)
func frames(sim: RefCounted, seconds: float, controls: Dictionary = {}) -> void:
 for i in range(int(ceil(seconds/dt))): sim.step(dt,controls)
func move_to(sim: RefCounted, target: float, controls: Dictionary = {}) -> void:
 for i in range(int(20.0/dt)):
  if sim.won or absf(sim.pos.x-target)<4: return
  var input := controls.duplicate()
  input.move = clampf((target-sim.pos.x)/4.0,-1,1)
  sim.step(dt,input)
 check(false,"Movement timeout level %d" % sim.index)
func jump(sim: RefCounted, direction: float = 0) -> void:
 sim.step(dt,{"jump":true,"move":direction})
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 levels = Catalog.load_levels()
 check(levels.size()==26,"Twenty-five trials and escape chapter")
 check(Rules.fruit_flees("back",100,100,1,false,false),"Looking at fruit makes it flee")
 check(not Rules.fruit_flees("back",100,100,-1,false,false),"Facing away is safe")
 check(not Rules.fruit_flees("eyes",100,100,1,true,false),"Closed eyes are safe")
 check(not Rules.fruit_flees("sneak",100,100,1,false,true),"Crouching is safe")
 check(Rules.water_target(true,true,false,3)==436,"Crouching drains water")
 check(Rules.water_target(true,false,true,3)==355,"Stillness raises water")
 check(Rules.water_target(false,false,true,3)==402,"Outside pool does not drink")
 for fps in [30,60,120]:
  dt=1.0/fps
  for index in range(9): solve(index,fps)
 dt=1.0/60
 var s = Simulation.new()
 s.reset(levels[0],0)
 frames(s,0.05)
 jump(s)
 check(s.vel.y<0,"Jump starts upward")
 frames(s,0.7)
 check(s.grounded and is_equal_approx(s.pos.y,384),"Lands on floor")
 s.reset(levels[0],0)
 s.grounded=false
 s.coyote=0.05
 jump(s)
 check(s.vel.y<0,"Coyote jump")
 s.reset(levels[0],0)
 s.pos.y=380
 s.grounded=false
 s.coyote=0
 s.vel.y=120
 jump(s)
 frames(s,0.04)
 check(s.vel.y<0,"Buffered jump after landing")
 s.reset(levels[0],0)
 frames(s,0.1,{"move":-1})
 var facing: int=s.face
 frames(s,0.1,{"move":1,"back":true})
 check(s.face==facing,"Backwards movement keeps facing")
 s.reset(levels[0],0)
 frames(s,3.0,{"move":1})
 check(s.taunts>0 and not s.won,"Naive approach fails")
 s.reset(levels[2],2)
 move_to(s,440)
 frames(s,5,{"crouch":true})
 check(not s.won and s.taunts>0,"Crouching cannot solve thirst")
 s.reset(levels[0],0)
 check(s.taunts==0 and not s.eyes and s.grounded and s.hop_time<0,"Reset clears state")
 s.reset(levels[7],7)
 s.step(dt,{"interact":true})
 check(s.torch_lit,"Cannot use distant torch")
 move_to(s,200)
 s.step(dt,{"interact":true})
 check(not s.torch_lit,"Near torch toggles")
 check(Rules.shadow_flees(540,740,220,true),"Shadow reaches fruit")
 check(not Rules.shadow_flees(540,740,220,false),"Darkness removes shadow")
 s.reset(levels[7],7)
 s.step(dt,{"eyes":true})
 move_to(s,690)
 frames(s,0.5)
 check(s.fleeing and not s.won,"Closing eyes does not hide shadow")
 s.reset(levels[8],8)
 frames(s,2.0,{"move":1})
 check(s.taunts>0 and not s.won,"Loud walking wakes Cerberus")
 frames(s,1.0)
 check(s.pos.x<340 and s.alert_time<=0,"Cerberus sends hero back safely")
 var russian = JSON.parse_string(FileAccess.get_file_as_string("res://localization/ru.json"))
 var english = JSON.parse_string(FileAccess.get_file_as_string("res://localization/en.json"))
 check(russian.keys().size()==english.keys().size(),"Locale key counts match")
 for key in russian: check(english.has(key),"EN has "+key)
 print("TEST RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
func solve(index: int, fps: int) -> void:
 var s = Simulation.new()
 s.reset(levels[index],index)
 match index:
  0:
   frames(s,0.1,{"move":-1})
   move_to(s,707,{"back":true})
   jump(s)
   frames(s,0.7)
  1:
   s.step(dt,{"eyes":true})
   move_to(s,530)
   jump(s,1)
   frames(s,0.38,{"move":1})
   frames(s,0.5)
   jump(s)
   frames(s,0.7)
  2:
   s.step(dt,{"eyes":true})
   move_to(s,450)
   frames(s,8)
  3:
   move_to(s,748,{"crouch":true})
  4:
   move_to(s,467)
   frames(s,1.0)
   jump(s)
   frames(s,0.7)
  5:
   s.step(dt,{"eyes":true})
   move_to(s,696)
   jump(s,1)
   frames(s,0.25,{"move":1})
   frames(s,0.5)
   jump(s)
   frames(s,0.7)
  6:
   s.step(dt,{"eyes":true})
   move_to(s,547)
   frames(s,8)
   jump(s)
   frames(s,0.7)
  7:
   move_to(s,200)
   s.step(dt,{"interact":true})
   move_to(s,727)
   jump(s)
   frames(s,0.7)
  8:
   move_to(s,840,{"crouch":true})
 check(s.won,"Solution level %d at %d FPS (pos=%s fruit=%s ate=%s drank=%s)" % [index+1,fps,s.pos,s.fruit,s.ate,s.drank])
 if s.won: print("PASS level %d @ %d FPS, %.2f s, taunts=%d" % [index+1,fps,s.elapsed,s.taunts])
