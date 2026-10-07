extends RefCounted
static func load_levels() -> Array:
 var all: Array=[]
 for path in ["res://levels/act_01.json","res://levels/act_02.json","res://levels/act_03.json"]:
  var data=JSON.parse_string(FileAccess.get_file_as_string(path))
  if data is Array: all.append_array(data)
  else: push_error("Invalid level catalog: "+path)
 return all
