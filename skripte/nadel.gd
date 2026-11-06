extends Node2D

# Wie schnell die Nadel fliegt, hin und zurueck, in Pixeln pro Sekunde.
@export var tempo: float = 3200.0

# Die Muendung der Kanone. Dorthin kehrt die Nadel zurueck. Die Kanone traegt sie beim Schuss ein.
var muendung: Node2D = null
# false heisst: Die Nadel fliegt nach oben. true heisst: Sie wird eingeholt wie eine Harpune.
var kehrt_zurueck: bool = false


func _process(delta: float) -> void:
	if kehrt_zurueck:
		zurueckfliegen(delta)
	else:
		position.y -= tempo * delta


func einholen() -> void:
	kehrt_zurueck = true


func zurueckfliegen(delta: float) -> void:
	var ziel: Vector2 = muendung.global_position
	global_position = global_position.move_toward(ziel, tempo * delta)
	if global_position == ziel:
		queue_free()
