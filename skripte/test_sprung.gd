extends Node

# Nur zum Testen, kommt vor der Abgabe wieder heraus.
# Die Zifferntasten 1, 2, 3 ... springen an den Anfang der ersten, zweiten, dritten ... Zone.
# Neustart am Boden: Taste 0, Taste R oder der Knopf "Neustart" oben rechts (Maus oder Finger).

# Der Knoten mit den Zonen. Seine Kinder sind die Zonen, von unten nach oben.
@export var zonen: Node
# Der Knopf "Neustart" oben rechts. Ein Mausklick darauf startet neu.
@export var knopf: Button


func _ready() -> void:
	knopf.pressed.connect(neustart)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("neustart"):
		neustart()


func neustart() -> void:
	get_tree().reload_current_scene()


func _unhandled_key_input(taste: InputEvent) -> void:
	if not taste.pressed or taste.echo:
		return
	if taste.keycode == KEY_0:
		neustart()
		return
	var nummer: int = taste.keycode - KEY_1
	if nummer >= 0 and nummer < zonen.get_child_count():
		var zone: Node = zonen.get_child(nummer)
		get_parent().springen(int(zone.ab_flugkraft))
