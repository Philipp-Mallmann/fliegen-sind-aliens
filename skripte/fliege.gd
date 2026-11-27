extends Node2D

# Das Gemeinsame aller Fliegen. Jede Art hat ein eigenes Skript, das auf diesem aufbaut (extends)
# und nur ihre eigene Flugweise dazuschreibt.

# Das langsamste und das schnellste Tempo dieser Art, in Pixeln pro Sekunde. Jede Fliege wuerfelt ihr eigenes dazwischen.
@export var tempo_langsam: float = 100.0
@export var tempo_schnell: float = 180.0
# Wie viel Flugkraft die Fliege gibt, wenn sie gefangen ist.
@export var flugkraft: int = 2
# Wie oft man die Fliege treffen muss, bis sie gefangen ist. Nur der Boss braucht mehr als 1.
@export var leben: int = 1
# true heisst: Der Erzeuger laesst sie fliehen, wenn sie zu tief oder zu hoch im Bild ist. Der Boss flieht nie.
@export var flieht: bool = true
# In welcher Farbe ihr Blut ist, wenn der Nagel sie trifft. Wie ihre Fluegel: Jede Zone hat ihre eigene Farbe.
@export var blut_farbe: Color = Color(0.75, 0.05, 0.05)
# Wie tief und wie hoch das Summen hoechstens klingt. 1 ist die Tonhoehe der Datei. Jede Fliege wuerfelt ihre eigene.
@export var tonhoehe_tief: float = 0.8
@export var tonhoehe_hoch: float = 1.4

# Das Tempo dieser einen Fliege. Wird beim Start ausgewuerfelt.
var tempo: float = 0.0
# Die Kanone. Manche Arten richten sich nach ihr. Setzt der Erzeuger, bevor die Fliege ins Spiel kommt.
var kanone: Node2D = null
# Um diese Stelle herum haelt sich die Fliege auf. Setzt der Erzeuger, bevor die Fliege ins Spiel kommt.
var mitte_x: float = 0.0
# 1 heisst nach rechts, -1 heisst nach links.
var richtung: float = 1.0
# true heisst: Die Fliege haengt an der Nadel und fliegt nicht mehr.
var gefangen: bool = false
# true heisst: Die Nadel fliegt gerade durch die Fliege hindurch, man kann sie nicht treffen. Nur die Teleport-Fliege setzt das.
var entkommt: bool = false
# In diese Richtung flieht die Fliege aus dem Bild. Vector2.ZERO heisst: Sie flieht nicht. Setzt der Erzeuger.
var flucht: Vector2 = Vector2.ZERO
# Die Hoehe, auf der die Fliege zu Hause ist. Um sie herum wippt oder kreist sie.
var grund_y: float = 0.0
# Wie viele Sekunden die Fliege schon fliegt.
var zeit: float = 0.0
# Die Nadeln, die in der Fliege stecken, solange sie noch nicht gefangen ist. Nur beim Boss.
var steckende: Array[Node2D] = []
# Die halbe Groesse der Trefferflaeche, in Pixeln. Wird beim Start aus der Groesse des Bilds berechnet.
var halbe_groesse: float = 50.0


func _ready() -> void:
	tempo = randf_range(tempo_langsam, tempo_schnell)
	# Die Trefferflaeche richtet sich nach dem Bild. Zieht man in der Fliegenszene das Bild groesser oder kleiner, waechst sie mit.
	var bild_groesse: Vector2 = $Bild.texture.get_size() * $Bild.scale.abs()
	halbe_groesse = (bild_groesse.x + bild_groesse.y) / 4.0
	grund_y = position.y
	if mitte_x < position.x:
		richtung = -1.0
	$Summen.pitch_scale = randf_range(tonhoehe_tief, tonhoehe_hoch)
	losfliegen()


func _process(delta: float) -> void:
	if gefangen:
		return
	zeit += delta
	if flucht != Vector2.ZERO:
		position += flucht * tempo * delta
		return
	fliegen(delta)


# Wird einmal aufgerufen, wenn die Fliege ins Spiel kommt. Hier leer, eine Art kann sie ueberschreiben.
func losfliegen() -> void:
	pass


# Wird in jedem Bild aufgerufen, solange die Fliege frei ist und nicht flieht. Hier leer, jede Art ueberschreibt sie.
func fliegen(_delta: float) -> void:
	pass


# Wird aufgerufen, wenn eine Nadel die Fliege trifft, sie aber noch nicht gefangen ist. Hier leer, der Boss ueberschreibt sie.
func angeschossen() -> void:
	pass
