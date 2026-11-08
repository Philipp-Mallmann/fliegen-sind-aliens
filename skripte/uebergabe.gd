extends Node

# Wie schnell Arm und Nadel bei der Uebergabe fahren, in Pixeln pro Sekunde.
@export var tempo: float = 1000.0
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
		await fahren(arm, "position", Vector2(ziel_x, 0.0))
		await fahren(nadel, "global_position", haken.global_position)
		nadel.reparent(haken)
		await fahren(arm, "position", Vector2.ZERO)
	laeuft = false


func fahren(ding: Node2D, eigenschaft: String, ziel: Vector2) -> void:
	var weg: float = ding.get(eigenschaft).distance_to(ziel)
	var ablauf: Tween = create_tween()
	ablauf.tween_property(ding, eigenschaft, ziel, weg / tempo)
	await ablauf.finished
