extends Node
# Original synthesized placeholder sounds, no third-party samples.
var cache: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
func _ready() -> void:
 for name in ["Music","Effects"]:
  if AudioServer.get_bus_index(name)<0:
   AudioServer.add_bus()
   AudioServer.set_bus_name(AudioServer.bus_count-1,name)
 Settings.changed.connect(apply_mix)
 apply_mix()
 for i in range(8):
  var player := AudioStreamPlayer.new()
  add_child(player)
  player.bus="Effects"
  players.append(player)
 music_player = AudioStreamPlayer.new()
 add_child(music_player)
 music_player.bus="Music"
 music_player.volume_db = -18
 music_player.stream = synth("music")
 if DisplayServer.get_name() != "headless": music_player.play()
func apply_mix() -> void:
 for pair in [["Master",Settings.master_volume],["Music",Settings.music_volume],["Effects",Settings.effects_volume]]:
  var index: int=AudioServer.get_bus_index(pair[0])
  AudioServer.set_bus_volume_db(index,linear_to_db(maxf(float(pair[1]),0.0001)))
 AudioServer.set_bus_mute(0,Settings.muted or Settings.master_volume<=0)

func play(event: String) -> void:
 if Settings.muted: return
 if not cache.has(event): cache[event] = synth(event)
 for player in players:
  if not player.playing:
   player.stream = cache[event]
   player.volume_db = -23 if event == "quiet_step" else -14 if event == "step" else -8
   player.play()
   return
func synth(event: String) -> AudioStreamWAV:
 var duration: float = 0.2
 var frequency: float = 260.0
 match event:
  "echo_start": duration=0.3; frequency=330
  "echo_stop": duration=0.2; frequency=220
  "echo_play": duration=0.5; frequency=550
  "echo_empty": duration=0.12; frequency=110
  "amphora": duration=0.65; frequency=880
  "win": duration = 0.9
  "taunt": duration = 0.65
  "eat": duration = 0.12
  "drink": duration = 0.4
  "splash": duration=0.4; frequency=130
  "light": duration=0.5; frequency=440
  "torch": duration=0.25; frequency=90
  "bark": duration=0.35; frequency=100
  "eyes": frequency = 180
  "step", "quiet_step": duration = 0.045; frequency = 90
  "music": duration = 12.0
 var rate: int = 22050
 var count: int = int(duration * rate)
 var samples := PackedByteArray()
 samples.resize(count * 2)
 var notes: Array[float] = [146.83, 164.81, 174.61, 220.0, 196.0, 174.61, 164.81, 146.83]
 for i in range(count):
  var t: float = float(i) / rate
  var envelope: float = exp(-t * 12.0)
  var wave: float = sin(TAU * frequency * t)
  match event:
   "bark": wave=sin(TAU*100*t)*sin(TAU*17*t); envelope=exp(-t*7)
   "splash": wave=sin(float(i)*153.3)*cos(float(i)*53.1); envelope=exp(-t*6)
   "light": wave=sin(TAU*440*t)+0.2*sin(TAU*660*t); envelope=exp(-t*5)
   "torch": wave=sin(float(i)*183.7)*cos(float(i)*42.3); envelope=exp(-t*8)
   "jump": wave = sin(TAU * (260 * t + 650 * t * t))
   "taunt": wave = sin(TAU * (170 * t - 35 * t * t)); envelope = maxf(0, sin(t * 40)) * exp(-t * 3)
   "eat", "step", "quiet_step": wave = sin(float(i) * 192.7) * cos(float(i) * 87.1)
   "drink": wave = sin(TAU * (460 * t + 180 * t * t))
   "win": wave = sin(TAU * notes[mini(7, int(t * 8))] * 2 * t); envelope = exp(-fmod(t, 0.125) * 15) * (1 - t / duration)
   "music":
    var note: float = notes[mini(7, int(t / 1.5))]
    var local: float = fmod(t, 1.5)
    wave = sin(TAU * note * local) + 0.3 * sin(TAU * note * 2 * local)
    envelope = exp(-local * 5)
  var sample: int = clampi(int(wave * envelope * 11000), -32768, 32767)
  samples.encode_s16(i * 2, sample)
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = rate
 stream.data = samples
 if event == "music":
  stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
  stream.loop_end = count
 return stream

func stop_all() -> void:
 if is_instance_valid(music_player):
  music_player.stop()
  music_player.stream = null
 for player in players:
  if is_instance_valid(player):
   player.stop()
   player.stream = null
 cache.clear()

func _exit_tree() -> void:
 stop_all()
