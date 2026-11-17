extends Node2D

# Die Szene der Fliege. Daraus entsteht jede neue Fliege.
@export var fliege_szene: PackedScene
# Die Kanone. An ihr liest der Erzeuger ab, wie hoch man gerade ist.
@export var kanone: Node2D
# Wie viele Pixel Hoehe zwischen zwei Fliegen liegen.
@export var abstand: float = 250.0
# Wie weit links oder rechts von der Kanone eine Fliege hoechstens entsteht, in Pixeln.
@export var breite: float = 400.0
# Wie weit ueber der Kanone die oberste Fliege schon bereitsteht, in Pixeln. Der Bildrand liegt bei 920.
@export var vorlauf: float = 1200.0
# Wie weit unter der Kanone eine Fliege geloescht wird, in Pixeln. Der Bildrand liegt bei 160.
@export var loeschen_unter: float = 300.0
# Das langsamste und das schnellste Tempo einer neuen Fliege, in Pixeln pro Sekunde.
@export var tempo_langsam: float = 100.0
@export var tempo_schnell: float = 180.0

# Auf dieser Hoehe entsteht die naechste Fliege. Nach oben wird y kleiner.
var naechste_hoehe: float = -400.0


func _process(_delta: float) -> void:
	while naechste_hoehe > kanone.position.y - vorlauf:
		var fliege: Node2D = fliege_szene.instantiate()
		fliege.position.x = kanone.position.x + randf_range(-breite, breite)
		fliege.position.y = naechste_hoehe
		fliege.tempo = randf_range(tempo_langsam, tempo_schnell)
		add_child(fliege)
		naechste_hoehe -= abstand
	for fliege in get_children():
		if fliege.position.y > kanone.position.y + loeschen_unter:
			fliege.queue_free()
