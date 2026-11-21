extends "res://skripte/fliege.gd"

# Die Koeder-Fliege: pendelt auf kleinem Raum zwischen zwei Punkten. Wird ein Hindernis angekuendigt,
# schwingt sie im Bogen darunter und zappelt dort. Kurz bevor der Klotz faellt, weicht sie zur Seite aus.

# Wie weit die beiden Punkte auseinander liegen, zwischen denen sie pendelt, in Pixeln. 144 ist ein Zehntel des Bildes.
@export var pendelweite: float = 144.0
# Dasselbe unter einer Warnung. Kleiner, damit sie in der Spalte (200 breit) bleibt.
@export var pendelweite_warnung: float = 100.0
# Wie viel hoeher oder tiefer ein Punkt hoechstens liegt, in Pixeln. Wird fuer jeden Punkt neu gewuerfelt.
@export var hoehen: float = 40.0
# Wie viel schneller sie unter einer Warnung pendelt. 3 heisst: dreimal so schnell.
@export var faktor_warnung: float = 3.0
# Wie schnell sie zu einer Warnung schwingt und vor dem Klotz ausweicht, in Pixeln pro Sekunde.
@export var tempo_eilig: float = 900.0
# Wie tief der Bogen beim Schwingen in der Mitte durchhaengt, in Pixeln.
@export var bogen: float = 80.0
# Wie viele Sekunden vor dem Fall sie ausweicht.
@export var ausweich_zeit: float = 0.25
# Wie weit neben die Mitte der Spalte sie ausweicht, in Pixeln. Die Spalte reicht 100 zur Seite, die Fliege ist 50 breit.
@export var ausweich_weite: float = 230.0
# Wie weit links und rechts von der Kanone sie eine Warnung noch bemerkt, in Pixeln. 720 ist der Bildrand.
@export var sichtweite: float = 720.0

# Der Punkt, zu dem sie gerade pendelt.
var ziel: Vector2 = Vector2.ZERO
# Auf welcher Seite ihrer Mitte der Punkt liegt: 1 rechts, -1 links.
var seite: float = 1.0
# true heisst: Sie pendelt gerade unter einer Warnung.
var unter_warnung: bool = false
# true heisst: Sie schwingt gerade im Bogen zu einer neuen Mitte.
var schwingt: bool = false
# Wo der Schwung angefangen hat: seitlich und in der Hoehe.
var schwung_von_x: float = 0.0
var schwung_von_y: float = 0.0


func losfliegen() -> void:
	neues_ziel()


func fliegen(delta: float) -> void:
	nach_warnung_sehen()
	if schwingt:
		schwingen(delta)
		return
	var jetzt: float = tempo
	if unter_warnung:
		jetzt = tempo * faktor_warnung
	position = position.move_toward(ziel, jetzt * delta)
	if position == ziel:
		seite = -seite
		neues_ziel()


func nach_warnung_sehen() -> void:
	var warnung: Node2D = warnung_im_bild()
	if warnung == null:
		unter_warnung = false
		return
	var wohin: float = warnung.position.x
	var rest: float = warnung.warnzeit - warnung.gewarnt
	unter_warnung = rest >= ausweich_zeit
	if not unter_warnung:
		if position.x < warnung.position.x:
			wohin -= ausweich_weite
		else:
			wohin += ausweich_weite
	if absf(wohin - mitte_x) > 1.0:
		mitte_x = wohin
		schwingt = true
		schwung_von_x = position.x
		schwung_von_y = position.y


func warnung_im_bild() -> Node2D:
	for hindernis in get_tree().get_nodes_in_group("hindernisse"):
		var warnt_noch: bool = hindernis.gewarnt < hindernis.warnzeit
		var seitlich: float = absf(hindernis.position.x - kanone.position.x)
		if warnt_noch and seitlich <= sichtweite:
			return hindernis
	return null


func schwingen(delta: float) -> void:
	var neues_x: float = move_toward(position.x, mitte_x, tempo_eilig * delta)
	position.x = neues_x
	if neues_x == mitte_x:
		schwingt = false
		position.y = schwung_von_y
		neues_ziel()
		return
	var anteil: float = (position.x - schwung_von_x) / (mitte_x - schwung_von_x)
	position.y = schwung_von_y + sin(anteil * PI) * bogen


func neues_ziel() -> void:
	var weite: float = pendelweite
	if unter_warnung:
		weite = pendelweite_warnung
	ziel = Vector2(mitte_x + seite * weite / 2.0, grund_y + randf_range(-hoehen, hoehen))
