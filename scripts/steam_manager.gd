extends Node
# Deliberately OFF. No SDK, App ID, achievements or Cloud integration in M1.
# Keep store-specific calls behind this boundary in M5.
var available: bool = false
func _ready() -> void:
 available = false
