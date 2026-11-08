extends Node2D

# Wird gesendet, sobald die Nadel eine Fliege getroffen hat. Mit dabei: die Nadel selbst.
signal getroffen(nadel: Node2D)

# Wie schnell die Nadel fliegt, in Pixeln pro Sekunde.
@export var tempo: float = 3200.0
# Wie weit die Nadel fliegt, bevor sie verschwindet, in Pixeln. 2160 ist zweimal die Bildhoehe.
@export var reichweite: float = 2160.0
# Wie weit eine Fliege seitlich neben der Nadel sein darf und trotzdem getroffen wird, in Pixeln.
@export var trefferbreite: float = 25.0
# Die Szene des Blutflecks. Bei jedem Treffer entsteht daraus ein neuer Fleck.
@export var blutfleck_szene: PackedScene

# Wie viele Pixel die Nadel schon geflogen ist.
var geflogen: float = 0.0
# true heisst: Die Nadel hat eine Fliege getroffen und steckt fest.
var steckt: bool = false


func _process(delta: float) -> void:
	if steckt:
		return
	var alte_y: float = global_position.y
	position.y -= tempo * delta
	geflogen += tempo * delta
	var fliege: Node2D = getroffene_fliege(alte_y)
	if fliege != null:
		treffen(fliege)
	elif geflogen >= reichweite:
		queue_free()


func getroffene_fliege(alte_y: float) -> Node2D:
	var kandidat: Node2D = null
	for fliege in get_tree().get_nodes_in_group("fliegen"):
		if fliege.gefangen:
			continue
		var seitlich: float = absf(fliege.global_position.x - global_position.x)
		var unterwegs: bool = fliege.global_position.y <= alte_y and fliege.global_position.y >= global_position.y
		if seitlich <= trefferbreite and unterwegs:
			if kandidat == null or fliege.global_position.y > kandidat.global_position.y:
				kandidat = fliege
	return kandidat


func treffen(fliege: Node2D) -> void:
	steckt = true
	global_position.y = fliege.global_position.y
	fliege.gefangen = true
	fliege.global_position.x = global_position.x
	fliege.reparent(self)
	var fleck: Node2D = blutfleck_szene.instantiate()
	get_parent().add_child(fleck)
	fleck.global_position = global_position
	getroffen.emit(self)
