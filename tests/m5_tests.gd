extends "res://tests/m3_tests.gd"
const Echo=preload("res://scripts/echo_track.gd")
func hold_echo(s: RefCounted, x: float) -> void:
 go(s,x-13)
 s.step(dt,{"echo_record":true})
 frames(s,0.3)
 s.step(dt,{"echo_record":true})
 s.step(dt,{"echo_play":true})
 frames(s,0.4)
 check(s.echo.active and s.echo.holding,"Stationary echo holds")
func loft_echo(s: RefCounted) -> void:
 go(s,628)
 s.step(dt,{"echo_record":true})
 jump(s,1)
 frames(s,0.33,{"move":1})
 frames(s,0.5)
 go(s,717)
 s.step(dt,{"echo_record":true})
 s.step(dt,{"echo_play":true})
 frames(s,1.2)
 check(s.echo.holding and s.echo.ghost.grounded,"Echo on raised plate")
func solve_room(index: int) -> RefCounted:
 var s=Sim.new()
 s.reset(levels[25].rooms[index],25)
 match index:
  0: hold_echo(s,220)
  1:
   hold_echo(s,200)
   go(s,536)
   jump(s,1)
   frames(s,0.46,{"move":1})
   frames(s,0.5)
  2:
   place(s,167,350)
   loft_echo(s)
  3:
   hold_echo(s,220)
   ferry(s)
  4:
   go(s,437)
   s.step(dt,{"echo_record":true})
   for i in range(int(3/dt)):
    var target: float=487 if (int(i*dt*2)%2)==0 else 437
    s.step(dt,{"move":clampf((target-s.pos.x)/4,-1,1)})
   go(s,487)
   s.step(dt,{"echo_record":true})
   s.step(dt,{"echo_play":true})
   frames(s,0.1)
   check(s.guardian_distracted,"Noisy echo distracts guard")
  5:
   go(s,236)
   jump(s,1)
   frames(s,0.46,{"move":1})
   frames(s,0.5)
   place(s,407,500)
   loft_echo(s)
 go(s,float(s.level.exit)-13,{"crouch":true} if index==4 else {})
 frames(s,0.7,{"crouch":index==4})
 check(s.echo_gate_open,"Gate open hall %d FPS %.0f plates %s"%[index,1/dt,s.plate_states])
 s.step(dt,{"interact":true,"crouch":index==4})
 check(s.won,"Exit hall %d at %.0f FPS pos %s"%[index,1/dt,s.pos])
 return s
func run() -> void:
 levels=Catalog.load_levels()
 check(levels.size()==26 and levels[25].rooms.size()==6,"Chapter has six halls")
 for fps in [30,60,120]:
  dt=1.0/fps
  for i in range(6): solve_room(i)
 dt=1.0/60
 var s=Sim.new()
 s.reset(levels[25].rooms[0],25)
 s.step(dt,{"echo_play":true})
 check("echo_empty" in s.events and not s.echo.active,"Empty replay safe")
 hold_echo(s,220)
 go(s,400)
 check(s.echo_gate_open,"Ghost alone holds plate")
 s.step(dt,{"echo_record":true})
 check(not s.echo.active and not s.echo_gate_open,"New recording replaces ghost")
 frames(s,8,{"move":1})
 check(not s.echo.recording and s.echo.duration<=6.001 and s.echo.samples.size()<=721,"Six second recording limit")
 s.step(dt,{"echo_play":true})
 frames(s,7)
 check(s.echo.holding and s.echo.ghost.noise==0,"Final pose silent")
 s.reset(levels[25].rooms[0],25)
 check(not s.echo.active and s.echo.samples.is_empty(),"Room restart clears echo")
 # Interpolation and final pose independent of replay frame rate.
 var track=Echo.new()
 track.begin({"pos":Vector2(0,384),"height":56,"face":1,"eyes":false,"grounded":true,"noise":0})
 track.capture(1.0,{"pos":Vector2(100,384),"height":56,"face":1,"eyes":false,"grounded":true,"noise":1})
 track.stop()
 track.play()
 track.advance(0.5)
 check(absf(track.ghost.pos.x-50)<0.01,"Trajectory interpolates")
 track.advance(0.5)
 check(track.holding and track.ghost.pos.x==100 and track.ghost.noise==0,"Exact final pose")
 s.reset(levels[25].rooms[0],25)
 go(s,207)
 s.step(dt,{"echo_record":true})
 jump(s)
 frames(s,0.1)
 s.step(dt,{"echo_record":true})
 s.step(dt,{"echo_play":true})
 frames(s,0.3)
 check(not s.echo.ghost.grounded,"Airborne final ghost")
 go(s,400)
 check(not s.echo_gate_open,"Airborne ghost cannot press plate")
 # Ghosts never collect optional amphoras.
 s.reset(levels[25].rooms[0],25)
 s.echo.begin({"pos":Vector2(637,240),"height":56,"face":1,"eyes":false,"grounded":true,"noise":0})
 s.echo.capture(0.3,{"pos":Vector2(637,240),"height":56,"face":1,"eyes":false,"grounded":true,"noise":0})
 s.echo.stop(); s.echo.play()
 frames(s,0.5)
 check(not s.relic_collected,"Echo cannot collect secret")
 go(s,560)
 jump(s,1); frames(s,0.4,{"move":1}); frames(s,0.5)
 check(s.relic_collected,"Hero collects amphora")

 # Collect every optional secret through real movement.
 for index in [2,3]:
  s.reset(levels[25].rooms[index],25)
  if index==2:
   place(s,167,350)
   go(s,628); jump(s,1); frames(s,0.33,{"move":1}); frames(s,0.5)
   go(s,757); jump(s); frames(s,0.7)
  else:
   hold_echo(s,220); ferry(s)
   jump(s); frames(s,0.7)
  check(s.relic_collected,"Collect secret hall %d"%index)
 var settings=root.get_node("Settings")
 var old: Dictionary=settings.DEFAULT_BINDINGS.duplicate()
 old.erase("echo_record"); old.erase("echo_play")
 old.left=KEY_T; old.eyes=KEY_F
 var config=ConfigFile.new()
 config.set_value("input","bindings",old)
 config.save("user://settings.cfg")
 settings.reload()
 check(settings.bindings.left==KEY_T and settings.bindings.eyes==KEY_F,"Old T/F remaps preserved")
 check(settings.validate_bindings(settings.bindings),"New echo keys avoid old conflicts")
 check(settings.bindings.echo_record!=KEY_T and settings.bindings.echo_play!=KEY_F,"Free fallback keys selected")
 settings.reset_bindings()
 var save=root.get_node("SaveManager")
 save.level_count=26
 save.load_slot(1)
 check(save.reset_active_slot()==OK,"Fresh test slot")
 check(save.checkpoint_escape(3,[0,2],12.5,2,true)==OK,"Write chapter checkpoint")
 save.escape_state=save.fresh_escape()
 save.load_slot(1)
 check(save.escape_state.room==3 and save.escape_state.relics==[0,2] and save.escape_state.seconds==12.5,"Checkpoint reload")
 save.load_slot(2)
 check(save.escape_state.room==0 and not save.escape_state.started,"Slot isolation")
 save.load_slot(1)
 var bad: Dictionary=save.sanitize_escape({"room":999,"relics":[0,0,1,2,"3",3],"seconds":-9,"taunts":-2})
 check(bad.room==5 and bad.relics==[0,2,3] and bad.seconds==0 and bad.taunts==0,"Validate optional checkpoint")
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.start_level(25)
 check(game.room_index==3 and game.run_seconds==12.5,"Continue at saved hall")
 game.run_seconds=17
 game.sim.taunts=1
 game.restart_current()
 check(game.room_index==3 and game.run_seconds==17 and game.chapter_taunts==3 and not game.sim.echo.active,"Restart room preserves run metrics")
 game.enter_next_room()
 check(game.room_index==4 and save.escape_state.room==4,"Hall transition checkpoints")
 game.start_level(25,true)
 check(game.room_index==0 and save.escape_state.room==0 and game.run_seconds==0,"New run checkpoint replaces old")
 game.screen="win"
 game.restart_current()
 check(game.room_index==0 and game.run_seconds==0,"Restart after win resets whole chapter")
 game.start_level(25,true)
 game.sim.pos.x=207
 game.sim.step(dt,{"echo_record":true})
 frames(game.sim,0.3)
 game.sim.step(dt,{"echo_record":true})
 game.sim.step(dt,{"echo_play":true})
 var echo_time: float=game.sim.echo.play_time
 var run_time: float=game.run_seconds
 game.pause_menu()
 game._physics_process(0.5)
 check(game.sim.echo.play_time==echo_time and game.run_seconds==run_time,"Pause freezes echo and timer")
 game.start_level(25,true)
 game.run_seconds=77
 for i in range(6):
  game.sim=solve_room(i)
  game.garden.sim=game.sim
  game.input_lock=0
  game._physics_process(dt)
  check(game.room_index==mini(i+1,5),"Integrated hall transition %d"%i)
 check(game.screen=="win" and save.best_times.has("25"),"Full chapter records win")
 check(float(save.best_times["25"])>=77 and float(save.best_times["25"])<78,"Whole chapter real-time record")
 game.gamepad=true
 check("D-pad ↑" in game.format_hint("{echo_record} {echo_play}"),"Controller echo hints")
 game.gamepad=false
 check(game.format_hint("{echo_record} {echo_play}")=="T F","Keyboard echo hints")
 game.show_controls()
 check(game.screen=="controls","Controls menu supports echo")
 root.get_node("AudioManager").stop_all()
 game.queue_free()
 await process_frame
 print("M5: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
