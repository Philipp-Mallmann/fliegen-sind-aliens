extends Node2D

# Wie schnell die Fliege seitlich fliegt, in Pixeln pro Sekunde.
@export var tempo: float = 150.0
# Wie weit die Fliege von ihrer Mitte nach links und nach rechts fliegt, in Pixeln.
@export var strecke: float = 300.0
# Wie viel Flugkraft die Fliege gibt, wenn sie gefangen ist.
@export var flugkraft: int = 2
# Die halbe Breite und die halbe Hoehe der Fliege, in Pixeln. 50 heisst: Die Fliege ist 100 mal 100 gross.
@export var halbe_groesse: float = 50.0
# Wie schnell sich die Fliege um sich selbst dreht, im Bogenmass pro Sekunde. 0 heisst: gar nicht.
@export var drehtempo: float = 0.0
# Wie weit die Fliege hoch und runter wippt, in Pixeln. 0 heisst: gar nicht.
@export var wipp_hoehe: float = 0.0
# Wie schnell sie wippt. 4 heisst: ein Auf und Ab dauert etwa 1,6 Sekunden.
@export var wipp_tempo: float = 4.0

# Um diese Stelle fliegt die Fliege hin und her. Setzt der Erzeuger, bevor die Fliege ins Spiel kommt.
var mitte_x: float = 0.0
# 1 heisst nach rechts, -1 heisst nach links.
var richtung: float = 1.0
# true heisst: Die Fliege haengt an der Nadel und fliegt nicht mehr.
var gefangen: bool = false
# 0 heisst: Die Fliege fliegt hin und her. 1 oder -1 heisst: Sie flieht nach rechts oder links aus dem Bild. Setzt der Erzeuger.
var flucht: float = 0.0
# Die Hoehe, um die die Fliege wippt.
var grund_y: float = 0.0
# Wie viele Sekunden die Fliege schon fliegt. Daraus wird das Wippen berechnet.
var zeit: float = 0.0


func _ready() -> void:
	grund_y = position.y


func _process(delta: float) -> void:
	if gefangen:
		return
	zeit += delta
	rotation += drehtempo * delta
	position.y = grund_y + sin(zeit * wipp_tempo) * wipp_hoehe
	if flucht != 0.0:
		position.x += flucht * tempo * delta
		return
	position.x += richtung * tempo * delta
	if position.x > mitte_x + strecke:
		richtung = -1.0
	if position.x < mitte_x - strecke:
		richtung = 1.0
