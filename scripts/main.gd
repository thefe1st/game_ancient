extends Node2D
const Simulation = preload("res://scripts/simulation.gd")
const Garden = preload("res://scripts/garden_view.gd")
var levels: Array = []
var sim = Simulation.new()
var garden: Node2D
var screen: String = "menu"
var current: int = 0
var hint_visible: bool = false
var taunt_timer: float = 0.0
var toast: String = ""
var input_edges: Dictionary = {}
var panel: PanelContainer
var hud: Control
var title: Label
var subtitle: Label
var status: Label
var hint_label: Label
var message: Label
var control_label: Label
var gamepad: bool = false
func _ready() -> void:
 get_tree().auto_accept_quit = false
 levels = JSON.parse_string(FileAccess.get_file_as_string("res://levels/act_01.json"))
 garden = Garden.new()
 add_child(garden)
 create_hud()
 show_menu()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--level="): start_level(clampi(int(arg.split("=")[1]),0,6))
func label_at(rect: Rect2, size: int, color: Color) -> Label:
 var label := Label.new()
 label.position = rect.position
 label.size = rect.size
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",color)
 hud.add_child(label)
 return label
func create_hud() -> void:
 hud = Control.new()
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(hud)
 title = label_at(Rect2(40,43,720,36),28,Color("1b120c"))
 subtitle = label_at(Rect2(40,83,800,24),16,Color("1b120c"))
 status = label_at(Rect2(730,44,190,50),16,Color("1b120c"))
 status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 message = label_at(Rect2(40,119,580,29),19,Color("f3dcc0"))
 message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 hint_label = label_at(Rect2(40,156,580,88),18,Color("f3dcc0"))
 hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var shade := StyleBoxFlat.new()
 shade.bg_color = Color("1b120c")
 shade.set_content_margin_all(8)
 shade.set_corner_radius_all(4)
 hint_label.add_theme_stylebox_override("normal",shade)
 message.add_theme_stylebox_override("normal",shade)
 control_label = label_at(Rect2(28,516,904,23),14,Color("f3dcc0"))
 control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
func clear_panel() -> void:
 if is_instance_valid(panel):
  remove_child(panel)
  panel.queue_free()
  panel = null
func overlay(heading: String, caption: String) -> VBoxContainer:
 clear_panel()
 hud.visible = false
 panel = PanelContainer.new()
 panel.position = Vector2(235,92)
 panel.custom_minimum_size = Vector2(490,340)
 var style := StyleBoxFlat.new()
 style.bg_color = Color("1b120c")
 style.border_color = Color("f3dcc0")
 style.set_border_width_all(1)
 style.set_content_margin_all(22)
 style.set_corner_radius_all(4)
 panel.add_theme_stylebox_override("panel",style)
 add_child(panel)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",9)
 panel.add_child(box)
 var heading_label := Label.new()
 heading_label.text = heading
 heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 heading_label.add_theme_font_size_override("font_size",30)
 heading_label.add_theme_color_override("font_color",Color("f3dcc0"))
 box.add_child(heading_label)
 if not caption.is_empty():
  var caption_label := Label.new()
  caption_label.text = caption
  caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  caption_label.add_theme_font_size_override("font_size",16)
  caption_label.add_theme_color_override("font_color",Color("d98a4e"))
  box.add_child(caption_label)
 return box
func button(box: VBoxContainer, text: String, action: Callable, disabled: bool = false) -> void:
 var b := Button.new()
 b.text = text
 b.custom_minimum_size.y = 34
 b.add_theme_font_size_override("font_size",18)
 b.disabled = disabled
 b.pressed.connect(action)
 box.add_child(b)
 var is_first: bool = true
 for child in box.get_children():
  if child is Button and child != b: is_first = false
 if is_first: b.call_deferred("grab_focus")
func show_menu() -> void:
 screen = "menu"
 garden.sim = null
 var box := overlay(Settings.text("title"),Settings.text("tagline"))
 button(box,Settings.text("play"),func(): start_level(SaveManager.unlocked))
 button(box,Settings.text("levels"),show_levels)
 button(box,"RU / EN",func(): Settings.toggle_language(); show_menu())
 button(box,Settings.text("sound")+Settings.text("off" if Settings.muted else "on"),func(): Settings.muted=not Settings.muted; Settings.save(); show_menu())
 button(box,Settings.text("motion")+Settings.text("on" if Settings.reduced_motion else "off"),func(): Settings.reduced_motion=not Settings.reduced_motion; Settings.save(); show_menu())
 button(box,Settings.text("quit"),finish)
func show_levels() -> void:
 screen = "levels"
 var box := overlay(Settings.text("levels"),"")
 for i in range(levels.size()):
  var number: int = i
  var best: String = "  ·  %.1f s" % float(SaveManager.best_times[str(i)]) if SaveManager.best_times.has(str(i)) else ""
  button(box,"%02d   %s%s" % [i+1,Settings.text("level_%d"%i),best],func(): start_level(number),i>SaveManager.unlocked)
 button(box,Settings.text("back"),show_menu)
 box.get_child(1).call_deferred("grab_focus")
func start_level(number: int) -> void:
 clear_panel()
 current = number
 sim.reset(levels[number],number)
 garden.sim = sim
 screen = "play"
 hud.visible = true
 hint_visible = false
 taunt_timer = 0.0
 toast = ""
 input_edges.clear()
 update_hud()
func pause_menu() -> void:
 screen = "pause"
 var box := overlay(Settings.text("pause"),Settings.text("level_%d"%current))
 button(box,Settings.text("resume"),resume)
 button(box,Settings.text("restart"),func(): start_level(current))
 button(box,Settings.text("menu"),show_menu)
func resume() -> void:
 clear_panel()
 screen = "play"
 hud.visible = true
func show_win() -> void:
 screen = "win"
 var save_error: Error = SaveManager.record(current,sim.elapsed,sim.taunts)
 var final: bool = current == levels.size()-1
 var heading: String = Settings.text("done" if final else "won")
 var box := overlay(heading,"%.1f s  ·  %s: %d" % [sim.elapsed,Settings.text("taunts"),sim.taunts])
 if save_error != OK:
  var warning := Label.new()
  warning.text = Settings.text("saved_error")
  box.add_child(warning)
 if not final: button(box,Settings.text("next"),func(): start_level(current+1))
 else:
  var ending := Label.new()
  ending.text = Settings.text("ending")
  ending.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  box.add_child(ending)
 button(box,Settings.text("restart"),func(): start_level(current))
 button(box,Settings.text("menu"),show_menu)
func finish() -> void:
 AudioManager.stop_all()
 await get_tree().create_timer(0.1).timeout
 get_tree().quit()
func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST: finish()
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and screen == "play": pause_menu()
func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  match event.physical_keycode:
   KEY_ESCAPE:
    if screen == "play": pause_menu()
    elif screen == "pause": resume()
    else: show_menu()
   KEY_R:
    if screen in ["play","pause","win"]: start_level(current)
   KEY_H:
    if screen == "play": hint_visible = not hint_visible
   KEY_M:
    Settings.muted = not Settings.muted
    Settings.save()
func edge(key: String, held: bool) -> bool:
 var previous: bool = input_edges.get(key,false)
 input_edges[key] = held
 return held and not previous
func _physics_process(delta: float) -> void:
 var pads := Input.get_connected_joypads()
 gamepad = not pads.is_empty()
 var pad: int = pads[0] if gamepad else -1
 if gamepad and edge("pause",Input.is_joy_button_pressed(pad,JOY_BUTTON_START)):
  if screen == "play": pause_menu()
  elif screen == "pause": resume()
 if screen != "play": return
 var direction: float = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
 if gamepad:
  var stick: float = Input.get_joy_axis(pad,JOY_AXIS_LEFT_X)
  if absf(stick)>0.2: direction=stick
  if Input.is_joy_button_pressed(pad,JOY_BUTTON_DPAD_LEFT): direction=-1
  if Input.is_joy_button_pressed(pad,JOY_BUTTON_DPAD_RIGHT): direction=1
 var jump_held: bool = Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or (gamepad and Input.is_joy_button_pressed(pad,JOY_BUTTON_A))
 var eyes_held: bool = Input.is_physical_key_pressed(KEY_E) or (gamepad and Input.is_joy_button_pressed(pad,JOY_BUTTON_X))
 var crouch_held: bool = Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or (gamepad and Input.is_joy_button_pressed(pad,JOY_BUTTON_B))
 var back_held: bool = Input.is_physical_key_pressed(KEY_SHIFT) or (gamepad and Input.is_joy_button_pressed(pad,JOY_BUTTON_LEFT_SHOULDER))
 if gamepad and edge("hint",Input.is_joy_button_pressed(pad,JOY_BUTTON_Y)): hint_visible=not hint_visible
 sim.step(delta,{"move":direction,"jump":edge("jump",jump_held),"eyes":edge("eyes",eyes_held),"crouch":crouch_held,"back":back_held})
 taunt_timer=maxf(0,taunt_timer-delta)
 for event in sim.events:
  AudioManager.play(event)
  if event=="taunt":
   taunt_timer=2.2
   toast=Settings.text("taunt_%d"%((sim.taunts+current)%5))
 if sim.elapsed>25 or sim.taunts>=4: hint_visible=true
 update_hud()
 if sim.won: show_win()
func update_hud() -> void:
 title.text="%02d  /  %s" % [current+1,Settings.text("level_%d"%current)]
 subtitle.text=Settings.text("sub_%d"%current)
 status.text="%s: %d\n%s" % [Settings.text("taunts"),sim.taunts,Settings.text("eyes_closed" if sim.eyes else "eyes_open")]
 message.visible=taunt_timer>0
 message.text=toast if taunt_timer>0 else ""
 hint_label.visible=hint_visible
 hint_label.text=Settings.text("hint")+": "+Settings.text("hint_%d"%current) if hint_visible else ""
 control_label.text=Settings.text("pad_controls" if gamepad else "controls")
