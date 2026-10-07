extends Node
signal changed
const DEFAULT_BINDINGS: Dictionary = {
 "left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "crouch": KEY_S,
 "backwards": KEY_SHIFT, "eyes": KEY_E, "interact": KEY_G,
 "hint": KEY_H, "restart": KEY_R, "mute": KEY_M, "echo_record": KEY_T, "echo_play": KEY_F
}
const ALIASES: Dictionary = {"left":[KEY_LEFT], "right":[KEY_RIGHT], "jump":[KEY_W,KEY_UP], "crouch":[KEY_DOWN]}
const PAD_BUTTONS: Dictionary = {"left":JOY_BUTTON_DPAD_LEFT,"right":JOY_BUTTON_DPAD_RIGHT,"jump":JOY_BUTTON_A,"crouch":JOY_BUTTON_B,"backwards":JOY_BUTTON_LEFT_SHOULDER,"eyes":JOY_BUTTON_X,"interact":JOY_BUTTON_RIGHT_SHOULDER,"hint":JOY_BUTTON_Y,"pause":JOY_BUTTON_START,"echo_record":JOY_BUTTON_DPAD_UP,"echo_play":JOY_BUTTON_DPAD_DOWN}
var language: String = "ru"
var muted: bool = false
var reduced_motion: bool = false
var large_text: bool = false
var slow_mode: bool = false
var fullscreen: bool = false
var vsync: bool = true
var master_volume: float = 0.8
var music_volume: float = 0.5
var effects_volume: float = 0.8
var bindings: Dictionary = DEFAULT_BINDINGS.duplicate()
var strings: Dictionary = {}
var last_save_error: Error = OK
func _ready() -> void:
 reload()
func valid_volume(value: Variant, fallback: float) -> float:
 if value is not int and value is not float: return fallback
 var number: float = float(value)
 return fallback if is_nan(number) or is_inf(number) else clampf(number,0,1)
func reload() -> void:
 var config := ConfigFile.new()
 if config.load("user://settings.cfg") == OK:
  language = str(config.get_value("game","language","ru"))
  if language not in ["ru","en"]: language="ru"
  muted = config.get_value("game","muted",false)==true
  reduced_motion = config.get_value("game","reduced_motion",false)==true
  large_text = config.get_value("game","large_text",false)==true
  slow_mode = config.get_value("game","slow_mode",false)==true
  fullscreen = config.get_value("display","fullscreen",false)==true
  vsync = config.get_value("display","vsync",true)==true
  master_volume=valid_volume(config.get_value("audio","master",0.8),0.8)
  music_volume=valid_volume(config.get_value("audio","music",0.5),0.5)
  effects_volume=valid_volume(config.get_value("audio","effects",0.8),0.8)
  var stored = config.get_value("input","bindings",{})
  bindings=DEFAULT_BINDINGS.duplicate()
  if stored is Dictionary:
   var candidate: Dictionary=DEFAULT_BINDINGS.duplicate()
   for action in DEFAULT_BINDINGS:
    if stored.has(action): candidate[action]=stored[action]
   # Preserve old remaps even when T/F already belong to an existing action.
   for added in ["echo_record","echo_play"]:
    if not stored.has(added):
     var used: Array=[]
     for other in candidate:
      if other!=added:
       used.append(candidate[other])
       if candidate[other]==DEFAULT_BINDINGS[other]: used.append_array(ALIASES.get(other,[]))
     for fallback in [DEFAULT_BINDINGS[added],KEY_T,KEY_F,KEY_V,KEY_B,KEY_N,KEY_J,KEY_K,KEY_L,KEY_U,KEY_I,KEY_O,KEY_P]:
      if fallback not in used:
       candidate[added]=fallback
       break
   if validate_bindings(candidate): bindings=candidate

 load_language()
 configure_input()
 apply_display()
 changed.emit()
func load_language() -> void:
 var value = JSON.parse_string(FileAccess.get_file_as_string("res://localization/%s.json" % language))
 strings=value if value is Dictionary else {}
func text(key: String) -> String:
 return str(strings.get(key,key))
func save() -> Error:
 var config := ConfigFile.new()
 for key in ["language","muted","reduced_motion","large_text","slow_mode"]: config.set_value("game",key,get(key))
 config.set_value("display","fullscreen",fullscreen)
 config.set_value("display","vsync",vsync)
 config.set_value("audio","master",master_volume)
 config.set_value("audio","music",music_volume)
 config.set_value("audio","effects",effects_volume)
 config.set_value("input","bindings",bindings)
 last_save_error=config.save("user://settings.tmp")
 if last_save_error==OK: last_save_error=DirAccess.rename_absolute("user://settings.tmp","user://settings.cfg")
 changed.emit()
 return last_save_error
func apply_display() -> void:
 if DisplayServer.get_name()=="headless": return
 DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
func toggle_language() -> void:
 language="en" if language=="ru" else "ru"
 load_language()
 save()
func keys_for(action: String) -> Array:
 var result: Array = [int(bindings[action])]
 if bindings[action]==DEFAULT_BINDINGS[action]: result.append_array(ALIASES.get(action,[]))
 return result
func set_binding(action: String, key: int, persist: bool=true) -> Error:
 if not DEFAULT_BINDINGS.has(action) or key <= 0 or key in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER,KEY_TAB,KEY_F11]: return ERR_INVALID_PARAMETER
 for other in DEFAULT_BINDINGS:
  if other!=action and key in keys_for(other): return ERR_ALREADY_EXISTS
 bindings[action]=key
 configure_input()
 if persist: return save()
 return OK
func reset_bindings() -> Error:
 bindings=DEFAULT_BINDINGS.duplicate()
 configure_input()
 return save()
func binding_label(action: String) -> String:
 return OS.get_keycode_string(int(bindings[action]))
func configure_input() -> void:
 for action in DEFAULT_BINDINGS:
  var name: String = "game_"+action
  if not InputMap.has_action(name): InputMap.add_action(name,0.2)
  InputMap.action_erase_events(name)
  for key in keys_for(action):
   var event := InputEventKey.new()
   event.physical_keycode=key
   InputMap.action_add_event(name,event)
  if PAD_BUTTONS.has(action):
   var button := InputEventJoypadButton.new()
   button.button_index=PAD_BUTTONS[action]
   InputMap.action_add_event(name,button)
  if action in ["left","right"]:
   var axis := InputEventJoypadMotion.new()
   axis.axis=JOY_AXIS_LEFT_X
   axis.axis_value=-1.0 if action=="left" else 1.0
   InputMap.action_add_event(name,axis)
 if not InputMap.has_action("game_pause"): InputMap.add_action("game_pause")
 InputMap.action_erase_events("game_pause")
 var escape := InputEventKey.new()
 escape.physical_keycode=KEY_ESCAPE
 InputMap.action_add_event("game_pause",escape)
 var start := InputEventJoypadButton.new()
 start.button_index=JOY_BUTTON_START
 InputMap.action_add_event("game_pause",start)

func validate_bindings(candidate: Dictionary) -> bool:
 var seen: Array=[]
 for action in DEFAULT_BINDINGS:
  if not candidate.has(action) or candidate[action] is not int: return false
  var key: int=candidate[action]
  if key<=0 or key in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER,KEY_TAB,KEY_F11]: return false
  var keys: Array=[key]
  if key==DEFAULT_BINDINGS[action]: keys.append_array(ALIASES.get(action,[]))
  for value in keys:
   if value in seen: return false
   seen.append(value)
 return true
