extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("capture")
func shot(name: String) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/data/qa_m5/"+name+".png")
func capture() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 var settings=root.get_node("Settings")
 settings.large_text=true
 root.get_node("SaveManager").unlocked=25
 for lang in ["ru","en"]:
  settings.language=lang
  settings.load_language()
  for i in range(6):
   game.start_level(25,true)
   game.room_index=i
   game.sim.reset(game.levels[25].rooms[i],25)
   game.hint_visible=true
   game.update_hud()
   await shot("hall_%d_%s"%[i,lang])
  game.show_controls()
  await shot("controls_"+lang)
  game.show_levels(3)
  await shot("chapter_menu_"+lang)
 settings.language="ru"; settings.load_language()
 game.start_level(25,true)
 game.sim.pos.x=207
 game.sim.step(1.0/60,{"echo_record":true})
 game.sim.step(0.2,{})
 game.update_hud()
 await shot("recording")
 game.sim.step(1.0/60,{"echo_record":true})
 game.sim.step(1.0/60,{"echo_play":true})
 game.sim.pos.x=400
 game.sim.step(0.3,{})
 game.update_hud()
 await shot("holding_gate")
 game.room_index=4
 game.sim.reset(game.levels[25].rooms[4],25)
 game.sim.echo.begin({"pos":Vector2(437,384),"height":56,"face":1,"eyes":false,"grounded":true,"noise":1.0})
 game.sim.echo.capture(3.0,{"pos":Vector2(487,384),"height":56,"face":1,"eyes":false,"grounded":true,"noise":1.0})
 game.sim.echo.stop(); game.sim.echo.play()
 game.sim.pos.x=700
 game.sim.step(1.0/60,{"move":1})
 game.update_hud()
 await shot("guard_listening")
 game.pause_menu()
 await shot("pause")
 game.room_index=5
 game.sim.reset(game.levels[25].rooms[5],25)
 game.chapter_relics=[0,2,3]
 game.run_seconds=155.3
 game.show_win()
 await shot("ending")
 root.get_node("AudioManager").stop_all()
 game.queue_free()
 await process_frame
 quit()
