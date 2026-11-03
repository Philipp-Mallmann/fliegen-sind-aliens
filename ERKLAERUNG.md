# Erklaerung des Codes - Fliegen sind Aliens

Jede Zeile des Spiels steht hier in einfachen Worten, Abschnitt fuer Abschnitt.

---

## Abschnitt 1 - Kanone und Welt

**Was der Abschnitt kann:** Eine graue Kanone steht unten in der Bildmitte. Mit A/D oder den Pfeiltasten faehrt sie nach links oder rechts. Sie faehrt kurz an und bremst kurz ab. Die Kamera faehrt mit, deshalb sieht es so aus, als ob die Welt an der Kanone vorbeizieht.

**Neue Dateien:** `skripte/kanone.gd`, `szenen/spiel.tscn`. **Geaendert:** `project.godot`.

### Der Trick: Nicht die Welt bewegt sich, sondern die Kanone

Im Konzept steht "die Kanone bleibt in der Bildmitte, seitlich scrollt die Welt". Man koennte dafuer die ganze Welt verschieben. Einfacher ist es andersherum: Die Kanone faehrt wirklich durch die Welt, und eine Kamera haengt an ihr fest. Weil die Kamera immer mitfaehrt, steht die Kanone im Bild immer in der Mitte. Fuer den Spieler sieht das genauso aus, als ob die Welt scrollt.

Die Welt ist seitlich **endlos** (Entscheidung Z11): Es gibt keinen Rand, man kann beliebig weit fahren.

### `skripte/kanone.gd`

```gdscript
extends Node2D
```
Das Skript gehoert zu einem `Node2D`, also einem Ding mit einer Position in der 2D-Welt. Alles, was ein `Node2D` kann, kann dieses Skript auch, zum Beispiel `position`.

```gdscript
# Hoechstes Tempo der Kanone, in Pixeln pro Sekunde.
@export var tempo: float = 250.0
```
Die erste Zeile ist ein Kommentar fuer Menschen, Godot ignoriert alles nach `#`.
`var tempo` legt eine Variable namens `tempo` an. `: float` heisst, sie enthaelt eine Kommazahl. Der Startwert ist 250, also faehrt die Kanone hoechstens 250 Pixel pro Sekunde. Das Bild ist 1440 Pixel breit, fuer eine Bildbreite braucht man also knapp 6 Sekunden.
`@export` sorgt dafuer, dass der Wert im **Inspector** auftaucht. Man kann ihn dort aendern, ohne den Code anzufassen.

```gdscript
# Wie schnell die Kanone anfaehrt und abbremst, in Pixeln pro Sekunde pro Sekunde.
@export var beschleunigung: float = 600.0
```
Eine zweite Zahl im Inspector. Sie sagt, wie viel Tempo die Kanone pro Sekunde dazugewinnt oder verliert. Mit 600 braucht sie 250 / 600 = etwa 0,4 Sekunden, bis sie volles Tempo hat. Je kleiner die Zahl, desto schwerer und traeger fuehlt sich die Kanone an.

```gdscript
# Das Tempo, mit dem die Kanone gerade faehrt. Negativ heisst nach links.
var aktuelles_tempo: float = 0.0
```
Diese Variable merkt sich, wie schnell die Kanone **in diesem Moment** faehrt. Am Anfang steht sie, also 0. Positive Werte heissen nach rechts, negative nach links. Sie hat kein `@export`, weil man sie nicht einstellt. Das Spiel aendert sie selbst.

```gdscript
func _process(delta: float) -> void:
```
`func` beginnt eine Funktion, also einen Block Befehle. `_process` ist ein Name, den Godot kennt: Diese Funktion ruft Godot **jedes Bild** einmal auf, also etwa 60-mal pro Sekunde.
`delta` ist die Zeit seit dem letzten Bild in Sekunden, meistens etwa 0,016. `-> void` heisst, die Funktion gibt nichts zurueck.

```gdscript
	var richtung: float = Input.get_axis("links", "rechts")
```
`Input.get_axis` schaut nach, welche Tasten gerade gedrueckt sind. Es gibt -1 zurueck, wenn "links" gedrueckt ist, +1 bei "rechts" und 0, wenn keine oder beide gedrueckt sind. "links" und "rechts" sind die Namen der Tasten-Aktionen aus `project.godot` (siehe unten). Das Ergebnis kommt in die Variable `richtung`. Sie gilt nur innerhalb dieser Funktion.

```gdscript
	var ziel_tempo: float = richtung * tempo
```
Wie schnell die Kanone fahren **will**: Richtung mal Hoechsttempo. Bei "rechts" ergibt das +250, bei "links" -250 und ohne Taste 0, dann soll sie stehen.

```gdscript
	aktuelles_tempo = move_toward(aktuelles_tempo, ziel_tempo, beschleunigung * delta)
```
Das ist das Anfahren und Abbremsen. `move_toward(von, nach, schritt)` bewegt eine Zahl um hoechstens `schritt` auf eine andere Zahl zu und schiesst nie darueber hinaus.
Beispiel: Die Kanone steht (0) und man drueckt rechts (Ziel 250). Der Schritt ist 600 mal 0,016, also etwa 10. Im ersten Bild wird das Tempo 10, im naechsten 20 und so weiter, bis es bei 250 stehen bleibt. Laesst man los, ist das Ziel 0, und das Tempo sinkt genauso schrittweise wieder auf 0.
Weil der Schritt mit `delta` malgenommen wird, faehrt die Kanone auf einem schnellen und einem langsamen Rechner gleich.

```gdscript
	position.x += aktuelles_tempo * delta
```
Hier faehrt die Kanone wirklich. `position.x` ist ihre Stelle von links nach rechts. `+=` heisst "dazuzaehlen". Tempo mal Zeit ergibt die Strecke: Bei 250 Pixeln pro Sekunde und 0,016 Sekunden sind das 4 Pixel in diesem Bild.

### `szenen/spiel.tscn`

Die Szene baut man im Editor zusammen, sie hat kein eigenes Skript. Der Baum sieht so aus:

```
Spiel (Node2D)
├── Boden (Parallax2D)
│   ├── Streifen (ColorRect)
│   ├── Pfosten1 bis Pfosten8 (ColorRect)
│   └── Nummer0 bis Nummer7 (Label)
└── Kanone (Node2D, Skript kanone.gd)
    ├── Koerper (ColorRect)
    ├── Rohr (ColorRect)
    └── Kamera (Camera2D)
```

- **Spiel:** der oberste Knoten. Er haelt alles zusammen.
- **Boden (Parallax2D):** sorgt dafuer, dass der Boden endlos ist. Bei `Repeat Size` steht x = 1600. Das heisst: Der Inhalt ist 1600 Pixel breit und wird links und rechts davon immer wieder angesetzt, egal wie weit man faehrt. Dafuer braucht es keinen Code.
- **Streifen:** ein mittelgraues Rechteck, das ist der Boden. Ein `ColorRect` wird ueber vier Raender beschrieben: `offset_left`, `offset_top`, `offset_right`, `offset_bottom`. Was nicht in der Datei steht, ist 0. Der Streifen geht also von x 0 bis 1600 und von y 0 bis 160. In Godot zeigt y nach **unten**, der Streifen liegt also unterhalb der Linie y = 0, und auf dieser Linie steht die Kanone.
- `color = Color(0.45, 0.45, 0.45, 1)` ist die Farbe: Rot, Gruen, Blau, jeweils von 0 bis 1, dazu die Deckkraft (1 = gar nicht durchsichtig). Dreimal derselbe Wert ergibt ein Grau, 0 waere schwarz, 1 weiss.
- **Pfosten1 bis 8:** schmale dunkle Rechtecke (Farbe 0.2), je 12 Pixel breit und 60 hoch (`offset_top = -60`, also ueber dem Boden). Sie stehen bei x = 0, 200, 400 bis 1400, also im Abstand von 200 Pixeln. Ein einfarbiger Boden saehe beim Fahren gleich aus, erst an den Pfosten sieht man, dass sich etwas bewegt. Spaeter (Abschnitt 10) ersetzen Fotos die grauen Formen.
- **Nummer0 bis Nummer7:** Ueber jedem Pfosten steht seine Nummer als `Label`, Schriftgroesse 48, dunkelgrau. Damit sieht man an jedem Bild, wie weit und in welche Richtung die Welt gefahren ist. Ohne Nummern sieht ein Pfosten aus wie der naechste: 35 Pixel nach links und 165 Pixel nach rechts ergeben dann dasselbe Bild. Nach 1600 Pixeln beginnen die Nummern wieder bei 0, weil sich der Boden dort wiederholt. Beim Start steht die Kanone genau auf Pfosten 0.
- **Kanone:** traegt `kanone.gd`. Ihre Position ist der Punkt unten in der Mitte, genau auf dem Boden.
- **Koerper und Rohr:** zwei hellgraue Rechtecke (Farbe 0.75), so dass man die Kanone sieht. Der Koerper ist 80 breit und 60 hoch (x -40 bis 40, y -60 bis 0), das Rohr 16 breit und sitzt darauf (y -140 bis -60). Die Zahlen gelten relativ zur Kanone, deshalb liegt die Mitte bei x = 0. Beide sind Kinder der Kanone und fahren deshalb automatisch mit.
- **Kamera (Camera2D):** ebenfalls ein Kind der Kanone, also faehrt sie mit, und die Kanone bleibt in der Bildmitte. `Offset` y = -380 schiebt den Blick 380 Pixel nach oben. Ohne das saesse die Kanone mitten im Bild und der halbe Bildschirm waere Boden. So sitzt sie unten, und oben bleibt Platz fuer die Fliegen.

### Nachtrag: Tasten fuer das Handy (in `szenen/spiel.tscn`)

Damit man schon jetzt am Handy fahren kann, gibt es zwei Tasten auf dem Bildschirm. Dafuer gibt es **keine neue Codezeile**, alles steht in der Szene:

```
Spiel
└── Bedienung (CanvasLayer)
    ├── TasteLinks (TouchScreenButton)
    │   └── Pfeil (Label)
    └── TasteRechts (TouchScreenButton)
        └── Pfeil (Label)
```

- **Bedienung (CanvasLayer):** eine eigene Bildebene, die **nicht** mit der Kamera mitfaehrt. Alles darin klebt am Bildschirm, wie eine Glasscheibe vor dem Spiel. Ohne sie wuerden die Tasten mit der Welt wegscrollen.
- **TasteLinks und TasteRechts (TouchScreenButton):** Godots fertige Taste fuer Touchscreens. Die wichtige Einstellung ist `action`: Bei der linken steht dort `"links"`, bei der rechten `"rechts"`. Solange der Finger auf der Taste liegt, tut Godot so, als waere diese Aktion gedrueckt, genau wie die Taste A oder D. Deshalb muss `kanone.gd` nichts davon wissen: `Input.get_axis("links", "rechts")` merkt den Finger wie eine Tastatur.
- `position = Vector2(40, 700)` und `Vector2(1200, 700)`: Die Tasten sitzen links und rechts unten im Bild, aber etwas hoeher als die Ecken. Die untersten Ecken nimmt Safari auf dem iPhone fuer eigene Wischgesten.
- `visibility_mode = 1` heisst "nur auf Touchscreens zeigen". Am PC sieht man die Tasten nicht.
- `texture_normal` ist das Bild der Taste: ein halb durchsichtiges weisses Quadrat, 200 mal 200 Pixel. Es steht als `GradientTexture2D` direkt in der Szene, ein Farbverlauf mit zweimal derselben Farbe, also eine Flaeche. So braucht es noch keine Bilddatei.
- **Pfeil (Label):** ein Text `<` oder `>` in Schriftgroesse 120, mittig auf der Taste.

Das ist vorgezogen aus Abschnitt 15. Dort kommen die Tasten spaeter in die Streifen neben dem Bild, und es kommt der Schuss-Knopf dazu.

### `project.godot` (die ganze Datei)

Das ist die Einstellungsdatei des Projekts. Fast alles hier stellt man im Editor unter Projekt > Projekteinstellungen ein, Godot schreibt es dann selbst hinein. Die Zeilen in eckigen Klammern wie `[display]` sind Ueberschriften fuer Gruppen.

```
config_version=5
```
Die Version des Dateiformats. Godot 4 schreibt hier 5. Man aendert das nie.

```
[application]
config/name="Fliegen sind Aliens"
run/main_scene="res://szenen/spiel.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")
```
Der Name des Spiels, der zum Beispiel im Fenstertitel steht. `run/main_scene` ist die Szene, die beim Start des Spiels laeuft (F5), sie ist **neu in Abschnitt 1**. `res://` heisst "im Projektordner". `config/features` merkt sich, fuer welche Godot-Version und welchen Renderer das Projekt angelegt wurde.

```
[display]
window/size/viewport_width=1440
window/size/viewport_height=1080
```
So gross ist das Spielbild intern: 1440 mal 1080 Pixel. 1440 geteilt durch 1080 ist 4 zu 3, daher das Format 4:3. Mit diesen Zahlen rechnet das ganze Spiel, auch wenn das Fenster anders gross ist.

```
window/size/window_width_override=1200
window/size/window_height_override=900
```
So gross geht das Fenster am PC auf: 1200 mal 900, ebenfalls 4:3, damit es auf jeden Bildschirm passt.

```
window/stretch/mode="canvas_items"
```
Ist das Fenster kleiner oder groesser als 1440 mal 1080, wird das Bild passend gestreckt. `canvas_items` heisst: Alles wird in der echten Fenstergroesse neu gezeichnet und bleibt scharf. Ohne eigene Zeile gilt das Seitenverhaeltnis `keep`, also bleibt es 4:3, und es kommen notfalls schwarze Raender dazu.

```
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```
Welcher Renderer zeichnet. `gl_compatibility` ist der einfachste, und nur er laeuft im Browser. Weil das Spiel auf itch.io im Browser laufen soll, gilt er ueberall, auch auf dem Handy.

```
[input]
links={ ... physical_keycode 65 ... physical_keycode 4194319 ... }
rechts={ ... physical_keycode 68 ... physical_keycode 4194321 ... }
```
Das sind die **Tasten-Aktionen**, sie sind **neu in Abschnitt 1**. Im Editor findet man sie unter Projekt > Projekteinstellungen > Eingabe-Zuordnung, dort sind sie lesbar. In der Datei stehen sie als Zahlen: 65 ist A, 68 ist D, 4194319 ist Pfeil links, 4194321 ist Pfeil rechts.
Der Code fragt nur nach "links" und "rechts", nie nach einer bestimmten Taste. Will man spaeter eine weitere Taste dazunehmen, aendert man das hier und nicht im Skript.
`physical_keycode` heisst: Gemeint ist die Taste an dieser Stelle der Tastatur, egal welche Tastaturbelegung eingestellt ist.
`deadzone` gilt nur fuer Joysticks: Kleine Ausschlaege unter 0,2 zaehlen nicht. Fuer Tasten spielt die Zahl keine Rolle, Godot schreibt sie trotzdem hinein.
Die vielen weiteren Angaben in jedem `Object(InputEventKey, ...)` wie `"shift_pressed":false` sind Standardwerte, die Godot immer mitschreibt. Gemeint ist: Die Taste zaehlt ohne Shift, Strg und Alt.

### `export_presets.cfg` (neu, fuer den Browser)

Damit man das Spiel schon jetzt auf itch.io im Browser testen kann, gibt es eine Export-Vorlage namens "Web". Im Editor steht sie unter Projekt > Exportieren. Die Datei schreibt Godot selbst, wichtig sind nur wenige Zeilen:

- `name="Web"`, `platform="Web"`: Die Vorlage baut eine Browser-Fassung.
- `export_path="build/web/index.html"`: Dorthin kommt das fertige Spiel. Der Ordner `build/` geht nicht ins Repo.
- `export_filter="all_resources"`: Alles, was das Spiel benutzt, kommt mit hinein.
- `variant/thread_support=false`: Das Spiel laeuft ohne Threads (mehrere Rechenstraenge). Mit Threads laeuft es auf dem iPhone gar nicht, und itch braucht dann eine Sondereinstellung.
- `html/canvas_resize_policy=2`: Das Spielbild waechst mit dem Fenster auf der itch-Seite mit.
- `html/focus_canvas_on_start=true`: Die Tastatur geht sofort ans Spiel, ohne dass man erst hineinklicken muss.
- Alles andere (`progressive_web_app/...`, `encrypt...`, `custom_template/...`) ist ausgeschaltet oder leer. Das sind Godots Standardwerte, sie spielen hier keine Rolle.

### `skripte/kanone.gd.uid` (von Godot selbst angelegt)

Eine Zeile wie `uid://...`. Godot legt diese Datei automatisch neben jedes Skript. Sie gibt dem Skript eine feste Nummer, damit Szenen es auch dann noch finden, wenn man es umbenennt oder verschiebt. Von Hand schreibt man daran nichts.

### Drei Fragen zur Selbstkontrolle

1. Warum steht die Kanone immer in der Bildmitte, obwohl sich ihre `position.x` aendert?
2. Was passiert mit `aktuelles_tempo`, wenn man rechts loslaesst, und welcher Inspector-Wert bestimmt, wie lange das dauert?
3. Warum wird beim Fahren mit `delta` malgenommen?

<details><summary>Antworten</summary>

1. Die Kamera ist ein Kind der Kanone und faehrt mit ihr mit. Was die Kamera zeigt, ist immer um die Kanone herum.
2. Das Ziel wird 0, und `move_toward` senkt das Tempo jedes Bild ein Stueck, bis es 0 ist. Wie schnell das geht, bestimmt `beschleunigung`.
3. `delta` ist die Zeit seit dem letzten Bild. Ohne es waere die Kanone auf einem Rechner mit mehr Bildern pro Sekunde schneller.

</details>
