extends Node2D

# Hoechstes Tempo der Kanone, in Pixeln pro Sekunde.
@export var tempo: float = 250.0
# Wie schnell die Kanone anfaehrt und abbremst, in Pixeln pro Sekunde pro Sekunde.
@export var beschleunigung: float = 600.0
# Welcher Teil des Tempos waehrend Uebergabe und Steigen bleibt. 0.5 heisst: halb so schnell.
@export var steig_anteil: float = 0.5
# Die Szene der Nadel. Bei jedem Schuss entsteht daraus eine neue Nadel.
@export var nadel_szene: PackedScene
# Wie lange die Kanone nach einem Schuss nachlaedt, in Sekunden.
@export var nachladezeit: float = 0.5

# Das Tempo, mit dem die Kanone gerade faehrt. Negativ heisst nach links.
var aktuelles_tempo: float = 0.0
# Wie viele Sekunden das Nachladen noch dauert. 0 oder weniger heisst: bereit.
var nachladen_noch: float = 0.0
# true heisst: Die Kanone darf nicht schiessen, zum Beispiel waehrend des Absturzes. Setzt spiel.gd.
var gesperrt: bool = false
# true heisst: Die Kanone steigt gerade nach einem Fang und faehrt darum langsamer. Setzt spiel.gd.
var steigt: bool = false


func _process(delta: float) -> void:
	fahren(delta)
	if not $Uebergabe.laeuft:
		schiessen(delta)


func fahren(delta: float) -> void:
	var richtung: float = Input.get_axis("links", "rechts")
	var hoechstes: float = tempo
	if steigt or $Uebergabe.laeuft:
		hoechstes = tempo * steig_anteil
	var ziel_tempo: float = richtung * hoechstes
	aktuelles_tempo = move_toward(aktuelles_tempo, ziel_tempo, beschleunigung * delta)
	position.x += aktuelles_tempo * delta


func schiessen(delta: float) -> void:
	nachladen_noch -= delta
	if nachladen_noch > 0.0:
		return
	if gesperrt:
		return
	if Input.is_action_just_pressed("schiessen"):
		var nadel: Node2D = nadel_szene.instantiate()
		nadel.position = $Arm/Muendung.global_position
		nadel.anker = $Arm/Muendung
		get_parent().add_child(nadel)
		nadel.getroffen.connect($Uebergabe.starten)
		nachladen_noch = nachladezeit
