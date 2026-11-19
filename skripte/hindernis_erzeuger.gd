extends Node2D

# Die Szene des Hindernisses. Daraus entsteht jedes neue Hindernis.
@export var hindernis_szene: PackedScene
# Die Kanone. Um sie herum wird die Spalte ausgewuerfelt.
@export var kanone: Node2D
# Der Faecher. Wird an jedes Hindernis weitergegeben.
@export var faecher: Node2D
# Die kuerzeste und die laengste Pause zwischen zwei Hindernissen, in Sekunden.
@export var pause_kurz: float = 6.0
@export var pause_lang: float = 10.0
# Wie weit links oder rechts von der Kanone die Spalte hoechstens liegt, in Pixeln. Das Bild reicht 720 zu jeder Seite.
@export var spielraum: float = 700.0

# Wie viele Sekunden es noch bis zum naechsten Hindernis dauert.
var naechstes_in: float = 0.0


func _ready() -> void:
	naechstes_in = randf_range(pause_kurz, pause_lang)


func _process(delta: float) -> void:
	naechstes_in -= delta
	if naechstes_in > 0.0:
		return
	var hindernis: Node2D = hindernis_szene.instantiate()
	hindernis.position.x = kanone.position.x + randf_range(-spielraum, spielraum)
	hindernis.kanone = kanone
	hindernis.faecher = faecher
	add_child(hindernis)
	naechstes_in = randf_range(pause_kurz, pause_lang)
