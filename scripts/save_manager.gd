extends Node
# Versioned profiles. M1's progress.cfg is kept intact and migrated into slot 0.
const VERSION: int = 2
const Catalog = preload("res://scripts/level_catalog.gd")
var active_slot: int = 0
var level_count: int = 9
var unlocked: int = 0
var total_taunts: int = 0
var best_times: Dictionary = {}
var assisted_times: Dictionary = {}
var load_error: bool = false
var recovered_backup: bool = false
var read_only: bool = false
var last_error: Error = OK
func _ready() -> void:
 level_count=Catalog.load_levels().size()
 var profile:=ConfigFile.new()
 if profile.load("user://profile.cfg")==OK:
  var value=profile.get_value("profile","active_slot",0)
  if value is int: active_slot=clampi(value,0,2)
 load_slot(active_slot)
func slot_path(slot: int) -> String:
 return "user://progress_slot_%d.cfg"%slot
func read_snapshot(path: String) -> Dictionary:
 var config:=ConfigFile.new()
 var error: Error=config.load(path)
 if error==ERR_FILE_NOT_FOUND: return {"missing":true}
 if error!=OK: return {"invalid":true}
 var version=config.get_value("meta","version",1)
 if version is not int or version<1 or version>VERSION: return {"invalid":true,"future":true}
 var progress=config.get_value("progress","unlocked",0)
 var taunts=config.get_value("progress","taunts",0)
 var times=config.get_value("progress","best_times",{})
 if progress is not int or taunts is not int or times is not Dictionary: return {"invalid":true}
 var safe_times: Dictionary={}
 for key in times:
  if str(key).is_valid_int() and int(key)>=0 and int(key)<level_count and (times[key] is float or times[key] is int):
   var value: float=float(times[key])
   if value>=0 and not is_nan(value) and not is_inf(value): safe_times[str(key)]=value
 var assisted=config.get_value("progress","assisted_times",{})
 var safe_assisted: Dictionary={}
 if assisted is Dictionary:
  for key in assisted:
   if str(key).is_valid_int() and int(key)>=0 and int(key)<level_count and (assisted[key] is float or assisted[key] is int):
    var value: float=float(assisted[key])
    if value>=0 and not is_nan(value) and not is_inf(value): safe_assisted[str(key)]=value
 return {"unlocked":clampi(progress,0,level_count-1),"taunts":maxi(0,taunts),"times":safe_times,"assisted_times":safe_assisted}
func load_slot(slot: int) -> void:
 active_slot=clampi(slot,0,2)
 unlocked=0
 total_taunts=0
 best_times={}
 assisted_times={}
 load_error=false
 recovered_backup=false
 read_only=false
 var path: String=slot_path(active_slot)
 var data: Dictionary=read_snapshot(path)
 var migrating: bool=false
 if data.has("missing"):
  var backup: Dictionary=read_snapshot(path+".bak")
  if backup.has("unlocked"):
   data=backup
   recovered_backup=true
 if data.has("missing") and active_slot==0:
  var legacy: Dictionary=read_snapshot("user://progress.cfg")
  if not legacy.has("missing"):
   data=legacy
   migrating=not legacy.has("invalid")
 if data.has("invalid"):
  load_error=true
  if data.get("future",false):
   read_only=true
   return
  var backup: Dictionary=read_snapshot(path+".bak")
  if backup.has("unlocked"):
   data=backup
   recovered_backup=true
  else:
   read_only=true
   return
 if data.has("unlocked"):
  unlocked=data.unlocked
  total_taunts=data.taunts
  best_times=data.times
  assisted_times=data.assisted_times
 if migrating:
  # M1 capped unlocked at 6 even after winning the seventh/final trial.
  # A recorded completion proves the next chapter can open immediately.
  if level_count>7 and unlocked>=6 and best_times.has("6"): unlocked=maxi(unlocked,7)
  flush()
func select_slot(slot: int) -> Error:
 if slot<0 or slot>2: return ERR_INVALID_PARAMETER
 load_slot(slot)
 var profile:=ConfigFile.new()
 profile.set_value("profile","active_slot",active_slot)
 var error: Error=profile.save("user://profile.tmp")
 if error==OK: error=DirAccess.rename_absolute("user://profile.tmp","user://profile.cfg")
 last_error=error
 return error
func slot_info(slot: int) -> Dictionary:
 var data: Dictionary=read_snapshot(slot_path(slot))
 if data.has("missing") and slot==0: data=read_snapshot("user://progress.cfg")
 return data
func flush() -> Error:
 last_error=write_snapshot()
 return last_error
func write_snapshot() -> Error:
 if read_only: return ERR_FILE_CANT_WRITE
 var config:=ConfigFile.new()
 config.set_value("meta","version",VERSION)
 config.set_value("progress","unlocked",unlocked)
 config.set_value("progress","taunts",total_taunts)
 config.set_value("progress","best_times",best_times)
 config.set_value("progress","assisted_times",assisted_times)
 var path: String=slot_path(active_slot)
 var error: Error=config.save(path+".tmp")
 if error!=OK: return error
 if FileAccess.file_exists(path) and not recovered_backup:
  error=DirAccess.copy_absolute(path,path+".bak")
  if error!=OK: return error
 error=DirAccess.rename_absolute(path+".tmp",path)
 if error==OK:
  load_error=false
  recovered_backup=false
 return error
func record(level: int, seconds: float, taunts: int, assisted: bool=false) -> Error:
 if read_only or level<0 or level>=level_count or seconds<0 or is_nan(seconds) or is_inf(seconds): return ERR_INVALID_PARAMETER
 unlocked=maxi(unlocked,mini(level+1,level_count-1))
 total_taunts+=maxi(0,taunts)
 var key: String=str(level)
 var times: Dictionary=assisted_times if assisted else best_times
 times[key]=minf(float(times.get(key,INF)),seconds)
 return flush()
func reset_active_slot() -> Error:
 # Called only after UI confirmation. Archive, do not delete the old profile.
 var path: String=slot_path(active_slot)
 var stamp: String="%d_%d"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
 for suffix in ["",".bak"]:
  if FileAccess.file_exists(path+suffix):
   var error: Error=DirAccess.rename_absolute(path+suffix,path+".archived_"+stamp+suffix)
   if error!=OK: return error
 unlocked=0
 total_taunts=0
 best_times={}
 assisted_times={}
 read_only=false
 load_error=false
 recovered_backup=false
 return flush()
