extends "res://skripte/fliege.gd"

# Die Heuschrecke: springt zweimal sehr schnell zur Seite, dann schwebt sie kurz auf der Stelle
# und wippt dabei leicht auf und ab. Dann springt sie wieder zweimal.

# Wie weit ein Sprung zur Seite geht, in Pixeln. Zwei Spruenge sind zusammen ein halber Bildschirm (720).
@export var sprungweite: float = 360.0
# Wie lange ein Sprung dauert, in Sekunden. Klein heisst: sehr schnell.
@export var sprungdauer: float = 0.2
# Wie hoch der Bogen eines Sprungs in der Mitte ist, in Pixeln.
@export var bogen: float = 60.0
# Wie lange sie nach zwei Spruengen auf der Stelle schwebt, in Sekunden.
@export var pause: float = 1.0
# Wie weit sie beim Schweben auf und ab wippt, in Pixeln.
@export var wippen: float = 8.0
# Wie weit sie sich hoechstens von ihrer Mitte entfernt, bevor sie umdreht, in Pixeln.
@export var strecke: float = 400.0

# true heisst: Sie ist gerade mitten in einem Sprung.
var springt: bool = false
# Der wievielte Sprung gerade laeuft: 1 oder 2.
var sprung_nummer: int = 0
# Die Uhr fuer den Sprung oder die Pause, in Sekunden.
var uhr: float = 0.0
# Wo der laufende Sprung angefangen hat, auf der x-Achse.
var start_x: float = 0.0


func fliegen(delta: float) -> void:
	uhr += delta
	if springt:
		var anteil: float = minf(uhr / sprungdauer, 1.0)
		position.x = start_x + richtung * sprungweite * anteil
		position.y = grund_y - sin(PI * anteil) * bogen
		if anteil >= 1.0:
			if sprung_nummer < 2:
				sprung_beginnen()
			else:
				springt = false
				uhr = 0.0
		return
	position.y = grund_y + sin(uhr * TAU) * wippen
	if uhr >= pause:
		if absf(position.x + richtung * sprungweite * 2.0 - mitte_x) > strecke:
			richtung = -richtung
		sprung_nummer = 0
		sprung_beginnen()


func sprung_beginnen() -> void:
	springt = true
	sprung_nummer += 1
	uhr = 0.0
	start_x = position.x
