extends Node2D

# Wie lange die Warnung laeuft, bevor der Gegenstand faellt, in Sekunden.
@export var warnzeit: float = 3.0
# Die Steine, die fallen koennen. Bei jedem Hindernis wird einer ausgewuerfelt.
@export var steine: Array[Texture2D] = []
# Wie schnell der Gegenstand faellt, in Pixeln pro Sekunde. Stuerzt die Kanone gerade ab, kommt ihr Tempo dazu (siehe fallen):
# Sonst wuerde der Faecher den Stein von oben einholen.
@export var falltempo: float = 1500.0
# Wie lange ein Blinken der Warnung dauert, am Anfang und am Ende, in Sekunden. Kleiner heisst schneller.
@export var blinken_anfang: float = 1.0
@export var blinken_ende: float = 0.1
# Wie weit ueber der Kanone der obere Bildrand liegt, in Pixeln. In der Luft 1060, am Boden etwas mehr (herausgezoomt).
@export var bildrand: float = 1060.0
# Wie gross das Warnschild am Anfang und am Ende der Warnung ist. 1 ist die Groesse aus der Szene.
@export var groesse_anfang: float = 0.25
@export var groesse_ende: float = 1.5
# Wie kraeftig die Spalte (der Schatten unter dem fallenden Stein) am Anfang der Warnung zu sehen ist. 1 heisst: voll, wie am Ende.
@export var spalte_anfang: float = 0.3
# Wie laut der Warnton am Anfang und am Ende der Warnung piept, in Dezibel. 0 ist die Lautstaerke der Datei.
@export var ton_leise: float = -30.0
@export var ton_laut: float = -20.0
# Wie weit unter der Kanone der Gegenstand verschwindet, in Pixeln. Der untere Bildrand liegt hoechstens 190 darunter.
@export var weg_unter: float = 300.0
# Die Szene des Matsches. Bei jeder zermatschten Fliege entsteht daraus ein Fleck.
@export var matsch_szene: PackedScene
# Die Farbe der Spalte auf jeder Pappe, von unten (blau) nach oben (fast schwarz). Die vierte Zahl ist die Deckkraft.
# Auf den hellen Pappen ein Schatten (Schwarz, 50 Prozent), ab Indigo das Gelb des Warnschilds (20 Prozent),
# weil man dort einen Schatten nicht saehe.
# Die Farbe des blinkenden Umrisses an den Fliegen unter dem Stein, je Pappe: Gelb wie das Schild,
# wo der Schatten gelb ist aber Schwarz, damit er sich abhebt.
@export var gefahr_farben: Array[Color] = [
	Color(0.92, 0.73, 0.17), Color(0.92, 0.73, 0.17), Color(0.92, 0.73, 0.17), Color(0.92, 0.73, 0.17),
	Color(0.92, 0.73, 0.17), Color(0, 0, 0), Color(0, 0, 0), Color(0, 0, 0),
]
# Ein duenner Rand um die Striche, je Pappe. Durchsichtig (vierte Zahl 0) heisst: kein Rand.
# Auf den dunklen Pappen Orange, sonst saehe man die schwarzen Striche kaum.
@export var gefahr_rand_farben: Array[Color] = [
	Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0),
	Color(0, 0, 0, 0), Color(1.0, 0.55, 0.1), Color(1.0, 0.55, 0.1), Color(1.0, 0.55, 0.1),
]
@export var spalte_farben: Array[Color] = [
	Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.5),
	Color(0, 0, 0, 0.5), Color(0.92, 0.73, 0.17, 0.2), Color(0.92, 0.73, 0.17, 0.2), Color(0.92, 0.73, 0.17, 0.2),
]

# Die Kanone. Die Warnung bleibt ueber ihr am oberen Bildrand. Setzt der Hindernis-Erzeuger.
var kanone: Node2D = null
# Der Faecher. Aus ihm werden getroffene Fliegen entfernt. Setzt der Hindernis-Erzeuger.
var faecher: Node2D = null
# Der Hintergrund. Seine Nummer sagt, welche Pappe zu sehen ist. Setzt der Hindernis-Erzeuger.
var hintergrund: Node = null
# Wie viele Sekunden schon gewarnt wird.
var gewarnt: float = 0.0
# Wie breit und wie hoch der fallende Stein ist, in Pixeln. Kommt aus der Groesse seines Bilds.
# So breit ist auch die Spalte: Jede Fliege darin wird zermatscht.
var breite: float = 200.0
var hoehe: float = 120.0
# Die laengste Warnzeit, die vorkommt. Daran haengt das Aussehen: Gleiche Restzeit heisst gleiches Schild. Setzt der Hindernis-Erzeuger.
var volle_warnzeit: float = 9.0
# Wo die Kanone im letzten Bild war (Hoehe). Daran sieht der Stein, ob und wie schnell sie gerade abstuerzt.
var kanone_vorher: float = 0.0


func _ready() -> void:
	$Klotz.texture = steine.pick_random()
	breite = $Klotz.texture.get_width()
	hoehe = $Klotz.texture.get_height()
	$Klotz.position.y = -hoehe / 2.0
	$Spalte.offset_left = -breite / 2.0
	$Spalte.offset_right = breite / 2.0


func _process(delta: float) -> void:
	if gewarnt < warnzeit:
		warnen(delta)
	else:
		fallen(delta)


func warnen(delta: float) -> void:
	gewarnt += delta
	position.y = kanone.position.y - bildrand
	kanone_vorher = kanone.position.y
	var rest: float = warnzeit - gewarnt
	var anteil: float = clampf(1.0 - rest / volle_warnzeit, 0.0, 1.0)
	$Warnung.scale = Vector2.ONE * lerpf(groesse_anfang, groesse_ende, anteil)
	$Spalte.color = spalte_farben[hintergrund.nummer]
	$Spalte.modulate.a = lerpf(spalte_anfang, 1.0, anteil)
	var takt: float = lerpf(blinken_anfang, blinken_ende, anteil)
	var an: bool = fmod(gewarnt, takt) < takt / 2.0
	if an and not $Warnung.visible and not $TonWarnung.playing:
		$TonWarnung.volume_db = lerpf(ton_leise, ton_laut, anteil)
		$TonWarnung.play()
	$Warnung.visible = an
	# Jede Fliege in der Spalte bekommt den blinkenden Umriss (fliege.gd, gefahr_zeigen). 0,1 Sekunden reichen:
	# Der Wert wird ja in jedem Bild neu gesetzt, solange gewarnt wird.
	for fliege in get_tree().get_nodes_in_group("fliegen"):
		if in_spalte(fliege):
			fliege.gefahr_noch = 0.1
			fliege.gefahr_farbe = gefahr_farben[hintergrund.nummer]
			fliege.gefahr_rand_farbe = gefahr_rand_farben[hintergrund.nummer]
	if gewarnt >= warnzeit:
		get_parent().get_node("TonKlotz").play()


func fallen(delta: float) -> void:
	$Warnung.visible = false
	$Spalte.visible = false
	# Sinkt die Kanone (Absturz), faellt der Stein um dasselbe Stueck mehr. So bleibt er immer schneller als der Faecher.
	var kanone_sinkt: float = maxf(kanone.position.y - kanone_vorher, 0.0)
	kanone_vorher = kanone.position.y
	position.y += falltempo * delta + kanone_sinkt
	for fliege in get_tree().get_nodes_in_group("fliegen"):
		if im_klotz(fliege):
			zermatschen(fliege)
	if position.y > kanone.position.y + weg_unter:
		queue_free()


# true heisst: Die Fliege ist in der Spalte unter dem Stein, der Stein trifft sie, wenn sie dort bleibt.
func in_spalte(fliege: Node2D) -> bool:
	var groesse: float = fliege.halbe_groesse * fliege.global_scale.x
	var seitlich: float = absf(fliege.global_position.x - global_position.x)
	return seitlich <= breite / 2.0 + groesse and fliege.global_position.y > global_position.y


func im_klotz(fliege: Node2D) -> bool:
	var groesse: float = fliege.halbe_groesse * fliege.global_scale.x
	var seitlich: float = absf(fliege.global_position.x - global_position.x)
	var senkrecht: float = absf(fliege.global_position.y - (global_position.y - hoehe / 2.0))
	return seitlich <= breite / 2.0 + groesse and senkrecht <= hoehe / 2.0 + groesse


func zermatschen(fliege: Node2D) -> void:
	# Alle Fliegen, die der Stein mitnimmt: eine freie Fliege allein, eine gefangene mit allen an ihrem Draht.
	var opfer: Array[Node2D] = []
	if fliege.gefangen:
		var nadel: Node2D = fliege.get_parent()
		if not nadel.haengt:
			return
		nadel.haengt = false
		faecher.entfernen(nadel)
		# Zeigt "-N" an der Stelle: Man sieht, dass der Stein die Fliegen trifft und das Hoehe kostet.
		get_tree().call_group("punktanzeige", "verloren", fliege.global_position, nadel.flugkraft())
		opfer.append_array(nadel.aufgespiesste)
		for gefangene in opfer:
			plattmachen(gefangene)
		nadel.queue_free()
	else:
		plattmachen(fliege)
	get_parent().get_node("TonMatsch").play()


# Von der Fliege bleibt nur ein Blutfleck in ihrer Farbe, unten am Stein. Er faellt mit dem Stein aus dem Bild.
# Die Fliege selbst verschwindet (aus der Gruppe sofort, geloescht am Ende des Bilds).
func plattmachen(fliege: Node2D) -> void:
	fliege.remove_from_group("fliegen")
	var matsch: Node2D = matsch_szene.instantiate()
	matsch.modulate = fliege.blut_farbe
	add_child(matsch)
	matsch.position = Vector2(to_local(fliege.global_position).x, 0.0)
	fliege.queue_free()
