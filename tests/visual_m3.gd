extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("capture")
func shot(name: String) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 if game.hint_label.visible: print(name," hint lines=",game.hint_label.get_line_count()," visible=",game.hint_label.get_visible_line_count()," size=",game.hint_label.size," text=",game.hint_label.text)
 root.get_texture().get_image().save_png("/data/qa_m3/"+name+".png")
func capture() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 var settings=root.get_node("Settings")
 root.get_node("SaveManager").unlocked=15
 for lang in ["ru","en"]:
  settings.language=lang
  settings.large_text=true
  settings.load_language()
  for i in range(9,16):
   game.start_level(i)
   game.hint_visible=true
   game.update_hud()
   await shot("%s_level_%02d"%[lang,i+1])
 settings.language="ru"
 settings.large_text=false
 settings.load_language()
 game.start_level(10)
 game.sim.pos.x=423
 game.sim.carried_torch=true
 game.sim.torch_x=460
 game.update_hud()
 await shot("torch_carried")
 game.sim.carried_torch=false
 game.sim.update_light()
 game.update_hud()
 await shot("socket_active")
 game.start_level(9)
 game.sim.world.boats[0].x=530
 game.sim.pos=Vector2(517,369)
 game.sim.support_boat=0
 game.update_hud()
 await shot("ferry_passenger")
 game.sim.pos=Vector2(510,478)
 game.sim.grounded=false
 await shot("pit_mask")
 game.start_level(15)
 game.sim.torch_x=240
 game.sim.update_light()
 game.sim.world.boats[0].x=710
 game.sim.pos=Vector2(765,384)
 game.sim.noise=0.8
 game.sim.alert_time=0.4
 game.update_hud()
 await shot("night_alert")
 game.show_menu()
 game.show_levels(1)
 await process_frame
 await process_frame
 game.panel.get_child(0).get_child(2).get_child(0).get_child(-1).grab_focus()
 game.panel.get_child(0).get_child(2).scroll_vertical=10000
 await shot("act_2_bottom")
 game.start_level(15)
 game.run_seconds=240
 game.show_win()
 await shot("final")
 root.get_node("AudioManager").stop_all()
 game.queue_free()
 await process_frame
 quit()
