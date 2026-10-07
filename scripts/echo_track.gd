extends RefCounted
# Position snapshots, not a second live physics simulation. Time-interpolated at any FPS.
const MAX_SECONDS: float=6.0
var samples: Array[Dictionary]=[]
var recording: bool=false
var active: bool=false
var holding: bool=false
var duration: float=0.0
var play_time: float=0.0
var cursor: int=0
var ghost: Dictionary={}
func clear() -> void:
 samples.clear()
 recording=false
 active=false
 holding=false
 duration=0
 play_time=0
 cursor=0
 ghost={}
func begin(frame: Dictionary) -> void:
 clear()
 recording=true
 var value: Dictionary=frame.duplicate(true)
 value.t=0.0
 samples.append(value)
func stop() -> void: recording=false
func capture(dt: float, frame: Dictionary) -> void:
 if not recording: return
 duration=minf(MAX_SECONDS,duration+dt)
 var value: Dictionary=frame.duplicate(true)
 value.t=duration
 samples.append(value)
 if duration>=MAX_SECONDS or samples.size()>=721: stop()
func play() -> bool:
 stop()
 if samples.size()<2 or duration<0.03: return false
 active=true
 holding=false
 play_time=0.0
 cursor=0
 ghost=samples[0].duplicate(true)
 return true
func advance(dt: float) -> void:
 if not active: return
 play_time=minf(duration,play_time+dt)
 while cursor<samples.size()-2 and float(samples[cursor+1].t)<=play_time: cursor+=1
 var a: Dictionary=samples[cursor]
 var b: Dictionary=samples[mini(cursor+1,samples.size()-1)]
 var span: float=float(b.t)-float(a.t)
 var weight: float=clampf((play_time-float(a.t))/span,0,1) if span>0 else 1.0
 ghost=a.duplicate(true)
 ghost.pos=Vector2(a.pos).lerp(Vector2(b.pos),weight)
 if play_time>=duration:
  holding=true
  ghost=samples[-1].duplicate(true)
  ghost.noise=0.0
