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
@export var halte_anteil: float = 0.4
# Der Wurf: Am Ende der Hinfahrt hebt die Kanone so viele Pixel an und kippt um so viele Grad zur Hand hin.
# Mit diesem Schwung wirft sie das Seil in die Hand.
@export var wurf_hoehe: float = 110.0
@export var wurf_winkel: float = 28.0
# Wie das Seil auf die Fahrt der Kanone antwortet. Am Anfang bleibt es zurueck und biegt sich von der Hand weg:
# gegen_schwung sagt, wie stark (0 heisst gar nicht). Erst ab diesem Anteil der Hinfahrt (schwung_ab) schwingt es zur Hand hinueber.
@export var gegen_schwung: float = 0.0
@export var schwung_ab: float = 0.6

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
		hin.tween_property(arm, "position:x", ziel_x, dauer)
		# Der Wurf: In der zweiten Haelfte der Hinfahrt hebt die Kanone an und kippt zur Hand. Erst langsam, dann schnell (EASE_IN).
		hin.parallel().tween_property(arm, "position:y", -wurf_hoehe, dauer / 2.0).set_delay(dauer / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		hin.parallel().tween_property(arm, "rotation", deg_to_rad(wurf_winkel), dauer / 2.0).set_delay(dauer / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var ziel: Vector2 = faecher.platz(nadel)
		hin.parallel().tween_property(nadel, "position:y", ziel.y, fahrzeit / 2.0).set_delay(verzoegerung)
		hin.parallel().tween_property(nadel, "position:x", ziel.x, fahrzeit / 2.0).set_delay(verzoegerung + fahrzeit / 2.0)
		hin.parallel().tween_property(nadel, "scale", Vector2.ONE * faecher.groesse(), fahrzeit).set_delay(verzoegerung)
		# Das Seil antwortet auf die Fahrt: erst bleibt es zurueck, am Ende schwingt es in die Hand (schwung_setzen).
		# tween_method ruft die Funktion in jedem Bild mit einer Zahl von 0 (Anfang der Hinfahrt) bis 1 (Ende) auf.
		nadel.schwung_punkt = griff
		hin.parallel().tween_method(schwung_setzen.bind(nadel), 0.0, 1.0, dauer)
		await hin.finished
		# Ein Hindernis kann die Nadel in der Zwischenzeit abgeschossen haben, dann gibt es sie nicht mehr.
		if not is_instance_valid(nadel):
			arm.position.y = 0.0
			arm.rotation = 0.0
			continue
		nadel.haengt = true
		# Die Kanone faehrt zurueck, senkt sich wieder und richtet sich auf. Das Seil laeuft durch die Hand und haengt noch am Lauf.
		var zurueck: Tween = fahrt_anlegen()
		zurueck.tween_property(arm, "position", Vector2.ZERO, dauer)
		zurueck.parallel().tween_property(arm, "rotation", 0.0, dauer)
		var draht: Tween = fahrt_anlegen()
		draht.tween_interval(dauer * halte_anteil)
		draht.tween_callback(vom_lauf_loesen.bind(nadel))
		await zurueck.finished
	laeuft = false


# Stellt ein, wie weit das Seil zur Hand geschwungen ist. anteil: wie viel der Hinfahrt schon vorbei ist (0 bis 1).
# Am Anfang faehrt die Kanone los, und das Seil bleibt zurueck: Es biegt sich von der Hand weg (schwung unter 0),
# am staerksten in der Mitte dieser Zeit, dann wieder weniger (sin). Ab schwung_ab kommt der Wurf: Das Seil schwingt
# zur Hand hinueber, erst langsam, dann schnell (rest * rest), bis es bei 1 genau durch die Hand laeuft.
func schwung_setzen(anteil: float, nadel: Node2D) -> void:
	if not is_instance_valid(nadel):
		return
	if anteil < schwung_ab:
		nadel.schwung = -gegen_schwung * sin(PI * anteil / schwung_ab)
	else:
		var rest: float = (anteil - schwung_ab) / (1.0 - schwung_ab)
		nadel.schwung = rest * rest


# Der Draht sitzt fest in der Hand: Er loest sich vom Lauf, und sein Ende faellt als Seil unter die Hand (nadel.gd, rest_abwerfen).
func vom_lauf_loesen(nadel: Node2D) -> void:
	if is_instance_valid(nadel):
		nadel.rest_abwerfen(griff)
