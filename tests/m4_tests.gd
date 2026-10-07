extends "res://tests/m3_tests.gd"
func water(s: RefCounted, target: float) -> void:
 go(s,float(s.level.vessel_source)-13)
 s.step(dt,{"interact":true})
 check(s.vessel_carried and s.vessel_water>0.9,"Vessel filled")
 go(s,target-13,{"crouch":true})
 s.step(dt,{"interact":true,"crouch":true})
 check(s.water_delivered,"Water delivered")
func stone(s: RefCounted) -> void:
 s.step(dt,{"eyes":true})
 go(s,float(s.level.plate[0])-64)
 frames(s,0.1)
 check(s.world.receiver_active,"Stone activates plate")
 jump(s,1)
 frames(s,0.46,{"move":1})
 frames(s,0.5)
func solve_new(index: int) -> void:
 var s=Sim.new()
 s.reset(levels[index],index)
 match index:
  16,18: water(s,float(s.level.vessel_target))
  17:
   water(s,700)
   s.step(dt,{"eyes":true})
   go(s,690)
   jump(s,1)
   frames(s,0.32,{"move":1})
   frames(s,0.5)
   go(s,787)
   jump(s)
   frames(s,0.7)
  19:
   stone(s)
   go(s,706)
   jump(s,1)
   frames(s,0.34,{"move":1})
   frames(s,0.5)
   go(s,807)
   jump(s)
   frames(s,0.7)
  20:
   stone(s)
   go(s,570)
   jump(s,1)
   frames(s,0.34,{"move":1})
   frames(s,0.5)
   go(s,683)
   jump(s,1)
   frames(s,0.43,{"move":1})
   frames(s,0.5)
   go(s,807)
   jump(s)
   frames(s,0.7)
  21:
   stone(s)
   go(s,817,{"crouch":true})
  22:
   s.step(dt,{"eyes":true})
   go(s,437)
   for i in range(int(10/dt)):
    if s.world.boats[0].y>408 and s.world.boats[0].vertical_direction==1: break
    s.step(dt,{})
   jump(s)
   frames(s,0.9)
   check(s.support_boat==0,"Board Ixion lift")
   for i in range(int(8/dt)):
    if s.world.boats[0].y<255: break
    s.step(dt,{})
   jump(s)
   frames(s,0.7)
  23:
   s.step(dt,{"eyes":true})
   go(s,222)
   jump(s,1)
   frames(s,0.32,{"move":1})
   frames(s,0.65)
   check(s.support_boat==0,"Board wheel over river")
   for i in range(int(14/dt)):
    if s.world.boats[0].y<353 and s.world.boats[1].x<470: break
    s.step(dt,{})
   jump(s,1)
   frames(s,0.5,{"move":1})
   frames(s,0.3)
   check(s.support_boat==1,"Transfer wheel to boat pos=%s"%s.pos)
   for i in range(int(10/dt)):
    if s.world.boats[1].x>690: break
    s.step(dt,{})
   go(s,838)
   if not s.won:
    jump(s)
    frames(s,0.7)
  24:
   water(s,230)
   s.step(dt,{"eyes":true})
   ferry(s,true)
 check(s.won,"M4 solution level%d @%.0fFPS pos=%s fruit=%s plate=%s"%[index+1,1/dt,s.pos,s.fruit,s.world.receiver_active])
 if s.won: print("PASS M4 level%d @%.0fFPS %.2fs"%[index+1,1/dt,s.elapsed])
func run() -> void:
 levels=Catalog.load_levels()
 for fps in [30,60,120]:
  dt=1.0/fps
  for index in range(16,25): solve_new(index)
 dt=1.0/60
 var s=Sim.new()
 s.reset(levels[16],16)
 go(s,127)
 s.step(dt,{"interact":true})
 frames(s,2,{"move":1})
 check(s.vessel_water<0.85,"Standing movement leaks")
 var amount: float=s.vessel_water
 frames(s,1,{"crouch":true,"move":1})
 check(is_equal_approx(amount,s.vessel_water),"Crouching seals vessel")
 s.pos.x=747
 s.vessel_water=0.4
 s.step(dt,{"interact":true})
 check(not s.water_delivered and not s.won,"Too little water rejected")
 check(s.taunts>0,"Failed delivery gives feedback")
 s.soft_respawn()
 check(s.vessel_carried,"Recovery retains vessel")
 s.reset(levels[19],19)
 s.boulder=600
 s.update_light()
 check(s.world.receiver_active,"Plate opens ledge")
 s.boulder=700
 s.update_light()
 check(not s.world.receiver_active,"Removing weight closes ledge")
 s.reset(levels[16],16)
 check(not s.won,"Water-only level does not auto-win")
 s.step(dt,{})
 check(not s.won,"Water requires delivery")
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 var settings=root.get_node("Settings")
 for lang in ["ru","en"]:
  settings.language=lang
  settings.large_text=true
  settings.load_language()
  for index in range(16,25):
   game.start_level(index)
   game.hint_visible=true
   game.update_hud()
   await process_frame
   await process_frame
   check(game.hint_label.get_line_count()<=game.hint_label.get_visible_line_count(),"Large new hint %s %d"%[lang,index])
 game.start_level(10)
 check(not game.control_label.text.contains("A/D") and not game.control_label.text.contains("Space"),"HUD no longer lists all actions")
 game.pause_menu()
 game.show_controls("pause")
 check(game.screen=="controls","Controls accessible from pause")
 await process_frame
 await process_frame
 await process_frame
 check(game.panel.get_child(0).get_child(2).scroll_vertical==0,"Help starts with visible torch combination")
 var list: Node=game.panel.get_child(0).get_child(2).get_child(0)
 check(list.get_child(-1).text.contains("Esc") and list.get_child(-1).text.contains("F11"),"Help includes fixed menu keys")
 var combo: String=list.get_child(0).text
 check(combo.contains("S + G"),"Help explicitly includes S + G")
 settings.set_binding("crouch",KEY_C)
 settings.set_binding("interact",KEY_V)
 game.show_controls("pause")
 list=game.panel.get_child(0).get_child(2).get_child(0)
 check(list.get_child(0).text.contains("C + V"),"Combo follows remapped keys")
 game.leave_controls()
 check(game.screen=="pause","Help returns to pause")
 game.gamepad=true
 game.show_controls()
 list=game.panel.get_child(0).get_child(2).get_child(0)
 check(list.get_child(0).text.contains("B + RB"),"Xbox torch combination")
 settings.reset_bindings()
 var save=root.get_node("SaveManager")
 save.level_count=25
 save.best_times={"15":100.0}
 save.assisted_times={}
 save.unlocked=15
 save.flush()
 save.load_slot(save.active_slot)
 check(save.unlocked==16,"Old finale opens third act")
 game.queue_free()
 await process_frame
 root.get_node("AudioManager").stop_all()
 print("M4 RESULT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
