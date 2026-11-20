extends Node2D

# Die Szene der Fliege. Daraus entsteht jede neue Fliege.
@export var fliege_szene: PackedScene
# Die Kanone. An ihr liest der Erzeuger ab, wo man gerade ist.
@export var kanone: Node2D
# Wie viele Pixel Hoehe zwischen zwei Fliegen liegen, die oben ueber dem Bild bereitstehen.
@export var abstand: float = 250.0
# Wie weit links oder rechts von der Kanone die Mitte einer neuen Fliege hoechstens liegt, in Pixeln.
@export var breite: float = 400.0
# Wie weit ueber der Kanone die oberste Fliege schon bereitsteht, in Pixeln. Der Bildrand liegt bei 920.
@export var vorlauf: float = 1200.0
# Das langsamste und das schnellste Tempo einer normalen Fliege, in Pixeln pro Sekunde.
@export var tempo_langsam: float = 100.0
@export var tempo_schnell: float = 180.0

# Testfassung fuer den Spass-Test: ein Teil der Fliegen ist doppelt so schnell und gibt mehr. Abschnitt 9 baut die richtigen Arten.
# Wie viele Fliegen schnell sind. 0.5 heisst: die Haelfte.
@export var anteil_schnell: float = 0.5
# Wie viel Flugkraft eine normale und eine schnelle Fliege geben.
@export var flugkraft_normal: int = 3
@export var flugkraft_schnell: int = 10

# Wie viele freie Fliegen mindestens in der Naehe sein sollen. Sind es weniger, fliegt eine von der Seite herein.
@export var mindestens: int = 4
# Wie weit links und rechts von der Kanone "in der Naehe" reicht, in Pixeln. Der Bildrand liegt bei 720.
@export var naehe: float = 900.0
# Wie weit links oder rechts von der Kanone eine hereinfliegende Fliege startet, in Pixeln.
# Muss groesser sein als breite + strecke der Fliege (400 + 300), sonst fliegt sie nicht herein.
@export var einflug_x: float = 800.0
# In welcher Hoehe ueber der Kanone eine hereinfliegende Fliege fliegt, hoechstens und mindestens, in Pixeln.
# Die Muendung liegt bei 140, der obere Bildrand bei 920.
@export var einflug_oben: float = 850.0
@export var einflug_unten: float = 300.0
# Ab wie weit weg eine freie Fliege geloescht wird: seitlich und unter der Kanone, in Pixeln.
@export var loeschen_seitlich: float = 2000.0
@export var loeschen_unten: float = 300.0

# Auf dieser Hoehe entsteht die naechste Fliege ueber dem Bild. Nach oben wird y kleiner.
var naechste_hoehe: float = -400.0


func _process(_delta: float) -> void:
	while naechste_hoehe > kanone.position.y - vorlauf:
		var x: float = kanone.position.x + randf_range(-breite, breite)
		fliege_bauen(x, x, naechste_hoehe)
		naechste_hoehe -= abstand
	aufraeumen()
	if freie_in_der_naehe() < mindestens:
		hereinfliegen()


func fliege_bauen(start_x: float, mitte_x: float, hoehe: float) -> void:
	var fliege: Node2D = fliege_szene.instantiate()
	fliege.position = Vector2(start_x, hoehe)
	fliege.mitte_x = mitte_x
	fliege.tempo = randf_range(tempo_langsam, tempo_schnell)
	fliege.flugkraft = flugkraft_normal
	if randf() < anteil_schnell:
		fliege.tempo *= 2.0
		fliege.flugkraft = flugkraft_schnell
	add_child(fliege)


func hereinfliegen() -> void:
	var seite: float = 1.0
	if randf() < 0.5:
		seite = -1.0
	var start_x: float = kanone.position.x + seite * einflug_x
	var mitte_x: float = kanone.position.x + randf_range(-breite, breite)
	var hoehe: float = kanone.position.y - randf_range(einflug_unten, einflug_oben)
	fliege_bauen(start_x, mitte_x, hoehe)


func freie_in_der_naehe() -> int:
	var anzahl: int = 0
	for fliege in get_children():
		var seitlich: float = absf(fliege.position.x - kanone.position.x)
		var ueber: float = kanone.position.y - fliege.position.y
		if seitlich <= naehe and ueber >= einflug_unten and ueber <= einflug_oben:
			anzahl += 1
	return anzahl


func aufraeumen() -> void:
	for fliege in get_children():
		var zu_tief: bool = fliege.position.y > kanone.position.y + loeschen_unten
		var zu_weit: bool = absf(fliege.position.x - kanone.position.x) > loeschen_seitlich
		if zu_tief or zu_weit:
			fliege.queue_free()
