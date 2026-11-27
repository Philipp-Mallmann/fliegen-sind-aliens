extends Label

# Eine Zahl oder ein Wort, das kurz aufsteigt und dabei verblasst, zum Beispiel "+4" oder "Double Kill".
# Text, Farbe und Groesse setzt die Punktanzeige, bevor die Zahl ins Spiel kommt.

# Wie weit die Zahl nach oben steigt, in Pixeln.
@export var steigen: float = 90.0
# Wie lange sie zu sehen ist, in Sekunden. In der zweiten Haelfte verblasst sie.
@export var dauer: float = 1.2


func _ready() -> void:
	var ablauf: Tween = create_tween()
	ablauf.set_parallel(true)
	ablauf.tween_property(self, "position:y", position.y - steigen, dauer)
	ablauf.tween_property(self, "modulate:a", 0.0, dauer / 2.0).set_delay(dauer / 2.0)
	ablauf.chain().tween_callback(queue_free)
