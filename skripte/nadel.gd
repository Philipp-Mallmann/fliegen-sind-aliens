extends Node2D

# Wird gesendet, sobald die Nadel in ihrer letzten Fliege stecken bleibt. Mit dabei: die Nadel selbst.
signal getroffen(nadel: Node2D)

# Wie schnell die Nadel fliegt, in Pixeln pro Sekunde.
@export var tempo: float = 3200.0
# Wie weit die Nadel hoechstens auf einmal vorrueckt, bevor sie wieder auf Treffer prueft, in Pixeln.
# Kleiner als die kleinste Fliege, damit sie keine ueberspringt.
@export var schritt_weite: float = 40.0
# Wie weit die Nadel fliegt, bevor sie verschwindet, in Pixeln. 2160 ist zweimal die Bildhoehe.
@export var reichweite: float = 2160.0
# Die Szene des Blutflecks. Bei jedem Treffer entsteht daraus ein neuer Fleck.
@export var blutfleck_szene: PackedScene
# Die Szene eines kurzen Drahtstuecks, das vor der unteren Haelfte einer Fliege liegt (siehe vorn_spannen).
@export var draht_vorn_szene: PackedScene
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
@export var steck_tiefe: float = -0.15
# Wie weit das kurze Drahtstueck vor der Fliege ueber ihren Rand hinausreicht, in Pixeln. Verhindert eine Luecke am Rand.
@export var rand_zugabe: float = 6.0

# Wie viele Pixel die Nadel schon geflogen ist.
var geflogen: float = 0.0
# true heisst: Die Nadel steckt in ihrer letzten Fliege und fliegt nicht mehr.
var steckt: bool = false
# Die Fliegen, die an der Nadel stecken, in der Reihenfolge, in der sie getroffen wurden.
var aufgespiesste: Array[Node2D] = []
# Die halbe Breite (x) und halbe Hoehe (y) jeder aufgespiessten Fliege, in Pixeln, in derselben Reihenfolge wie aufgespiesste.
var halbe_groessen: Array[Vector2] = []
# Die kurzen Drahtstuecke vor den aelteren Fliegen, eines je Fliege.
var vorn_stuecke: Array[Line2D] = []
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
	# Die Strecke dieses Bildes in kleinen Schritten: Dauert ein Bild einmal laenger (ein Ruckler),
	# wuerde die Nadel sonst in einem Satz ueber eine Fliege springen, ohne sie zu treffen.
	var strecke: float = tempo * delta
	var schritte: int = maxi(1, ceili(strecke / schritt_weite))
	for schritt in schritte:
		position += richtung * strecke / schritte
		geflogen += strecke / schritte
		if fliegen_pruefen():
			break
	faden_spannen()


# Prueft nach einem Schritt, ob die Nadel eine Fliege trifft, und ob sie stehen bleibt oder verschwindet.
# true heisst: Die Nadel fliegt nicht weiter, die restlichen Schritte dieses Bildes entfallen.
func fliegen_pruefen() -> bool:
	var getroffene: Node2D = fliege_an_der_spitze()
	if getroffene != null:
		if getroffene.leben > 1:
			stecken_in(getroffene)
			return true
		aufspiessen(getroffene)
	if not aufgespiesste.is_empty():
		if geflogen >= reichweite or kanone == null or not noch_eine_darueber():
			stecken_bleiben()
			return true
	elif geflogen >= reichweite:
		queue_free()
		return true
	return false


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
	var halbe_groesse: Vector2 = bild.texture.get_size() * (bild.scale * getroffene.scale).abs() / 2.0
	halb_zeigen(halbe_groesse.y * steck_tiefe)
	aufgespiesste.append(getroffene)
	halbe_groessen.append(halbe_groesse)
	getroffene.gefangen = true
	if getroffene.leben_voll > 1:
		# Der letzte Treffer auf den Boss: "3/3".
		get_tree().call_group("punktanzeige", "boss_treffer", global_position, getroffene.leben_voll, getroffene.leben_voll)
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
	# Zeigt "1/3", "2/3" und laesst das Bild wackeln (punktanzeige.gd).
	get_tree().call_group("punktanzeige", "boss_treffer", global_position, grosse.leben_voll - grosse.leben, grosse.leben_voll)
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
	for stueck in vorn_stuecke:
		stueck.clear_points()


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
		var bis_zum_rand: float = rand_abstand(halbe_groessen[nummer] * global_scale.abs(), oben.direction_to(unten))
		vorn_spannen(nummer, oben, unten, bogen, anteil, (bis_zum_rand + rand_zugabe) / laenge)


# Wie weit es von der Fliegenmitte in Richtung des Drahts bis zu ihrem Rand ist, in Pixeln.
# Die Fliege wird dafuer als Ellipse gerechnet: halbe Breite und halbe Hoehe. Laeuft der Draht senkrecht,
# ist es die halbe Hoehe, laeuft er waagerecht, die halbe Breite, dazwischen etwas dazwischen.
func rand_abstand(halb: Vector2, richtung: Vector2) -> float:
	var x: float = richtung.x / maxf(halb.x, 1.0)
	var y: float = richtung.y / maxf(halb.y, 1.0)
	return 1.0 / maxf(sqrt(x * x + y * y), 0.001)


# Der Draht laeuft durch jede aeltere Fliege hindurch. Der ganze Draht (Faden) liegt hinter den Fliegen.
# Vor der unteren Haelfte einer Fliege liegt zusaetzlich ein kurzes Stueck: von ihrer Mitte, wo das Blut ist,
# bis zu ihrem unteren Rand. So sieht es aus, als ginge der Draht unten in die Fliege hinein und oben wieder heraus.
# anfang: wo die Fliegenmitte auf dem Draht liegt (0 bis 1). stueck_anteil: ihre halbe Hoehe als Anteil der Drahtlaenge.
func vorn_spannen(nummer: int, oben: Vector2, unten: Vector2, bogen: Vector2, anfang: float, stueck_anteil: float) -> void:
	while vorn_stuecke.size() <= nummer:
		var neues: Line2D = draht_vorn_szene.instantiate()
		add_child(neues)
		vorn_stuecke.append(neues)
	var stueck: Line2D = vorn_stuecke[nummer]
	var punkte: PackedVector2Array = []
	for schritt in 5:
		var anteil: float = minf(anfang + stueck_anteil * schritt / 4.0, 1.0)
		punkte.append(stueck.to_local(faden_punkt(oben, unten, bogen, anteil)))
	stueck.points = punkte


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
