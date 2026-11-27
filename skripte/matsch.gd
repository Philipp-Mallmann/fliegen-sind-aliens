extends Sprite2D

# Der Matsch, wenn ein Stein eine Fliege zerquetscht: ein Blutspritzer in ihrer Farbe, der schnell aufspritzt.
# Er haengt am Stein und faellt mit ihm aus dem Bild. Mit dem Stein wird auch er geloescht.

# Wie gross der Spritzer am Anfang und am Ende ist. 1 ist die Groesse des Bilds.
@export var groesse_anfang: float = 0.15
@export var groesse_ende: float = 1.3
# Wie lange das Aufspritzen dauert, in Sekunden.
@export var dauer: float = 0.12


func _ready() -> void:
	scale = Vector2.ONE * groesse_anfang
	var spritzen: Tween = create_tween()
	spritzen.tween_property(self, "scale", Vector2.ONE * groesse_ende, dauer)
