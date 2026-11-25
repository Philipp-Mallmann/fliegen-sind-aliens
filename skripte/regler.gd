extends Control

# Ein Regler auf der Wand: ein Balken, den man mit Maus oder Finger fuellt. Er stellt die Lautstaerke eines Tonkanals.

# Der Name des Tonkanals (Bus), den der Regler stellt. Er steht auch als Schrift ueber dem Balken.
@export var bus: String = "Effekte"

# true heisst: Maus oder Finger haelt den Balken gerade fest.
var zieht: bool = false


func _ready() -> void:
	$Name.text = bus
	zeigen(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus)))


func _input(ereignis: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if ereignis is InputEventMouseButton or ereignis is InputEventScreenTouch:
		zieht = ereignis.pressed and $Balken.get_global_rect().has_point(ereignis.position)
		if zieht:
			setzen(ereignis.position.x)
	if ereignis is InputEventMouseMotion or ereignis is InputEventScreenDrag:
		if zieht:
			setzen(ereignis.position.x)


func setzen(x: float) -> void:
	var wert: float = clampf((x - $Balken.global_position.x) / $Balken.size.x, 0.0, 1.0)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus), wert)
	zeigen(wert)


func zeigen(wert: float) -> void:
	$Balken/Fuellung.size.x = $Balken.size.x * wert
