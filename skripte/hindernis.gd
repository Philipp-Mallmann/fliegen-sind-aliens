extends Node2D

# Wie lange die Warnung laeuft, bevor der Gegenstand faellt, in Sekunden.
@export var warnzeit: float = 3.0
# Wie breit die Spalte ist, in Pixeln. Jede Fliege darin wird zermatscht.
@export var breite: float = 200.0
# Wie hoch der fallende Gegenstand ist, in Pixeln.
@export var hoehe: float = 120.0
# Wie schnell der Gegenstand faellt, in Pixeln pro Sekunde. Muss schneller sein als der Absturz (falltempo in spiel.gd).
@export var falltempo: float = 1800.0
# Wie lange ein Blinken der Warnung dauert, am Anfang und am Ende, in Sekunden. Kleiner heisst schneller.
@export var blinken_anfang: float = 1.0
@export var blinken_ende: float = 0.1
# Wie weit ueber der Kanone der obere Bildrand liegt, in Pixeln. In der Luft 1060, am Boden etwas mehr (herausgezoomt).
@export var bildrand: float = 1060.0
# Wie gross das Warnschild am Anfang und am Ende der Warnung ist. 1 ist die Groesse aus der Szene.
@export var groesse_anfang: float = 0.25
@export var groesse_ende: float = 1.5
# Wie kraeftig die gelbe Spalte am Anfang der Warnung zu sehen ist. 1 heisst: voll, wie am Ende.
@export var spalte_anfang: float = 0.3
# Wie laut der Warnton am Anfang und am Ende der Warnung piept, in Dezibel. 0 ist die Lautstaerke der Datei.
@export var ton_leise: float = -24.0
@export var ton_laut: float = -8.0
# Wie weit unter der Kanone der Gegenstand verschwindet, in Pixeln. Der untere Bildrand liegt hoechstens 190 darunter.
@export var weg_unter: float = 300.0
# Die Szene des Matsches. Bei jeder zermatschten Fliege entsteht daraus ein Fleck.
@export var matsch_szene: PackedScene

# Die Kanone. Die Warnung bleibt ueber ihr am oberen Bildrand. Setzt der Hindernis-Erzeuger.
var kanone: Node2D = null
# Der Faecher. Aus ihm werden getroffene Fliegen entfernt. Setzt der Hindernis-Erzeuger.
var faecher: Node2D = null
# Wie viele Sekunden schon gewarnt wird.
var gewarnt: float = 0.0
# Die laengste Warnzeit, die vorkommt. Daran haengt das Aussehen: Gleiche Restzeit heisst gleiches Schild. Setzt der Hindernis-Erzeuger.
var volle_warnzeit: float = 9.0


func _ready() -> void:
	$Spalte.offset_left = -breite / 2.0
	$Spalte.offset_right = breite / 2.0
	$Klotz.offset_left = -breite / 2.0
	$Klotz.offset_right = breite / 2.0
	$Klotz.offset_top = -hoehe


func _process(delta: float) -> void:
	if gewarnt < warnzeit:
		warnen(delta)
	else:
		fallen(delta)


func warnen(delta: float) -> void:
	gewarnt += delta
	position.y = kanone.position.y - bildrand
	var rest: float = warnzeit - gewarnt
	var anteil: float = clampf(1.0 - rest / volle_warnzeit, 0.0, 1.0)
	$Warnung.scale = Vector2.ONE * lerpf(groesse_anfang, groesse_ende, anteil)
	$Spalte.modulate.a = lerpf(spalte_anfang, 1.0, anteil)
	var takt: float = lerpf(blinken_anfang, blinken_ende, anteil)
	var an: bool = fmod(gewarnt, takt) < takt / 2.0
	if an and not $Warnung.visible and not $TonWarnung.playing:
		$TonWarnung.volume_db = lerpf(ton_leise, ton_laut, anteil)
		$TonWarnung.play()
	$Warnung.visible = an
	if gewarnt >= warnzeit:
		get_parent().get_node("TonKlotz").play()


func fallen(delta: float) -> void:
	$Warnung.visible = false
	$Spalte.visible = false
	position.y += falltempo * delta
	for fliege in get_tree().get_nodes_in_group("fliegen"):
		if im_klotz(fliege):
			zermatschen(fliege)
	if position.y > kanone.position.y + weg_unter:
		queue_free()


func im_klotz(fliege: Node2D) -> bool:
	var groesse: float = fliege.halbe_groesse * fliege.global_scale.x
	var seitlich: float = absf(fliege.global_position.x - global_position.x)
	var senkrecht: float = absf(fliege.global_position.y - (global_position.y - hoehe / 2.0))
	return seitlich <= breite / 2.0 + groesse and senkrecht <= hoehe / 2.0 + groesse


func zermatschen(fliege: Node2D) -> void:
	if fliege.gefangen:
		var nadel: Node2D = fliege.get_parent()
		if not nadel.haengt:
			return
		nadel.haengt = false
		faecher.entfernen(nadel)
		nadel.queue_free()
	else:
		fliege.queue_free()
	get_parent().get_node("TonMatsch").play()
	var matsch: Node2D = matsch_szene.instantiate()
	get_parent().add_child(matsch)
	matsch.global_position = fliege.global_position
