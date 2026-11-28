extends Node2D

# Hoechstes Tempo der Kanone, in Pixeln pro Sekunde.
@export var tempo: float = 360.0
# Wie schnell die Kanone anfaehrt und abbremst, in Pixeln pro Sekunde pro Sekunde.
@export var beschleunigung: float = 720.0
# Welcher Teil des Tempos waehrend Uebergabe und Steigen bleibt. 0 heisst: Man lenkt dann gar nicht, 0.5 hiesse halb so schnell.
@export var steig_anteil: float = 0.0
# Die Szene der Nadel. Bei jedem Schuss entsteht daraus eine neue Nadel.
@export var nadel_szene: PackedScene
# Wie lange die Kanone nach einem Schuss nachlaedt, in Sekunden.
@export var nachladezeit: float = 0.5
# Der Joystick am Handy. Sein Ausschlag nach links oder rechts lenkt wie die Pfeiltasten.
@export var joystick: Node2D
# Lenken mit dem Mauszeiger: Liegt der Zeiger naeher als so viele Pixel neben der Mitte der Kanone, bleibt sie stehen.
@export var maus_totzone: float = 40.0
# Ab so vielen Pixeln neben der Kanone faehrt sie mit vollem Tempo zum Zeiger. Dazwischen entsprechend langsamer.
@export var maus_voll: float = 300.0

# Das Tempo, mit dem die Kanone gerade faehrt. Negativ heisst nach links.
var aktuelles_tempo: float = 0.0
# Wie viele Sekunden das Nachladen noch dauert. 0 oder weniger heisst: bereit.
var nachladen_noch: float = 0.0
# true heisst: Die Kanone darf nicht schiessen, zum Beispiel waehrend des Absturzes. Setzt spiel.gd.
var gesperrt: bool = false
# true heisst: Die Kanone steigt gerade nach einem Fang und faehrt darum langsamer. Setzt spiel.gd.
var steigt: bool = false
# Die Nadeln, die gerade noch Draht aus der Kanone ziehen: Sie fliegen und stecken noch nicht.
var ziehende: Array[Node2D] = []
# true heisst: Der Mauszeiger lenkt. Gilt ab einer Mausbewegung und endet, sobald Tasten oder Joystick lenken.
var maus_lenkt: bool = false


# Godot ruft _input bei jeder Eingabe. Hier zaehlt nur: Die Maus wurde bewegt.
func _input(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseMotion:
		maus_lenkt = true


func _process(delta: float) -> void:
	fahren(delta)
	if not $Uebergabe.laeuft:
		schiessen(delta)
	draht_zeigen()


func fahren(delta: float) -> void:
	var richtung: float = Input.get_axis("links", "rechts") + joystick.richtung.x
	if richtung != 0.0:
		maus_lenkt = false
	elif maus_lenkt:
		var abstand: float = get_global_mouse_position().x - global_position.x
		if absf(abstand) > maus_totzone:
			richtung = abstand / maus_voll
	richtung = clampf(richtung, -1.0, 1.0)
	feuer_zeigen(richtung)
	var hoechstes: float = tempo
	if steigt or $Uebergabe.laeuft:
		hoechstes = tempo * steig_anteil
	var ziel_tempo: float = richtung * hoechstes
	aktuelles_tempo = move_toward(aktuelles_tempo, ziel_tempo, beschleunigung * delta)
	position.x += aktuelles_tempo * delta


# Zeigt das Feuer an den Triebwerken. Es brennt auf der Seite, von der die Kanone weggeschoben wird:
# Lenkt man nach rechts, brennt das linke Triebwerk. Lenkt man gar nicht, brennt keins.
func feuer_zeigen(richtung: float) -> void:
	$Arm/FeuerLinks.visible = richtung > 0.0
	$Arm/FeuerRechts.visible = richtung < 0.0


# Die Drahtrolle bewegt sich, solange Draht aus der Kanone laeuft. Steckt die Nadel oder ist sie weggeflogen,
# bleibt die Rolle stehen, und zwar genau so, wie sie gerade ist.
func draht_zeigen() -> void:
	var noch: Array[Node2D] = []
	for nadel in ziehende:
		if is_instance_valid(nadel) and not nadel.steckt:
			noch.append(nadel)
	ziehende = noch
	if ziehende.is_empty():
		$Arm/Drahtrolle.pause()
	elif not $Arm/Drahtrolle.is_playing():
		$Arm/Drahtrolle.play()


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
		nadel.kanone = self
		get_parent().add_child(nadel)
		nadel.getroffen.connect($Uebergabe.starten)
		ziehende.append(nadel)
		nachladen_noch = nachladezeit
		$TonSchuss.play()
