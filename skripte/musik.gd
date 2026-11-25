extends Node

# Die Musik. Zwei Tonspieler: Schleife laeuft das ganze Spiel in einer Endlosschleife, Ende spielt einmal, wenn man im All ist.
# In der Totale ist die Musik ganz leise, im Spiel laut.

# Wie laut die Musik im Spiel ist, in Dezibel. 0 waere die volle Lautstaerke der Datei, jede 6 weniger halbiert sie etwa.
@export var laut_db: float = -12.0
# Wie laut sie in der Totale ist.
@export var leise_db: float = -30.0
# Wie lange der Wechsel zwischen leise und laut dauert, in Sekunden.
@export var blenddauer: float = 1.5
# Wie schnell die Schleife verklingt, wenn das Ende einsetzt, in Sekunden.
@export var ende_blenddauer: float = 0.5

# Der Wechsel der Lautstaerke, der gerade laeuft. null heisst: Es gab noch keinen.
var blende: Tween = null


func _ready() -> void:
	$Schleife.volume_db = leise_db
	$Schleife.play()


func laut() -> void:
	blenden(laut_db)


func leise() -> void:
	blenden(leise_db)


func blenden(ziel_db: float) -> void:
	if blende != null:
		blende.kill()
	blende = create_tween()
	blende.tween_property($Schleife, "volume_db", ziel_db, blenddauer)


# Im All: Das Ende setzt ein, die Schleife verklingt schnell und hoert dann auf.
func ende_spielen() -> void:
	$Ende.volume_db = laut_db
	$Ende.play()
	if blende != null:
		blende.kill()
	blende = create_tween()
	blende.tween_property($Schleife, "volume_db", -60.0, ende_blenddauer)
	blende.tween_callback($Schleife.stop)
