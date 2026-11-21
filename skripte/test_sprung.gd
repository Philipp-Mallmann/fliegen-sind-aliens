extends Node

# Nur zum Testen, kommt vor der Abgabe wieder heraus.
# Die Zifferntasten 1, 2, 3 ... springen an den Anfang der ersten, zweiten, dritten ... Zone. Die 0 startet am Boden neu.

# Der Knoten mit den Zonen. Seine Kinder sind die Zonen, von unten nach oben.
@export var zonen: Node


func _unhandled_key_input(taste: InputEvent) -> void:
	if not taste.pressed or taste.echo:
		return
	if taste.keycode == KEY_0:
		get_tree().reload_current_scene()
		return
	var nummer: int = taste.keycode - KEY_1
	if nummer >= 0 and nummer < zonen.get_child_count():
		var zone: Node = zonen.get_child(nummer)
		get_parent().springen(int(zone.ab_flugkraft))
