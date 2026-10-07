extends SceneTree
var checks: int=0
var failures: int=0
func _initialize() -> void:
 call_deferred("run")
func check(condition: bool, label: String) -> void:
 checks+=1
 if not condition:
  failures+=1
  push_error("FAIL: "+label)
func write_text(path: String, text: String) -> void:
 var file:=FileAccess.open(path,FileAccess.WRITE)
 file.store_string(text)
func run() -> void:
 var save=root.get_node("SaveManager")
 var settings=root.get_node("Settings")
 # This runner requires a fresh, isolated XDG_DATA_HOME, set by CI.
 for i in range(3):
  check(not FileAccess.file_exists(save.slot_path(i)),"Fresh profile %d"%i)
 var legacy:=ConfigFile.new()
 legacy.set_value("progress","unlocked",6)
 legacy.set_value("progress","taunts",17)
 legacy.set_value("progress","best_times",{"0":5.5,"6":7.4})
 legacy.save("user://progress.cfg")
 var legacy_text: String=FileAccess.get_file_as_string("user://progress.cfg")
 save.load_slot(0)
 check(save.unlocked==7 and save.total_taunts==17,"Completed M1 migrates and unlocks Underworld")
 check(is_equal_approx(float(save.best_times["6"]),7.4),"M1 records migrated")
 check(FileAccess.file_exists(save.slot_path(0)),"Migration creates v2 slot")
 check(FileAccess.get_file_as_string("user://progress.cfg")==legacy_text,"Legacy left untouched")
 check(save.record(6,4.0,1)==OK and save.unlocked==7,"Old finale unlocks Underworld")
 var slot_zero: String=FileAccess.get_file_as_string(save.slot_path(0))
 check(save.select_slot(1)==OK,"Select second slot")
 check(save.unlocked==0 and save.best_times.is_empty(),"Second slot independent")
 check(save.record(0,9.0,2)==OK,"Second slot can save")
 check(FileAccess.get_file_as_string(save.slot_path(0))==slot_zero,"Writing slot 1 preserves slot 0")
 check(save.select_slot(2)==OK,"Select third slot")
 check(save.record(1,8.0,3,true)==OK,"Assisted progress saves")
 check(save.best_times.is_empty() and save.assisted_times.has("1"),"Assisted scores kept separate")
 check(save.unlocked==2,"Assisted play still unlocks levels")
 check(save.record(1,12.0,1)==OK,"Normal score saves separately")
 check(float(save.best_times["1"])==12.0 and float(save.assisted_times["1"])==8.0,"Normal score not overwritten by calm score")
 save.load_slot(2)
 check(save.assisted_times.has("1") and save.best_times.has("1"),"Both score types survive reload")
 check(save.record(1,14.0,0)==OK and float(save.best_times["1"])==12.0,"Slower run cannot replace best")
 check(FileAccess.file_exists(save.slot_path(2)+".bak"),"Backup created")
 var known_backup: Dictionary=save.read_snapshot(save.slot_path(2)+".bak")
 write_text(save.slot_path(2),'[progress]\nunlocked="invalid"\n')
 save.load_slot(2)
 check(save.recovered_backup and not save.read_only,"Corrupt primary recovered")
 check(save.best_times==known_backup.times,"Recovered scores match backup")
 check(save.record(1,11.0,0)==OK,"Recovered save writable")
 save.load_slot(2)
 check(not save.load_error and float(save.best_times["1"])==11.0,"Recovery persists valid file")
 DirAccess.remove_absolute(save.slot_path(2))
 save.load_slot(2)
 check(save.recovered_backup,"Missing primary uses backup")
 save.flush()
 var future:=ConfigFile.new()
 future.set_value("meta","version",99)
 future.set_value("progress","unlocked",99)
 future.save(save.slot_path(2))
 var future_text: String=FileAccess.get_file_as_string(save.slot_path(2))
 save.load_slot(2)
 check(save.read_only,"Future save is protected")
 check(save.record(0,1.0,0)!=OK,"Future save cannot be overwritten")
 check(FileAccess.get_file_as_string(save.slot_path(2))==future_text,"Future bytes preserved")
 check(save.reset_active_slot()==OK,"Confirmed reset archives old save")
 check(not save.read_only and save.unlocked==0,"Reset creates clean slot")
 var archives: Array=[]
 for name in DirAccess.get_files_at("user://"):
  if "archived_" in name: archives.append(name)
 check(not archives.is_empty(),"Reset preserves archived files")
 save.select_slot(0)
 check(save.unlocked==7 and save.total_taunts==18,"Original profile still intact")
 check(save.select_slot(3)==ERR_INVALID_PARAMETER,"Invalid slot rejected")
 # Settings persist and retain M1's flags.
 var m1:=ConfigFile.new()
 m1.set_value("game","language","en")
 m1.set_value("game","muted",true)
 m1.set_value("game","reduced_motion",true)
 m1.save("user://settings.cfg")
 settings.reload()
 check(settings.language=="en" and settings.muted and settings.reduced_motion,"M1 settings migration")
 check(is_equal_approx(settings.music_volume,0.5),"New mix uses safe default")
 check(settings.set_binding("eyes",KEY_Q)==OK,"Remap eyes")
 check(settings.set_binding("left",KEY_E)==OK,"Remap to freed key")
 check(settings.set_binding("right",KEY_E)==ERR_ALREADY_EXISTS,"Conflicting primary rejected")
 check(settings.set_binding("right",KEY_UP)==ERR_ALREADY_EXISTS,"Alias conflict rejected")
 check(settings.set_binding("jump",KEY_ESCAPE)==ERR_INVALID_PARAMETER,"Esc remains reserved")
 check(settings.set_binding("jump",KEY_ENTER)==ERR_INVALID_PARAMETER,"Enter remains reserved")
 settings.reload()
 check(settings.bindings.eyes==KEY_Q and settings.bindings.left==KEY_E,"Dependent remaps survive reload")
 var key:=InputEventKey.new()
 key.physical_keycode=KEY_Q
 key.pressed=true
 check(key.is_action_pressed("game_eyes"),"Rebound physical key maps to eyes")
 key.physical_keycode=KEY_E
 check(key.is_action_pressed("game_left"),"Freed E maps to movement")
 settings.master_volume=0.4
 settings.music_volume=0.3
 settings.effects_volume=0.7
 settings.muted=false
 settings.large_text=true
 settings.slow_mode=true
 settings.save()
 check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")),linear_to_db(0.3)),"Music mix applied")
 check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Effects")),linear_to_db(0.7)),"Effects mix independent")
 settings.reload()
 check(settings.large_text and settings.slow_mode and is_equal_approx(settings.master_volume,0.4),"Accessibility and mix persist")
 settings.muted=true
 settings.save()
 check(AudioServer.is_bus_mute(0),"Mute silences master bus")
 check(settings.reset_bindings()==OK and settings.bindings==settings.DEFAULT_BINDINGS,"Reset restores controls")
 # UI/input integration, isolated from actual device certification.
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.start_level(0)
 game.input_lock=0
 game._physics_process(1.0/60.0)
 check(is_equal_approx(game.run_seconds,1.0/60.0),"Real-time clock")
 check(is_equal_approx(game.sim.elapsed,0.7/60.0),"Calm mode scales simulation only")
 check(game.assisted_run,"Assisted flag latched")
 settings.slow_mode=false
 game._physics_process(1.0/60.0)
 check(game.assisted_run,"Turning calm off does not erase assisted flag")
 game.pause_menu()
 var paused: float=game.sim.elapsed
 game.show_settings("pause")
 game._physics_process(1)
 check(game.sim.elapsed==paused,"Settings reached from pause do not advance game")
 game.leave_settings()
 check(game.screen=="pause","Settings return to pause")
 game.resume()
 check(game.screen=="play","Resume after settings")
 game.show_bindings()
 await process_frame
 check(root.gui_get_focus_owner() is Button,"Bindings keyboard focus")
 game.capture_binding("eyes")
 key.physical_keycode=KEY_Q
 game._input(key)
 check(game.screen=="bindings" and settings.bindings.eyes==KEY_Q,"Binding capture works")
 game.start_level(0)
 game.input_lock=0
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 game._physics_process(1.0/60.0)
 check(game.sim.eyes,"Rebound key changes gameplay")
 key.pressed=false
 Input.parse_input_event(key.duplicate())
 game.update_hud()
 check(game.format_hint("{eyes}")=="Q","Help reflects remapped key")
 game.start_level(1)
 game.hint_visible=true
 game.update_hud()
 check(game.hint_label.text.contains("Q"),"Oracle reflects remapped key")
 game.show_slots()
 await process_frame
 check(root.gui_get_focus_owner() is Button,"Save slots keyboard focus")
 game.confirm_reset_slot()
 await process_frame
 check(root.gui_get_focus_owner().text==settings.text("cancel"),"Destructive confirmation defaults to cancel")
 game.start_level(8)
 game.show_win()
 await process_frame
 check(root.gui_get_focus_owner() is Button,"Final victory keyboard focus")
 root.get_node("AudioManager").stop_all()
 game.queue_free()
 await process_frame
 print("M2 RESULT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
