extends SceneTree
const Sim=preload("res://scripts/simulation.gd")
const Catalog=preload("res://scripts/level_catalog.gd")
var checks: int=0
var failures: int=0
var dt: float=1.0/60
var levels: Array
func _initialize() -> void: call_deferred("run")
func check(ok: bool, msg: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error("FAIL: "+msg)
func frames(s: RefCounted, seconds: float, controls: Dictionary={}) -> void:
 for i in range(int(ceil(seconds/dt))): s.step(dt,controls)
func go(s: RefCounted, x: float, controls: Dictionary={}) -> void:
 for i in range(int(20/dt)):
  if s.won or absf(s.pos.x-x)<4: return
  var c:=controls.duplicate()
  c.move=clampf((x-s.pos.x)/4,-1,1)
  s.step(dt,c)
 check(false,"Movement timeout %d at %s"%[s.index,s.pos])
func jump(s: RefCounted, dir: float=0) -> void: s.step(dt,{"jump":true,"move":dir})
func ferry(s: RefCounted, quiet_end: bool=false) -> void:
 go(s,222)
 jump(s,1)
 frames(s,0.32,{"move":1})
 frames(s,0.65)
 check(s.support_boat==0,"Board ferry %d @ %.0f FPS"%[s.index,1/dt])
 frames(s,4.8)
 go(s,838,{"crouch":true} if quiet_end else {})
 if not quiet_end:
  jump(s)
  frames(s,0.7)
func place(s: RefCounted, pickup: float, socket: float) -> void:
 go(s,pickup)
 s.step(dt,{"interact":true})
 check(s.carried_torch,"Pick up torch %d"%s.index)
 go(s,socket-37)
 s.step(dt,{"interact":true})
 check(s.world.receiver_active and not s.carried_torch,"Power socket %d"%s.index)
func solve(index: int) -> void:
 var s=Sim.new()
 s.reset(levels[index],index)
 match index:
  9:
   s.step(dt,{"eyes":true})
   ferry(s)
  10:
   place(s,177,460)
   s.step(dt,{"eyes":true})
   go(s,628)
   jump(s,1)
   frames(s,0.33,{"move":1})
   frames(s,0.5)
   go(s,727)
   jump(s)
   frames(s,0.7)
  11: ferry(s,true)
  12:
   place(s,187,380)
   go(s,467)
   jump(s)
   frames(s,0.7)
   jump(s)
   frames(s,0.7)
  13:
   s.step(dt,{"eyes":true})
   frames(s,8)
   check(s.drank,"Drink before crossing")
   ferry(s)
  14:
   go(s,174)
   # Wait for a boat within boarding distance, then intercept it.
   for i in range(int(6/dt)):
    if s.world.boats[0].x<285 and s.world.boats[0].direction==1: break
    s.step(dt,{})
   jump(s,1)
   frames(s,0.42,{"move":1})
   frames(s,0.4)
   check(s.support_boat==0,"Board automatic boat")
   for i in range(int(12/dt)):
    if s.world.boats[1].x-s.world.boats[0].x<165 and s.world.boats[0].x>390: break
    s.step(dt,{})
   jump(s,1)
   frames(s,0.48,{"move":1})
   frames(s,0.35)
   check(s.support_boat==1,"Transfer between boats pos=%s"%s.pos)
   for i in range(int(8/dt)):
    if s.world.boats[1].x>730 and s.world.boats[1].direction==1: break
    s.step(dt,{})
   go(s,847)
   jump(s)
   frames(s,0.7)
  15:
   place(s,157,240)
   s.step(dt,{"eyes":true})
   ferry(s,true)
 check(s.won,"Solve level %d @ %.0f FPS pos=%s fruit=%s support=%d"%[index+1,1/dt,s.pos,s.fruit,s.support_boat])
 if s.won: print("PASS M3 level %d @ %.0f FPS %.2fs taunts=%d"%[index+1,1/dt,s.elapsed,s.taunts])
func run() -> void:
 levels=Catalog.load_levels()
 for fps in [30,60,120]:
  dt=1.0/fps
  for i in range(9,16): solve(i)
 dt=1.0/60
 var s=Sim.new()
 s.reset(levels[10],10)
 place(s,177,460)
 frames(s,0.3)
 s.step(dt,{"interact":true,"crouch":true})
 check(not s.torch_lit and not s.world.receiver_active,"Extinguish placed torch")
 frames(s,0.3)
 s.step(dt,{"interact":true,"crouch":true})
 check(s.torch_lit and s.world.receiver_active,"Relight socket")
 frames(s,0.3)
 s.step(dt,{"interact":true})
 check(s.carried_torch and not s.world.receiver_active,"Pickup disables platform")
 s.reset(levels[13],13)
 s.drank=true
 frames(s,2,{"move":1})
 check(s.taunts>0 and s.drank,"Pit recovery preserves collected drink")
 s.reset(levels[9],9)
 go(s,222)
 jump(s,1)
 frames(s,0.32,{"move":1})
 frames(s,0.65)
 var old: float=s.world.boats[0].x
 frames(s,0.2,{"move":0.1})
 check(is_equal_approx(s.world.boats[0].x,old),"Ferry pauses for noisy movement")
 frames(s,0.5)
 check(s.world.boats[0].x>old,"Ferry carries idle passenger")
 check(absf((s.pos.y+s.height)-s.world.boats[0].y)<0.1,"Passenger stays on deck")
 # Artificial vertical motion validates the general carrier solver.
 for fps in [30,60,120]:
  dt=1.0/fps
  var level: Dictionary=levels[9].duplicate(true)
  level.boats[0].vertical=[400,430,35]
  s.reset(level,9)
  s.pos=Vector2(297,425-s.height)
  s.grounded=true
  s.support_boat=0
  frames(s,2)
  check(s.support_boat==0 and absf(s.pos.y+s.height-s.world.boats[0].y)<0.1,"Vertical carrier %.0f FPS"%(1/dt))
 dt=1.0/60
 s.reset(levels[15],15)
 var original: float=s.world.boats[0].x
 s.support_boat=0
 frames(s,0.5)
 check(is_equal_approx(s.world.boats[0].x,original),"Unpowered ferry cannot sail")
 s.torch_x=240
 s.update_light()
 check(s.world.receiver_active,"Placed torch powers night ferry")
 s.drank=true
 s.ate=true
 s.won=false
 s.pos=Vector2(500,530)
 s.grounded=false
 s.step(dt,{})
 check(s.pos.x==float(s.level.start) and s.ate and s.drank,"Fall retains rewards")
 check(s.world.receiver_active and s.torch_x==240,"Fall retains placed torch")
 s.reset(levels[15],15)
 s.ate=true
 s.alert_time=0.01
 frames(s,0.03)
 check(s.ate and s.pos.x==float(s.level.start),"Guardian recovery retains rewards")
 for index in [11,15]:
  s.reset(levels[index],index)
  s.pos=Vector2(810,384)
  s.eyes=true
  go(s,838,{"crouch":true})
  check(s.won,"Shore goal reachable while crouching %d"%index)
 var audio=root.get_node("AudioManager")
 for event in ["light","splash"]:
  var wave: AudioStreamWAV=audio.synth(event)
  check(wave.data.size()>1000 and wave.get_length()>0.3,"Audio generated for "+event)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.start_level(9)
 game.sim.pos=Vector2(297,369)
 game.sim.support_boat=0
 var before: float=game.sim.world.boats[0].x
 game.pause_menu()
 game._physics_process(0.5)
 check(game.sim.world.boats[0].x==before,"Pause freezes ferry")
 game.show_settings("pause")
 game._physics_process(0.5)
 check(game.sim.world.boats[0].x==before,"Settings freeze ferry")
 var settings=root.get_node("Settings")
 for lang in ["ru","en"]:
  settings.language=lang
  settings.large_text=true
  settings.load_language()
  for i in range(16):
   game.start_level(i)
   game.hint_visible=true
   game.update_hud()
   await process_frame
   await process_frame
   check(game.hint_label.get_line_count()<=game.hint_label.get_visible_line_count(),"Unclipped large hint %s level%d"%[lang,i+1])
 game.queue_free()
 await process_frame
 var save=root.get_node("SaveManager")
 save.level_count=16
 save.best_times={"8":123.0}
 save.unlocked=8
 save.flush()
 save.load_slot(save.active_slot)
 check(save.unlocked==9 and save.best_times.has("8"),"M2 finale unlocks appended content")
 save.best_times={}
 save.assisted_times={"8":123.0}
 save.unlocked=8
 save.flush()
 save.load_slot(save.active_slot)
 check(save.unlocked==9 and save.assisted_times.has("8"),"Assisted M2 finale also unlocks new content")
 print("M3 TEST RESULT: %d checks, %d failures"%[checks,failures])
 root.get_node("AudioManager").stop_all()
 quit(1 if failures else 0)
