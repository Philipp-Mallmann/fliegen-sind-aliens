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
# Das Seilende, das unter der Hand haengt, nachdem es sich vom Lauf geloest hat. Es faellt wie ein Seil aus kurzen Gliedern.
# Wie stark die Schwerkraft daran zieht (Pixel pro Sekunde im Quadrat), wie viel Schwung es von Bild zu Bild behaelt
# (1 heisst: alles, kleiner heisst: es beruhigt sich schneller) und aus wie vielen Gliedern es besteht.
@export var rest_schwerkraft: float = 2600.0
@export var rest_daempfung: float = 0.97
@export var rest_glieder: int = 10
# In so kleinen Zeitschritten wird das Seilende gerechnet, in Sekunden. Immer gleich, egal wie schnell das Spiel gerade laeuft.
@export var rest_takt: float = 0.0166
# Wie schnell der Draht nach dem Loslassen aus seinem Bogen in den normalen Durchhang zurueckfindet. Groesser heisst schneller.
@export var bogen_tempo: float = 8.0

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
# false heisst: Der Draht ist gerade ausgeblendet (beim Absturz, wenn er an der Kanone haengt, siehe draht_zeigen).
var draht_sichtbar: bool = true
# Der Punkt, an dem der Faden der Nadel festhaengt: erst die Muendung der Kanone, im Faecher die rechte Hand.
var anker: Node2D = null
# Die Hand, zu der der Schwung der Kanone den Draht hinueberdrueckt, und wie weit er schon dort ist:
# 0 heisst: Der Draht haengt normal durch. 1 heisst: Er laeuft in einem Bogen genau durch die Hand. null heisst: kein Schwung.
var schwung_punkt: Node2D = null
var schwung: float = 0.0
# Ein zusaetzlicher Bogen im Draht, der von selbst wieder verschwindet (nach dem Loslassen, siehe rest_abwerfen).
var bogen_extra: Vector2 = Vector2.ZERO
# Das Seilende unter der Hand: die Punkte seiner Glieder, gemessen von der Hand aus, dieselben Punkte im Bild davor
# (aus dem Unterschied ergibt sich der Schwung), und wie lang jedes Glied ist. Leer heisst: Es gibt kein Seilende.
var rest_punkte: PackedVector2Array = []
var rest_vorher: PackedVector2Array = []
var rest_laengen: PackedFloat32Array = []
# true heisst: Das Seilende haengt still und wird nicht mehr gerechnet.
var rest_ruht: bool = true
# Wie viel Zeit noch nicht gerechnet ist, und wie lange sich das Seil schon kaum bewegt, beides in Sekunden.
var rest_uhr: float = 0.0
var rest_stille: float = 0.0
# Die Kanone, die die Nadel geschossen hat. Solange die Nadel fliegt, bleibt sie genau ueber ihr. Setzt kanone.gd.
# null heisst: Die Nadel kommt aus der Totale (start_totale.gd) und fliegt frei in ihre Richtung.
var kanone: Node2D = null
# In diese Richtung fliegt die Nadel. Im Spiel immer nach oben, in der Totale dorthin, wohin der Arm zeigt.
var richtung: Vector2 = Vector2.UP
# true heisst: Die Nadel haengt mit ihren Fliegen fertig im Faecher. Erst dann kann ein Hindernis sie treffen.
var haengt: bool = false


func _process(delta: float) -> void:
	if steckt:
		# Der zusaetzliche Bogen wird in jedem Bild ein Stueck kleiner, bis er weg ist.
		bogen_extra = bogen_extra.lerp(Vector2.ZERO, minf(bogen_tempo * delta, 1.0))
		if not rest_ruht:
			rest_fallen(delta)
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
	# Die Teleport-Fliege kann gerade noch halb im Glitch stecken (beim Auftauchen). Gefangen ist sie wieder ganz da.
	if getroffene.has_method("glitchen"):
		getroffene.glitchen(0.0)
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
	schwung_punkt = null
	rest_punkte.clear()
	rest_ruht = true
	$Faden.clear_points()
	$Rest.clear_points()
	for stueck in vorn_stuecke:
		stueck.clear_points()


# Blendet den ganzen Draht aus oder wieder ein: den Faden, das Seilende und die kurzen Stuecke vor den Fliegen.
# Gerechnet wird er weiter, er wird nur nicht gezeichnet. Die Nadel und ihre Fliegen bleiben zu sehen.
func draht_zeigen(sichtbar: bool) -> void:
	draht_sichtbar = sichtbar
	$Faden.visible = sichtbar
	$Rest.visible = sichtbar
	for stueck in vorn_stuecke:
		stueck.visible = sichtbar


# Der Bogen des Drahts in diesem Bild: der normale Durchhang, dazu der zusaetzliche Bogen.
# Drueckt der Schwung der Kanone den Draht zur Hand, wandert der Bogen dorthin: Bei schwung 1 ist er genau so gross,
# dass die Mitte des Drahts in der Hand liegt (Hand minus Mitte der geraden Linie).
func bogen_jetzt(oben: Vector2, unten: Vector2) -> Vector2:
	var bogen: Vector2 = durchbiegung(oben, unten) + bogen_extra
	if schwung_punkt != null:
		bogen = bogen.lerp(schwung_punkt.global_position - (oben + unten) / 2.0, schwung)
	return bogen


# Der Draht sitzt fest in der Hand und loest sich vom Lauf. Bis jetzt lief er in einem Bogen von der Fliege durch die Hand
# zur Kanone. Die obere Haelfte bleibt der Draht zur Fliege, die untere Haelfte wird zum Seilende, das unter der Hand faellt.
func rest_abwerfen(hand: Node2D) -> void:
	var oben: Vector2 = $Oese.global_position
	var unten: Vector2 = anker.global_position
	var bogen: Vector2 = bogen_jetzt(oben, unten)
	var mitte: Vector2 = faden_punkt(oben, unten, bogen, 0.5)
	# Die untere Haelfte des Drahts wird zum Seilende. Zuerst wird sie fein abgetastet (40 kurze Stuecke) und ihre Laenge gemessen.
	var fein: PackedVector2Array = []
	var laenge: float = 0.0
	for nummer in 41:
		fein.append(faden_punkt(oben, unten, bogen, 0.5 + 0.5 * nummer / 40.0) - mitte)
		if nummer > 0:
			laenge += fein[nummer].distance_to(fein[nummer - 1])
	# Dann werden die Glieder darauf verteilt, alle gleich lang: Immer wenn ein Glied voll ist, kommt der naechste Punkt.
	var glied: float = laenge / rest_glieder
	rest_punkte.clear()
	rest_vorher.clear()
	rest_laengen.clear()
	rest_punkte.append(Vector2.ZERO)
	rest_laengen.append(0.0)
	var gelaufen: float = 0.0
	for nummer in range(1, 41):
		gelaufen += fein[nummer].distance_to(fein[nummer - 1])
		if gelaufen >= glied * rest_punkte.size() or nummer == 40:
			rest_punkte.append(fein[nummer])
			rest_laengen.append(glied)
	# Eine eigene Kopie: Sonst waeren beide Listen dieselbe, und das Seil haette keinen Schwung.
	rest_vorher = rest_punkte.duplicate()
	rest_ruht = false
	rest_uhr = 0.0
	rest_stille = 0.0
	# Der Draht zur Fliege endet jetzt in der Hand. Damit er nicht springt, bekommt er den Bogen mit, den seine Haelfte gerade hatte
	# (ihr mittlerer Punkt minus die Mitte der neuen geraden Linie). bogen_extra ist der Teil davon, der wieder verschwindet.
	var viertel: Vector2 = faden_punkt(oben, unten, bogen, 0.25)
	anker = hand
	schwung_punkt = null
	schwung = 0.0
	bogen_extra = viertel - (oben + mitte) / 2.0 - durchbiegung(oben, mitte)
	# Gleich neu spannen, damit Draht und Seilende schon in diesem Bild an der Hand sitzen.
	faden_spannen()


# Laesst das Seilende weiter fallen. Gerechnet wird in gleich grossen Zeitschritten (rest_takt): Dauert ein Bild laenger,
# gibt es mehrere Schritte, dauert es kuerzer, manchmal keinen. So faellt das Seil auf jedem Geraet gleich.
func rest_fallen(delta: float) -> void:
	rest_uhr += minf(delta, 0.1)
	while rest_uhr >= rest_takt:
		rest_uhr -= rest_takt
		rest_schritt()


# Ein Zeitschritt des Seilendes. Jedes Glied bewegt sich so weiter wie im Schritt davor (Schwung) und wird von der
# Schwerkraft nach unten gezogen. Danach werden die Glieder wieder auf ihre Laenge gebracht, das oberste haengt an der Hand.
func rest_schritt() -> void:
	var punkte: PackedVector2Array = rest_punkte
	var vorher: PackedVector2Array = rest_vorher
	var schnellstes: float = 0.0
	for nummer in range(1, punkte.size()):
		var schritt: Vector2 = (punkte[nummer] - vorher[nummer]) * rest_daempfung
		vorher[nummer] = punkte[nummer]
		punkte[nummer] = punkte[nummer] + schritt + Vector2.DOWN * rest_schwerkraft * rest_takt * rest_takt
		schnellstes = maxf(schnellstes, schritt.length())
	# Achtmal nacheinander, damit sich die Korrekturen durch das ganze Seil fortsetzen und es sich nicht dehnt.
	for runde in 8:
		for nummer in range(1, punkte.size()):
			var stueck: Vector2 = punkte[nummer] - punkte[nummer - 1]
			var zu_viel: Vector2 = stueck.normalized() * (stueck.length() - rest_laengen[nummer])
			if nummer == 1:
				# Das oberste Glied haengt an der Hand, nur sein unteres Ende gibt nach.
				punkte[nummer] = punkte[nummer] - zu_viel
			else:
				punkte[nummer - 1] = punkte[nummer - 1] + zu_viel / 2.0
				punkte[nummer] = punkte[nummer] - zu_viel / 2.0
	rest_punkte = punkte
	rest_vorher = vorher
	# Bewegt sich eine halbe Sekunde lang fast nichts mehr, haengt das Seil still und wird nicht weiter gerechnet.
	if schnellstes < 0.05:
		rest_stille += rest_takt
	else:
		rest_stille = 0.0
	if rest_stille > 0.5:
		rest_ruht = true


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
	# Das Seilende haengt an der Hand (dem Anker): Jedes Glied steht an seinem Platz von der Hand aus.
	if rest_punkte.size() > 0:
		var glieder: PackedVector2Array = []
		for versatz in rest_punkte:
			glieder.append($Rest.to_local(unten + versatz))
		$Rest.points = glieder
	var bogen: Vector2 = bogen_jetzt(oben, unten)
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
		neues.visible = draht_sichtbar
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
