extends Node2D

# Wie weit zwei Fliegen im Faecher auseinander sind, solange er noch nicht schrumpfen muss, in Pixeln.
@export var abstand: float = 110.0
# Wie breit der Faecher hoechstens werden darf, in Pixeln. Das Bild ist 1440 breit.
@export var breite: float = 1400.0
# Wie lange das Zusammenruecken und Schrumpfen dauert, in Sekunden. Lang heisst: man merkt es kaum.
@export var gleitdauer: float = 1.5
# Wie weit eine Fliege hoechstens ueber oder unter der Linie haengt, in Pixeln. Macht den Faecher natuerlicher.
@export var hoehen_streuung: float = 20.0

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
	if gleiten != null:
		gleiten.kill()
	if reihe.size() == 1:
		return
	gleiten = create_tween()
	gleiten.set_parallel(true)
	for nadel in reihe:
		if nadel == neue:
			continue
		gleiten.tween_property(nadel, "position", platz(nadel), gleitdauer)
		gleiten.tween_property(nadel, "scale", Vector2.ONE * groesse(), gleitdauer)


func groesse() -> float:
	return minf(1.0, breite / (reihe.size() * abstand))


func platz(nadel: Node2D) -> Vector2:
	var nummer: int = reihe.find(nadel)
	var mitte: float = (reihe.size() - 1) / 2.0
	return Vector2((nummer - mitte) * abstand * groesse(), versatz[nadel])
