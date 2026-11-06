extends Node2D

# Hoechstes Tempo der Kanone, in Pixeln pro Sekunde.
@export var tempo: float = 250.0
# Wie schnell die Kanone anfaehrt und abbremst, in Pixeln pro Sekunde pro Sekunde.
@export var beschleunigung: float = 600.0
# Die Szene der Nadel. Bei jedem Schuss entsteht daraus eine neue Nadel.
@export var nadel_szene: PackedScene
# Wie lange die Kanone nachlaedt, nachdem die Nadel weg ist, in Sekunden.
@export var nachladezeit: float = 0.5

# Das Tempo, mit dem die Kanone gerade faehrt. Negativ heisst nach links.
var aktuelles_tempo: float = 0.0
# Die Nadel, die gerade fliegt. null heisst: Es ist keine Nadel unterwegs.
var nadel: Node2D = null
# Wie viele Sekunden das Nachladen noch dauert. 0 oder weniger heisst: bereit.
var nachladen_noch: float = 0.0


func _process(delta: float) -> void:
	fahren(delta)
	schiessen(delta)


func fahren(delta: float) -> void:
	var richtung: float = Input.get_axis("links", "rechts")
	var ziel_tempo: float = richtung * tempo
	aktuelles_tempo = move_toward(aktuelles_tempo, ziel_tempo, beschleunigung * delta)
	position.x += aktuelles_tempo * delta


func schiessen(delta: float) -> void:
	nachladen_noch -= delta
	if nadel != null or nachladen_noch > 0.0:
		return
	if Input.is_action_just_pressed("schiessen"):
		nadel = nadel_szene.instantiate()
		nadel.position = $Muendung.global_position
		get_parent().add_child(nadel)
		nadel.tree_exited.connect(nadel_ist_weg)


func nadel_ist_weg() -> void:
	nadel = null
	nachladen_noch = nachladezeit
