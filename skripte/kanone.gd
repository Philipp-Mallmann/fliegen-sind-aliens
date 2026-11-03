extends Node2D

# Hoechstes Tempo der Kanone, in Pixeln pro Sekunde.
@export var tempo: float = 250.0
# Wie schnell die Kanone anfaehrt und abbremst, in Pixeln pro Sekunde pro Sekunde.
@export var beschleunigung: float = 600.0

# Das Tempo, mit dem die Kanone gerade faehrt. Negativ heisst nach links.
var aktuelles_tempo: float = 0.0


func _process(delta: float) -> void:
	var richtung: float = Input.get_axis("links", "rechts")
	var ziel_tempo: float = richtung * tempo
	aktuelles_tempo = move_toward(aktuelles_tempo, ziel_tempo, beschleunigung * delta)
	position.x += aktuelles_tempo * delta
