extends Node2D

# Wie schnell die Nadel nach oben fliegt, in Pixeln pro Sekunde.
@export var tempo: float = 1600.0


func _process(delta: float) -> void:
	position.y -= tempo * delta
