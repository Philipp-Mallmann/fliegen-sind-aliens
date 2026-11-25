extends Node2D

# Der Joystick am Handy. Er merkt sich nur, wohin der Finger ihn drueckt. Was damit geschieht, entscheiden andere Skripte.

# Wie weit der Knopf hoechstens aus der Mitte geht, in Pixeln.
@export var radius: float = 120.0

# Wohin der Joystick zeigt. Vector2.ZERO heisst: losgelassen. Die Laenge 1 heisst: ganz am Rand.
var richtung: Vector2 = Vector2.ZERO
# Die Nummer des Fingers, der den Joystick haelt. -1 heisst: keiner.
var finger: int = -1


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()


func _input(ereignis: InputEvent) -> void:
	if not visible:
		return
	if ereignis is InputEventScreenTouch:
		if ereignis.pressed and finger == -1 and ereignis.position.distance_to(global_position) <= radius * 1.5:
			finger = ereignis.index
			auslenken(ereignis.position)
		elif not ereignis.pressed and ereignis.index == finger:
			finger = -1
			richtung = Vector2.ZERO
			$Knopf.position = Vector2.ZERO
	if ereignis is InputEventScreenDrag and ereignis.index == finger:
		auslenken(ereignis.position)


func auslenken(stelle: Vector2) -> void:
	var weg: Vector2 = (stelle - global_position).limit_length(radius)
	$Knopf.position = weg
	richtung = weg / radius
