extends "res://skripte/fliege.gd"

# Die Teleport-Fliege: fliegt hin und her. Kommt die Kanone unter sie, flackert sie kurz und springt zur Seite.
# Sobald sie flackert, ist sie schon entkommen: Die Nadel fliegt durch sie hindurch. Das Flackern ist nur zum Ansehen.
# Das kann sie ein paarmal hintereinander, dann muss sie sich erholen. In dieser Pause kann man sie fangen.
# Wie viele Spruenge sie noch hat, sieht man am Schimmer um sie herum und hoert man an ihrem Summen:
# Mit jedem Sprung wird der Schimmer schwaecher und das Summen tiefer.
# Ist der Schimmer ganz weg, erholt sie sich, und beides kommt langsam zurueck.

# Wie weit die Fliege von ihrer Mitte nach links und nach rechts fliegt, in Pixeln.
@export var strecke: float = 150.0
# Wie nah die Kanone seitlich unter ihr sein muss, damit sie springt, in Pixeln.
@export var ausloese_weite: float = 120.0
# Wie oft sie hintereinander springen kann, bevor sie sich erholen muss.
@export var spruenge: int = 3
# Wie viele Sekunden sie sich danach erholt. So lange springt sie nicht.
@export var erholzeit: float = 5.0
# Wie viele Sekunden vor dem Sprung sie flackert.
@export var flacker_zeit: float = 0.2
# Wie lange ein Flackern dauert, in Sekunden: die Haelfte davon blass, die Haelfte voll.
@export var flacker_takt: float = 0.1
# Wie blass sie beim Flackern wird. 0.25 heisst: nur ein Viertel so kraeftig.
@export var flacker_blass: float = 0.25
# Wie weit sie mindestens und hoechstens springt, in Pixeln.
@export var sprung_nah: float = 200.0
@export var sprung_weit: float = 350.0
# Wie tief das Summen ohne Spruenge klingt, als Anteil ihrer eigenen Tonhoehe. 0.6 heisst: deutlich tiefer.
@export var tonhoehe_leer: float = 0.6

# Wie viele Spruenge sie noch hat. 0 heisst: Sie erholt sich gerade.
var uebrig: int = 0
# Wie viele Sekunden die Erholung noch dauert.
var erholt_in: float = 0.0
# Wie viele Sekunden sie noch flackert, bevor sie springt. 0 oder weniger heisst: Sie flackert nicht.
var flackert_noch: float = 0.0
# Ihre eigene Tonhoehe, wie sie beim Start ausgewuerfelt wurde. Davon geht das tiefere Summen aus.
var eigene_tonhoehe: float = 1.0


func losfliegen() -> void:
	uebrig = spruenge
	eigene_tonhoehe = $Summen.pitch_scale


func fliegen(delta: float) -> void:
	position.x += richtung * tempo * delta
	if position.x > mitte_x + strecke:
		richtung = -1.0
	if position.x < mitte_x - strecke:
		richtung = 1.0
	modulate.a = 1.0
	var ladung: float = ladung_jetzt()
	$Schimmer.modulate.a = ladung
	$Summen.pitch_scale = eigene_tonhoehe * lerpf(tonhoehe_leer, 1.0, ladung)
	if uebrig == 0:
		erholt_in -= delta
		if erholt_in <= 0.0:
			uebrig = spruenge
		return
	if flackert_noch > 0.0:
		flackert_noch -= delta
		if fmod(flackert_noch, flacker_takt) < flacker_takt / 2.0:
			modulate.a = flacker_blass
		if flackert_noch <= 0.0:
			springen()
		return
	if absf(position.x - kanone.position.x) < ausloese_weite:
		flackert_noch = flacker_zeit
		entkommt = true


func springen() -> void:
	var weit: float = randf_range(sprung_nah, sprung_weit)
	if randf() < 0.5:
		weit = -weit
	position.x += weit
	mitte_x += weit
	modulate.a = 1.0
	entkommt = false
	uebrig -= 1
	if uebrig == 0:
		erholt_in = erholzeit


# Wie viel Sprungkraft sie gerade hat: 1 heisst alle Spruenge, 0 heisst keiner.
# Waehrend der Erholung waechst sie gleitend von 0 bis 1.
func ladung_jetzt() -> float:
	if uebrig == 0:
		return 1.0 - erholt_in / erholzeit
	return float(uebrig) / float(spruenge)
