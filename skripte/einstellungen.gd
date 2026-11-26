extends CanvasLayer

# Die Wand mit den Einstellungen. Sie faehrt hoch, wenn die Einstellungsfliege getroffen ist,
# und wieder herunter, wenn man die Fliege oben an der Kante oder das Schild "Einstellungen" anklickt oder antippt.
# Das Schild kommt dabei von oben herein und faehrt am Ende wieder nach oben hinaus.

# Die Einstellungsfliege auf der Wiese.
@export var fliege: Node2D
# Die Figur. Solange die Wand oben ist, wartet sie.
@export var figur: Node2D
# Wie lange die Wand fuer den Weg braucht, in Sekunden.
@export var fahrdauer: float = 0.6
# Auf dieser Bildhoehe liegt in der Totale die Oberkante der Wiese: drei Viertel von 1080.
@export var wiesenkante: float = 810.0
# Wo das Schild "Einstellungen" steht, wenn die Wand oben ist, und wo es wartet, solange sie unten ist (ueber dem Bildrand).
@export var titel_oben: float = 0.0
@export var titel_versteckt: float = -150.0


func _ready() -> void:
	fliege.angeschossen.connect(oeffnen)


func oeffnen() -> void:
	if figur.wand_offen:
		return
	figur.wand_offen = true
	fliege.visible = false
	musik_daempfen(true)
	$Wand.position.y = wiesenkante
	$Wand.visible = true
	$Titel.position.y = titel_versteckt
	$Titel.visible = true
	var fahrt: Tween = create_tween()
	fahrt.tween_property($Wand, "position:y", 0.0, fahrdauer)
	fahrt.parallel().tween_property($Titel, "position:y", titel_oben, fahrdauer)


func schliessen() -> void:
	var fahrt: Tween = create_tween()
	fahrt.tween_property($Wand, "position:y", wiesenkante, fahrdauer)
	fahrt.parallel().tween_property($Titel, "position:y", titel_versteckt, fahrdauer)
	fahrt.tween_callback(zu)


func zu() -> void:
	$Wand.visible = false
	$Titel.visible = false
	fliege.visible = true
	figur.wand_offen = false
	musik_daempfen(false)


# Schaltet den Daempfer auf dem Tonkanal Musik ein oder aus. Mit Daempfer klingt die Musik dumpf, wie durch eine Wand.
func musik_daempfen(an: bool) -> void:
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Musik"), 0, an)


# Wird gerufen, wenn die Szene verschwindet, zum Beispiel beim Neustart. Der Daempfer gehoert zur Tonanlage, nicht zur Szene.
# Ohne diese Zeile bliebe er an, wenn man bei offener Wand neu startet.
func _exit_tree() -> void:
	musik_daempfen(false)


func _input(ereignis: InputEvent) -> void:
	if not $Wand.visible:
		return
	if ereignis is InputEventMouseButton or ereignis is InputEventScreenTouch:
		if not ereignis.pressed:
			return
		if $Wand/Fliege.get_global_rect().has_point(ereignis.position) or $Titel.get_global_rect().has_point(ereignis.position):
			schliessen()
