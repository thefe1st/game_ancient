extends Node
var language: String = "ru"
var muted: bool = false
var reduced_motion: bool = false
var strings: Dictionary = {}
func _ready() -> void:
 var config := ConfigFile.new()
 if config.load("user://settings.cfg") == OK:
  language = config.get_value("game", "language", "ru")
  muted = config.get_value("game", "muted", false)
  reduced_motion = config.get_value("game", "reduced_motion", false)
 load_language()
func load_language() -> void:
 var value = JSON.parse_string(FileAccess.get_file_as_string("res://localization/%s.json" % language))
 strings = value if value is Dictionary else {}
func text(key: String) -> String:
 return str(strings.get(key, key))
func save() -> void:
 var config := ConfigFile.new()
 config.set_value("game", "language", language)
 config.set_value("game", "muted", muted)
 config.set_value("game", "reduced_motion", reduced_motion)
 config.save("user://settings.cfg")
func toggle_language() -> void:
 language = "en" if language == "ru" else "ru"
 load_language()
 save()
