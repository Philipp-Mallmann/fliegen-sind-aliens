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
# Die Warnzeit in Sekunden: ganz unten, an der Spitze und ganz oben bei 100 Flugkraft.
# Bis zur Spitze waechst sie (der Faecher wird breiter), danach wird es wieder knapper.
@export var warnzeit_unten: float = 6.0
@export var warnzeit_spitze: float = 9.0
@export var warnzeit_ende: float = 5.0
# Wo die Spitze liegt und wo das Ende, in Pixeln Hoehe. 15000 ist die Haelfte, 30000 sind 100 Flugkraft (100 x 300 px).
@export var hoehe_spitze: float = 15000.0
@export var hoehe_ende: float = 30000.0

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
	hindernis.warnzeit = warnzeit_hier()
	hindernis.volle_warnzeit = warnzeit_spitze
	add_child(hindernis)
	naechstes_in = randf_range(pause_kurz, pause_lang)


func warnzeit_hier() -> float:
	var hoehe: float = -kanone.position.y
	if hoehe < hoehe_spitze:
		return lerpf(warnzeit_unten, warnzeit_spitze, clampf(hoehe / hoehe_spitze, 0.0, 1.0))
	var anteil: float = (hoehe - hoehe_spitze) / (hoehe_ende - hoehe_spitze)
	return lerpf(warnzeit_spitze, warnzeit_ende, clampf(anteil, 0.0, 1.0))
