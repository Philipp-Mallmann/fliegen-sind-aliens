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
# Wie lange die Figur nach dem ersten Treffer braucht, um ein Stueck abzuheben, in Sekunden.
@export var einstieg_dauer: float = 0.3
# Wie hoch die Figur dabei schon abhebt, in Pixeln. 132 ist eine Kopfhoehe.
@export var abheben: float = 132.0
# Der Forscher, der am Draht haengt (haengen.gd). Er ersetzt beim ersten Treffer den stehenden Koerper.
@export var haenger: Node2D
# Wie lange der Kanonenarm braucht, um mit dem Draht zur Hand zu schwenken, in Sekunden.
@export var schwenk_dauer: float = 0.45
# Wie lange der Draht braucht, um von der Kanonenspitze in die Hand zu gleiten, in Sekunden.
@export var gleit_dauer: float = 0.2
# Wie lange der Forscher danach noch ganz zu sehen ist, ueber der Wiese haengend, bevor die Kamera heranfaehrt, in Sekunden.
# In dieser Zeit laeuft der Draht durch die Hand weiter bis zur Kanonenspitze, und der Arm geht ein Stueck zurueck.
@export var halte_dauer: float = 0.7
# Wie weit der Kanonenarm dabei zurueckgeht, in Grad.
@export var rueck_winkel: float = 35.0
# Wie weit der Kanonenarm beim Heranfahren nach links unten wegschwenkt, in Grad.
@export var wegschwenk_winkel: float = 160.0

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
# true heisst: Der Draht haengt an der Kanonenspitze und wird gerade in die Hand eingehakt.
var hakt_ein: bool = false
# Wo der Draht gehalten wird: 0 heisst an der Kanonenspitze, 1 heisst in der Hand, dazwischen unterwegs.
var halt: float = 0.0
# true heisst: Der Draht sitzt fest in der Hand, und sein Rest loest sich gerade von der Kanonenspitze.
var laesst_los: bool = false
# Wo das Ende des Rests ist: 0 heisst noch an der Kanonenspitze, 1 heisst in der Hand angekommen.
var los: float = 0.0
# Der Ablauf nach dem ersten Treffer. null heisst: Es gab noch keinen.
var ablauf: Tween = null


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
	# Der Ablauf wird hier von Hand weitergestellt und nicht von Godot selbst. Godot wuerde ihn erst nach allen
	# _process-Funktionen weiterstellen: Dann waere der Arm schon weiter als der Draht, und man saehe eine Luecke.
	if ablauf != null and ablauf.is_valid():
		ablauf.custom_step(delta)
	# Haengt der Forscher, sitzt die Figur (mit dem Kanonenarm) immer gleich zu ihm und pendelt so mit.
	if folgt:
		global_transform = haenger.get_node("Inhalt").global_transform * relativ
	# Einhaken: Der Punkt, an dem der Draht gehalten wird, wandert von der Kanonenspitze in die Hand.
	# Um diesen Punkt pendelt der Forscher. Der Draht selbst bleibt dabei am Lauf der Kanone haengen.
	if hakt_ein:
		var spitze: Vector2 = $Schulter/Armbild/Bild/Spitze.global_position
		var hand: Vector2 = haenger.get_node("Inhalt").global_position
		var ort: Vector2 = spitze.lerp(hand, halt)
		kanone.get_node("Fadenpunkt").global_position = ort
		haenger.drehpunkt_setzen(ort)
	# Loslassen: Das Ende des Drahts wandert von der Kanonenspitze in die Hand.
	if laesst_los:
		var von: Vector2 = $Schulter/Armbild/Bild/Spitze.global_position
		var bis: Vector2 = haenger.get_node("Inhalt").global_position
		kanone.get_node("Fadenpunkt").global_position = von.lerp(bis, los)
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
	# Der Koerper steht ab jetzt gerade. Der Arm behaelt dabei seine Richtung.
	$Schulter.rotation += rotation
	rotation = 0.0
	anhaengen()


# Der stehende Koerper wird zum haengenden Forscher, er hebt ein Stueck ab und pendelt.
# Der Draht haengt am Lauf der Kanone, waehrend der Arm zur Hand schwenkt. Dort hakt er zwischen Daumen und Fingern ein
# und laeuft durch die Hand weiter bis zur Kanone. Erst wenn er fest sitzt, loest sich sein Rest vom Lauf.
func anhaengen() -> void:
	$Koerper.visible = false
	$Gesicht.visible = false
	haenger.visible = true
	relativ = haenger.get_node("Inhalt").global_transform.affine_inverse() * global_transform
	folgt = true
	halt = 0.0
	hakt_ein = true
	erste_nadel.anker = $Schulter/Armbild/Bild/Spitze
	haenger.anstossen()
	# Die Richtung von der Schulter zur Hand, gemessen in der Figur. Die Figur pendelt mit, darum bleibt sie gleich.
	var zur_hand: Vector2 = to_local(haenger.get_node("Inhalt").global_position) - $Schulter.position
	var ziel_winkel: float = $Schulter.rotation + wrapf(zur_hand.angle() + PI / 2.0 - $Schulter.rotation, -PI, PI)
	ablauf = create_tween()
	ablauf.pause()
	ablauf.tween_property($Schulter, "rotation", ziel_winkel, schwenk_dauer)
	ablauf.parallel().tween_property(kanone, "position:y", -abheben, einstieg_dauer)
	ablauf.parallel().tween_property(erste_nadel, "rotation", 0.0, einstieg_dauer)
	ablauf.tween_callback(einhaken)
	ablauf.tween_property(self, "halt", 1.0, gleit_dauer)
	ablauf.tween_callback(in_der_hand)
	ablauf.tween_property($Schulter, "rotation", ziel_winkel - deg_to_rad(rueck_winkel), halte_dauer)
	ablauf.tween_callback(loslassen)
	ablauf.tween_property(self, "los", 1.0, gleit_dauer)
	ablauf.tween_callback(frei)


# Die Kanonenspitze ist bei der Hand: Ab jetzt laeuft der Draht ueber den Haltepunkt und von dort weiter zum Lauf.
func einhaken() -> void:
	erste_nadel.ueber = kanone.get_node("Fadenpunkt")


# Der Draht steckt in der Hand: Ab jetzt ist die Hand der Drehpunkt. Sein Rest haengt noch am Lauf der Kanone.
func in_der_hand() -> void:
	hakt_ein = false
	haenger.drehpunkt_setzen(haenger.get_node("Inhalt").global_position)
	erste_nadel.ueber = haenger


# Der Draht sitzt fest: Sein Rest loest sich vom Lauf und rutscht in die Hand.
func loslassen() -> void:
	los = 0.0
	laesst_los = true
	erste_nadel.anker = kanone.get_node("Fadenpunkt")


# Der Rest ist in der Hand angekommen: Der Draht endet jetzt in der Hand, die Fliege kann nicht mehr entkommen.
func frei() -> void:
	laesst_los = false
	erste_nadel.ueber = null
	erste_nadel.anker = haenger
	sequenz_fertig()


func sequenz_fertig() -> void:
	spielstart.emit(erste_nadel)


# Wird von spiel.gd gerufen, wenn die Kamera heranfaehrt: Der Arm mit der Kanone schwenkt im Bogen nach links unten
# und verlaesst so das Bild. Die Figur pendelt dabei weiter mit dem Forscher mit.
func wegschwenken(dauer: float) -> void:
	aktiv = false
	$Koerper.visible = false
	$Gesicht.visible = false
	if not folgt:
		relativ = haenger.get_node("Inhalt").global_transform.affine_inverse() * global_transform
		folgt = true
	var schwenk: Tween = create_tween()
	schwenk.tween_property($Schulter, "rotation", $Schulter.rotation - deg_to_rad(wegschwenk_winkel), dauer)


# Wird von spiel.gd gerufen, wenn die Kamera angekommen ist: Der Arm mit der Kanone verschwindet, die Figur pendelt nicht mehr mit.
# Ab jetzt sieht man die Kanone des Spiels und die Hand des haengenden Forschers.
func ausschalten() -> void:
	aktiv = false
	folgt = false
	hakt_ein = false
	laesst_los = false
	transform = start_lage
	$Schulter.visible = false
