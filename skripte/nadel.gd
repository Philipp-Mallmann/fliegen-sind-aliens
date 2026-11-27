extends Node2D

# Wird gesendet, sobald die Nadel in ihrer letzten Fliege stecken bleibt. Mit dabei: die Nadel selbst.
signal getroffen(nadel: Node2D)

# Wie schnell die Nadel fliegt, in Pixeln pro Sekunde.
@export var tempo: float = 3200.0
# Wie weit die Nadel fliegt, bevor sie verschwindet, in Pixeln. 2160 ist zweimal die Bildhoehe.
@export var reichweite: float = 2160.0
# Die Szene des Blutflecks. Bei jedem Treffer entsteht daraus ein neuer Fleck.
@export var blutfleck_szene: PackedScene
# Um wie viel die Trefferflaeche einer Fliege groesser ist als die Fliege selbst. 1.125 heisst: ein Achtel groesser.
@export var trefferzugabe: float = 1.125
# Wie weit die aufgespiessten Fliegen am Faden hintereinander haengen, in Pixeln. Die Fliege ist 100 gross.
@export var spiess_abstand: float = 110.0
# Wie weit der Draht in der Mitte durchhaengt, als Anteil seiner Laenge: im Flug und wenn er im Faecher an der Hand haengt.
# Er haengt nur quer zur Schwerkraft durch: Ist er senkrecht gespannt, bleibt er gerade.
@export var durchhang_flug: float = 0.02
@export var durchhang_haengend: float = 0.06
# Aus wie vielen Stuecken die Drahtlinie besteht. Mehr Stuecke heisst: rundere Kurve.
@export var draht_stuecke: int = 16
# Wo am halben Nagel der Draht den Kopf verlaesst, gemessen ab der Schnittkante, in Pixeln.
@export var oese_halb: Vector2 = Vector2(7.2, 45.6)
# Wie tief die Schnittkante des halben Nagels in der Fliege sitzt, als Anteil ihrer halben Hoehe. 0 ist die Fliegenmitte.
@export var steck_tiefe: float = 0.0

# Wie viele Pixel die Nadel schon geflogen ist.
var geflogen: float = 0.0
# true heisst: Die Nadel steckt in ihrer letzten Fliege und fliegt nicht mehr.
var steckt: bool = false
# Die Fliegen, die an der Nadel stecken, in der Reihenfolge, in der sie getroffen wurden.
var aufgespiesste: Array[Node2D] = []
# Der Punkt, an dem der Faden der Nadel festhaengt: erst die Muendung der Kanone, im Faecher die rechte Hand.
var anker: Node2D = null
# Die Kanone, die die Nadel geschossen hat. Solange die Nadel fliegt, bleibt sie genau ueber ihr. Setzt kanone.gd.
# null heisst: Die Nadel kommt aus der Totale (start_totale.gd) und fliegt frei in ihre Richtung.
var kanone: Node2D = null
# In diese Richtung fliegt die Nadel. Im Spiel immer nach oben, in der Totale dorthin, wohin der Arm zeigt.
var richtung: Vector2 = Vector2.UP
# true heisst: Die Nadel haengt mit ihren Fliegen fertig im Faecher. Erst dann kann ein Hindernis sie treffen.
var haengt: bool = false


func _process(delta: float) -> void:
	if steckt:
		faden_spannen()
		return
	if kanone != null:
		position.x = kanone.position.x
	position += richtung * tempo * delta
	geflogen += tempo * delta
	var getroffene: Node2D = fliege_an_der_spitze()
	if getroffene != null:
		if getroffene.leben > 1:
			stecken_in(getroffene)
			return
		aufspiessen(getroffene)
	if not aufgespiesste.is_empty():
		if geflogen >= reichweite or kanone == null or not noch_eine_darueber():
			stecken_bleiben()
	elif geflogen >= reichweite:
		queue_free()
	faden_spannen()


func trifft(kandidat: Node2D, nur_darueber: bool) -> bool:
	if kandidat.gefangen or kandidat.entkommt:
		return false
	if kandidat.leben > 1 and not aufgespiesste.is_empty():
		return false
	var halb: float = kandidat.halbe_groesse * trefferzugabe
	var seitlich: float = absf(kandidat.global_position.x - global_position.x)
	if seitlich > halb:
		return false
	if nur_darueber:
		return kandidat.global_position.y < global_position.y and kandidat.global_position.y > bildrand_oben()
	return absf(kandidat.global_position.y - global_position.y) <= halb


func fliege_an_der_spitze() -> Node2D:
	for kandidat in get_tree().get_nodes_in_group("fliegen"):
		if trifft(kandidat, false):
			return kandidat
	return null


func noch_eine_darueber() -> bool:
	for kandidat in get_tree().get_nodes_in_group("fliegen"):
		if trifft(kandidat, true):
			return true
	return false


func bildrand_oben() -> float:
	var kamera: Camera2D = get_viewport().get_camera_2d()
	return kamera.get_screen_center_position().y - 540.0 / kamera.zoom.y


func aufspiessen(getroffene: Node2D) -> void:
	var bild: Sprite2D = getroffene.get_node("Bild")
	var halbe_hoehe: float = bild.texture.get_size().y * absf(bild.scale.y * getroffene.scale.y) / 2.0
	halb_zeigen(halbe_hoehe * steck_tiefe)
	aufgespiesste.append(getroffene)
	getroffene.gefangen = true
	getroffene.get_node("Summen").stop()
	$TonTreffer.play()
	getroffene.reparent(self)
	getroffene.position = Vector2.ZERO
	getroffene.rotation = 0.0
	getroffene.modulate.a = 1.0
	for alte in getroffene.steckende:
		alte.faden_loesen()
	# Blut an der Einstichstelle: ein Kind der Fliege, also ueber ihr, aber unter dem Nagel. In ihrer Zonenfarbe.
	var fleck: Node2D = blutfleck_szene.instantiate()
	fleck.modulate = getroffene.blut_farbe
	getroffene.add_child(fleck)


# Die Fliege braucht noch mehr Treffer (Boss): Die Nadel bleibt in ihr stecken und fliegt mit ihr mit. Gefangen ist sie noch nicht.
func stecken_in(grosse: Node2D) -> void:
	steckt = true
	halb_zeigen(0.0)
	grosse.leben -= 1
	grosse.steckende.append(self)
	grosse.angeschossen()
	$TonTreffer.play()
	var fleck: Node2D = blutfleck_szene.instantiate()
	fleck.modulate = grosse.blut_farbe
	grosse.add_child(fleck)
	fleck.global_position = global_position
	reparent(grosse)


# Der Faden geht ab: Er haengt nirgends mehr fest und wird nicht mehr gezeichnet.
func faden_loesen() -> void:
	anker = null
	$Faden.clear_points()


func stecken_bleiben() -> void:
	steckt = true
	getroffen.emit(self)


func flugkraft() -> int:
	var summe: int = 0
	for fliege in aufgespiesste:
		summe += fliege.flugkraft
	return summe


# Sobald die Nadel in einer Fliege steckt, sieht man nur noch die hintere Haelfte des Nagels:
# Die Spitze steckt in der Fliege, der Kopf mit dem Draht schaut unten heraus.
# Bei jedem neuen Treffer steckt sie in der neuen Fliege, darum wird jedes Mal neu gesetzt.
# tiefe: wie weit unter der Nadelspitze die Schnittkante des halben Nagels sitzt, in Pixeln.
func halb_zeigen(tiefe: float) -> void:
	$Nagel.visible = false
	$NagelHalb.visible = true
	$NagelHalb.position.y = tiefe
	$Oese.position = Vector2(oese_halb.x, tiefe + oese_halb.y)


func faden_spannen() -> void:
	if anker == null:
		return
	var oben: Vector2 = $Oese.global_position
	var unten: Vector2 = anker.global_position
	var bogen: Vector2 = durchbiegung(oben, unten)
	var punkte: PackedVector2Array = []
	for nummer in draht_stuecke + 1:
		punkte.append($Faden.to_local(faden_punkt(oben, unten, bogen, float(nummer) / draht_stuecke)))
	# Der Draht ist ein Kind der Nadel, seine Punkte stehen darum in ihren Koordinaten (to_local).
	# So bewegt er sich mit der Nadel mit und bleibt am Nagelkopf, auch waehrend sie faehrt.
	# Godot zeichnet eine Linie erst im naechsten Bild neu, wenn sich ihre Punkte aendern;
	# frei im Raum haette der Draht dabei ein Bild hinterhergehangen, mit einer Luecke am Nagel.
	$Faden.points = punkte
	var laenge: float = maxf(oben.distance_to(unten), 1.0)
	var anzahl: int = aufgespiesste.size()
	for nummer in anzahl - 1:
		var fliege: Node2D = aufgespiesste[nummer]
		var schritte: int = anzahl - 1 - nummer
		var anteil: float = minf(spiess_abstand * global_scale.x * schritte / laenge, 1.0)
		fliege.global_position = faden_punkt(oben, unten, bogen, anteil)


# Wie weit und wohin der Draht in der Mitte durchhaengt. Die Schwerkraft zieht nach unten,
# aber nur der Teil, der quer zum Draht zieht, biegt ihn: Ein senkrechter Draht bleibt gerade.
func durchbiegung(oben: Vector2, unten: Vector2) -> Vector2:
	var richtung: Vector2 = oben.direction_to(unten)
	var quer: Vector2 = Vector2.DOWN - richtung * Vector2.DOWN.dot(richtung)
	var anteil: float = durchhang_flug
	if haengt:
		anteil = durchhang_haengend
	return quer * oben.distance_to(unten) * anteil


# Ein Punkt auf dem Draht. anteil 0 ist oben an der Nadel, 1 unten am Anker.
# Auf der geraden Linie dazwischen, plus der Bogen: in der Mitte am staerksten, an den Enden gar nicht.
func faden_punkt(oben: Vector2, unten: Vector2, bogen: Vector2, anteil: float) -> Vector2:
	return oben.lerp(unten, anteil) + bogen * 4.0 * anteil * (1.0 - anteil)
