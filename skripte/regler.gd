extends Control

# Ein Regler auf der Wand: ein Brett mit Naegeln. Je mehr Naegel stecken, desto lauter.
# Wo kein Nagel steckt, sieht man nur seinen Schatten. Man klickt oder zieht mit Maus oder Finger ueber die Naegel.

# Der Name des Tonkanals (Bus), den der Regler stellt.
@export var bus: String = "Effekte"
# Was vorne auf dem Brett steht.
@export var beschriftung: String = "SFX"
# Ein einzelner Nagel. Der Regler setzt ihn so oft nebeneinander, wie anzahl sagt.
@export var nagel_szene: PackedScene
# Wie viele Naegel auf dem Brett Platz haben. Alle Naegel heisst: volle Lautstaerke.
@export var anzahl: int = 20
# So sieht ein fehlender Nagel aus: schwarz und halb durchsichtig, also ein Schatten.
@export var schatten: Color = Color(0.0, 0.0, 0.0, 0.35)

# true heisst: Maus oder Finger haelt den Regler gerade fest.
var zieht: bool = false


func _ready() -> void:
	$Name.text = beschriftung
	for nummer in anzahl:
		$Naegel.add_child(nagel_szene.instantiate())
	zeigen(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus)))


func _input(ereignis: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if ereignis is InputEventMouseButton or ereignis is InputEventScreenTouch:
		zieht = ereignis.pressed and $Naegel.get_global_rect().has_point(ereignis.position)
		if zieht:
			setzen(ereignis.position.x)
	if ereignis is InputEventMouseMotion or ereignis is InputEventScreenDrag:
		if zieht:
			setzen(ereignis.position.x)


func setzen(x: float) -> void:
	var wert: float = clampf((x - $Naegel.global_position.x) / $Naegel.size.x, 0.0, 1.0)
	var stecken: int = ceili(wert * anzahl)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus), float(stecken) / anzahl)
	zeigen(float(stecken) / anzahl)


func zeigen(wert: float) -> void:
	var stecken: int = roundi(wert * anzahl)
	for nummer in anzahl:
		var nagel: Control = $Naegel.get_child(nummer)
		if nummer < stecken:
			nagel.modulate = Color.WHITE
		else:
			nagel.modulate = schatten
