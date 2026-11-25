extends Node2D

# Die Einstellungsfliege auf der Wiese. Sie merkt nur, wenn eine Nadel sie trifft, und meldet das.

# Wird gesendet, wenn eine Nadel die Fliege getroffen hat.
signal angeschossen

# Die halbe Breite und die halbe Hoehe der Fliege, in Pixeln. 100 heisst: Sie ist 200 mal 200 gross.
@export var halbe_groesse: float = 100.0


func _process(_delta: float) -> void:
	if not visible:
		return
	for nadel in get_tree().get_nodes_in_group("nadeln"):
		var abstand: Vector2 = nadel.global_position - global_position
		if absf(abstand.x) <= halbe_groesse and absf(abstand.y) <= halbe_groesse:
			nadel.queue_free()
			angeschossen.emit()
