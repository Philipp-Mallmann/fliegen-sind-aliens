extends "res://skripte/fliege.gd"

# Die schnelle Fliege: fliegt gerade und sehr schnell. Am Ende ihrer Strecke wendet sie in einer Schleife.

# Wie weit die Fliege von ihrer Mitte nach links und nach rechts fliegt, bevor sie wendet, in Pixeln.
@export var strecke: float = 300.0
# Wie eng die Schleife ist: der Radius des Kreises, in Pixeln.
@export var schleife: float = 60.0
# Wie viel schneller sie auf dem geraden Stueck fliegt als in der Schleife. 2 heisst: doppelt so schnell.
@export var faktor_gerade: float = 2.0
# Wie viel schneller sie die Schleife fliegt als ihr einfaches Tempo. 2 heisst: doppelt so schnell, die Wende dauert halb so lang.
@export var faktor_schleife: float = 2.0

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
# true heisst: Bild und Fluegel sind gerade gespiegelt (sie fliegt nach rechts). In der Szene schaut sie nach links.
var gespiegelt: bool = false


func losfliegen() -> void:
	if richtung < 0.0:
		winkel = PI
	bild_richten()


func fliegen(delta: float) -> void:
	if not wendet:
		position += Vector2.from_angle(winkel) * tempo * faktor_gerade * delta
		var rechts_draussen: bool = richtung > 0.0 and position.x > mitte_x + strecke
		var links_draussen: bool = richtung < 0.0 and position.x < mitte_x - strecke
		if rechts_draussen or links_draussen:
			wendet = true
			gelenkt = 0.0
		return
	position += Vector2.from_angle(winkel) * tempo * faktor_schleife * delta
	var schritt: float = tempo * faktor_schleife / schleife * delta
	gelenkt += schritt
	if gelenkt < ERSTES_STUECK or gelenkt > TAU:
		winkel -= schritt * richtung
	else:
		winkel += schritt * richtung
	if gelenkt >= WENDE_GANZ:
		wendet = false
		richtung = -richtung
		bild_richten()
		position.y = grund_y
		winkel = 0.0
		if richtung < 0.0:
			winkel = PI


# Das Bild schaut nach links (der Kopf ist links). Fliegt sie nach rechts, wird es gespiegelt.
# In der Schleife dreht es sich nicht mit, es wird erst umgedreht, wenn sie wirklich in die andere Richtung fliegt.
func bild_richten() -> void:
	var nach_rechts: bool = richtung > 0.0
	$Bild.flip_h = nach_rechts
	# Die Fluegel werden mitgespiegelt: Bild umdrehen und auf die andere Seite der Mitte setzen.
	# Nur wenn sich die Richtung wirklich aendert, sonst wuerden sie bei jedem Aufruf hin und her springen.
	if nach_rechts != gespiegelt:
		gespiegelt = nach_rechts
		for fluegel in [$FluegelVorn, $FluegelHinten]:
			fluegel.flip_h = nach_rechts
			fluegel.position.x = -fluegel.position.x
