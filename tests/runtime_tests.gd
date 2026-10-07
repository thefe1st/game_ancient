extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
 call_deferred("run")
func check(condition: bool, message: String) -> void:
 checks+=1
 if not condition:
  failures+=1
  push_error("FAIL: "+message)
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 check(game.screen=="menu","Starts in menu")
 check(root.gui_get_focus_owner() is Button,"Menu has keyboard focus")
 game.start_level(0)
 check(game.screen=="play" and game.hud.visible,"Starting level activates HUD")
 game.sim.step(1.0/60.0,{"move":1})
 var time_before: float=game.sim.elapsed
 game.pause_menu()
 await process_frame
 check(game.screen=="pause" and not game.hud.visible,"Pause hides HUD")
 check(game.sim.elapsed==time_before,"Paused simulation does not advance")
 game.resume()
 check(game.screen=="play","Resume returns to play")
 game.hint_visible=true
 game.update_hud()
 check(game.hint_label.visible and not game.hint_label.text.is_empty(),"Oracle visible")
 game.start_level(0)
 check(not game.hint_visible and game.sim.elapsed==0,"Restart resets state")
 var save=root.get_node("SaveManager")
 var error: Error=save.record(0,5.0,2)
 check(error==OK,"Atomic save succeeds")
 check(save.unlocked>=1,"Victory unlocks next level")
 check(save.best_times.has("0"),"Best time stored")
 var config:=ConfigFile.new()
 check(config.load(save.slot_path(save.active_slot))==OK,"Saved file can be loaded")
 check(config.get_value("progress","unlocked",-1)==save.unlocked,"Saved unlock matches memory")
 game.start_level(game.levels.size()-1)
 game.sim.elapsed=12.3
 game.show_win()
 await process_frame
 check(game.screen=="win","Final win shows overlay")
 check(root.gui_get_focus_owner() is Button,"Final overlay keyboard focus")
 check(not root.get_node("SteamManager").available,"Steam explicitly disabled")
 var settings=root.get_node("Settings")
 settings.language="en"
 settings.load_language()
 game.start_level(1)
 check(game.title.text.contains("Gaze"),"English HUD loads")
 root.get_node("AudioManager").stop_all()
 game.queue_free()
 await process_frame
 print("RUNTIME RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
