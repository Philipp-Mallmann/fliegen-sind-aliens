extends Node

# Wie lange die Fahrt hinueber dauert, in Sekunden. Arm und Nadel brauchen gleich lang, der Rueckweg auch.
@export var dauer: float = 0.48
# Wie weit der Arm von der Mitte nach rechts faehrt, in Pixeln. Dort sitzt die rechte Hand.
@export var ziel_x: float = 480.0
# Der Arm: linke Hand, Kanone und Muendung. Nur er faehrt, die Kamera bleibt stehen.
@export var arm: Node2D
# Die Stelle ueber der rechten Hand, an der die gefangenen Fliegen haengen.
@export var haken: Node2D

# true heisst: Gerade laeuft eine Uebergabe. Die Kanone faehrt und schiesst dann nicht.
var laeuft: bool = false
# Nadeln mit Fliege, die noch uebergeben werden muessen, der Reihe nach.
var warteschlange: Array[Node2D] = []


func starten(nadel: Node2D) -> void:
	warteschlange.append(nadel)
	if not laeuft:
		uebergeben()


func uebergeben() -> void:
	laeuft = true
	while warteschlange.size() > 0:
		var nadel: Node2D = warteschlange.pop_front()
		var hin: Tween = create_tween()
		hin.tween_property(arm, "position", Vector2(ziel_x, 0.0), dauer)
		hin.parallel().tween_property(nadel, "global_position", haken.global_position, dauer)
		await hin.finished
		nadel.reparent(haken)
		var zurueck: Tween = create_tween()
		zurueck.tween_property(arm, "position", Vector2.ZERO, dauer)
		await zurueck.finished
	laeuft = false
