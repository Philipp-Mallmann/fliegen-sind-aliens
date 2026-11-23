extends "res://skripte/fliege.gd"

# Die normale Fliege: fliegt hin und her, dreht sich, wippt und wird zwischendurch langsamer.

# Wie weit die Fliege von ihrer Mitte nach links und nach rechts fliegt, in Pixeln.
@export var strecke: float = 300.0
# Wie schnell sich die Fliege um sich selbst dreht, im Bogenmass pro Sekunde. 6.28 ist eine Umdrehung pro Sekunde.
@export var drehtempo: float = 12.56
# Wie weit die Fliege hoch und runter wippt, in Pixeln.
@export var wipp_hoehe: float = 50.0
# Wie schnell sie wippt. 4 heisst: ein Auf und Ab dauert etwa 1,6 Sekunden.
@export var wipp_tempo: float = 4.0
# Wie langsam sie hoechstens wird, als Anteil ihres Tempos. 0.5 heisst: halb so schnell.
@export var langsam_anteil: float = 0.5
# Wie schnell ihr Tempo schwankt. 1.5 heisst: einmal langsam und wieder schnell dauert etwa 4 Sekunden.
@export var tempo_wechsel: float = 1.5
# Alle so viele Sekunden bremst sie kurz zusaetzlich ab.
@export var bremse_alle: float = 2.0
# So viele Sekunden dauert dieses Abbremsen.
@export var bremse_dauer: float = 0.5
# So schnell ist sie waehrenddessen, als Anteil des Tempos von gerade eben. 0.5 heisst: halb so schnell.
@export var bremse_anteil: float = 0.5


func fliegen(delta: float) -> void:
	rotation += drehtempo * delta
	position.y = grund_y + sin(zeit * wipp_tempo) * wipp_hoehe
	var welle: float = (sin(zeit * tempo_wechsel) + 1.0) / 2.0
	var jetzt: float = tempo * lerpf(langsam_anteil, 1.0, welle)
	if fmod(zeit, bremse_alle) > bremse_alle - bremse_dauer:
		jetzt = jetzt * bremse_anteil
	position.x += richtung * jetzt * delta
	if position.x > mitte_x + strecke:
		richtung = -1.0
	if position.x < mitte_x - strecke:
		richtung = 1.0
