extends Node2D

# Bei so viel Flugkraft ist man im All.
@export var ziel: int = 100
# Wie viele Pixel man fuer einen Punkt Flugkraft steigt.
@export var hoehe_je_flugkraft: float = 300.0
# Wie lange das Gleiten nach oben dauert, in Sekunden.
@export var steigdauer: float = 0.8
# Wie schnell man abstuerzt, in Pixeln pro Sekunde. Wer mehr verliert, faellt tiefer und darum laenger.
# Ein Hindernis faellt beim Absturz um dieses Tempo schneller mit (hindernis.gd, fallen), sonst holte der Faecher es ein.
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
# Bei einem Absturz, der nicht bis zum Boden geht: So weit kommt der fallende Forscher von unten ins Bild, in Pixeln.
@export var koerper_einflug: float = 1600.0
# Welcher Anteil des Absturzes fuer das Hereinkommen gebraucht wird. Genauso lang dauert am Ende das Hinausgehen.
@export var koerper_anteil: float = 0.3
# Wie gross der haengende Forscher im Flug ist. In der Totale ist er 0.935 gross. Im Flug ist auf seinen Arm herangezoomt:
# Bei 1.9 sieht man nur Hand, Unterarm und ein Stueck Aermel, der Kopf liegt knapp unter dem unteren Bildrand.
@export var hand_groesse: float = 1.9
# Wie lange die Kanone braucht, um von unten ins Bild zu kommen, in Sekunden, und wie tief sie davor steht, in Pixeln.
@export var kanone_dauer: float = 0.4
@export var kanone_tiefe: float = 450.0

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
# Wie weit die Einstellungsfliege am Anfang rechts von der Kanone steht, in Pixeln. Wird in _ready gemessen.
var fliege_abstand: float = 0.0
# Wo der Forscher (Knoten Aufstehen) unten unter der Kanone steht. Wird in _ready gemerkt, dorthin kehrt er zurueck.
var koerper_unten: float = 0.0
# Die Fahrt des fallenden Forschers ins Bild und wieder hinaus. null heisst: Es gab noch keine.
var koerperfahrt: Tween = null
# true heisst: Die Kanone des Spiels ist von unten ins Bild gekommen. Vorher ist sie unsichtbar.
var kanone_da: bool = false
# Die Fahrt der Hand in die Ecke oben rechts. null heisst: Es gab noch keine.
var einzug: Tween = null


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
	# Im Editor ist der Forscher sichtbar, damit man ihn hinziehen kann. Im Spiel erst beim Absturz.
	$Kanone/Aufstehen.visible = false
	# Der haengende Forscher erscheint erst beim ersten Treffer (start_totale.gd, anhaengen).
	$Kanone/Haenger.visible = false
	koerper_unten = $Kanone/Aufstehen.position.y
	$Kanone.set_process(false)
	$Hindernisse.set_process(false)
	fliege_abstand = $Einstellungsfliege.position.x - $Kanone.position.x
	anzeige_schreiben()


func _process(delta: float) -> void:
	# Die Fahrt der Hand wird hier von Hand weitergestellt (wie der Ablauf in start_totale.gd): Dieses Skript
	# ist als erstes dran, also stehen Hand und Nadel schon richtig, wenn die Nadel danach ihren Draht spannt.
	if einzug != null and einzug.is_valid():
		einzug.custom_step(delta)
	if wackel_zeit > 0.0:
		wackel_zeit -= delta
		$Kanone/Kamera.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * wackel_staerke
	else:
		$Kanone/Kamera.position = Vector2.ZERO
	# Die Wiese und die Einstellungsfliege fahren zur Seite mit der Kanone mit. So landet man immer an derselben Stelle.
	$Boden.scroll_offset.x = $Kanone.position.x
	$Einstellungsfliege.position.x = $Kanone.position.x + fliege_abstand


func wackeln(staerke: float, dauer: float) -> void:
	wackel_staerke = staerke
	wackel_zeit = dauer


# Das Ende der Totale: Die Kamera faehrt nach oben und zoomt auf den Arm des haengenden Forschers.
# Sein Kanonenarm schwenkt dabei weg. Erst wenn die Hand oben rechts sitzt, kommt die Kanone des Spiels von unten.
# nadel ist die Nadel mit der ersten Fliege. null heisst: Es gibt keine (Testsprung).
func losgehen(nadel: Node2D = null) -> void:
	$Kanone/RechteHand.visible = true
	$Musik.laut()
	$Kanone/Figur.wegschwenken(steigdauer)
	var haenger: Node2D = $Kanone/Haenger
	haenger.visible = true
	if not haenger.pendelt:
		haenger.anstossen()
	# Die Hand gleitet an den Griff oben rechts (dort haengen die Faeden), und der Forscher wird so gross,
	# dass nur noch sein Arm im Bild ist. Das dauert so lange wie die Kamerafahrt.
	einzug = create_tween()
	einzug.pause()
	einzug.tween_property(haenger, "position", $Kanone/Griff.position, steigdauer)
	einzug.parallel().tween_property(haenger.get_node("Inhalt"), "scale", Vector2.ONE * hand_groesse, steigdauer)
	if nadel != null:
		$Kanone/Uebergabe.erste(nadel, einzug, steigdauer)
	einzug.tween_callback(kanone_kommt)


# Die Hand sitzt: Der Kanonenarm der Figur ist weg, die Kanone des Spiels kommt von unten in die Mitte.
func kanone_kommt() -> void:
	$Kanone/Figur.ausschalten()
	kanone_da = true
	$Kanone/Arm.position.y = kanone_tiefe
	$Kanone/Arm.visible = true
	var hoch: Tween = create_tween()
	hoch.tween_property($Kanone/Arm, "position:y", 0.0, kanone_dauer)
	hoch.tween_callback(spielen)


# Die Kanone steht: Ab jetzt faehrt und schiesst sie, und die Hindernisse kommen.
func spielen() -> void:
	$Kanone.set_process(true)
	$Hindernisse.set_process(true)


# Wird von der Figur gerufen, wenn die Einstiegs-Sequenz nach dem ersten Treffer vorbei ist. Mit dabei: die Nadel mit der Fliege.
# Ihr Draht steckt schon in der Hand des Forschers (start_totale.gd, in_der_hand).
func erster_fang(nadel: Node2D) -> void:
	losgehen(nadel)


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
		fallen()
		kamera_fahren(zoom_totale, versatz_totale, strecke / falltempo)
		$Musik.leise()
	else:
		steigen.tween_callback(entsperren)
		zwischenfall(strecke / falltempo)


# Ein Absturz, der nicht bis zum Boden geht: Der fallende Forscher kommt von unten ins Bild
# und verschwindet kurz vor dem Ende des Absturzes wieder nach unten. Die Kanone bleibt zu sehen.
func zwischenfall(dauer: float) -> void:
	var koerper: AnimatedSprite2D = $Kanone/Aufstehen
	koerper_zuruecksetzen()
	koerper.visible = true
	koerper.play("fallen")
	# Waehrenddessen haengt niemand an der Hand, sonst saehe man den Forscher zweimal.
	$Kanone/Haenger.visible = false
	koerperfahrt = create_tween()
	koerperfahrt.tween_property(koerper, "position:y", koerper_unten - koerper_einflug, dauer * koerper_anteil)
	koerperfahrt.tween_interval(dauer * (1.0 - 2.0 * koerper_anteil))
	koerperfahrt.tween_property(koerper, "position:y", koerper_unten, dauer * koerper_anteil)
	koerperfahrt.tween_callback(koerper.hide)
	koerperfahrt.tween_callback($Kanone/Haenger.show)


# Haelt eine laufende Fahrt des Forschers an und stellt ihn wieder unten hin.
func koerper_zuruecksetzen() -> void:
	if koerperfahrt != null:
		koerperfahrt.kill()
	$Kanone/Aufstehen.position.y = koerper_unten


# Der Absturz bis auf den Boden: Statt Kanone und Figur faellt der Forscher, bis er aufschlaegt.
func fallen() -> void:
	koerper_zuruecksetzen()
	$Kanone/Arm.visible = false
	$Kanone/Figur.visible = false
	$Kanone/Haenger.visible = false
	$Kanone/Aufstehen.visible = true
	$Kanone/Aufstehen.play("fallen")


func aufstehen() -> void:
	$Kanone/Arm.visible = false
	$Kanone/Figur.visible = false
	$Kanone/Aufstehen.visible = true
	$Kanone/Aufstehen.play("aufstehen")
	$Bedienung/Absturz.visible = true
	$Ton/Aufstehen.play()
	wackeln(wackeln_aufprall, aufprall_dauer)


func aufstehen_abbrechen() -> void:
	koerper_zuruecksetzen()
	$Kanone/Aufstehen.stop()
	$Kanone/Aufstehen.visible = false
	$Kanone/Figur.visible = true
	# Die Kanone gibt es erst, wenn sie nach dem ersten Fang von unten gekommen ist.
	$Kanone/Arm.visible = kanone_da
	$Bedienung/Absturz.visible = false
	# Nach dem ersten Treffer haengt der Forscher wieder an der Hand (beim ersten Fang macht das hand_in_die_ecke).
	if not $Kanone/Figur.aktiv:
		$Kanone/Haenger.visible = true


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
