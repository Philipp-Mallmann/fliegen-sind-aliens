extends "res://skripte/fliege.gd"

# Die Teleport-Fliege: fliegt hin und her. Kommt die Kanone unter sie, glitcht sie weg und taucht an anderer Stelle wieder auf.
# Sobald sie glitcht, ist sie schon entkommen: Die Nadel fliegt durch sie hindurch. Der Glitch ist nur zum Ansehen.
# Das kann sie ein paarmal hintereinander, dann muss sie sich erholen. In dieser Pause kann man sie fangen.
# Wie viele Spruenge sie noch hat, sieht man an den Leuchtringen um ihren Umriss und hoert man an ihrem Summen:
# Jeder Sprung kostet den aeussersten Ring, und das Summen wird tiefer.
# Sind alle Ringe weg, erholt sie sich: Die Ringe kommen einer nach dem anderen zurueck, von innen nach aussen.

# Wie weit die Fliege von ihrer Mitte nach links und nach rechts fliegt, in Pixeln.
@export var strecke: float = 150.0
# Wie nah die Kanone seitlich unter ihr sein muss, damit sie springt, in Pixeln.
@export var ausloese_weite: float = 120.0
# Wie oft sie hintereinander springen kann, bevor sie sich erholen muss.
@export var spruenge: int = 3
# Wie viele Sekunden sie sich danach erholt. So lange springt sie nicht.
@export var erholzeit: float = 4.0
# Wie viele Sekunden vor dem Sprung sie weg-glitcht. In dieser Zeit wird der Glitch immer staerker (shader/glitch.gdshader).
@export var flacker_zeit: float = 0.2
# Wie viele Sekunden sie nach dem Sprung braucht, bis sie wieder ganz da ist. Der Glitch wird dabei schwaecher.
@export var auftauch_zeit: float = 0.15
# Wie weit sie mindestens und hoechstens springt, in Pixeln.
@export var sprung_nah: float = 200.0
@export var sprung_weit: float = 350.0
# Wie tief das Summen ohne Spruenge klingt, als Anteil ihrer eigenen Tonhoehe. 0.6 heisst: deutlich tiefer.
@export var tonhoehe_leer: float = 0.6
# Die Farben der drei Leuchtringe, von innen nach aussen. Aus ihrem eigenen Bild gemessen: Gruen vom Koerper,
# Blau von den Beinen, Violett vom Hinterleib.
@export var leucht_farben: Array[Color] = [Color(0.44, 0.69, 0.27), Color(0.44, 0.5, 0.78), Color(0.48, 0.28, 0.6)]

# Wie kraeftig die Ringe hoechstens sind. 1 heisst voll, 0.5 halb durchsichtig.
@export var leucht_deckkraft: float = 0.55

# Wie viele Spruenge sie noch hat. 0 heisst: Sie erholt sich gerade.
var uebrig: int = 0
# Wie viele Sekunden die Erholung noch dauert.
var erholt_in: float = 0.0
# Wie viele Sekunden sie noch weg-glitcht, bevor sie springt. 0 oder weniger heisst: Sie glitcht nicht.
var flackert_noch: float = 0.0
# Wie viele Sekunden sie nach dem Sprung noch auftaucht. 0 oder weniger heisst: Sie ist ganz da.
var taucht_noch: float = 0.0
# Ihre eigene Tonhoehe, wie sie beim Start ausgewuerfelt wurde. Davon geht das tiefere Summen aus.
var eigene_tonhoehe: float = 1.0


func losfliegen() -> void:
	uebrig = spruenge
	eigene_tonhoehe = $Summen.pitch_scale
	# Die Ringe sofort einfaerben. Sonst sind sie weiss, bis sie das erste Mal frei fliegt:
	# Eine Fliege, die gerade ins Bild hereinflieht, ruft fliegen() noch nicht auf.
	leuchten_zeigen(ladung_jetzt())


func fliegen(delta: float) -> void:
	position.x += richtung * tempo * delta
	if position.x > mitte_x + strecke:
		richtung = -1.0
	if position.x < mitte_x - strecke:
		richtung = 1.0
	glitchen(0.0)
	if taucht_noch > 0.0:
		taucht_noch -= delta
		glitchen(taucht_noch / auftauch_zeit)
	var ladung: float = ladung_jetzt()
	leuchten_zeigen(ladung)
	$Summen.pitch_scale = eigene_tonhoehe * lerpf(tonhoehe_leer, 1.0, ladung)
	if uebrig == 0:
		erholt_in -= delta
		if erholt_in <= 0.0:
			uebrig = spruenge
		return
	if flackert_noch > 0.0:
		flackert_noch -= delta
		glitchen(1.0 - flackert_noch / flacker_zeit)
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
	taucht_noch = auftauch_zeit
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


# Zeigt so viele Ringe, wie sie Spruenge hat. ladung 1 heisst alle drei, 2/3 heisst die inneren zwei, 0 heisst keiner.
# Dazwischen (waehrend der Erholung) wird der naechste Ring gerade eingeblendet.
func leuchten_zeigen(ladung: float) -> void:
	var ringe: float = ladung * 3.0
	for nummer in 3:
		var ring: Sprite2D = $Leuchten.get_child(nummer)
		ring.modulate = leucht_farben[nummer]
		ring.modulate.a = clampf(ringe - nummer, 0.0, 1.0) * leucht_deckkraft


# Stellt den Glitch ein: 0 heisst ganz normal, 1 heisst voll verrutscht und fast weg.
# Der Shader sitzt an der Fliege selbst, Koerper, Fluegel und Ringe benutzen ihn mit (use_parent_material).
func glitchen(staerke: float) -> void:
	material.set_shader_parameter("staerke", clampf(staerke, 0.0, 1.0))
	material.set_shader_parameter("zufall", randf() * 100.0)
