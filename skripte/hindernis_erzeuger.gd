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
# Wie weit links oder rechts von der Kanone das innere Drittel des Bildes reicht, in Pixeln (1440 / 3 / 2 = 240).
@export var mitte: float = 240.0
# Wie oft die Spalte im inneren Drittel liegt. 0.7 heisst: in 7 von 10 Faellen, sonst irgendwo im Bild.
@export var anteil_mitte: float = 0.7
# Die Warnzeit ganz unten und die laengste Warnzeit weiter oben, in Sekunden. Oben ist der Faecher breiter, man braucht mehr Zeit.
@export var warnzeit_unten: float = 6.0
@export var warnzeit_oben: float = 10.0
# Ab dieser Hoehe gilt die laengste Warnzeit, in Pixeln. Bis dahin waechst sie gleichmaessig.
# 20000 sind zwei Drittel des Wegs bis 100 Flugkraft (100 x 300 px). Bei einem Drittel sind es dann 8 s.
@export var hoehe_oben: float = 20000.0

# Wie viele Sekunden es noch bis zum naechsten Hindernis dauert.
var naechstes_in: float = 0.0


func _ready() -> void:
	naechstes_in = randf_range(pause_kurz, pause_lang)


func _process(delta: float) -> void:
	naechstes_in -= delta
	if naechstes_in > 0.0:
		return
	var hindernis: Node2D = hindernis_szene.instantiate()
	var abstand: float = randf_range(-spielraum, spielraum)
	if randf() < anteil_mitte:
		abstand = randf_range(-mitte, mitte)
	hindernis.position.x = kanone.position.x + abstand
	hindernis.kanone = kanone
	hindernis.faecher = faecher
	var anteil: float = clampf(-kanone.position.y / hoehe_oben, 0.0, 1.0)
	hindernis.warnzeit = lerpf(warnzeit_unten, warnzeit_oben, anteil)
	add_child(hindernis)
	naechstes_in = randf_range(pause_kurz, pause_lang)
