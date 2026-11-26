extends Node

# Kennt alle Hoehenzonen (seine Kindknoten, von unten nach oben) und sagt, in welcher man gerade ist.

# Die Kanone. An ihrer Hoehe haengt die Zone.
@export var kanone: Node2D
# Das Schild oben links, auf dem der Name der Zone steht.
@export var anzeige: Label


func _process(_delta: float) -> void:
	var zone: Node = aktuelle()
	anzeige.text = "Zone: " + str(zone.name)


func aktuelle() -> Node:
	var hoehe: float = -kanone.position.y / get_parent().hoehe_je_flugkraft
	var gefunden: Node = get_child(0)
	for zone in get_children():
		if hoehe >= zone.ab_flugkraft:
			gefunden = zone
	return gefunden
