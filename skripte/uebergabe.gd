extends Node

# Wird gesendet, sobald eine Fliege getroffen ist, noch vor der Fahrt zur Hand. Mit dabei: ihre Flugkraft.
signal gefangen(flugkraft: int)

# Wie lange die Fahrt hinueber dauert, in Sekunden. Der Rueckweg dauert genauso lang.
@export var dauer: float = 0.48
# Wie lange die Fliege wartet, bevor sie losfaehrt, in Sekunden. Sie kommt trotzdem gleichzeitig mit dem Arm an.
@export var verzoegerung: float = 0.1
# Wie weit der Arm von der Mitte nach rechts faehrt, in Pixeln. Dort sitzt die rechte Hand.
@export var ziel_x: float = 480.0
# Der Arm: linke Hand, Kanone und Muendung. Nur er faehrt zur Seite, die Kamera und der Faecher nicht.
@export var arm: Node2D
# Der Faecher am oberen Bildrand, in dem die gefangenen Fliegen haengen.
@export var faecher: Node2D
# Der Punkt an der rechten Hand, an dem die Faeden der Fliegen im Faecher festhaengen.
@export var griff: Node2D
# Ein Punkt, der das Drahtende von der Muendung zur Hand traegt. Muss ein Kind der Kanone sein, wie der Griff.
@export var fadenpunkt: Node2D

# true heisst: Gerade laeuft eine Uebergabe. Die Kanone faehrt und schiesst dann nicht.
var laeuft: bool = false
# Nadeln mit Fliege, die noch uebergeben werden muessen, der Reihe nach.
var warteschlange: Array[Node2D] = []


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
		var hin: Tween = create_tween()
		hin.tween_property(arm, "position", Vector2(ziel_x, 0.0), dauer)
		var ziel: Vector2 = faecher.platz(nadel)
		hin.parallel().tween_property(nadel, "position:y", ziel.y, fahrzeit / 2.0).set_delay(verzoegerung)
		hin.parallel().tween_property(nadel, "position:x", ziel.x, fahrzeit / 2.0).set_delay(verzoegerung + fahrzeit / 2.0)
		hin.parallel().tween_property(nadel, "scale", Vector2.ONE * faecher.groesse(), fahrzeit).set_delay(verzoegerung)
		await hin.finished
		nadel.haengt = true
		# Das Drahtende springt nicht zur Hand: Es startet an der Muendung und wandert hinueber,
		# waehrend die Kanone zurueckfaehrt. Erst danach haengt der Draht wirklich am Griff.
		fadenpunkt.global_position = nadel.anker.global_position
		nadel.anker = fadenpunkt
		var zurueck: Tween = create_tween()
		zurueck.tween_property(arm, "position", Vector2.ZERO, dauer)
		zurueck.parallel().tween_property(fadenpunkt, "position", griff.position, dauer)
		await zurueck.finished
		# Ein Hindernis kann die Nadel in der Zwischenzeit abgeschossen haben, dann gibt es sie nicht mehr.
		if is_instance_valid(nadel):
			nadel.anker = griff
	laeuft = false
