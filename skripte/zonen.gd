extends Node

# Kennt alle Hoehenzonen (seine Kindknoten, von unten nach oben) und sagt, in welcher man gerade ist.

# Die Kanone. An ihrer Hoehe haengt die Zone.
@export var kanone: Node2D
# Der Hintergrund. Er wird in der Farbe der Zone getoent.
@export var hintergrund: Node2D
# Das Schild oben links, auf dem der Name der Zone steht.
@export var anzeige: Label


func _process(_delta: float) -> void:
	var zone: Node = aktuelle()
	hintergrund.modulate = zone.farbe
	anzeige.text = "Zone: " + str(zone.name)


func aktuelle() -> Node:
	var hoehe: float = -kanone.position.y / get_parent().hoehe_je_flugkraft
	var gefunden: Node = get_child(0)
	for zone in get_children():
		if hoehe >= zone.ab_flugkraft:
			gefunden = zone
	return gefunden
