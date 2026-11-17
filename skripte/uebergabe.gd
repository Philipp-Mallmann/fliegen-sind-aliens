extends Node

# Wird gesendet, sobald eine Fliege in der Reihe oben haengt. Mit dabei: ihre Flugkraft.
signal angekommen(flugkraft: int)

# Wie lange die Fahrt hinueber dauert, in Sekunden. Der Rueckweg dauert genauso lang.
@export var dauer: float = 0.48
# Wie lange die Fliege wartet, bevor sie losfaehrt, in Sekunden. Sie kommt trotzdem gleichzeitig mit dem Arm an.
@export var verzoegerung: float = 0.1
# Wie weit der Arm von der Mitte nach rechts faehrt, in Pixeln. Dort sitzt die rechte Hand.
@export var ziel_x: float = 480.0
# Wie weit zwei haengende Fliegen nebeneinander auseinander sind, in Pixeln.
@export var abstand: float = 110.0
# Der Arm: linke Hand, Kanone und Muendung. Nur er faehrt, die Kamera bleibt stehen.
@export var arm: Node2D
# Die Mitte der Reihe am oberen Bildrand, in der die gefangenen Fliegen haengen.
@export var haken: Node2D

# true heisst: Gerade laeuft eine Uebergabe. Die Kanone faehrt und schiesst dann nicht.
var laeuft: bool = false
# Nadeln mit Fliege, die noch uebergeben werden muessen, der Reihe nach.
var warteschlange: Array[Node2D] = []
# Wie viele Fliegen schon in der Reihe haengen.
var anzahl: int = 0


func starten(nadel: Node2D) -> void:
	nadel.reparent(haken)
	warteschlange.append(nadel)
	if not laeuft:
		uebergeben()


func uebergeben() -> void:
	laeuft = true
	while warteschlange.size() > 0:
		var nadel: Node2D = warteschlange.pop_front()
		var hin: Tween = create_tween()
		hin.tween_property(arm, "position", Vector2(ziel_x, 0.0), dauer)
		hin.parallel().tween_property(nadel, "position", platz(anzahl), dauer - verzoegerung).set_delay(verzoegerung)
		await hin.finished
		anzahl += 1
		angekommen.emit(nadel.fliege.flugkraft)
		var zurueck: Tween = create_tween()
		zurueck.tween_property(arm, "position", Vector2.ZERO, dauer)
		await zurueck.finished
	laeuft = false


func platz(nummer: int) -> Vector2:
	var schritte: float = ceilf(nummer / 2.0)
	var seite: float = 1.0
	if nummer % 2 == 0:
		seite = -1.0
	return Vector2(seite * schritte * abstand, 0.0)
