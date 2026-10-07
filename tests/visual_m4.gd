extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("capture")
func shot(name: String) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/data/qa_m4/"+name+".png")
func capture() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 var settings=root.get_node("Settings")
 settings.language="ru"
 settings.large_text=true
 settings.load_language()
 root.get_node("SaveManager").unlocked=24
 game.show_menu()
 await shot("menu")
 game.show_controls()
 await shot("controls_ru_top")
 game.panel.get_child(0).get_child(2).get_child(0).get_child(-1).grab_focus()
 await shot("controls_ru_bottom")
 settings.language="en"
 settings.load_language()
 game.show_controls()
 await shot("controls_en_top")
 settings.language="ru"
 settings.load_language()
 for i in range(16,25):
  game.start_level(i)
  game.hint_visible=true
  game.update_hud()
  await shot("level_%d"%(i+1))
 game.start_level(16)
 game.sim.pos.x=400
 game.sim.vessel_carried=true
 game.sim.vessel_water=0.7
 game.update_hud()
 await shot("water_carried")
 game.start_level(19)
 game.sim.boulder=600
 game.sim.update_light()
 game.sim.pos.x=536
 game.update_hud()
 await shot("plate_active")
 game.start_level(22)
 game.sim.world.boats[0].y=250
 game.sim.pos=Vector2(437,194)
 game.sim.support_boat=0
 game.update_hud()
 await shot("wheel_high")
 game.show_menu()
 game.show_levels(2)
 await process_frame
 await process_frame
 game.panel.get_child(0).get_child(2).get_child(0).get_child(-1).grab_focus()
 await shot("act3_bottom")
 root.get_node("AudioManager").stop_all()
 game.queue_free()
 await process_frame
 quit()
