extends RefCounted
# Stateless rules are shared by runtime and regression tests.
static func fruit_flees(rule: String, distance: float, dx: float, face: int, eyes: bool, crouch: bool) -> bool:
 match rule:
  "back", "stone": return distance < 240.0 and not eyes and signf(dx) == face
  "eyes", "feast": return distance < 280.0 and not eyes
  "sneak": return distance < 210.0 and not crouch
  "mirror": return false
 return false
static func water_target(inside: bool, crouch: bool, eyes: bool, idle: float) -> float:
 if inside and crouch: return 436.0
 if inside and eyes and idle >= 2.5: return 355.0
 return 402.0

static func shadow_flees(hero_x: float, fruit_x: float, torch_x: float, lit: bool) -> bool:
 if not lit: return false
 var side: float=1.0 if hero_x>=torch_x else -1.0
 var tip: float=hero_x+side*240.0
 return fruit_x>=minf(hero_x,tip)-25 and fruit_x<=maxf(hero_x,tip)+25
static func noise_target(moving: bool, crouch: bool, jumping: bool) -> float:
 if jumping: return 1.0
 if not moving: return 0.0
 return 0.18 if crouch else 0.85
