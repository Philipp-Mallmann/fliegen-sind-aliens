extends Node2D

# Wie schnell die Fliege seitlich fliegt, in Pixeln pro Sekunde.
@export var tempo: float = 150.0
# Wie weit die Fliege von ihrem Startpunkt nach links und nach rechts fliegt, in Pixeln.
@export var strecke: float = 300.0

# Wo die Fliege angefangen hat. Um diese Stelle fliegt sie hin und her.
var start_x: float = 0.0
# 1 heisst nach rechts, -1 heisst nach links.
var richtung: float = 1.0
# true heisst: Die Fliege haengt an der Nadel und fliegt nicht mehr.
var gefangen: bool = false


func _ready() -> void:
	start_x = position.x


func _process(delta: float) -> void:
	if gefangen:
		return
	position.x += richtung * tempo * delta
	if position.x > start_x + strecke:
		richtung = -1.0
	if position.x < start_x - strecke:
		richtung = 1.0
