extends "res://skripte/fliege.gd"

# Die schnelle Fliege: fliegt gerade und sehr schnell. Am Ende ihrer Strecke wendet sie in einer Schleife, dort mit ihrem einfachen Tempo.

# Wie weit die Fliege von ihrer Mitte nach links und nach rechts fliegt, bevor sie wendet, in Pixeln.
@export var strecke: float = 300.0
# Wie eng die Schleife ist: der Radius des Kreises, in Pixeln.
@export var schleife: float = 60.0
# Wie viel schneller sie auf dem geraden Stueck fliegt als in der Schleife. 2 heisst: doppelt so schnell.
@export var faktor_gerade: float = 2.0

# Wie weit sie in der Schleife insgesamt lenkt, im Bogenmass:
# erst ein Sechstel Kreis nach oben, dann fuenf Sechstel Kreis nach unten herum, dann wieder ein Sechstel nach oben.
const ERSTES_STUECK: float = PI / 3.0
const WENDE_GANZ: float = TAU + PI / 3.0

# In welche Richtung sie gerade fliegt, als Winkel. 0 heisst nach rechts, PI heisst nach links.
var winkel: float = 0.0
# true heisst: Sie fliegt gerade die Schleife.
var wendet: bool = false
# Wie viel von der Schleife sie schon gelenkt hat, im Bogenmass.
var gelenkt: float = 0.0


func losfliegen() -> void:
	if richtung < 0.0:
		winkel = PI


func fliegen(delta: float) -> void:
	if not wendet:
		position += Vector2.from_angle(winkel) * tempo * faktor_gerade * delta
		var rechts_draussen: bool = richtung > 0.0 and position.x > mitte_x + strecke
		var links_draussen: bool = richtung < 0.0 and position.x < mitte_x - strecke
		if rechts_draussen or links_draussen:
			wendet = true
			gelenkt = 0.0
		return
	position += Vector2.from_angle(winkel) * tempo * delta
	var schritt: float = tempo / schleife * delta
	gelenkt += schritt
	if gelenkt < ERSTES_STUECK or gelenkt > TAU:
		winkel -= schritt * richtung
	else:
		winkel += schritt * richtung
	rotation = richtung * TAU * gelenkt / WENDE_GANZ
	if gelenkt >= WENDE_GANZ:
		wendet = false
		richtung = -richtung
		rotation = 0.0
		position.y = grund_y
		winkel = 0.0
		if richtung < 0.0:
			winkel = PI
