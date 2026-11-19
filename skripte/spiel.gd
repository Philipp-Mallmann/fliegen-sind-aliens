extends Node2D

# Bei so viel Flugkraft ist man im All.
@export var ziel: int = 100
# Wie viele Pixel man fuer einen Punkt Flugkraft steigt.
@export var hoehe_je_flugkraft: float = 300.0
# Wie lange das Gleiten nach oben dauert, in Sekunden.
@export var steigdauer: float = 0.8

# Die Flugkraft aller Fliegen, die oben im Faecher haengen.
var flugkraft: int = 0
# Das Gleiten nach oben, das gerade laeuft. null heisst: Es gab noch keins.
var steigen: Tween = null


func _ready() -> void:
	$Kanone/Uebergabe.angekommen.connect(fliege_zaehlen)
	$Kanone/Arm/Leiste.max_value = ziel
	anzeige_schreiben()


func fliege_zaehlen(dazu: int) -> void:
	flugkraft += dazu
	anzeige_schreiben()
	if steigen != null:
		steigen.kill()
	steigen = create_tween()
	steigen.tween_property($Kanone, "position:y", -flugkraft * hoehe_je_flugkraft, steigdauer)
	if flugkraft >= ziel:
		$Bedienung/Sieg.visible = true
		$Kanone.set_process(false)


func anzeige_schreiben() -> void:
	$Kanone/Arm/Leiste.value = flugkraft
