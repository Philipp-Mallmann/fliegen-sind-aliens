extends Node

# Wird gesendet, sobald eine Fliege getroffen ist, noch vor der Fahrt zur Hand. Mit dabei: ihre Flugkraft.
signal gefangen(flugkraft: int)

# Wie lange die Fahrt hinueber dauert, in Sekunden. Der Rueckweg dauert genauso lang.
@export var dauer: float = 0.48
# Wie lange die Fliege wartet, bevor sie losfaehrt, in Sekunden. Sie kommt trotzdem gleichzeitig mit dem Arm an.
@export var verzoegerung: float = 0.1
# Wie weit der Arm von der Mitte nach rechts faehrt, in Pixeln: bis unter die Hand und ein Stueck weiter.
@export var ziel_x: float = 540.0
# Der Arm: linke Hand, Kanone und Muendung. Nur er faehrt zur Seite, die Kamera und der Faecher nicht.
@export var arm: Node2D
# Der Faecher am oberen Bildrand, in dem die gefangenen Fliegen haengen.
@export var faecher: Node2D
# Der Punkt an der rechten Hand, an dem die Faeden der Fliegen im Faecher festhaengen.
@export var griff: Node2D
# Wie lange der Draht auf der Rueckfahrt noch am Lauf haengt, als Anteil der Rueckfahrt. Danach loest er sich.
@export var halte_anteil: float = 0.25

# true heisst: Gerade laeuft eine Uebergabe. Die Kanone faehrt und schiesst dann nicht.
var laeuft: bool = false
# Nadeln mit Fliege, die noch uebergeben werden muessen, der Reihe nach.
var warteschlange: Array[Node2D] = []
# Die Fahrten, die gerade laufen. Sie werden in _process von Hand weitergestellt.
var fahrten: Array[Tween] = []


# Dieses Skript ist in jedem Bild vor den Nadeln dran (kleinere Zahl heisst frueher).
func _ready() -> void:
	process_priority = -1


# Godot stellt Tweens erst nach allen _process-Funktionen weiter. Dann haette die Nadel ihren Draht schon gespannt,
# und die Kanone waere danach ein Stueck weitergefahren: eine Luecke am Lauf. Darum werden die Fahrten hier weitergestellt.
func _process(delta: float) -> void:
	for fahrt in fahrten.duplicate():
		if fahrt.is_valid():
			fahrt.custom_step(delta)
		else:
			fahrten.erase(fahrt)


# Legt eine Fahrt an, die nicht von selbst laeuft, sondern in _process weitergestellt wird.
func fahrt_anlegen() -> Tween:
	var fahrt: Tween = create_tween()
	fahrt.pause()
	fahrten.append(fahrt)
	return fahrt


func starten(nadel: Node2D) -> void:
	nadel.reparent(faecher)
	gefangen.emit(nadel.flugkraft())
	# Zeigt "+N" und bei mehreren Fliegen das Kombo-Wort (punktanzeige.gd).
	get_tree().call_group("punktanzeige", "gefangen", nadel)
	warteschlange.append(nadel)
	if not laeuft:
		uebergeben()


# Der erste Fang aus der Totale: Der Draht steckt schon in der Hand des Forschers, die Kanone faehrt nicht hinueber.
# Die Nadel gleitet nur an ihren Platz im Faecher. Das wird an die Fahrt der Hand (fahrt, aus spiel.gd) angehaengt,
# damit Nadel, Hand und Draht im selben Bild zusammenpassen.
func erste(nadel: Node2D, fahrt: Tween, fahrzeit: float) -> void:
	nadel.reparent(faecher)
	gefangen.emit(nadel.flugkraft())
	get_tree().call_group("punktanzeige", "gefangen", nadel)
	faecher.aufnehmen(nadel)
	fahrt.parallel().tween_property(nadel, "position", faecher.platz(nadel), fahrzeit)
	fahrt.parallel().tween_property(nadel, "scale", Vector2.ONE * faecher.groesse(), fahrzeit)
	fahrt.tween_callback(erste_haengt.bind(nadel))


# Die erste Nadel ist an ihrem Platz: Sie haengt jetzt wie alle anderen am Griff.
func erste_haengt(nadel: Node2D) -> void:
	if is_instance_valid(nadel):
		nadel.haengt = true
		nadel.anker = griff


func uebergeben() -> void:
	laeuft = true
	while warteschlange.size() > 0:
		var nadel: Node2D = warteschlange.pop_front()
		faecher.aufnehmen(nadel)
		$TonArm.play()
		var fahrzeit: float = dauer - verzoegerung
		var hin: Tween = fahrt_anlegen()
		hin.tween_property(arm, "position", Vector2(ziel_x, 0.0), dauer)
		var ziel: Vector2 = faecher.platz(nadel)
		hin.parallel().tween_property(nadel, "position:y", ziel.y, fahrzeit / 2.0).set_delay(verzoegerung)
		hin.parallel().tween_property(nadel, "position:x", ziel.x, fahrzeit / 2.0).set_delay(verzoegerung + fahrzeit / 2.0)
		hin.parallel().tween_property(nadel, "scale", Vector2.ONE * faecher.groesse(), fahrzeit).set_delay(verzoegerung)
		# In der zweiten Haelfte der Hinfahrt nimmt die Kanone das Seil mit hoch zur Hand: Wenn sie ankommt, liegt es darin.
		nadel.schwung_punkt = griff
		hin.parallel().tween_property(nadel, "schwung", 1.0, dauer / 2.0).set_delay(dauer / 2.0)
		await hin.finished
		# Ein Hindernis kann die Nadel in der Zwischenzeit abgeschossen haben, dann gibt es sie nicht mehr.
		if not is_instance_valid(nadel):
			continue
		nadel.haengt = true
		# Die Kanone faehrt zurueck. Der Draht laeuft durch die Hand und haengt noch am Lauf, bis er fest sitzt.
		var zurueck: Tween = fahrt_anlegen()
		zurueck.tween_property(arm, "position", Vector2.ZERO, dauer)
		var draht: Tween = fahrt_anlegen()
		draht.tween_interval(dauer * halte_anteil)
		draht.tween_callback(vom_lauf_loesen.bind(nadel))
		await zurueck.finished
	laeuft = false


# Der Draht sitzt fest in der Hand: Er loest sich vom Lauf, und sein Ende faellt als Seil unter die Hand (nadel.gd, rest_abwerfen).
func vom_lauf_loesen(nadel: Node2D) -> void:
	if is_instance_valid(nadel):
		nadel.rest_abwerfen(griff)
