extends Node2D

# Wie schnell die Fliege seitlich fliegt, in Pixeln pro Sekunde.
@export var tempo: float = 150.0
# Wie weit die Fliege von ihrer Mitte nach links und nach rechts fliegt, in Pixeln.
@export var strecke: float = 300.0
# Wie viel Flugkraft die Fliege gibt, wenn sie gefangen ist.
@export var flugkraft: int = 2
# Die halbe Breite und die halbe Hoehe der Fliege, in Pixeln. 50 heisst: Die Fliege ist 100 mal 100 gross.
@export var halbe_groesse: float = 50.0

# Um diese Stelle fliegt die Fliege hin und her. Setzt der Erzeuger, bevor die Fliege ins Spiel kommt.
var mitte_x: float = 0.0
# 1 heisst nach rechts, -1 heisst nach links.
var richtung: float = 1.0
# true heisst: Die Fliege haengt an der Nadel und fliegt nicht mehr.
var gefangen: bool = false


func _process(delta: float) -> void:
	if gefangen:
		return
	position.x += richtung * tempo * delta
	if position.x > mitte_x + strecke:
		richtung = -1.0
	if position.x < mitte_x - strecke:
		richtung = 1.0
