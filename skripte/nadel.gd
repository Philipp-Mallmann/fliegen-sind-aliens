extends Node2D

# Wird gesendet, sobald die Nadel eine Fliege getroffen hat. Mit dabei: die Nadel selbst.
signal getroffen(nadel: Node2D)

# Wie schnell die Nadel fliegt, in Pixeln pro Sekunde.
@export var tempo: float = 3200.0
# Wie weit die Nadel fliegt, bevor sie verschwindet, in Pixeln. 2160 ist zweimal die Bildhoehe.
@export var reichweite: float = 2160.0
# Die Szene des Blutflecks. Bei jedem Treffer entsteht daraus ein neuer Fleck.
@export var blutfleck_szene: PackedScene

# Wie viele Pixel die Nadel schon geflogen ist.
var geflogen: float = 0.0
# true heisst: Die Nadel hat eine Fliege getroffen und steckt fest.
var steckt: bool = false
# Die Fliege, die an der Nadel steckt. null heisst: noch keine.
var fliege: Node2D = null


func _process(delta: float) -> void:
	if steckt:
		return
	position.y -= tempo * delta
	geflogen += tempo * delta
	var getroffene: Node2D = fliege_an_der_spitze()
	if getroffene != null:
		treffen(getroffene)
	elif geflogen >= reichweite:
		queue_free()


func fliege_an_der_spitze() -> Node2D:
	for kandidat in get_tree().get_nodes_in_group("fliegen"):
		if kandidat.gefangen:
			continue
		var seitlich: float = absf(kandidat.global_position.x - global_position.x)
		var senkrecht: float = absf(kandidat.global_position.y - global_position.y)
		if seitlich <= kandidat.halbe_groesse and senkrecht <= kandidat.halbe_groesse:
			return kandidat
	return null


func treffen(getroffene: Node2D) -> void:
	steckt = true
	fliege = getroffene
	fliege.gefangen = true
	fliege.reparent(self)
	var fleck: Node2D = blutfleck_szene.instantiate()
	get_parent().add_child(fleck)
	fleck.global_position = global_position
	getroffen.emit(self)
