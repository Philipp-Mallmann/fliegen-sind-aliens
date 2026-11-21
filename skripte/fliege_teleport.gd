extends "res://skripte/fliege.gd"

# Die Teleport-Fliege: fliegt hin und her und springt zwischendurch ein Stueck zur Seite. Vorher flackert sie.

# Wie weit die Fliege von ihrer Mitte nach links und nach rechts fliegt, in Pixeln.
@export var strecke: float = 150.0
# Die kuerzeste und die laengste Pause zwischen zwei Spruengen, in Sekunden.
@export var pause_kurz: float = 1.5
@export var pause_lang: float = 3.0
# Wie viele Sekunden vor dem Sprung sie flackert.
@export var flacker_zeit: float = 0.3
# Wie lange ein Flackern dauert, in Sekunden: die Haelfte davon blass, die Haelfte voll.
@export var flacker_takt: float = 0.1
# Wie blass sie beim Flackern wird. 0.25 heisst: nur ein Viertel so kraeftig.
@export var flacker_blass: float = 0.25
# Wie weit sie mindestens und hoechstens springt, in Pixeln.
@export var sprung_nah: float = 150.0
@export var sprung_weit: float = 300.0

# Wie viele Sekunden es noch bis zum naechsten Sprung dauert.
var sprung_in: float = 0.0


func losfliegen() -> void:
	sprung_in = randf_range(pause_kurz, pause_lang)


func fliegen(delta: float) -> void:
	position.x += richtung * tempo * delta
	if position.x > mitte_x + strecke:
		richtung = -1.0
	if position.x < mitte_x - strecke:
		richtung = 1.0
	sprung_in -= delta
	modulate.a = 1.0
	if sprung_in < flacker_zeit and fmod(sprung_in, flacker_takt) < flacker_takt / 2.0:
		modulate.a = flacker_blass
	if sprung_in <= 0.0:
		springen()


func springen() -> void:
	var weit: float = randf_range(sprung_nah, sprung_weit)
	if randf() < 0.5:
		weit = -weit
	position.x += weit
	mitte_x += weit
	modulate.a = 1.0
	sprung_in = randf_range(pause_kurz, pause_lang)
