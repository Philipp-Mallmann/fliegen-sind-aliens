extends Node

# Schickt ab und zu eine Stechfliege los, aber nur in einer bestimmten Zone.

# Die Szene der Stechfliege.
@export var stechfliege_szene: PackedScene
# Die Kanone. Die Stechfliege wird an sie gehaengt, damit sie mit ihr mitfaehrt.
@export var kanone: Node2D
# Der Knoten mit den Zonen. Er sagt, in welcher Zone man gerade ist.
@export var zonen: Node
# Nur in dieser Zone kommt die Stechfliege.
@export var zone: Node
# Das Rechteck auf dem Arm, in dem sie sich hinsetzt. Im Editor verschieben und groesser oder kleiner ziehen.
@export var stichstelle: Control
# Wie viele Sekunden zwischen zwei Stechfliegen vergehen, mindestens und hoechstens.
@export var abstand_kurz: float = 6.0
@export var abstand_lang: float = 12.0

# Wie viele Sekunden noch, bis die naechste kommt.
var uhr: float = 0.0


func _ready() -> void:
	uhr = randf_range(abstand_kurz, abstand_lang)


func _process(delta: float) -> void:
	if zonen.aktuelle() != zone:
		return
	uhr -= delta
	if uhr > 0.0:
		return
	uhr = randf_range(abstand_kurz, abstand_lang)
	var flaeche: Rect2 = stichstelle.get_global_rect()
	var punkt: Vector2 = flaeche.position + Vector2(randf() * flaeche.size.x, randf() * flaeche.size.y)
	var fliege: Node2D = stechfliege_szene.instantiate()
	fliege.ziel = kanone.to_local(punkt)
	kanone.add_child(fliege)
