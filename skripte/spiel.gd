extends Node2D

# Bei so viel Flugkraft ist man im All.
@export var ziel: int = 100
# Wie viele Pixel man fuer einen Punkt Flugkraft steigt.
@export var hoehe_je_flugkraft: float = 300.0
# Wie lange das Gleiten nach oben dauert, in Sekunden.
@export var steigdauer: float = 0.8
# Wie schnell man abstuerzt, in Pixeln pro Sekunde. Wer mehr verliert, faellt tiefer und darum laenger.
# Muss langsamer sein als ein Hindernis faellt (falltempo in hindernis.gd), sonst holt der Faecher es ein.
@export var falltempo: float = 2400.0
# Wie stark die Kamera beim Fallen und beim Aufprall auf dem Boden wackelt, hoechstens so viele Pixel zur Seite.
@export var wackeln_fall: float = 5.0
@export var wackeln_aufprall: float = 28.0
# Wie lange das Wackeln beim Aufprall dauert, in Sekunden.
@export var aufprall_dauer: float = 0.4
# Die Kamera in der Totale am Boden: weit herausgezoomt, man sieht die ganze Figur auf der Wiese.
# 0.43 heisst: alles ist 43 Prozent so gross, das Bild zeigt 2512 Pixel Hoehe. 584 schiebt die Bildmitte so weit
# unter die Kanone, dass die Fuesse (1212 unter der Kanone) auf drei Vierteln der Bildhoehe stehen (1212 - 2512 / 4).
@export var zoom_totale: float = 0.43
@export var versatz_totale: float = 584.0
# Die Kamera in der Luft: normale Groesse, die Kanone sitzt am unteren Bildrand (540 - 20 Pixel Rand).
@export var zoom_luft: float = 1.0
@export var versatz_luft: float = -520.0

# Die Flugkraft aller Fliegen, die oben im Faecher haengen.
var flugkraft: int = 0
# Das Gleiten nach oben, das gerade laeuft. null heisst: Es gab noch keins.
var steigen: Tween = null
# Die Kamerafahrt, die gerade laeuft. null heisst: Es gab noch keine.
var kamerafahrt: Tween = null
# Wie stark die Kamera gerade wackelt, in Pixeln.
var wackel_staerke: float = 0.0
# Wie viele Sekunden sie noch wackelt. 0 oder weniger heisst: Sie steht still.
var wackel_zeit: float = 0.0


func _ready() -> void:
	$Kanone/Uebergabe.gefangen.connect(fliege_zaehlen)
	$Kanone/Figur.spielstart.connect(erster_fang)
	$Kanone/Faecher.verloren.connect(fliege_verlieren)
	$Kanone/Aufstehen.animation_finished.connect(neustart)
	$Kanone/RechteHand/Leiste.max_value = ziel
	$Kanone/Kamera.zoom = Vector2.ONE * zoom_totale
	$Kanone/Kamera.offset.y = versatz_totale
	$Kanone/Arm.visible = false
	$Kanone/RechteHand.visible = false
	$Kanone.set_process(false)
	$Hindernisse.set_process(false)
	anzeige_schreiben()


func _process(delta: float) -> void:
	if wackel_zeit > 0.0:
		wackel_zeit -= delta
		$Kanone/Kamera.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * wackel_staerke
	else:
		$Kanone/Kamera.position = Vector2.ZERO


func wackeln(staerke: float, dauer: float) -> void:
	wackel_staerke = staerke
	wackel_zeit = dauer


# Das Ende der Totale: Die Figur gibt ab, ab jetzt faehrt und schiesst die Kanone, und die Hindernisse kommen.
func losgehen() -> void:
	$Kanone/Figur.ausschalten()
	$Kanone/Arm.visible = true
	$Kanone/RechteHand.visible = true
	$Kanone.set_process(true)
	$Hindernisse.set_process(true)
	$Musik.laut()


# Wird von der Figur gerufen, wenn die Einstiegs-Sequenz nach dem ersten Treffer vorbei ist. Mit dabei: die Nadel mit der Fliege.
func erster_fang(nadel: Node2D) -> void:
	losgehen()
	nadel.anker = $Kanone/Arm/Muendung
	$Kanone/Uebergabe.starten(nadel)


func fliege_zaehlen(dazu: int) -> void:
	flugkraft += dazu
	anzeige_schreiben()
	aufstehen_abbrechen()
	wackel_zeit = 0.0
	$Kanone.steigt = true
	$Ton/Steigen.play()
	if steigen != null:
		steigen.kill()
	steigen = create_tween()
	steigen.tween_property($Kanone, "position:y", -flugkraft * hoehe_je_flugkraft, steigdauer)
	steigen.tween_callback(entsperren)
	kamera_fahren(zoom_luft, versatz_luft, steigdauer)
	if flugkraft >= ziel:
		$Bedienung/Sieg.visible = true
		$Ton/Sieg.play()
		$Musik.ende_spielen()
		$Kanone.set_process(false)
		$Hindernisse.set_process(false)
		for hindernis in $Hindernisse.get_children():
			hindernis.queue_free()


# Nur zum Testen (test_sprung.gd): setzt die Flugkraft auf einen Wert und faehrt dorthin, als haette man gerade gefangen.
func springen(auf: int) -> void:
	flugkraft = auf
	losgehen()
	$Erzeuger.schwarm_aufloesen()
	fliege_zaehlen(0)


func fliege_verlieren(weg: int) -> void:
	flugkraft -= weg
	anzeige_schreiben()
	if steigen != null:
		steigen.kill()
	var neue_hoehe: float = -flugkraft * hoehe_je_flugkraft
	var strecke: float = absf(neue_hoehe - $Kanone.position.y)
	$Kanone.gesperrt = true
	$Kanone.steigt = false
	$Ton/Absturz.play()
	steigen = create_tween()
	steigen.tween_property($Kanone, "position:y", neue_hoehe, strecke / falltempo)
	wackeln(wackeln_fall, strecke / falltempo)
	if flugkraft <= 0:
		steigen.tween_callback(aufstehen)
		kamera_fahren(zoom_totale, versatz_totale, strecke / falltempo)
		$Musik.leise()
	else:
		steigen.tween_callback(entsperren)


func aufstehen() -> void:
	$Kanone/Arm.visible = false
	$Kanone/Figur.visible = false
	$Kanone/Aufstehen.visible = true
	$Kanone/Aufstehen.play("aufstehen")
	$Bedienung/Absturz.visible = true
	$Ton/Aufstehen.play()
	wackeln(wackeln_aufprall, aufprall_dauer)


func aufstehen_abbrechen() -> void:
	$Kanone/Aufstehen.stop()
	$Kanone/Aufstehen.visible = false
	$Kanone/Figur.visible = true
	$Kanone/Arm.visible = true
	$Bedienung/Absturz.visible = false


func neustart() -> void:
	get_tree().reload_current_scene()


func kamera_fahren(zoom: float, versatz: float, dauer: float) -> void:
	if kamerafahrt != null:
		kamerafahrt.kill()
	kamerafahrt = create_tween()
	kamerafahrt.set_parallel(true)
	kamerafahrt.tween_property($Kanone/Kamera, "zoom", Vector2.ONE * zoom, dauer)
	kamerafahrt.tween_property($Kanone/Kamera, "offset:y", versatz, dauer)


func entsperren() -> void:
	$Kanone.gesperrt = false
	$Kanone.steigt = false


func anzeige_schreiben() -> void:
	$Kanone/RechteHand/Leiste.value = flugkraft
