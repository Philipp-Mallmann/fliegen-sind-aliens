extends "res://skripte/fliege.gd"

# Die scheue Fliege: haelt Abstand zur Kanone. Kommt die Kanone naeher, weicht sie aus, aber langsamer als die Kanone faehrt.

# Wie viel Abstand zur Kanone sie mindestens und hoechstens halten will, in Pixeln. Jede Fliege wuerfelt ihren eigenen.
@export var abstand_nah: float = 200.0
@export var abstand_weit: float = 450.0
# Wie weit die Fliege hoch und runter wippt, in Pixeln.
@export var wipp_hoehe: float = 15.0
# Wie schnell sie wippt.
@export var wipp_tempo: float = 6.0

# Der Abstand, den diese eine Fliege halten will.
var abstand: float = 0.0


func losfliegen() -> void:
	abstand = randf_range(abstand_nah, abstand_weit)


func fliegen(delta: float) -> void:
	position.y = grund_y + sin(zeit * wipp_tempo) * wipp_hoehe
	var seite: float = 1.0
	if position.x < kanone.position.x:
		seite = -1.0
	var wunsch_x: float = kanone.position.x + seite * abstand
	position.x = move_toward(position.x, wunsch_x, tempo * delta)
