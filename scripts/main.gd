extends Node2D
const Simulation = preload("res://scripts/simulation.gd")
const Garden = preload("res://scripts/garden_view.gd")
const Catalog = preload("res://scripts/level_catalog.gd")
var levels: Array=[]
var sim=Simulation.new()
var garden: Node2D
var screen: String="menu"
var current: int=0
var hint_visible: bool=false
var taunt_timer: float=0.0
var toast: String=""
var panel: PanelContainer
var hud: Control
var title: Label
var subtitle: Label
var status: Label
var hint_label: Label
var message: Label
var control_label: Label
var gamepad: bool=false
var pad_device: int=-1
var settings_origin: String="menu"
var controls_origin: String="menu"
var binding_action: String=""
var run_seconds: float=0.0
var assisted_run: bool=false
var input_lock: int=0
var quitting: bool=false
func _ready() -> void:
 get_tree().auto_accept_quit=false
 levels=Catalog.load_levels()
 SaveManager.level_count=levels.size()
 garden=Garden.new()
 add_child(garden)
 create_hud()
 show_menu()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--level="): start_level(clampi(int(arg.split("=")[1]),0,levels.size()-1))
func label_at(rect: Rect2, size: int, color: Color) -> Label:
 var label:=Label.new()
 label.position=rect.position
 label.size=rect.size
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",color)
 hud.add_child(label)
 return label
func create_hud() -> void:
 hud=Control.new()
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(hud)
 title=label_at(Rect2(40,42,650,38),28,Color("1b120c"))
 subtitle=label_at(Rect2(40,84,670,24),16,Color("1b120c"))
 status=label_at(Rect2(700,43,220,64),16,Color("1b120c"))
 status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 message=label_at(Rect2(40,117,560,32),18,Color("f3dcc0"))
 message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 hint_label=label_at(Rect2(40,156,560,108),18,Color("f3dcc0"))
 hint_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var shade:=StyleBoxFlat.new()
 shade.bg_color=Color("1b120c")
 shade.set_content_margin_all(8)
 shade.set_corner_radius_all(4)
 hint_label.add_theme_stylebox_override("normal",shade)
 message.add_theme_stylebox_override("normal",shade)
 control_label=label_at(Rect2(28,482,904,55),14,Color("f3dcc0"))
 control_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 control_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 apply_hud_style()
func apply_hud_style() -> void:
 hint_label.size.y=128 if Settings.large_text else 108
 title.add_theme_font_size_override("font_size",32 if Settings.large_text else 28)
 subtitle.add_theme_font_size_override("font_size",18 if Settings.large_text else 16)
 status.add_theme_font_size_override("font_size",18 if Settings.large_text else 16)
 hint_label.add_theme_font_size_override("font_size",22 if Settings.large_text else 18)
 control_label.add_theme_font_size_override("font_size",16 if Settings.large_text else 14)
func clear_panel() -> void:
 if is_instance_valid(panel):
  remove_child(panel)
  panel.queue_free()
  panel=null
func overlay(heading: String, caption: String="") -> VBoxContainer:
 clear_panel()
 hud.visible=false
 panel=PanelContainer.new()
 panel.position=Vector2(175,55)
 panel.custom_minimum_size=Vector2(610,430)
 var style:=StyleBoxFlat.new()
 style.bg_color=Color("1b120c")
 style.border_color=Color("f3dcc0")
 style.set_border_width_all(1)
 style.set_content_margin_all(16)
 style.set_corner_radius_all(4)
 panel.add_theme_stylebox_override("panel",style)
 add_child(panel)
 var box:=VBoxContainer.new()
 box.add_theme_constant_override("separation",8)
 panel.add_child(box)
 var heading_label:=Label.new()
 heading_label.text=heading
 heading_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 heading_label.add_theme_font_size_override("font_size",30)
 heading_label.add_theme_color_override("font_color",Color("f3dcc0"))
 box.add_child(heading_label)
 if not caption.is_empty():
  var caption_label:=Label.new()
  caption_label.text=caption
  caption_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  caption_label.add_theme_font_size_override("font_size",16)
  caption_label.add_theme_color_override("font_color",Color("f3dcc0"))
  box.add_child(caption_label)
 return box
func button(box: BoxContainer, text: String, action: Callable, disabled: bool=false) -> Button:
 var b:=Button.new()
 b.text=text
 b.custom_minimum_size.y=44
 b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 b.add_theme_font_size_override("font_size",20 if Settings.large_text else 18)
 var normal:=StyleBoxFlat.new()
 normal.bg_color=Color("2b211a")
 normal.border_color=Color("b99472")
 normal.set_border_width_all(1)
 normal.set_corner_radius_all(3)
 var hover: StyleBoxFlat=normal.duplicate()
 hover.bg_color=Color("473323")
 hover.border_color=Color("f3dcc0")
 var focus:=StyleBoxFlat.new()
 focus.bg_color=Color(0,0,0,0)
 focus.border_color=Color("f3dcc0")
 focus.set_border_width_all(2)
 focus.set_corner_radius_all(3)
 b.add_theme_stylebox_override("normal",normal)
 b.add_theme_stylebox_override("hover",hover)
 b.add_theme_stylebox_override("pressed",hover)
 b.add_theme_stylebox_override("focus",focus)
 b.add_theme_color_override("font_color",Color("f3dcc0"))
 b.disabled=disabled
 b.pressed.connect(action)
 box.add_child(b)
 return b
func focus_later(control: Control) -> void:
 _try_focus.call_deferred(control)
func _try_focus(control: Control) -> void:
 if is_instance_valid(control) and control.is_inside_tree(): control.grab_focus()
func focus_first(box: Control) -> bool:
 for child in box.get_children():
  if child is Button and not child.disabled:
   focus_later(child)
   return true
  if child is Control and focus_first(child): return true
 return false
func scroll_box(box: VBoxContainer, height: int=270) -> VBoxContainer:
 var scroll:=ScrollContainer.new()
 scroll.custom_minimum_size=Vector2(575,height)
 scroll.follow_focus=true
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 box.add_child(scroll)
 var content:=VBoxContainer.new()
 content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",8)
 scroll.add_child(content)
 return content
func show_menu() -> void:
 screen="menu"
 binding_action=""
 garden.sim=null
 var box:=overlay(Settings.text("title"),"%s · %s %d"%[Settings.text("tagline"),Settings.text("slot"),SaveManager.active_slot+1])
 var play_button:=button(box,Settings.text("play"),func(): start_level(SaveManager.unlocked),SaveManager.read_only)
 button(box,Settings.text("levels"),show_levels,SaveManager.read_only)
 button(box,Settings.text("slots"),show_slots)
 button(box,Settings.text("controls_menu"),func(): show_controls("menu"))
 button(box,Settings.text("settings"),func(): show_settings("menu"))
 button(box,Settings.text("quit"),finish)
 if SaveManager.read_only or SaveManager.recovered_backup:
  var warning:=Label.new()
  warning.text=Settings.text("profile_readonly" if SaveManager.read_only else "profile_recovered")
  warning.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  warning.add_theme_color_override("font_color",Color("f3dcc0"))
  box.add_child(warning)
 if not play_button.disabled: focus_later(play_button)
 else: focus_later(box.get_child(4))
func show_levels(act: int=0) -> void:
 screen="levels"
 var box:=overlay(Settings.text("levels"))
 var tabs:=HBoxContainer.new()
 box.add_child(tabs)
 for i in range(3):
  var number: int=i
  button(tabs,Settings.text("act_short_%d"%i),func(): show_levels(number),i==act)
 var list:=scroll_box(box,264)
 for i in range(levels.size()):
  if int(levels[i].get("act",0))!=act: continue
  var number: int=i
  var best: String=" · %.1f s"%float(SaveManager.best_times[str(i)]) if SaveManager.best_times.has(str(i)) else ""
  button(list,"%02d   %s%s"%[i+1,Settings.text("level_%d"%i),best],func(): start_level(number),i>SaveManager.unlocked)
 button(box,Settings.text("back"),show_menu)
 if not focus_first(list): focus_first(tabs)
func start_level(number: int) -> void:
 clear_panel()
 current=clampi(number,0,levels.size()-1)
 sim.reset(levels[current],current)
 garden.sim=sim
 screen="play"
 hud.visible=true
 hint_visible=false
 taunt_timer=0
 toast=""
 run_seconds=0
 assisted_run=Settings.slow_mode
 input_lock=2
 apply_hud_style()
 update_hud()
func pause_menu() -> void:
 screen="pause"
 var box:=overlay(Settings.text("pause"),Settings.text("level_%d"%current))
 button(box,Settings.text("resume"),resume)
 button(box,Settings.text("restart"),func(): start_level(current))
 button(box,Settings.text("controls_menu"),func(): show_controls("pause"))
 button(box,Settings.text("settings"),func(): show_settings("pause"))
 button(box,Settings.text("menu"),show_menu)
 focus_first(box)
func resume() -> void:
 clear_panel()
 screen="play"
 hud.visible=true
 input_lock=2
 apply_hud_style()
 update_hud()
func show_win() -> void:
 screen="win"
 var save_error: Error=SaveManager.record(current,run_seconds,sim.taunts,assisted_run)
 var final: bool=current==levels.size()-1
 var box:=overlay(Settings.text("done" if final else "won"),"%.1f s · %s: %d%s"%[run_seconds,Settings.text("taunts"),sim.taunts," · "+Settings.text("assisted") if assisted_run else ""])
 if save_error!=OK:
  var warning:=Label.new()
  warning.text=Settings.text("saved_error")
  box.add_child(warning)
 if not final: button(box,Settings.text("next"),func(): start_level(current+1))
 else:
  var ending:=Label.new()
  ending.text=Settings.text("ending")
  ending.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  box.add_child(ending)
 button(box,Settings.text("restart"),func(): start_level(current))
 button(box,Settings.text("menu"),show_menu)
 focus_first(box)
func show_slots() -> void:
 screen="slots"
 var box:=overlay(Settings.text("slots"),Settings.text("saved_error") if SaveManager.last_error!=OK else "")
 for i in range(3):
  var number: int=i
  var info: Dictionary=SaveManager.slot_info(i)
  var summary: String=Settings.text("new_game")
  if info.has("invalid"): summary=Settings.text("profile_problem")
  elif info.has("unlocked"): summary="%s: %d/%d"%[Settings.text("open_levels"),int(info.unlocked)+1,levels.size()]
  var suffix: String=" · "+Settings.text("active") if i==SaveManager.active_slot else ""
  button(box,"%s %d — %s%s"%[Settings.text("slot"),i+1,summary,suffix],func(): SaveManager.select_slot(number); show_slots())
 button(box,Settings.text("reset_slot"),confirm_reset_slot)
 button(box,Settings.text("back"),show_menu)
 focus_first(box)
func confirm_reset_slot() -> void:
 screen="confirm_reset"
 var box:=overlay(Settings.text("reset_slot"),Settings.text("reset_warning"))
 button(box,Settings.text("confirm"),func(): SaveManager.reset_active_slot(); show_slots())
 var cancel:=button(box,Settings.text("cancel"),show_slots)
 focus_later(cancel)
func show_controls(origin: String="menu") -> void:
 controls_origin=origin
 screen="controls"
 var box:=overlay(Settings.text("controls_menu"),Settings.text("controls_caption"))
 var list:=scroll_box(box,260)
 for key in ["torch_combo","vessel_controls"]:
  var row:=Label.new()
  row.text=format_hint(Settings.text(key))
  row.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  row.custom_minimum_size.y=54
  row.add_theme_font_size_override("font_size",20 if Settings.large_text else 18)
  row.add_theme_color_override("font_color",Color("e9ae5b"))
  row.focus_mode=Control.FOCUS_ALL
  list.add_child(row)
 for action in Settings.DEFAULT_BINDINGS:
  var row:=Label.new()
  row.text=Settings.text("action_"+str(action))+" — "+format_hint("{"+str(action)+"}")
  row.custom_minimum_size.y=36
  row.add_theme_font_size_override("font_size",20 if Settings.large_text else 18)
  row.add_theme_color_override("font_color",Color("f3dcc0"))
  row.focus_mode=Control.FOCUS_ALL
  list.add_child(row)
 var fixed:=Label.new()
 fixed.text=Settings.text("pause_controls")
 fixed.custom_minimum_size.y=36
 fixed.add_theme_font_size_override("font_size",20 if Settings.large_text else 18)
 fixed.add_theme_color_override("font_color",Color("e9ae5b"))
 fixed.focus_mode=Control.FOCUS_ALL
 list.add_child(fixed)
 button(box,Settings.text("reset_controls_link"),func(): show_settings(controls_origin))
 button(box,Settings.text("back"),leave_controls)
 focus_controls_start(list.get_parent(),list.get_child(0))
func focus_controls_start(scroll: ScrollContainer, first: Control) -> void:
 await get_tree().process_frame
 await get_tree().process_frame
 if is_instance_valid(scroll) and is_instance_valid(first) and screen=="controls":
  first.grab_focus()
  scroll.scroll_vertical=0
func leave_controls() -> void:
 if controls_origin=="pause": pause_menu()
 else: show_menu()
func show_settings(origin: String="menu") -> void:
 settings_origin=origin
 screen="settings"
 var box:=overlay(Settings.text("settings"))
 var list:=scroll_box(box,290)
 volume_row(list,"master_volume","volume_master")
 volume_row(list,"music_volume","volume_music")
 volume_row(list,"effects_volume","volume_effects")
 option_row(list,"muted","mute_audio")
 option_row(list,"fullscreen","fullscreen")
 option_row(list,"vsync","vsync")
 option_row(list,"large_text","large_text")
 option_row(list,"reduced_motion","reduced_motion")
 option_row(list,"slow_mode","slow_mode")
 button(list,Settings.text("language")+": "+Settings.language.to_upper(),func(): Settings.toggle_language(); show_settings(settings_origin))
 button(list,Settings.text("bindings"),show_bindings)
 if Settings.last_save_error!=OK:
  var warning:=Label.new()
  warning.text=Settings.text("settings_save_error")
  list.add_child(warning)
 button(box,Settings.text("back"),leave_settings)
 focus_later(list.get_child(0).get_child(1))
func volume_row(box: VBoxContainer, property: String, key: String) -> void:
 var row:=HBoxContainer.new()
 row.custom_minimum_size.y=44
 box.add_child(row)
 var label:=Label.new()
 label.text=Settings.text(key)
 label.custom_minimum_size.x=200
 label.add_theme_font_size_override("font_size",20 if Settings.large_text else 18)
 label.add_theme_color_override("font_color",Color("f3dcc0"))
 row.add_child(label)
 var slider:=HSlider.new()
 slider.min_value=0
 slider.max_value=100
 slider.step=5
 slider.value=float(Settings.get(property))*100
 slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 slider.custom_minimum_size.y=44
 slider.tooltip_text=label.text
 row.add_child(slider)
 var value:=Label.new()
 value.custom_minimum_size.x=58
 value.text="%d%%"%int(slider.value)
 value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 row.add_child(value)
 slider.value_changed.connect(func(number: float): Settings.set(property,number/100); Settings.save(); value.text="%d%%"%int(number))
func option_row(box: VBoxContainer, property: String, key: String) -> void:
 var check:=CheckBox.new()
 check.add_theme_icon_override("unchecked",preload("res://art/ui/check_off.svg"))
 check.add_theme_icon_override("checked",preload("res://art/ui/check_on.svg"))
 check.text=Settings.text(key)
 check.button_pressed=Settings.get(property)
 check.custom_minimum_size.y=44
 check.add_theme_font_size_override("font_size",20 if Settings.large_text else 18)
 box.add_child(check)
 check.toggled.connect(func(value: bool): Settings.set(property,value); Settings.apply_display() if property in ["fullscreen","vsync"] else null; Settings.save(); apply_hud_style())
func leave_settings() -> void:
 if settings_origin=="pause": pause_menu()
 else: show_menu()
func show_bindings(notice: String="") -> void:
 binding_action=""
 screen="bindings"
 var box:=overlay(Settings.text("bindings"))
 var list:=scroll_box(box,260)
 if not notice.is_empty():
  var info:=Label.new()
  info.text=notice
  info.add_theme_color_override("font_color",Color("f3dcc0"))
  list.add_child(info)
 for action in Settings.DEFAULT_BINDINGS:
  var key: String=action
  button(list,Settings.text("action_"+key)+" — "+Settings.binding_label(key),func(): capture_binding(key))
 button(list,Settings.text("reset_bindings"),func(): Settings.reset_bindings(); show_bindings())
 button(box,Settings.text("back"),func(): show_settings(settings_origin))
 focus_first(list)
func capture_binding(action: String, notice: String="") -> void:
 binding_action=action
 screen="binding_capture"
 var box:=overlay(Settings.text("press_key"),Settings.text("action_"+action))
 var instructions:=Label.new()
 instructions.text=Settings.text("binding_instruction")+"\n"+notice
 instructions.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 instructions.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 instructions.custom_minimum_size=Vector2(570,100)
 instructions.add_theme_font_size_override("font_size",18)
 box.add_child(instructions)
 focus_later(button(box,Settings.text("cancel"),show_bindings))
func finish() -> void:
 if quitting: return
 quitting=true
 AudioManager.stop_all()
 await get_tree().create_timer(0.1).timeout
 get_tree().quit()
func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST: finish()
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and screen=="play": pause_menu()
func _input(event: InputEvent) -> void:
 if event is InputEventJoypadButton and event.pressed or event is InputEventJoypadMotion and absf(event.axis_value)>0.2:
  gamepad=true
  pad_device=event.device
 elif event is InputEventKey and event.pressed or event is InputEventMouseButton and event.pressed:
  gamepad=false
 if screen=="binding_capture" and event is InputEventKey and event.pressed and not event.echo:
  get_viewport().set_input_as_handled()
  if event.physical_keycode==KEY_ESCAPE:
   show_bindings()
   return
  var action: String=binding_action
  var error: Error=Settings.set_binding(action,event.physical_keycode)
  if error==OK: show_bindings(Settings.text("binding_saved"))
  else: capture_binding(action,Settings.text("binding_conflict" if error==ERR_ALREADY_EXISTS else "binding_reserved"))
  return
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F11:
  Settings.fullscreen=not Settings.fullscreen
  Settings.apply_display()
  Settings.save()
  get_viewport().set_input_as_handled()
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.echo: return
 if event.is_action_pressed("game_pause") or (screen!="play" and event.is_action_pressed("ui_cancel")):
  if screen=="play": pause_menu()
  elif screen=="pause": resume()
  elif screen in ["settings","bindings"]: leave_settings()
  elif screen=="controls": leave_controls()
  elif screen=="confirm_reset": show_slots()
  else: show_menu()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("game_restart") and screen in ["play","pause","win"]:
  start_level(current)
 elif event.is_action_pressed("game_hint") and screen=="play": hint_visible=not hint_visible
 elif event.is_action_pressed("game_mute") and screen in ["play","pause"]:
  Settings.muted=not Settings.muted
  Settings.save()
func _physics_process(delta: float) -> void:
 if gamepad and pad_device not in Input.get_connected_joypads(): gamepad=false
 if screen!="play": return
 if input_lock>0:
  input_lock-=1
  return
 assisted_run=assisted_run or Settings.slow_mode
 run_seconds+=delta
 var controls: Dictionary={"move":Input.get_axis("game_left","game_right"),"jump":Input.is_action_just_pressed("game_jump"),"eyes":Input.is_action_just_pressed("game_eyes"),"crouch":Input.is_action_pressed("game_crouch"),"back":Input.is_action_pressed("game_backwards"),"interact":Input.is_action_just_pressed("game_interact")}
 sim.step(delta*(0.7 if Settings.slow_mode else 1.0),controls)
 taunt_timer=maxf(0,taunt_timer-delta)
 for event in sim.events:
  AudioManager.play(event)
  if event=="taunt":
   taunt_timer=2.2
   toast=Settings.text("taunt_%d"%((sim.taunts+current)%5))
 if run_seconds>25 or sim.taunts>=4: hint_visible=true
 update_hud()
 if sim.won: show_win()
func update_hud() -> void:
 title.text="%02d / %s"%[current+1,Settings.text("level_%d"%current)]
 subtitle.text=Settings.text("sub_%d"%current)
 var state: String=Settings.text("eyes_closed" if sim.eyes else "eyes_open")
 if sim.level.rule=="shadow": state=Settings.text("torch_on" if sim.torch_lit else "torch_off")
 if sim.level.has("torch") and sim.level.get("portable_torch",false): state=Settings.text("torch_carried" if sim.carried_torch else "light_on" if sim.world.receiver_active else "light_off")
 if sim.level.has("boats") and not sim.level.has("torch"): state=Settings.text("ferry_riding" if sim.support_boat>=0 else "ferry_waiting")
 if sim.level.has("boats") and sim.level.boats[0].get("mode","")=="auto": state=Settings.text("boats_moving")
 if sim.level.has("boats") and sim.level.boats[0].has("vertical"): state=Settings.text("platforms_moving")
 if sim.level.has("vessel_source"): state="%s %d%%"%[Settings.text("vessel_done" if sim.water_delivered else "vessel_fill"),int(sim.vessel_water*100)]
 if sim.level.has("plate"): state=Settings.text("plate_on" if sim.world.receiver_active else "plate_off")
 if sim.level.has("guardian"): state="%s: %d%%"%[Settings.text("noise"),int(sim.noise*100)]
 if sim.level.has("vessel_source") and sim.level.has("guardian"): state=Settings.text("water_noise")%[int(sim.vessel_water*100),int(sim.noise*100)]
 status.text="%s: %d\n%s"%[Settings.text("taunts"),sim.taunts,state]
 message.visible=taunt_timer>0
 message.text=toast if taunt_timer>0 else ""
 hint_label.visible=hint_visible
 hint_label.text=Settings.text("hint")+": "+format_hint(Settings.text("hint_%d"%current)) if hint_visible else ""
 control_label.text=format_hint(Settings.text("minimal_controls"))
 if gamepad: control_label.text=Settings.text("minimal_pad")

func is_playstation() -> bool:
 var name: String=Input.get_joy_name(pad_device).to_lower()
 return "sony" in name or "playstation" in name or "dual" in name or "ps4" in name or "ps5" in name
func format_hint(text: String) -> String:
 var tokens: Dictionary={}
 for action in Settings.DEFAULT_BINDINGS: tokens[action]=Settings.binding_label(action)
 if gamepad:
  var ps: bool=is_playstation()
  tokens.merge({"jump":"×" if ps else "A","crouch":"○" if ps else "B","backwards":"L1" if ps else "LB","eyes":"□" if ps else "X","interact":"R1" if ps else "RB","hint":"△" if ps else "Y"},true)
 for action in tokens: text=text.replace("{"+str(action)+"}",str(tokens[action]))
 return text
