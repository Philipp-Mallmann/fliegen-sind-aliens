extends CanvasLayer

# Zeigt, was ein Treffer bringt und was ein Stein kostet: "+4" beim Fang, "Double Kill" bei mehreren Fliegen
# auf einmal, "-4", wenn ein Stein gefangene Fliegen zermatscht. Die Anzeige liegt auf dem Bildschirm (CanvasLayer),
# nicht in der Welt: Sonst blieben die Zahlen zurueck, wenn die Kamera nach einem Fang mit der Kanone steigt.
# Wer etwas zeigen will, ruft get_tree().call_group("punktanzeige", ...): Der Knoten ist in dieser Gruppe.

# Die Szene einer aufsteigenden Zahl.
@export var zahl_szene: PackedScene
# Die Farben: Gewinn, Verlust und das Kombo-Wort.
@export var farbe_plus: Color = Color(0.55, 1.0, 0.45)
@export var farbe_minus: Color = Color(1.0, 0.3, 0.25)
@export var farbe_kombo: Color = Color(1.0, 0.85, 0.2)
# Die Kombo-Woerter fuer 2, 3, 4 und 5 oder mehr Fliegen auf einmal.
@export var kombo_woerter: Array[String] = ["Double Kill", "Triple Kill", "Quadra Kill", "Mega Kill"]
# Wie gross das Kombo-Wort ist, verglichen mit einer Zahl. 1.5 heisst: anderthalbmal so gross.
@export var kombo_groesse: float = 1.5
# Wo das Kombo-Wort auf dem Bildschirm steht, in Pixeln. Das Bild ist 1440 breit und 1080 hoch.
@export var kombo_ort: Vector2 = Vector2(720, 330)
# Das Spiel (spiel.gd). Seine Funktion wackeln laesst das Bild wackeln.
@export var spiel: Node
# Die Treffer-Anzeige am Boss ("1/3"): Farbe, Groesse und wie stark das Bild wackelt, in Pixeln und Sekunden.
@export var farbe_boss: Color = Color(1.0, 0.6, 0.25)
@export var boss_groesse: float = 1.6
@export var boss_wackeln: float = 12.0
@export var boss_wackeln_letzter: float = 24.0
@export var boss_wackel_dauer: float = 0.3


# Eine Nadel hat getroffen und wird uebergeben: Flugkraft als "+N", bei mehreren Fliegen dazu das Kombo-Wort.
func gefangen(nadel: Node2D) -> void:
	zeigen(im_bild(nadel.global_position) + Vector2(70, 0), "+" + str(nadel.flugkraft()), farbe_plus, 1.0)
	var anzahl: int = nadel.aufgespiesste.size()
	if anzahl >= 2:
		var nummer: int = mini(anzahl - 2, kombo_woerter.size() - 1)
		zeigen(kombo_ort, kombo_woerter[nummer], farbe_kombo, kombo_groesse)


# Ein Treffer auf den Boss: "1/3", "2/3", "3/3" an der Trefferstelle, dazu wackelt das Bild, beim letzten staerker.
func boss_treffer(ort: Vector2, nummer: int, von: int) -> void:
	zeigen(im_bild(ort) + Vector2(0, -80), str(nummer) + "/" + str(von), farbe_boss, boss_groesse)
	var staerke: float = boss_wackeln
	if nummer >= von:
		staerke = boss_wackeln_letzter
	spiel.wackeln(staerke, boss_wackel_dauer)


# Ein Stein hat gefangene Fliegen zermatscht: so viel Flugkraft geht verloren, als "-N" an der Stelle.
func verloren(ort: Vector2, flugkraft: int) -> void:
	zeigen(im_bild(ort), "-" + str(flugkraft), farbe_minus, 1.0)


# Rechnet einen Punkt in der Welt in einen Punkt auf dem Bildschirm um: dort, wo die Kamera ihn gerade zeigt.
func im_bild(ort: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * ort


# ort: wo auf dem Bildschirm die Mitte des Textes steht.
func zeigen(ort: Vector2, text: String, farbe: Color, groesse: float) -> void:
	var zahl: Label = zahl_szene.instantiate()
	zahl.text = text
	zahl.modulate = farbe
	zahl.scale = Vector2.ONE * groesse
	add_child(zahl)
	zahl.position = ort - zahl.pivot_offset
