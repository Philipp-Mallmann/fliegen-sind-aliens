extends Node2D

# Die ganze Figur in der Totale. Mit den Pfeiltasten kippt sie, ihr Arm zielt mit der Kanone, sie schiesst schraeg.
# Nach dem ersten Treffer spielt sie die Einstiegs-Sequenz und meldet danach den Spielstart.

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
# Wie lange die Einstiegs-Sequenz nach dem ersten Treffer dauert, in Sekunden.
@export var einstieg_dauer: float = 2.0
# Wie hoch die Figur dabei abhebt, in Pixeln. 132 ist eine Kopfhoehe.
@export var abheben: float = 132.0
# Wie weit sie dabei hin und her schwankt, in Grad nach jeder Seite.
@export var schwanken: float = 8.0

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


func _input(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseMotion:
		maus_zielt = true


func _process(delta: float) -> void:
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
		nadel.position = $Schulter/Spitze.global_position
		nadel.rotation = $Schulter.global_rotation
		nadel.richtung = Vector2.UP.rotated($Schulter.global_rotation)
		nadel.anker = $Schulter/Spitze
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
	var viertel: float = einstieg_dauer / 4.0
	var ablauf: Tween = create_tween()
	ablauf.tween_property(kanone, "position:y", -abheben, viertel)
	ablauf.parallel().tween_property(self, "rotation_degrees", schwanken, viertel)
	ablauf.tween_property(self, "rotation_degrees", -schwanken, viertel)
	ablauf.tween_property(self, "rotation_degrees", schwanken, viertel)
	ablauf.tween_property(self, "rotation_degrees", 0.0, viertel)
	ablauf.parallel().tween_property($Schulter, "rotation", 0.0, viertel)
	ablauf.parallel().tween_property(nadel, "rotation", 0.0, viertel)
	ablauf.tween_callback(sequenz_fertig)


func sequenz_fertig() -> void:
	spielstart.emit(erste_nadel)


# Wird von spiel.gd gerufen, wenn das Spiel beginnt: Die Figur steht gerade, ihr Arm mit der Kanone verschwindet.
# An seiner Stelle sieht man ab jetzt die Kanone des Spiels.
func ausschalten() -> void:
	aktiv = false
	rotation = 0.0
	$Schulter.visible = false
