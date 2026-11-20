extends Node2D

# Die Szene der Fliege. Daraus entsteht jede neue Fliege.
@export var fliege_szene: PackedScene
# Die Kanone. An ihr liest der Erzeuger ab, wo man gerade ist.
@export var kanone: Node2D
# Wie weit links oder rechts von der Kanone die Mitte einer neuen Fliege hoechstens liegt, in Pixeln.
@export var breite: float = 400.0
# Das langsamste und das schnellste Tempo einer normalen Fliege, in Pixeln pro Sekunde.
@export var tempo_langsam: float = 100.0
@export var tempo_schnell: float = 180.0

# Testfassung fuer den Spass-Test: zwei Arten. Abschnitt 9 baut die richtigen Arten.
# Wie viele Fliegen schnell sind. 0.5 heisst: die Haelfte.
@export var anteil_schnell: float = 0.5
# Wie viel Flugkraft eine normale und eine schnelle Fliege geben.
@export var flugkraft_normal: int = 2
@export var flugkraft_schnell: int = 5
# Wie viel schneller eine schnelle Fliege ist als eine normale. 4 heisst: viermal so schnell.
@export var faktor_schnell: float = 4.0
# Wie viele Umdrehungen pro Sekunde eine normale Fliege um sich selbst macht.
@export var drehungen_normal: float = 1.0
# Wie weit eine normale Fliege hoch und runter wippt, in Pixeln.
@export var wippen_normal: float = 25.0

# Wie viele freie Fliegen mindestens da sein sollen. Sind es weniger, fliegt eine von der Seite herein.
@export var mindestens: int = 4
# Wie weit links und rechts von der Kanone eine Fliege noch mitzaehlt, in Pixeln.
@export var naehe: float = 1000.0
# Wie weit links oder rechts von der Kanone eine hereinfliegende Fliege startet, in Pixeln.
# Der Bildrand liegt in der Luft 720 neben der Kanone, am Boden (herausgezoomt) 847. Dazu die halbe Fliege (50).
# Muss groesser sein als breite + strecke der Fliege (400 + 300), sonst fliegt sie nicht herein.
@export var einflug_x: float = 900.0
# In welcher Hoehe ueber der Kanone eine hereinfliegende Fliege fliegt, hoechstens und mindestens, in Pixeln.
# Liegt mit Abstand zum Wippen zwischen flucht_unten und flucht_oben, damit sie nicht gleich flieht.
@export var einflug_oben: float = 750.0
@export var einflug_unten: float = 560.0
# Zwischen diesen Hoehen ueber der Kanone fliegt eine Fliege ruhig hin und her, in Pixeln.
# Darunter (untere Bildhaelfte) und darueber (oberes Viertel, dort haengt der Faecher) flieht sie zum naeheren Rand.
# Der obere Bildrand liegt in der Luft 1060 ueber der Kanone: Haelfte 520, Viertel 790.
@export var flucht_unten: float = 520.0
@export var flucht_oben: float = 790.0
# Ab wie weit weg eine freie Fliege geloescht wird: seitlich und unter der Kanone, in Pixeln.
@export var loeschen_seitlich: float = 1100.0
@export var loeschen_unten: float = 300.0


func _process(_delta: float) -> void:
	aufraeumen()
	fliehen_lassen()
	if freie_in_der_naehe() < mindestens:
		hereinfliegen()


func hereinfliegen() -> void:
	var seite: float = 1.0
	if randf() < 0.5:
		seite = -1.0
	var fliege: Node2D = fliege_szene.instantiate()
	fliege.position.x = kanone.position.x + seite * einflug_x
	fliege.position.y = kanone.position.y - randf_range(einflug_unten, einflug_oben)
	fliege.mitte_x = kanone.position.x + randf_range(-breite, breite)
	fliege.tempo = randf_range(tempo_langsam, tempo_schnell)
	if randf() < anteil_schnell:
		fliege.tempo *= faktor_schnell
		fliege.flugkraft = flugkraft_schnell
	else:
		fliege.flugkraft = flugkraft_normal
		fliege.drehtempo = drehungen_normal * TAU
		fliege.wipp_hoehe = wippen_normal
	add_child(fliege)


func fliehen_lassen() -> void:
	for fliege in get_children():
		if fliege.flucht != 0.0:
			continue
		var ueber: float = kanone.position.y - fliege.position.y
		if ueber < flucht_unten or ueber > flucht_oben:
			if fliege.position.x < kanone.position.x:
				fliege.flucht = -1.0
			else:
				fliege.flucht = 1.0


func freie_in_der_naehe() -> int:
	var anzahl: int = 0
	for fliege in get_children():
		var seitlich: float = absf(fliege.position.x - kanone.position.x)
		if fliege.flucht == 0.0 and seitlich <= naehe:
			anzahl += 1
	return anzahl


func aufraeumen() -> void:
	for fliege in get_children():
		var zu_tief: bool = fliege.position.y > kanone.position.y + loeschen_unten
		var zu_weit: bool = absf(fliege.position.x - kanone.position.x) > loeschen_seitlich
		if zu_tief or zu_weit:
			fliege.queue_free()
