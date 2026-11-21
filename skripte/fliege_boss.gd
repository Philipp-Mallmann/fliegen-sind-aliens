extends "res://skripte/fliege.gd"

# Die Boss-Fliege: gross und langsam. Fliegt quer durchs Bild und steigt dabei, bis sie oben hinaus ist.
# Jeder Treffer laesst sie ein Stueck absacken. Wie oft man treffen muss, steht in "leben" (fliege.gd).

# Wie schnell sie steigt, in Pixeln pro Sekunde.
@export var steigtempo: float = 75.0
# Wie weit sie hoch und runter wippt, in Pixeln.
@export var wipp_hoehe: float = 20.0
# Wie schnell sie wippt.
@export var wipp_tempo: float = 2.0
# Wie weit sie bei einem Treffer absackt, in Pixeln.
@export var absacken: float = 200.0
# Wie schnell sie dabei sinkt, in Pixeln pro Sekunde.
@export var sacktempo: float = 600.0

# Wie viele Pixel sie noch absacken muss.
var sack_rest: float = 0.0


func fliegen(delta: float) -> void:
	position.x += richtung * tempo * delta
	grund_y -= steigtempo * delta
	var stueck: float = minf(sack_rest, sacktempo * delta)
	sack_rest -= stueck
	grund_y += stueck
	position.y = grund_y + sin(zeit * wipp_tempo) * wipp_hoehe


func angeschossen() -> void:
	sack_rest += absacken
