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
