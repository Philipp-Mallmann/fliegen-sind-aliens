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
@export var blinken_anfang: float = 0.5
@export var blinken_ende: float = 0.1
# Wie weit ueber der Kanone der obere Bildrand liegt, in Pixeln.
@export var bildrand: float = 920.0
# Wie weit unter der Kanone der Gegenstand verschwindet, in Pixeln. Der untere Bildrand liegt bei 160.
@export var weg_unter: float = 300.0
# Die Szene des Matsches. Bei jeder zermatschten Fliege entsteht daraus ein Fleck.
@export var matsch_szene: PackedScene

# Die Kanone. Die Warnung bleibt ueber ihr am oberen Bildrand. Setzt der Hindernis-Erzeuger.
var kanone: Node2D = null
# Der Faecher. Aus ihm werden getroffene Fliegen entfernt. Setzt der Hindernis-Erzeuger.
var faecher: Node2D = null
# Wie viele Sekunden schon gewarnt wird.
var gewarnt: float = 0.0


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
	var anteil: float = gewarnt / warnzeit
	$Warnung.scale = Vector2.ONE * (0.5 + anteil)
	var takt: float = lerpf(blinken_anfang, blinken_ende, anteil)
	$Warnung.visible = fmod(gewarnt, takt) < takt / 2.0


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
	var matsch: Node2D = matsch_szene.instantiate()
	get_parent().add_child(matsch)
	matsch.global_position = fliege.global_position
