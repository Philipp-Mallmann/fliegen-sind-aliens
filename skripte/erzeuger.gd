extends Node2D

# Die Kanone. An ihr liest der Erzeuger ab, wo man gerade ist.
@export var kanone: Node2D
# Der Knoten mit den Zonen. Er sagt, welche Fliegen in der aktuellen Hoehe hereinfliegen.
@export var zonen: Node
# Die Fliegen-Szenen fuer den Schwarm am Boden: alle Arten ausser dem Boss.
@export var schwarm_szenen: Array[PackedScene] = []
# Wie weit links oder rechts von der Kanone eine Fliege des Schwarms hoechstens startet, in Pixeln.
# In der Totale sieht man 1675 zu jeder Seite.
@export var schwarm_breite: float = 900.0
# In welcher Hoehe ueber der Kanone der Schwarm fliegt, mindestens und hoechstens, in Pixeln.
# Der obere Bildrand der Totale liegt 672 ueber der Kanone.
@export var schwarm_unten: float = 250.0
@export var schwarm_oben: float = 600.0
# Um wie viel schneller der Schwarm flieht, als er sonst fliegt. 3 heisst: dreimal so schnell.
@export var flucht_faktor: float = 3.0
# Wie weit links oder rechts von der Kanone die Mitte einer neuen Fliege hoechstens liegt, in Pixeln.
@export var breite: float = 400.0

# Wie weit links und rechts von der Kanone eine Fliege noch mitzaehlt, in Pixeln.
@export var naehe: float = 1000.0
# Wie weit links oder rechts von der Kanone eine hereinfliegende Fliege startet, in Pixeln.
# Der Bildrand liegt in der Luft 720 neben der Kanone. Dazu die halbe Fliege (50).
# Muss groesser sein als breite + strecke der Fliege (400 + 300), sonst fliegt sie nicht herein.
@export var einflug_x: float = 900.0
# In welcher Hoehe ueber der Kanone eine hereinfliegende Fliege fliegt, hoechstens und mindestens, in Pixeln.
# Liegt zwischen flucht_unten und flucht_oben, damit sie nicht gleich flieht.
@export var einflug_oben: float = 750.0
@export var einflug_unten: float = 560.0
# Zwischen diesen Hoehen ueber der Kanone bleibt eine Fliege ruhig, in Pixeln. Gemessen wird ihre Grundhoehe, nicht das Wippen.
# Darunter (untere Bildhaelfte) und darueber (oberes Viertel, dort haengt der Faecher) flieht sie zum naeheren Rand.
# Der obere Bildrand liegt in der Luft 1060 ueber der Kanone: Haelfte 520, Viertel 790.
@export var flucht_unten: float = 520.0
@export var flucht_oben: float = 790.0
# Ab wie weit weg eine freie Fliege geloescht wird: seitlich, unter und ueber der Kanone, in Pixeln.
# Seitlich mehr als der Bildrand der Totale (1675), sonst verschwindet der fliehende Schwarm sichtbar.
@export var loeschen_seitlich: float = 1800.0
@export var loeschen_unten: float = 300.0
@export var loeschen_oben: float = 1400.0

# true heisst: Am Boden schwirrt noch der Schwarm vom Anfang, es fliegt nichts nach.
var schwarm: bool = true
# Die Zone, in der man zuletzt war. Daran merkt der Erzeuger, dass man eine neue betritt.
var letzte_zone: Node = null


func _ready() -> void:
	letzte_zone = zonen.get_child(0)
	for szene in schwarm_szenen:
		for nummer in randi_range(1, 2):
			var fliege: Node2D = szene.instantiate()
			fliege.kanone = kanone
			fliege.position.x = kanone.position.x + randf_range(-schwarm_breite, schwarm_breite)
			fliege.position.y = kanone.position.y - randf_range(schwarm_unten, schwarm_oben)
			fliege.mitte_x = fliege.position.x
			add_child(fliege)


func _process(_delta: float) -> void:
	aufraeumen()
	if schwarm:
		if get_child_count() == 0:
			schwarm = false
		return
	fliehen_lassen()
	if kanone.steigt:
		return
	var zone: Node = zonen.aktuelle()
	if zone != letzte_zone:
		if zone.ab_flugkraft > letzte_zone.ab_flugkraft:
			for szene in zone.einmalig:
				hereinfliegen(szene)
		fremde_fliehen_lassen(zone)
		letzte_zone = zone
	if freie_in_der_naehe() < zone.mindestens:
		hereinfliegen(zone.fliegen.pick_random())


# Wird beim ersten Treffer aufgerufen (start_totale.gd): Der Schwarm flieht von der Kanone weg, jede Fliege in ihre eigene Richtung.
func schwarm_aufloesen() -> void:
	if not schwarm:
		return
	schwarm = false
	for fliege in get_children():
		fliege.flucht = kanone.position.direction_to(fliege.position)
		fliege.tempo *= flucht_faktor


func hereinfliegen(szene: PackedScene) -> void:
	var seite: float = 1.0
	if randf() < 0.5:
		seite = -1.0
	var fliege: Node2D = szene.instantiate()
	fliege.kanone = kanone
	fliege.position.x = kanone.position.x + seite * einflug_x
	fliege.position.y = kanone.position.y - randf_range(einflug_unten, einflug_oben)
	fliege.mitte_x = kanone.position.x + randf_range(-breite, breite)
	add_child(fliege)


func fliehen_lassen() -> void:
	for fliege in get_children():
		if fliege.flucht != Vector2.ZERO or not fliege.flieht:
			continue
		var ueber: float = kanone.position.y - fliege.grund_y
		if ueber < flucht_unten or ueber > flucht_oben:
			if fliege.position.x < kanone.position.x:
				fliege.flucht = Vector2.LEFT
			else:
				fliege.flucht = Vector2.RIGHT


# Beim Wechsel in eine neue Zone: Jede freie Fliege, die nicht zu dieser Zone gehoert, fliegt zum naeheren Rand davon.
# Zur Zone gehoert sie, wenn ihre Szene in der Liste fliegen oder einmalig der Zone steht.
func fremde_fliehen_lassen(zone: Node) -> void:
	for fliege in get_children():
		if fliege.flucht != Vector2.ZERO or not fliege.flieht:
			continue
		var gehoert_dazu: bool = false
		for szene in zone.fliegen + zone.einmalig:
			if szene.resource_path == fliege.scene_file_path:
				gehoert_dazu = true
		if not gehoert_dazu:
			if fliege.position.x < kanone.position.x:
				fliege.flucht = Vector2.LEFT
			else:
				fliege.flucht = Vector2.RIGHT


func freie_in_der_naehe() -> int:
	var anzahl: int = 0
	for fliege in get_children():
		var seitlich: float = absf(fliege.position.x - kanone.position.x)
		if fliege.flucht == Vector2.ZERO and seitlich <= naehe:
			anzahl += 1
	return anzahl


func aufraeumen() -> void:
	for fliege in get_children():
		var zu_tief: bool = fliege.position.y > kanone.position.y + loeschen_unten
		var zu_hoch: bool = fliege.position.y < kanone.position.y - loeschen_oben
		var zu_weit: bool = absf(fliege.position.x - kanone.position.x) > loeschen_seitlich
		if zu_tief or zu_hoch or zu_weit:
			fliege.queue_free()
