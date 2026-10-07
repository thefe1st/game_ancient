extends Node
# M1 has one profile. Three slots and Steam Cloud are deferred to M2/M5.
var unlocked: int = 0
var total_taunts: int = 0
var best_times: Dictionary = {}
var load_error: bool = false
func _ready() -> void:
 var config := ConfigFile.new()
 var error := config.load("user://progress.cfg")
 if error == OK:
  unlocked = clampi(int(config.get_value("progress", "unlocked", 0)), 0, 6)
  total_taunts = maxi(0, int(config.get_value("progress", "taunts", 0)))
  var times = config.get_value("progress", "best_times", {})
  best_times = times if times is Dictionary else {}
 elif error != ERR_FILE_NOT_FOUND:
  load_error = true
func record(level: int, seconds: float, taunts: int) -> Error:
 unlocked = maxi(unlocked, mini(level + 1, 6))
 total_taunts += taunts
 var key := str(level)
 best_times[key] = minf(float(best_times.get(key, INF)), seconds)
 var config := ConfigFile.new()
 config.set_value("progress", "unlocked", unlocked)
 config.set_value("progress", "taunts", total_taunts)
 config.set_value("progress", "best_times", best_times)
 var error := config.save("user://progress.tmp")
 if error != OK:
  return error
 return DirAccess.rename_absolute("user://progress.tmp", "user://progress.cfg")
