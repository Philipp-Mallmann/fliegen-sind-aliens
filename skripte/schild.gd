extends TextureRect

# Ein Holzschild mit Schrift, zum Beispiel "Einstellungen". Schrift und Groesse stellt man im Inspector ein.

# Was auf dem Schild steht. \n im Text macht eine neue Zeile.
@export_multiline var schrift: String = "Schild"
# Wie gross die Schrift ist.
@export var groesse: int = 64


func _ready() -> void:
	$Schrift.text = schrift
	$Schrift.add_theme_font_size_override("font_size", groesse)
