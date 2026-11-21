extends Node2D

# Wird gesendet, wenn eine Fliege aus dem Faecher entfernt wurde. Mit dabei: ihre Flugkraft.
signal verloren(flugkraft: int)

# Wie weit zwei Fliegen im Faecher auseinander sind, solange er noch nicht schrumpfen muss, in Pixeln. Unter 100 ueberlappen sie sich leicht.
@export var abstand: float = 90.0
# Wie breit der Faecher hoechstens werden darf, in Pixeln. Das Bild ist 1440 breit, 1152 laesst je ein Zehntel (144) Rand.
@export var breite: float = 1152.0
# Wie lange das Zusammenruecken und Schrumpfen dauert, in Sekunden. Lang heisst: man merkt es kaum.
@export var gleitdauer: float = 1.5
# Wie weit eine Fliege hoechstens ueber oder unter der Linie haengt, in Pixeln. Macht den Faecher natuerlicher.
@export var hoehen_streuung: float = 30.0

# Wie weit die untere Reihe unter der oberen haengt, in Pixeln. Die Fliegen haengen im Zickzack: abwechselnd oben und unten.
@export var reihen_abstand: float = 90.0

# Die Nadeln mit Fliege, die im Faecher haengen, von links nach rechts.
var reihe: Array[Node2D] = []
# Fuer jede Nadel ihr eigener Hoehenunterschied. Wird einmal beim Aufnehmen ausgewuerfelt.
var versatz: Dictionary = {}
# Das Gleiten, das gerade laeuft. null heisst: Es gab noch keins.
var gleiten: Tween = null


func aufnehmen(neue: Node2D) -> void:
	versatz[neue] = randf_range(-hoehen_streuung, hoehen_streuung)
	if reihe.size() % 2 == 0:
		reihe.push_front(neue)
	else:
		reihe.push_back(neue)
	nachruecken()


func entfernen(nadel: Node2D) -> void:
	reihe.erase(nadel)
	versatz.erase(nadel)
	verloren.emit(nadel.flugkraft())
	nachruecken()


func nachruecken() -> void:
	if gleiten != null:
		gleiten.kill()
	var haengende: Array[Node2D] = []
	for nadel in reihe:
		if nadel.haengt:
			haengende.append(nadel)
	if haengende.is_empty():
		return
	gleiten = create_tween()
	gleiten.set_parallel(true)
	for nadel in haengende:
		gleiten.tween_property(nadel, "position", platz(nadel), gleitdauer)
		gleiten.tween_property(nadel, "scale", Vector2.ONE * groesse(), gleitdauer)


func groesse() -> float:
	return minf(1.0, breite / (reihe.size() * abstand / 2.0))


func platz(nadel: Node2D) -> Vector2:
	var nummer: int = reihe.find(nadel)
	var mitte: float = (reihe.size() - 1) / 2.0
	var unten: float = 0.0
	if nummer % 2 == 1:
		unten = reihen_abstand
	return Vector2((nummer - mitte) * abstand / 2.0 * groesse(), unten + versatz[nadel])
