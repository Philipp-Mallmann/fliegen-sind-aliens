extends CanvasLayer

# Der Hintergrund: eine Riffelpappe, die den ganzen Bildschirm fuellt.
# Je hoeher die Kanone ist, desto weiter hinten in der Liste liegt das Bild, das gezeigt wird.

# Die Kanone. An ihrer Hoehe haengt die Farbe.
@export var kanone: Node2D
# Die Pappen von unten nach oben: erst Regenbogen, dann Weltall.
@export var bilder: Array[Texture2D] = []
# Nach so viel Flugkraft Hoehe kommt die naechste Pappe.
@export var flugkraft_je_bild: float = 10.0


func _process(_delta: float) -> void:
	var hoehe: float = -kanone.position.y / get_parent().hoehe_je_flugkraft
	var nummer: int = int(hoehe / flugkraft_je_bild)
	nummer = clampi(nummer, 0, bilder.size() - 1)
	$Pappe.texture = bilder[nummer]
