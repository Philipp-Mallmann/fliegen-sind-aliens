extends Node

# Eine Hoehenzone. Das Skript rechnet nichts, es haelt nur die Werte der Zone fuer den Inspector.
# Der Name der Zone ist der Name des Knotens.

# Ab so viel Flugkraft Hoehe beginnt die Zone. Sie reicht bis zum Anfang der naechsten.
@export var ab_flugkraft: float = 0.0
# Die Fliegen-Szenen, die hier hereinfliegen. Aus der Liste wird jedes Mal eine ausgewuerfelt.
# Steht eine Szene mehrmals darin, kommt sie entsprechend oefter.
@export var fliegen: Array[PackedScene] = []
# Fliegen-Szenen, die genau einmal hereinfliegen, wenn man die Zone von unten betritt. Zum Beispiel der Boss.
@export var einmalig: Array[PackedScene] = []
# Wie viele freie Fliegen hier mindestens in der Naehe sein sollen.
@export var mindestens: int = 4
