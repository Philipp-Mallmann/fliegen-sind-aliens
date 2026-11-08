extends Node2D

# Wie lange der Fleck waechst und verblasst, in Sekunden.
@export var dauer: float = 0.6


func _ready() -> void:
	var ablauf: Tween = create_tween()
	ablauf.tween_property(self, "scale", Vector2(2.0, 2.0), dauer)
	ablauf.parallel().tween_property(self, "modulate:a", 0.0, dauer)
	ablauf.tween_callback(queue_free)
