extends Node2D

# Die Stechfliege: ein Gag, man kann sie nicht treffen.
# Sie kommt im Bogen von oben angeflogen, dreht sich hochkant, setzt sich auf den Arm,
# sticht (ein roter Punkt bleibt kurz zurueck) und fliegt im Bogen wieder weg.

# Wie lange der Anflug und der Abflug dauern, in Sekunden. Klein heisst: schnell.
@export var flugzeit: float = 0.4
# Wie lange sie auf dem Arm sitzt, in Sekunden.
@export var sitzzeit: float = 0.8
# Wie weit sie sich zum Sitzen dreht. PI / 2 ist eine Vierteldrehung, also hochkant.
@export var sitz_drehung: float = PI / 2.0
# Woher sie kommt und wohin sie wieder fliegt, von der Stelle auf dem Arm aus gesehen, in Pixeln.
@export var anflug_von: Vector2 = Vector2(-600.0, -900.0)
@export var abflug_nach: Vector2 = Vector2(600.0, -900.0)
# Wie weit der Bogen zur Seite ausholt, in Pixeln.
@export var ausholen: float = 300.0
# Der rote Punkt, den der Stich hinterlaesst.
@export var stich_szene: PackedScene
# Wie lange der rote Punkt braucht, bis er verblasst ist, in Sekunden.
@export var stich_dauer: float = 3.0

# Die Stelle auf dem Arm, an der sie sich hinsetzt. Setzt der Stecher, bevor sie ins Spiel kommt.
var ziel: Vector2 = Vector2.ZERO
# Wo der Bogen gerade anfaengt und wo er aufhoert.
var bogen_start: Vector2 = Vector2.ZERO
var bogen_ende: Vector2 = Vector2.ZERO
# Der Punkt, zu dem der Bogen hin ausholt.
var bogen_mitte: Vector2 = Vector2.ZERO


func _ready() -> void:
	position = ziel + anflug_von
	bogen_setzen(position, ziel, -ausholen)
	var ablauf: Tween = create_tween()
	ablauf.tween_method(bogen_fliegen, 0.0, 1.0, flugzeit)
	ablauf.tween_property(self, "rotation", sitz_drehung, 0.15)
	ablauf.tween_callback(stechen)
	ablauf.tween_interval(sitzzeit)
	ablauf.tween_property(self, "rotation", 0.0, 0.15)
	ablauf.tween_callback(abflug_vorbereiten)
	ablauf.tween_method(bogen_fliegen, 0.0, 1.0, flugzeit)
	ablauf.tween_callback(queue_free)


# Legt fest, von wo nach wo der naechste Bogen geht. Die Mitte liegt seitlich daneben, darum wird es ein Bogen.
func bogen_setzen(von: Vector2, nach: Vector2, seite: float) -> void:
	bogen_start = von
	bogen_ende = nach
	bogen_mitte = (von + nach) / 2.0 + Vector2(seite, 0.0)


# Setzt die Fliege an die Stelle des Bogens, die zum Anteil passt: 0 ist der Anfang, 1 das Ende.
func bogen_fliegen(anteil: float) -> void:
	var erstes: Vector2 = bogen_start.lerp(bogen_mitte, anteil)
	var zweites: Vector2 = bogen_mitte.lerp(bogen_ende, anteil)
	position = erstes.lerp(zweites, anteil)


func stechen() -> void:
	var stich: Node2D = stich_szene.instantiate()
	stich.position = ziel
	get_parent().add_child(stich)
	var verblassen: Tween = stich.create_tween()
	verblassen.tween_property(stich, "modulate:a", 0.0, stich_dauer)
	verblassen.tween_callback(stich.queue_free)


func abflug_vorbereiten() -> void:
	bogen_setzen(ziel, ziel + abflug_nach, ausholen)
