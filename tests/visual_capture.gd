extends SceneTree
var game: Node
var output: String="/data/qa_m2"
func _initialize() -> void:
 call_deferred("capture")
func shot(name: String) -> void:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var error:=root.get_texture().get_image().save_png(output+"/"+name+".png")
 if error!=OK: push_error("Capture failed: "+name)
func capture() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 var settings=root.get_node("Settings")
 var save=root.get_node("SaveManager")
 settings.language="ru"
 settings.large_text=false
 settings.load_language()
 save.unlocked=8
 game.show_menu()
 await shot("menu")
 game.show_levels(0)
 await shot("act_1")
 game.show_levels(1)
 await shot("act_2")
 game.show_slots()
 await shot("slots")
 game.confirm_reset_slot()
 await shot("reset_confirm")
 game.show_settings()
 await shot("settings_top")
 game.panel.get_child(0).get_child(1).scroll_vertical=10000
 await shot("settings_bottom")
 game.show_bindings()
 await shot("bindings_top")
 game.panel.get_child(0).get_child(1).scroll_vertical=10000
 await shot("bindings_bottom")
 game.capture_binding("eyes")
 await shot("capture_binding")
 for i in range(9):
  game.start_level(i)
  await shot("level_%d"%i)
 game.start_level(7)
 game.sim.torch_lit=false
 game.update_hud()
 await shot("torch_off")
 game.start_level(8)
 game.sim.alert_time=0.5
 game.sim.noise=0.85
 game.update_hud()
 await shot("cerberus_alert")
 game.pause_menu()
 await shot("pause")
 settings.large_text=true
 game.start_level(8)
 game.hint_visible=true
 game.update_hud()
 await shot("large_hint_ru")
 settings.language="en"
 settings.load_language()
 game.show_settings()
 await shot("settings_en")
 game.start_level(7)
 game.hint_visible=true
 game.update_hud()
 await shot("large_hint_en")
 game.start_level(8)
 game.run_seconds=130.5
 game.assisted_run=true
 game.show_win()
 await shot("win")
 root.get_node("AudioManager").stop_all()
 await create_timer(0.15).timeout
 game.queue_free()
 await process_frame
 quit()
