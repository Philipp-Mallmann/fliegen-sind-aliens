extends Node2D

# Die ganze Figur in der Totale. Mit den Pfeiltasten kippt sie, ihr Arm zielt mit der Kanone, sie schiesst schraeg.
# Nach dem ersten Treffer hebt sie kurz ab, nimmt den Arm nach oben und meldet dann den Spielstart.

# Wird gesendet, wenn die Einstiegs-Sequenz vorbei ist. Mit dabei: die Nadel mit der ersten Fliege.
signal spielstart(nadel: Node2D)

# Die Szene der Nadel. Bei jedem Schuss entsteht daraus eine neue Nadel.
@export var nadel_szene: PackedScene
# Die Kanone des Spiels. An ihr haengt die Figur, mit ihr hebt sie ab.
@export var kanone: Node2D
# Der Erzeuger der Fliegen. Er laesst den Schwarm beim ersten Treffer fliehen.
@export var erzeuger: Node2D
# Der Joystick am Handy. Zeigt er irgendwohin, zeigt der Arm dorthin.
@export var joystick: Node2D
# Wie lange die Figur nach einem Schuss nachlaedt, in Sekunden.
@export var nachladezeit: float = 0.5
# Wie weit die Figur mit den Pfeiltasten hoechstens kippt, in Grad nach jeder Seite.
@export var kippwinkel: float = 20.0
# Wie schnell sie kippt, in Grad pro Sekunde.
@export var kipptempo: float = 80.0
# Wie lange die Figur nach dem ersten Treffer braucht, um den Arm gerade nach oben zu nehmen, in Sekunden.
# Danach beginnt sofort das Spiel mit Steigen und Zoom.
@export var einstieg_dauer: float = 0.3
# Wie hoch die Figur dabei schon abhebt, in Pixeln. 132 ist eine Kopfhoehe.
@export var abheben: float = 132.0
# Der Forscher, der am Draht haengt (haengen.gd). Er ersetzt beim ersten Treffer den stehenden Koerper.
@export var haenger: Node2D
# Wie lange der Kanonenarm braucht, um den Draht in die Hand zu schwenken, in Sekunden.
@export var schwenk_dauer: float = 0.45
# Wie weit der Arm dabei ueber die Richtung zur Hand hinaus nach rechts geht, in Grad.
@export var schwenk_extra: float = 10.0

# true heisst: Man steuert die Figur. false ab dem ersten Treffer.
var aktiv: bool = true
# true heisst: Die Wand mit den Einstellungen ist oben, die Figur wartet. Setzt einstellungen.gd.
var wand_offen: bool = false
# true heisst: Der Arm folgt dem Mauszeiger. Erst nach der ersten Mausbewegung, vorher zeigt er nach oben.
var maus_zielt: bool = false
# Wie viele Sekunden das Nachladen noch dauert. 0 oder weniger heisst: bereit.
var nachladen_noch: float = 0.0
# Die Nadel, die als erste getroffen hat. Sie wird am Ende der Sequenz an das Spiel uebergeben.
var erste_nadel: Node2D = null
# true heisst: Die Figur (mit dem Kanonenarm) pendelt mit dem haengenden Forscher mit.
var folgt: bool = false
# Wo die Figur relativ zum haengenden Forscher sitzt. Wird beim Anhaengen gemessen.
var relativ: Transform2D = Transform2D.IDENTITY
# Wo die Figur am Anfang steht. Dorthin kommt sie zurueck, wenn sie nicht mehr mitpendelt.
var start_lage: Transform2D = Transform2D.IDENTITY


# Setzt den Arm an den Koerper. Zwei Marker sagen, wo: Schulterpunkt liegt auf dem Koerper an der Schulter,
# Drehpunkt liegt auf dem Arm an der Stelle, um die er sich dreht. Beide verschiebt man im Editor.
func _ready() -> void:
	$Schulter.position = $Schulterpunkt.position
	$Schulter/Armbild.position = -$Schulter/Armbild/Drehpunkt.position
	start_lage = transform


func _input(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseMotion:
		maus_zielt = true


func _process(delta: float) -> void:
	# Haengt der Forscher, sitzt die Figur (mit dem Kanonenarm) immer gleich zu ihm und pendelt so mit.
	if folgt:
		global_transform = haenger.get_node("Inhalt").global_transform * relativ
	if not aktiv or wand_offen:
		return
	kippen(delta)
	zielen()
	schiessen(delta)


func kippen(delta: float) -> void:
	var ziel: float = Input.get_axis("links", "rechts") * kippwinkel
	rotation_degrees = move_toward(rotation_degrees, ziel, kipptempo * delta)


func zielen() -> void:
	if joystick.richtung != Vector2.ZERO:
		maus_zielt = false
		$Schulter.rotation = wrapf(joystick.richtung.angle() + PI / 2.0, -PI, PI)
	elif maus_zielt:
		var zur_maus: Vector2 = get_global_mouse_position() - $Schulter.global_position
		$Schulter.rotation = wrapf(zur_maus.angle() + PI / 2.0, -PI, PI)


func schiessen(delta: float) -> void:
	nachladen_noch -= delta
	if nachladen_noch > 0.0:
		return
	if Input.is_action_just_pressed("schiessen"):
		var nadel: Node2D = nadel_szene.instantiate()
		# Die Spitze haengt am Kanonenbild (oben am Lauf). Verschiebt man das Bild, wandert sie mit.
		nadel.position = $Schulter/Armbild/Bild/Spitze.global_position
		nadel.rotation = $Schulter.global_rotation
		nadel.richtung = Vector2.UP.rotated($Schulter.global_rotation)
		nadel.anker = $Schulter/Armbild/Bild/Spitze
		kanone.get_parent().add_child(nadel)
		nadel.getroffen.connect(erster_treffer)
		nachladen_noch = nachladezeit
		kanone.get_node("TonSchuss").play()


# Wird von der Nadel gerufen, sobald sie in einer Fliege steckt.
func erster_treffer(nadel: Node2D) -> void:
	if not aktiv or wand_offen:
		nadel.queue_free()
		return
	aktiv = false
	erste_nadel = nadel
	kanone.steigt = true
	erzeuger.schwarm_aufloesen()
	var ablauf: Tween = create_tween()
	ablauf.tween_property(kanone, "position:y", -abheben, einstieg_dauer)
	ablauf.parallel().tween_property(self, "rotation_degrees", 0.0, einstieg_dauer)
	ablauf.parallel().tween_property($Schulter, "rotation", 0.0, einstieg_dauer)
	ablauf.parallel().tween_property(nadel, "rotation", 0.0, einstieg_dauer)
	ablauf.tween_callback(anhaengen)


# Der stehende Koerper wird zum haengenden Forscher. Erst pendelt er um die Kanonenspitze, an der der Draht haengt.
# Dann schwenkt der Arm nach rechts, der Draht gleitet zwischen Daumen und Finger, und ab da pendelt er um die Hand.
func anhaengen() -> void:
	$Koerper.visible = false
	$Gesicht.visible = false
	haenger.visible = true
	relativ = haenger.get_node("Inhalt").global_transform.affine_inverse() * global_transform
	folgt = true
	var spitze: Node2D = $Schulter/Armbild/Bild/Spitze
	var griff: Vector2 = haenger.get_node("Inhalt").global_position
	haenger.drehpunkt_setzen(spitze.global_position)
	haenger.anstossen()
	# Der Draht haengt an einem Punkt, der von der Spitze in die Hand wandert.
	var faden: Node2D = kanone.get_node("Fadenpunkt")
	faden.global_position = spitze.global_position
	erste_nadel.anker = faden
	var zur_hand: Vector2 = griff - $Schulter.global_position
	var ziel_winkel: float = zur_hand.angle() + PI / 2.0 + deg_to_rad(schwenk_extra)
	var schwenk: Tween = create_tween()
	schwenk.tween_property($Schulter, "rotation", ziel_winkel, schwenk_dauer)
	schwenk.parallel().tween_property(faden, "global_position", griff, schwenk_dauer)
	schwenk.tween_callback(in_der_hand)


# Der Draht steckt in der Hand: Ab jetzt ist die Hand der Drehpunkt, und der Draht haengt am Forscher.
func in_der_hand() -> void:
	haenger.drehpunkt_setzen(haenger.get_node("Inhalt").global_position)
	erste_nadel.anker = haenger
	sequenz_fertig()


func sequenz_fertig() -> void:
	spielstart.emit(erste_nadel)


# Wird von spiel.gd gerufen, wenn das Spiel beginnt: Ihr Arm mit der Kanone verschwindet, sie pendelt nicht mehr mit.
# An ihrer Stelle sieht man ab jetzt die Kanone des Spiels und den haengenden Forscher.
func ausschalten() -> void:
	aktiv = false
	folgt = false
	transform = start_lage
	$Schulter.visible = false
