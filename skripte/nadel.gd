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

# Wie viele Pixel die Nadel schon geflogen ist.
var geflogen: float = 0.0
# true heisst: Die Nadel steckt in ihrer letzten Fliege und fliegt nicht mehr.
var steckt: bool = false
# Die Fliegen, die an der Nadel stecken, in der Reihenfolge, in der sie getroffen wurden.
var aufgespiesste: Array[Node2D] = []
# Der Punkt, an dem der Faden der Nadel festhaengt: erst die Muendung der Kanone, im Faecher die rechte Hand.
var anker: Node2D = null
# true heisst: Die Nadel haengt mit ihren Fliegen fertig im Faecher. Erst dann kann ein Hindernis sie treffen.
var haengt: bool = false


func _process(delta: float) -> void:
	if steckt:
		faden_spannen()
		return
	position.y -= tempo * delta
	geflogen += tempo * delta
	var getroffene: Node2D = fliege_an_der_spitze()
	if getroffene != null:
		aufspiessen(getroffene)
	if not aufgespiesste.is_empty():
		if geflogen >= reichweite or not noch_eine_darueber():
			stecken_bleiben()
	elif geflogen >= reichweite:
		queue_free()
	faden_spannen()


func trifft(kandidat: Node2D, nur_darueber: bool) -> bool:
	if kandidat.gefangen:
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
	aufgespiesste.append(getroffene)
	getroffene.gefangen = true
	getroffene.get_node("Summen").stop()
	$TonTreffer.play()
	getroffene.reparent(self)
	getroffene.position = Vector2.ZERO
	getroffene.get_node("Loch").visible = true
	var fleck: Node2D = blutfleck_szene.instantiate()
	get_parent().add_child(fleck)
	fleck.global_position = global_position


func stecken_bleiben() -> void:
	steckt = true
	getroffen.emit(self)


func flugkraft() -> int:
	var summe: int = 0
	for fliege in aufgespiesste:
		summe += fliege.flugkraft
	return summe


func faden_spannen() -> void:
	if anker == null:
		return
	$Faden.points = PackedVector2Array([anker.global_position, $Oese.global_position])
	var richtung: Vector2 = $Oese.global_position.direction_to(anker.global_position)
	var anzahl: int = aufgespiesste.size()
	for nummer in anzahl:
		var fliege: Node2D = aufgespiesste[nummer]
		var schritte: int = anzahl - 1 - nummer
		fliege.global_position = $Oese.global_position + richtung * spiess_abstand * global_scale.x * schritte
		fliege.global_rotation = richtung.angle() - PI / 2.0
