extends SceneTree
var game: Node
func _initialize() -> void:
 call_deferred("capture")
func shot(name: String) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var error := root.get_texture().get_image().save_png("/data/qa/"+name+".png")
 if error != OK: push_error("Capture failed "+name)
func capture() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 root.get_node("Settings").language="ru"
 root.get_node("Settings").load_language()
 game.show_menu()
 await shot("menu_ru")
 root.get_node("SaveManager").unlocked=6
 game.show_levels()
 await shot("levels_ru")
 for i in range(7):
  game.start_level(i)
  await shot("level_%d"%i)
 game.start_level(1)
 game.sim.eyes=true
 game.hint_visible=true
 game.update_hud()
 await shot("closed_hint")
 game.pause_menu()
 await shot("pause_ru")
 game.start_level(6)
 game.sim.elapsed=123.4
 game.show_win()
 await shot("win_ru")
 root.get_node("Settings").language="en"
 root.get_node("Settings").load_language()
 game.show_menu()
 await shot("menu_en")
 game.start_level(5)
 game.hint_visible=true
 game.update_hud()
 await shot("level_en_hint")
 root.get_node("AudioManager").stop_all()
 await create_timer(0.15).timeout
 game.queue_free()
 await process_frame
 quit()
