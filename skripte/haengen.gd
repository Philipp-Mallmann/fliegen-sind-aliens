extends Node2D

# Der Forscher, der am Draht haengt. Dieser Knoten ist der Drehpunkt: Um ihn pendelt der ganze Koerper.
# Erst liegt der Drehpunkt an der Kanone (der Draht haengt noch dort), dann in der Hand zwischen Daumen und Fingern.
# Bewegt sich der Drehpunkt, schwingt der Koerper mit: Er bleibt zurueck und schwingt aus, wie ein Pendel.

# Wie weit der Koerper hoechstens zur Seite schwingt, in Grad.
@export var groesster_winkel: float = 3.0
# Wie lange eine ganze Schwingung (hin und zurueck) dauert, in Sekunden.
@export var schwingdauer: float = 1.6
# Wie schnell das Schwingen abklingt. 0 heisst: nie.
@export var daempfung: float = 0.8
# Wie stark eine Bewegung des Drehpunkts zur Seite den Koerper anstoesst.
@export var mitnahme: float = 0.004

# Der aktuelle Winkel und wie schnell er sich gerade aendert (im Bogenmass).
var winkel: float = 0.0
var winkeltempo: float = 0.0
# Wo der Drehpunkt im letzten Bild war und wie schnell er sich bewegt hat. Daraus kommt der Anstoss.
var letzter_ort: Vector2 = Vector2.ZERO
var letztes_tempo: float = 0.0
# false heisst: Er haengt noch nicht, es wird nicht gependelt.
var pendelt: bool = false


func _ready() -> void:
	letzter_ort = global_position
	# In jedem Bild frueher dran als die Figur (kleinere Zahl heisst frueher): Die Figur richtet sich nach diesem Knoten.
	process_priority = -1


func _process(delta: float) -> void:
	if not pendelt or delta <= 0.0:
		letzter_ort = global_position
		return
	# Wie schnell und wie ruckartig sich der Drehpunkt zur Seite bewegt.
	var tempo: float = (global_position.x - letzter_ort.x) / delta
	var ruck: float = (tempo - letztes_tempo) / delta
	letzter_ort = global_position
	letztes_tempo = tempo
	# Ein Pendel: Es zieht zur Mitte zurueck, klingt ab, und eine Bewegung des Drehpunkts stoesst es entgegen an.
	var eigen: float = TAU / schwingdauer
	var beschleunigung: float = -eigen * eigen * winkel - daempfung * winkeltempo - ruck * mitnahme
	winkeltempo += beschleunigung * delta
	winkel += winkeltempo * delta
	var grenze: float = deg_to_rad(groesster_winkel)
	if absf(winkel) > grenze:
		winkel = clampf(winkel, -grenze, grenze)
		winkeltempo = 0.0
	rotation = winkel


# Laesst das Pendeln beginnen, mit einem kleinen Schwung zur Seite.
func anstossen() -> void:
	pendelt = true
	letzter_ort = global_position
	letztes_tempo = 0.0
	winkeltempo = deg_to_rad(groesster_winkel) * TAU / schwingdauer


# Verlegt den Drehpunkt an eine andere Stelle, ohne dass der Koerper springt.
# Der Inhalt behaelt seinen Platz auf dem Bildschirm, nur der Punkt, um den er pendelt, wandert.
func drehpunkt_setzen(neuer_ort: Vector2) -> void:
	var vorher: Transform2D = $Inhalt.global_transform
	global_position = neuer_ort
	$Inhalt.global_transform = vorher
	letzter_ort = global_position
