extends Node

# Tut der Spieler eine Weile nichts, wechselt der Forscher am Boden in die Warte-Animation.
# Bewegt er die Maus, drueckt eine Taste oder tippt, steht der Forscher sofort wieder normal.

# Der Koerper und der Kopf des Forschers. Beide spielen immer dieselbe Animation.
@export var koerper: AnimatedSprite2D
@export var gesicht: AnimatedSprite2D
# Die Schulter mit dem Arm und der Kanone. Sie geht beim In-die-Knie-Gehen mit nach unten.
@export var schulter: Node2D
# Nach so vielen Sekunden ohne Eingabe beginnt das Warten.
@export var wartezeit: float = 3.0
# So viele Pixel tiefer liegt die Schulter im ersten Warte-Bild (in den Knien).
@export var knie_tiefe: float = 231.9

# Wie viele Sekunden schon keine Eingabe kam.
var ruhig: float = 0.0
# Wo die Schulter beim Stehen ist (y).
var schulter_y: float = 0.0


func _ready() -> void:
	schulter_y = schulter.position.y
	koerper.frame_changed.connect(schulter_setzen)


func _process(delta: float) -> void:
	# Nur am Boden vor dem ersten Fang. Danach haengt die Figur unter der Kanone und soll nicht warten.
	if not get_parent().aktiv:
		if koerper.animation != "stehen":
			zeigen("stehen")
		return
	ruhig += delta
	if ruhig >= wartezeit and koerper.animation != "warten":
		zeigen("warten")


# Godot ruft _input bei jeder Eingabe: Maus bewegt oder geklickt, Taste, Finger auf dem Bildschirm.
func _input(_ereignis: InputEvent) -> void:
	ruhig = 0.0
	if koerper.animation != "stehen":
		zeigen("stehen")


func zeigen(animation: String) -> void:
	koerper.play(animation)
	gesicht.play(animation)
	schulter_setzen()


# Wird bei jedem Bildwechsel des Koerpers gerufen.
func schulter_setzen() -> void:
	if koerper.animation == "warten" and koerper.frame == 0:
		schulter.position.y = schulter_y + knie_tiefe
	else:
		schulter.position.y = schulter_y
