extends CanvasLayer

# Der Hintergrund: eine Riffelpappe, die den ganzen Bildschirm fuellt.
# Je hoeher die Kanone ist, desto weiter hinten in der Liste liegt das Bild, das gezeigt wird.
# Kurz vor dem Wechsel wird die naechste Pappe langsam darueber eingeblendet.

# Die Kanone. An ihrer Hoehe haengt die Farbe.
@export var kanone: Node2D
# Die Pappen von unten nach oben: erst Regenbogen, dann Weltall.
@export var bilder: Array[Texture2D] = []
# Nach so viel Flugkraft Hoehe kommt die naechste Pappe.
@export var flugkraft_je_bild: float = 10.0
# So viel Flugkraft vor dem Wechsel beginnt die Ueberblendung zur naechsten Pappe.
@export var uebergang: float = 4.0


func _process(_delta: float) -> void:
	var hoehe: float = -kanone.position.y / get_parent().hoehe_je_flugkraft
	var nummer: int = int(hoehe / flugkraft_je_bild)
	nummer = clampi(nummer, 0, bilder.size() - 1)
	var naechste: int = mini(nummer + 1, bilder.size() - 1)
	$Pappe.texture = bilder[nummer]
	$Naechste.texture = bilder[naechste]
	var schon_geflogen: float = hoehe - nummer * flugkraft_je_bild
	var beginn: float = flugkraft_je_bild - uebergang
	$Naechste.modulate.a = clampf((schon_geflogen - beginn) / uebergang, 0.0, 1.0)
