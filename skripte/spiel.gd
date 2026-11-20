extends Node2D

# Bei so viel Flugkraft ist man im All.
@export var ziel: int = 100
# Wie viele Pixel man fuer einen Punkt Flugkraft steigt.
@export var hoehe_je_flugkraft: float = 300.0
# Wie lange das Gleiten nach oben dauert, in Sekunden.
@export var steigdauer: float = 0.8
# Wie schnell man abstuerzt, in Pixeln pro Sekunde. Wer mehr verliert, faellt tiefer und darum laenger.
# Muss langsamer sein als ein Hindernis faellt (falltempo in hindernis.gd), sonst holt der Faecher es ein.
@export var falltempo: float = 1200.0
# Die Kamera am Boden: etwas herausgezoomt, die Kanone wirkt kleiner und man sieht den Boden.
# 0.85 heisst: alles ist 85 Prozent so gross. -447 setzt die Kanone dabei auf dieselbe Bildhoehe wie vorher (380 / 0.85).
@export var zoom_boden: float = 0.85
@export var versatz_boden: float = -447.0
# Die Kamera in der Luft: normale Groesse, die Kanone sitzt am unteren Bildrand (540 - 20 Pixel Rand).
@export var zoom_luft: float = 1.0
@export var versatz_luft: float = -520.0

# Die Flugkraft aller Fliegen, die oben im Faecher haengen.
var flugkraft: int = 0
# Das Gleiten nach oben, das gerade laeuft. null heisst: Es gab noch keins.
var steigen: Tween = null
# Die Kamerafahrt, die gerade laeuft. null heisst: Es gab noch keine.
var kamerafahrt: Tween = null


func _ready() -> void:
	$Kanone/Uebergabe.gefangen.connect(fliege_zaehlen)
	$Kanone/Faecher.verloren.connect(fliege_verlieren)
	$Kanone/Aufstehen.animation_finished.connect(neustart)
	$Kanone/RechteHand/Leiste.max_value = ziel
	$Kanone/Kamera.zoom = Vector2.ONE * zoom_boden
	$Kanone/Kamera.offset.y = versatz_boden
	anzeige_schreiben()


func fliege_zaehlen(dazu: int) -> void:
	flugkraft += dazu
	anzeige_schreiben()
	aufstehen_abbrechen()
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
		$Kanone.set_process(false)
		$Hindernisse.set_process(false)
		for hindernis in $Hindernisse.get_children():
			hindernis.queue_free()


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
	if flugkraft <= 0:
		steigen.tween_callback(aufstehen)
		kamera_fahren(zoom_boden, versatz_boden, strecke / falltempo)
	else:
		steigen.tween_callback(entsperren)


func aufstehen() -> void:
	$Kanone/Arm.visible = false
	$Kanone/Aufstehen.visible = true
	$Kanone/Aufstehen.play("aufstehen")
	$Bedienung/Absturz.visible = true
	$Ton/Aufstehen.play()


func aufstehen_abbrechen() -> void:
	$Kanone/Aufstehen.stop()
	$Kanone/Aufstehen.visible = false
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
