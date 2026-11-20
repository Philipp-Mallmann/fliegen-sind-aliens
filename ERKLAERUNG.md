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

---

## Abschnitt 2 - Nadel

**Was der Abschnitt kann:** Mit Leertaste, W oder linker Maustaste schiesst die Kanone eine Nadel senkrecht nach oben. Am Handy gibt es dafuer die Taste "Schuss". Es fliegt immer nur eine Nadel. Ist sie oben aus dem Bild, fliegt sie zurueck zur Kanone, wie eine Harpune, die eingeholt wird. Erst wenn sie wieder an der Rohrspitze ist, verschwindet sie, die Kanone laedt 0,5 Sekunden nach, dann kann man wieder schiessen.

**Geaendert am 06.11. auf Philipps Wunsch:** Die Nadel fliegt doppelt so schnell (3200 statt 1600) und kehrt als Harpune zur Kanone zurueck, statt oben einfach zu verschwinden. Neu dafuer sind in `nadel.gd` alles ausser `extends` und der `_process`-Zeile mit `position.y`, in `nadel.tscn` die Verbindung am Ende und in `kanone.gd` die Zeile `nadel.muendung = $Muendung`.

**Neue Dateien:** `skripte/nadel.gd`, `szenen/nadel.tscn`. **Geaendert:** `skripte/kanone.gd` (aus Abschnitt 1), `szenen/spiel.tscn`, `project.godot`.

### Wer macht was

- Die **Nadel** kann zwei Dinge: nach oben fliegen und zur Kanone zurueckfliegen. Sie weiss nichts von Tasten oder vom Nachladen.
- Die **Kanone** entscheidet, wann geschossen wird, und zaehlt das Nachladen. Sie hat damit zwei Aufgaben, fahren und schiessen. Das ist so gewollt (Entscheidung Z32): lieber ein Skript mehr lesen als eine Datei mehr.
- Dass die Nadel oben aus dem Bild ist, merkt ein fertiger Godot-Knoten, der **Waechter**. Dafuer braucht es keine Rechnung. Er sagt der Nadel dann: umkehren.

### `skripte/nadel.gd` (die ganze Datei)

```gdscript
extends Node2D
```
Wie bei der Kanone: Die Nadel ist ein Ding mit einer Position in der 2D-Welt.

```gdscript
# Wie schnell die Nadel fliegt, hin und zurueck, in Pixeln pro Sekunde.
@export var tempo: float = 3200.0
```
Eine Zahl im Inspector, sie gilt fuer den Hinflug und fuer den Rueckflug. Von der Rohrspitze bis zum oberen Bildrand sind es etwa 800 Pixel, die Nadel braucht dafuer also rund eine Viertelsekunde, und zurueck noch einmal so lange. Wer sie schneller oder langsamer haben will, aendert nur diese Zahl.

```gdscript
# Die Muendung der Kanone. Dorthin kehrt die Nadel zurueck. Die Kanone traegt sie beim Schuss ein.
var muendung: Node2D = null
```
Hier merkt sich die Nadel, wohin sie zurueck muss: den Knoten `Muendung` der Kanone (siehe `spiel.tscn`). Die Nadel merkt sich den **Knoten** und nicht nur seine Position von damals. Faehrt die Kanone weiter, waehrend die Nadel oben ist, kennt die Nadel so trotzdem die neue Stelle. Am Anfang steht hier `null`, also nichts. Eingetragen wird die Muendung von der Kanone, beim Schuss (siehe `kanone.gd` unten).

```gdscript
# false heisst: Die Nadel fliegt nach oben. true heisst: Sie wird eingeholt wie eine Harpune.
var kehrt_zurueck: bool = false
```
`bool` ist eine Variable, die nur zwei Werte kennt: `true` (wahr) oder `false` (falsch). Sie ist wie ein Schalter. Am Anfang steht er auf `false`, die Nadel fliegt nach oben.

```gdscript
func _process(delta: float) -> void:
	if kehrt_zurueck:
		zurueckfliegen(delta)
	else:
		position.y -= tempo * delta
```
Jedes Bild ruft Godot `_process` auf. Zuerst schaut die Nadel auf ihren Schalter. Steht er auf `true`, fliegt sie zurueck (die Funktion `zurueckfliegen` steht weiter unten). Sonst (`else`) fliegt sie nach oben wie bisher.

Zur Zeile `position.y -= tempo * delta`: `-=` heisst "ziehe ab", die y-Position wird kleiner. In Godot zeigt y nach unten, kleiner heisst also **nach oben**. Die Nadel aendert dabei nur `position.y`, nie `position.x`, deshalb fliegt sie nach oben nur senkrecht. `tempo * delta` ist wieder Tempo mal vergangene Zeit, so fliegt sie auf jedem Rechner gleich schnell.

```gdscript
func einholen() -> void:
	kehrt_zurueck = true
```
Diese Funktion legt nur den Schalter um. Wer ruft sie auf? Der Waechter in `nadel.tscn`, sobald die Nadel oben aus dem Bild ist (siehe unten). Ab dem naechsten Bild nimmt `_process` dann den Weg zurueck.

```gdscript
func zurueckfliegen(delta: float) -> void:
	var ziel: Vector2 = muendung.global_position
```
Ein `Vector2` ist ein Punkt mit zwei Zahlen, x und y. `ziel` ist die Stelle, an der die Muendung **in diesem Bild** steht. Weil das jedes Bild neu gefragt wird, folgt die Nadel der Kanone, auch wenn sie gerade faehrt. `global_position` ist wieder die Position in der ganzen Welt.

```gdscript
	global_position = global_position.move_toward(ziel, tempo * delta)
```
`move_toward` kennst du von der Kanone, dort mit einer Zahl (dem Tempo). Hier geht es mit einem Punkt: Die Nadel rueckt ein Stueck auf `ziel` zu, hoechstens `tempo * delta` Pixel weit, auf gerader Linie. Ist das Ziel naeher als dieses Stueck, landet sie genau auf dem Ziel und schiesst nicht darueber hinaus. Hat die Kanone sich seitlich bewegt, fliegt die Nadel deshalb schraeg zurueck. Sie bleibt dabei senkrecht ausgerichtet, gedreht wird sie nicht.

```gdscript
	if global_position == ziel:
		queue_free()
```
`==` heisst "ist gleich". Ist die Nadel an der Muendung angekommen, loescht sie sich mit `queue_free` (loescht einen Knoten am Ende des Bildes, mit allen Kindern). Erst jetzt erfaehrt die Kanone, dass die Nadel weg ist, und erst jetzt beginnt das Nachladen. Dass der Vergleich wirklich einmal genau stimmt, liegt an `move_toward`: Im letzten Schritt setzt es die Nadel exakt auf das Ziel.

### `szenen/nadel.tscn`

```
Nadel (Node2D, traegt nadel.gd)
├── Strich (ColorRect)
└── Waechter (VisibleOnScreenNotifier2D)
```

- **Strich:** ein fast weisses Rechteck (Farbe 0.9), 6 Pixel breit und 50 hoch (x -3 bis 3, y -50 bis 0). Das ist die Nadel, solange es noch keine Fotos gibt.
- **Waechter (VisibleOnScreenNotifier2D):** ein unsichtbarer Godot-Knoten, der meldet, wenn sein Rechteck ins Bild kommt oder es verlaesst. `rect` ist genau so gross wie der Strich.
- **Die Verbindung** am Ende der Datei: `[connection signal="screen_exited" from="Waechter" to="." method="einholen"]`. Uebersetzt: "Wenn der Waechter meldet *ich bin aus dem Bild* (`screen_exited`), dann rufe bei der Nadel selbst (`.`) die Funktion `einholen` auf." Die Nadel kehrt also um, sobald sie ganz oben raus ist. Bis Philipps Wunsch vom 06.11. stand hier `queue_free`, da hat sich die Nadel oben einfach geloescht.

Warum so und nicht mit einer Rechnung wie "ab y kleiner als -920 umkehren"? Der Waechter fragt die Kamera. Wenn die Kamera in Abschnitt 4 mit der Kanone nach oben steigt, stimmt eine feste Zahl nicht mehr, der Waechter schon.

Meldet der Waechter beim Rueckflug nicht noch einmal? `screen_exited` kommt nur, wenn die Nadel das Bild **verlaesst**. Auf dem Rueckweg kommt sie ins Bild hinein und bleibt dort, bis sie an der Kanone ankommt. Dann meldet er nichts mehr.

### `skripte/kanone.gd` - geaendert in Abschnitt 2

Die Zeilen fuers Fahren sind **unveraendert**, sie stehen jetzt nur in einer eigenen Funktion `fahren`. Neu ist alles fuers Schiessen.

```gdscript
# Die Szene der Nadel. Bei jedem Schuss entsteht daraus eine neue Nadel.
@export var nadel_szene: PackedScene
```
Eine `PackedScene` ist eine gespeicherte Szene, hier `nadel.tscn`, wie ein Bauplan. Weil es ein `@export` ist, steht der Bauplan im Inspector der Kanone (in `spiel.tscn` eingetragen) und nicht als Pfad im Code.

```gdscript
# Wie lange die Kanone nachlaedt, nachdem die Nadel weg ist, in Sekunden.
@export var nachladezeit: float = 0.5
```
Die Nachladezeit im Inspector, Startwert 0,5 Sekunden aus dem Feinkonzept.

```gdscript
# Die Nadel, die gerade fliegt. null heisst: Es ist keine Nadel unterwegs.
var nadel: Node2D = null
```
Hier merkt sich die Kanone ihre fliegende Nadel. `null` heisst "nichts". Am Anfang fliegt keine.

```gdscript
# Wie viele Sekunden das Nachladen noch dauert. 0 oder weniger heisst: bereit.
var nachladen_noch: float = 0.0
```
Ein Countdown. Steht er auf 0, ist die Kanone sofort bereit.

```gdscript
func _process(delta: float) -> void:
	fahren(delta)
	schiessen(delta)
```
Jedes Bild macht die Kanone zwei Dinge nacheinander: erst fahren, dann schiessen. Beides sind eigene Funktionen, damit man sie getrennt lesen kann. `delta` wird an beide weitergereicht.

```gdscript
func fahren(delta: float) -> void:
	var richtung: float = Input.get_axis("links", "rechts")
	var ziel_tempo: float = richtung * tempo
	aktuelles_tempo = move_toward(aktuelles_tempo, ziel_tempo, beschleunigung * delta)
	position.x += aktuelles_tempo * delta
```
Genau die vier Zeilen aus Abschnitt 1, nur unter einem eigenen Namen. Erklaert sind sie oben bei Abschnitt 1.

```gdscript
func schiessen(delta: float) -> void:
	nachladen_noch -= delta
```
Der Countdown laeuft jedes Bild um die vergangene Zeit herunter. Er darf ruhig unter 0 fallen, alles unter 0 heisst einfach "bereit".

```gdscript
	if nadel != null or nachladen_noch > 0.0:
		return
```
`!=` heisst "ist nicht". Wenn noch eine Nadel fliegt, hin oder zurueck, **oder** (`or`) noch nachgeladen wird, bricht die Funktion hier ab (`return`). Ein Druck auf die Taste bewirkt dann nichts. Das ist die ganze Sperre gegen Dauerfeuer.

```gdscript
	if Input.is_action_just_pressed("schiessen"):
```
`is_action_just_pressed` ist nur in dem einen Bild wahr, in dem die Taste **neu** gedrueckt wird. Wer sie festhaelt, schiesst also nur einmal, danach muss man loslassen und neu druecken. Die Aktion `schiessen` steht in `project.godot` (siehe unten).

```gdscript
		nadel = nadel_szene.instantiate()
```
`instantiate` baut aus dem Bauplan eine echte, neue Nadel. Sie ist jetzt da, aber noch nirgends in der Welt. Die Kanone merkt sie sich in `nadel`.

```gdscript
		nadel.position = $Muendung.global_position
```
Die Nadel startet an der Rohrspitze. `$Muendung` ist der Kind-Knoten `Muendung` der Kanone (siehe Szene). `global_position` ist seine Position in der ganzen Welt, nicht nur relativ zur Kanone.

```gdscript
		nadel.muendung = $Muendung
```
Neu seit Philipps Wunsch vom 06.11. (Harpune). Die Kanone gibt der Nadel ihre Muendung mit, also den Knoten selbst, nicht nur eine Position. Die Nadel speichert ihn in ihrer Variable `muendung` und weiss damit spaeter, wohin sie zurueckfliegen muss, auch wenn die Kanone inzwischen weitergefahren ist. Der Unterschied zur Zeile davor: Dort wird **einmal** eine Position kopiert, hier merkt sich die Nadel den Knoten und kann ihn jedes Bild neu nach seiner Position fragen.

```gdscript
		get_parent().add_child(nadel)
```
Erst hier kommt die Nadel in die Welt. `get_parent()` ist der Knoten ueber der Kanone, also `Spiel`. Die Nadel wird ein Kind von `Spiel` und **nicht** von der Kanone. Das ist wichtig: Kinder fahren mit ihren Eltern mit. Hinge die Nadel an der Kanone, wuerde sie beim Fahren seitlich mitwandern und nicht mehr senkrecht fliegen.

```gdscript
		nadel.tree_exited.connect(nadel_ist_weg)
```
Jeder Knoten sendet das Signal `tree_exited`, wenn er aus der Welt verschwindet. `connect` sagt: "Wenn diese Nadel verschwindet, rufe meine Funktion `nadel_ist_weg` auf." So erfaehrt die Kanone, dass die Nadel zurueck an der Rohrspitze ist und sich geloescht hat, ohne selbst nachzusehen. Ab Abschnitt 3 verschwindet die Nadel auch bei einem Treffer, und dieselbe Zeile startet dann das Nachladen.

```gdscript
func nadel_ist_weg() -> void:
	nadel = null
	nachladen_noch = nachladezeit
```
Die Nadel ist weg: Die Kanone vergisst sie (`null`) und stellt den Countdown auf 0,5 Sekunden. Erst wenn der abgelaufen ist, kommt `schiessen` wieder an der Sperre vorbei.

### `szenen/spiel.tscn` - geaendert

```
Spiel
├── Kanone
│   ├── ...
│   └── Muendung (Marker2D)      neu
└── Bedienung (CanvasLayer)
    ├── ...
    └── TasteSchuss (TouchScreenButton)   neu
        └── Wort (Label)
```

- **Kanone:** Im Inspector steht jetzt `nadel_szene = nadel.tscn`. Ohne diesen Eintrag waere `nadel_szene` leer, und der erste Schuss wuerde mit einem Fehler abbrechen.
- **Muendung (Marker2D):** ein unsichtbarer Punkt, nur eine Position. Er sitzt bei y = -140, das ist die obere Kante des Rohrs. So steht die Rohrspitze in der Szene und nicht als Zahl im Code.
- **TasteSchuss:** gebaut wie die Pfeiltasten aus Abschnitt 1, ohne Code. `action = "schiessen"` heisst: Solange der Finger auf der Taste liegt, gilt `schiessen` als gedrueckt, wie die Leertaste. Sie sitzt rechts ueber der rechten Pfeiltaste (`position = Vector2(1200, 460)`), damit der rechte Daumen zwischen Fahren und Schiessen wechseln kann. `visibility_mode = 1`: nur auf Touchscreens zu sehen.
- **Wort (Label):** der Text "Schuss" in Groesse 48 auf der Taste.

### `project.godot` - geaendert

```
schiessen={ ... }
```
Eine dritte Aktion neben `links` und `rechts`, mit drei Ausloesern: Leertaste (`physical_keycode` 32), W (87) und linke Maustaste (`InputEventMouseButton` mit `button_index` 1). Der Rest jeder Zeile sind Standardwerte, die Godot immer mitschreibt.

```
[input_devices]
pointing/emulate_mouse_from_touch=false
```
Normalerweise tut Godot bei jedem Fingertipp so, als waere zusaetzlich die Maus geklickt worden. Weil die linke Maustaste schiesst, haette dann **jeder** Tipp geschossen, auch der auf eine Pfeiltaste. Diese Zeile schaltet das ab. Die Touch-Tasten funktionieren trotzdem, weil sie Fingertipps direkt verstehen.

### `skripte/nadel.gd.uid` (von Godot selbst angelegt)

Wie bei der Kanone: eine Kennnummer, mit der Godot die Datei wiederfindet, auch wenn sie umbenannt wird. Nicht von Hand aendern.

### Drei Fragen zur Selbstkontrolle

1. Warum wird die Nadel ein Kind von `Spiel` und nicht von der Kanone?
2. Du haeltst die Leertaste fest. Warum kommt nach dem Nachladen kein zweiter Schuss?
3. Die Nadel ist oben aus dem Bild. Was passiert, bis die Kanone wieder schiessen kann?

<details><summary>Antworten</summary>

1. Kinder bewegen sich mit ihren Eltern. Als Kind der Kanone wuerde die Nadel beim Fahren seitlich mitwandern und nicht mehr senkrecht fliegen.
2. `is_action_just_pressed` ist nur in dem Bild wahr, in dem die Taste neu gedrueckt wird. Festhalten zaehlt nicht als neuer Druck.
3. Der Waechter in `nadel.tscn` meldet `screen_exited` und ruft damit `einholen` auf. Der Schalter `kehrt_zurueck` steht dann auf `true`, und die Nadel fliegt mit `move_toward` zur Muendung, dorthin, wo die Kanone gerade steht. Ist sie angekommen, loescht sie sich mit `queue_free`. Dabei sendet sie `tree_exited`, das hat die Kanone beim Schuss mit `nadel_ist_weg` verbunden. Dort startet das Nachladen, nach 0,5 Sekunden ist die Kanone bereit.

</details>


---

## Abschnitt 3 - Fliegen, Treffer und Uebergabe

> **Stand 17.11.:** "Der Trick 1", `nadel.gd`, `uebergabe.gd`, die Zeile zum Haken, die fuenf Fliegen von Hand und Frage 1 sind ueberholt. Die neue Fassung steht weiter unten in "Abschnitt 3 - geaendert am 17.11." und in Abschnitt 4.

**Was der Abschnitt kann:** Fuenf graue Fliegen fliegen seitlich hin und her. Die Nadel fliegt geradeaus, zweimal so weit, wie das Bild hoch ist, und verschwindet erst dann. Sie kehrt **nicht** mehr zurueck, die Harpune aus Abschnitt 2 ist wieder ausgebaut. Spaeter kommt dafuer ein Seil an die Nadel. Nach jedem Schuss laedt die Kanone 0,5 Sekunden nach, egal wo die Nadel gerade ist. Deshalb koennen kurz zwei Nadeln gleichzeitig fliegen (Entscheidung Z81).

Trifft die Nadel eine Fliege, bleibt sie mit der Fliege an der Stelle stecken, und dort erscheint ein roter Fleck, der kurz waechst und verblasst. Dann faehrt der **Arm** (linke Hand mit Kanone) an den rechten Bildrand zur rechten Hand. Nadel und Fliege fliegen zum Haken oben ueber der rechten Hand und bleiben dort haengen (Z52). Danach faehrt der Arm zurueck in die Mitte. Waehrenddessen steht die Kamera still, man kann weder fahren noch schiessen, die anderen Fliegen fliegen weiter.

**Platzhalter:** Der rote Fleck ist ein Platzhalter, der richtige Effekt kommt in Abschnitt 12. Bis Abschnitt 5 haengen alle gefangenen Fliegen am selben Punkt uebereinander. Das Auffaechern baut Abschnitt 5.

**Neue Dateien:** `skripte/fliege.gd`, `szenen/fliege.tscn`, `skripte/blutfleck.gd`, `szenen/blutfleck.tscn`, `skripte/uebergabe.gd`. **Geaendert:** `skripte/nadel.gd` (komplett neu geschrieben), `szenen/nadel.tscn`, `skripte/kanone.gd`, `szenen/spiel.tscn`.

### Wer macht was

- Die **Fliege** fliegt nur hin und her. Wird sie gefangen, haelt sie still. Sie weiss nichts von der Nadel.
- Die **Nadel** fliegt nach oben und schaut in jedem Bild nach, ob sie eine Fliege erwischt hat. Bei einem Treffer ruft sie laut "getroffen" (ein Signal). Wer zuhoert, entscheidet sie nicht.
- Der **Blutfleck** spielt nur seine kurze Animation ab und loescht sich danach selbst.
- Die **Uebergabe** hoert auf das "getroffen" und faehrt den Arm hin und zurueck. Das ist ein eigenes Skript, damit `kanone.gd` nicht noch eine dritte Aufgabe bekommt (§2: ein Skript, eine Sache).
- Die **Kanone** faehrt und schiesst wie bisher. Neu: Waehrend die Uebergabe laeuft, macht sie nichts.

### Der Trick 1: Wie die Nadel eine Fliege trifft

Die Nadel ist sehr schnell: 3200 Pixel pro Sekunde, das sind bei 60 Bildern pro Sekunde etwa 53 Pixel **pro Bild**. Die Fliege ist nur 24 Pixel hoch. Wuerde man nur fragen "beruehrt die Nadel gerade eine Fliege?", koennte die Nadel in einem Bild unter der Fliege sein und im naechsten schon darueber. Sie wuerde einfach durch die Fliege springen.

Deshalb fragt die Nadel anders: "Liegt eine Fliege **auf dem Stueck, das ich seit dem letzten Bild geflogen bin**?" Dafuer merkt sie sich, wo sie vor dem Schritt war (`alte_y`), und vergleicht danach. So geht keine Fliege dazwischen verloren, egal wie schnell die Nadel ist. Das ist eine einfache Rechnung, keine Physik-Engine (Entscheidung Z31).

### Der Trick 2: Warum die Kamera bei der Uebergabe stehen bleibt

Die Kamera ist ein Kind der Kanone (seit Abschnitt 1). Wuerde die ganze Kanone nach rechts fahren, fuehre die Kamera mit, und im Bild saehe man gar keine Bewegung, nur die Welt, die nach links rutscht. Deshalb gibt es jetzt den Knoten **Arm** in der Kanone. Darin stecken linke Hand, Koerper, Rohr und Muendung. Bei der Uebergabe faehrt nur der Arm. Der Knoten `Kanone` selbst, und mit ihm die Kamera, bleibt stehen.

Die rechte Hand und der Haken sind ebenfalls Kinder der Kanone, aber **nicht** des Arms. Sie fahren also mit der Kamera mit und stehen immer an derselben Stelle im Bild, egal wohin man faehrt.

### `skripte/fliege.gd` (die ganze Datei)

```gdscript
extends Node2D
```
Wie Kanone und Nadel: ein Ding mit einer Position in der 2D-Welt.

```gdscript
# Wie schnell die Fliege seitlich fliegt, in Pixeln pro Sekunde.
@export var tempo: float = 150.0
```
Eine Zahl im Inspector. 150 ist langsamer als die Kanone (250), man kann eine Fliege also einholen. In `spiel.tscn` hat jede der fuenf Fliegen ein eigenes Tempo zwischen 100 und 180, damit sie nicht alle gleich fliegen.

```gdscript
# Wie weit die Fliege von ihrem Startpunkt nach links und nach rechts fliegt, in Pixeln.
@export var strecke: float = 300.0
```
Die Fliege fliegt von ihrem Startpunkt aus hoechstens 300 Pixel nach rechts und 300 nach links. Ihre ganze Bahn ist also 600 Pixel breit.

```gdscript
# Wo die Fliege angefangen hat. Um diese Stelle fliegt sie hin und her.
var start_x: float = 0.0
```
Hier merkt sich die Fliege die Mitte ihrer Bahn. Am Anfang steht 0, der richtige Wert kommt in `_ready` (unten).

```gdscript
# 1 heisst nach rechts, -1 heisst nach links.
var richtung: float = 1.0
```
Die Richtung als Zahl. Der Vorteil: Man kann damit rechnen. Mal 1 bleibt das Tempo positiv (nach rechts), mal -1 wird es negativ (nach links). Am Anfang fliegt jede Fliege nach rechts.

```gdscript
# true heisst: Die Fliege haengt an der Nadel und fliegt nicht mehr.
var gefangen: bool = false
```
Ein Schalter wie `kehrt_zurueck` in Abschnitt 2. Die Fliege selbst legt ihn nie um, das macht die Nadel beim Treffer (siehe unten).

```gdscript
func _ready() -> void:
	start_x = position.x
```
`_ready` ruft Godot **einmal** auf, sobald die Fliege in der Welt ist. In diesem Moment steht sie noch da, wo sie in `spiel.tscn` hingesetzt wurde. Diese Stelle merkt sie sich als Mitte ihrer Bahn.

```gdscript
func _process(delta: float) -> void:
	if gefangen:
		return
```
Jedes Bild: Ist die Fliege gefangen, hoert die Funktion hier auf (`return`). Die Zeilen darunter laufen dann nicht mehr, die Fliege bewegt sich nicht mehr von selbst.

```gdscript
	position.x += richtung * tempo * delta
```
Die Fliege rueckt seitlich weiter. `richtung * tempo` ist +150 oder -150, mal `delta` (vergangene Zeit) ergibt das das Stueck fuer dieses eine Bild. Nur `position.x` aendert sich, nie `position.y`. Deshalb fliegt die Fliege **nur seitlich**.

```gdscript
	if position.x > start_x + strecke:
		richtung = -1.0
	if position.x < start_x - strecke:
		richtung = 1.0
```
Die zwei Wendepunkte. Ist die Fliege weiter rechts als Mitte plus 300, fliegt sie ab jetzt nach links. Ist sie weiter links als Mitte minus 300, fliegt sie ab jetzt nach rechts. Sie kann dabei hoechstens ein winziges Stueck ueber den Wendepunkt hinausfliegen, so weit, wie sie in einem Bild kommt (etwa 3 Pixel). Weil sie immer gleich schnell fliegt und immer an denselben Stellen wendet, kann man vorausschaetzen, wo sie gleich ist. Das ist das "berechenbar" aus der Abschnittsdatei. Die zufaellig wendende Fliege und die Teleport-Fliege kommen in Abschnitt 9 (Z61).

### `szenen/fliege.tscn`

```
Fliege (Node2D, traegt fliege.gd, Gruppe "fliegen")
├── Fluegel (ColorRect)
└── Koerper (ColorRect)
```

- **Gruppe "fliegen":** In der Kopfzeile des Knotens steht `groups=["fliegen"]`. Eine Gruppe ist wie ein Etikett. Jede Fliege traegt es, und die Nadel kann damit fragen: "Gib mir alle Knoten mit dem Etikett fliegen." So muss niemand eine Liste der Fliegen pflegen. Auch Fliegen, die ab Abschnitt 4 der Erzeuger baut, haben das Etikett automatisch.
- **Fluegel:** ein hellgraues Rechteck (0.6), 30 breit, 10 hoch, ueber dem Koerper.
- **Koerper:** ein fast schwarzes Rechteck (0.1), 40 breit (x -20 bis 20), 24 hoch (y -12 bis 12). Der Hintergrund ist Godots Standardgrau (0.3). Ein mittelgrauer Koerper waere darauf unsichtbar gewesen. Der Punkt der Fliege liegt genau in der Mitte des Koerpers.

### `skripte/nadel.gd` (die ganze Datei, neu geschrieben)

Von der Harpune aus Abschnitt 2 bleiben nur `extends` und die Zeile `@export var tempo`. `muendung`, `kehrt_zurueck`, `einholen` und `zurueckfliegen` sind weg.

```gdscript
extends Node2D

# Wird gesendet, sobald die Nadel eine Fliege getroffen hat. Mit dabei: die Nadel selbst.
signal getroffen(nadel: Node2D)
```
Ein **Signal** ist eine Nachricht, die ein Knoten in die Runde ruft. `tree_exited` aus Abschnitt 2 war ein Signal, das Godot selbst mitbringt. `getroffen` ist ein eigenes. Die Nadel weiss nicht, wer zuhoert. Sie ruft nur. Mitgeschickt wird die Nadel selbst, damit der Zuhoerer weiss, **welche** Nadel getroffen hat (es koennen ja zwei fliegen). Wer zuhoert, wird in `kanone.gd` festgelegt.

```gdscript
# Wie schnell die Nadel fliegt, in Pixeln pro Sekunde.
@export var tempo: float = 3200.0
```
Wie bisher. Im Kommentar steht nicht mehr "hin und zurueck", weil es kein Zurueck mehr gibt.

```gdscript
# Wie weit die Nadel fliegt, bevor sie verschwindet, in Pixeln. 2160 ist zweimal die Bildhoehe.
@export var reichweite: float = 2160.0
```
Das Bild ist 1080 Pixel hoch, die Nadel fliegt also zweimal so weit. Bei 3200 Pixeln pro Sekunde braucht sie dafuer 0,675 Sekunden. Fuer das Nachladen spielt das keine Rolle mehr, das zaehlt ab dem Schuss (siehe `kanone.gd`).

Warum zaehlt die Nadel die Strecke selbst und fragt nicht mehr den Waechter, ob sie aus dem Bild ist? Weil sie absichtlich **ueber** den Bildrand hinaus fliegen soll, damit spaeter das Seil daran haengen kann. Der Waechter haette nur "aus dem Bild" melden koennen, nicht "doppelt so weit".

```gdscript
# Wie weit eine Fliege seitlich neben der Nadel sein darf und trotzdem getroffen wird, in Pixeln.
@export var trefferbreite: float = 25.0
```
Die Fliege ist 40 Pixel breit, also 20 nach jeder Seite, die Nadel 3 nach jeder Seite. 20 + 3 = 23, mit 2 Pixeln Spielraum ergibt das 25. Ist die Mitte der Fliege hoechstens 25 Pixel neben der Nadel, ist es ein Treffer. Wird das Fangen zu schwer oder zu leicht, aendert man nur diese Zahl.

```gdscript
# Die Szene des Blutflecks. Bei jedem Treffer entsteht daraus ein neuer Fleck.
@export var blutfleck_szene: PackedScene
```
Genau wie `nadel_szene` in der Kanone: ein Bauplan, eingetragen im Inspector (in `nadel.tscn`).

```gdscript
# Wie viele Pixel die Nadel schon geflogen ist.
var geflogen: float = 0.0
```
Ein Zaehler, der mit jedem Bild waechst. Hat er die Reichweite erreicht, verschwindet die Nadel.

```gdscript
# true heisst: Die Nadel hat eine Fliege getroffen und steckt fest.
var steckt: bool = false
```
Wieder ein Schalter.

```gdscript
func _process(delta: float) -> void:
	if steckt:
		return
```
Steckt die Nadel, macht sie selbst nichts mehr: kein Fliegen, kein Pruefen. Bewegt wird sie ab dann nur noch von der Uebergabe.

```gdscript
	var alte_y: float = global_position.y
	position.y -= tempo * delta
	geflogen += tempo * delta
```
Erst merkt sich die Nadel, wo sie gerade ist (`alte_y`). Dann fliegt sie ein Stueck nach oben (wie in Abschnitt 2: kleineres y heisst weiter oben). Dann zaehlt sie dasselbe Stueck zu `geflogen` dazu. `position` und `global_position` sind bei der fliegenden Nadel dasselbe, weil sie direkt unter `Spiel` haengt und `Spiel` bei 0, 0 steht. `global_position` steht hier, weil die Fliegen auch so verglichen werden (unten).

```gdscript
	var fliege: Node2D = getroffene_fliege(alte_y)
```
Die Nadel fragt ihre eigene Funktion `getroffene_fliege` (unten): "Habe ich auf dem Stueck von `alte_y` bis hierher eine Fliege erwischt?" Die Antwort ist entweder eine Fliege oder `null` (keine).

```gdscript
	if fliege != null:
		treffen(fliege)
	elif geflogen >= reichweite:
		queue_free()
```
`!=` heisst "ist nicht gleich". Gab es eine Fliege, kommt der Treffer (Funktion `treffen`, unten). Sonst (`elif` = "sonst, wenn") prueft die Nadel, ob sie schon weit genug geflogen ist. Dann loescht sie sich. Das ist ein Fehlschuss.

```gdscript
func getroffene_fliege(alte_y: float) -> Node2D:
	var kandidat: Node2D = null
```
`-> Node2D` heisst: Diese Funktion gibt am Ende einen Knoten zurueck (oder `null`). `kandidat` ist die bisher beste Fliege. Am Anfang gibt es noch keine.

```gdscript
	for fliege in get_tree().get_nodes_in_group("fliegen"):
```
`get_nodes_in_group("fliegen")` liefert alle Knoten mit dem Etikett "fliegen" (siehe `fliege.tscn`). `for ... in` heisst: Die eingerueckten Zeilen darunter laufen einmal **fuer jede Fliege**. Die Fliege, die gerade dran ist, heisst in jedem Durchgang `fliege`.

```gdscript
		if fliege.gefangen:
			continue
```
Eine Fliege, die schon an einer Nadel haengt, zaehlt nicht. `continue` heisst: diese Fliege ueberspringen, weiter mit der naechsten.

```gdscript
		var seitlich: float = absf(fliege.global_position.x - global_position.x)
```
Wie weit ist die Fliege seitlich von der Nadel weg? "Fliege x minus Nadel x" ist positiv, wenn die Fliege rechts ist, und negativ, wenn sie links ist. `absf` macht daraus immer eine positive Zahl (aus -10 wird 10). So zaehlt nur der Abstand, nicht die Seite.

```gdscript
		var unterwegs: bool = fliege.global_position.y <= alte_y and fliege.global_position.y >= global_position.y
```
Liegt die Fliege auf dem Stueck, das die Nadel gerade geflogen ist? Das Stueck geht von `alte_y` (unten, groessere Zahl) bis `global_position.y` (oben, kleinere Zahl). Die Fliege muss dazwischen sein: nicht tiefer als `alte_y` (`<=` heisst "kleiner oder gleich") **und** (`and`) nicht hoeher als die Nadel jetzt (`>=` heisst "groesser oder gleich"). Das Ergebnis ist `true` oder `false`. Das ist Trick 1 von oben: So springt die Nadel nie ueber eine Fliege hinweg.

```gdscript
		if seitlich <= trefferbreite and unterwegs:
```
Ein Treffer braucht beides: seitlich nah genug **und** auf dem Stueck.

```gdscript
			if kandidat == null or fliege.global_position.y > kandidat.global_position.y:
				kandidat = fliege
```
Es koennten zwei Fliegen auf dem Stueck sein, eine ueber der anderen. Getroffen wird **die erste in der Linie**, also die unterste. Unten heisst in Godot: die groessere y-Zahl. Die Fliege wird zum neuen Kandidaten, wenn es noch keinen gibt (`kandidat == null`) **oder** (`or`) wenn sie tiefer haengt als der bisherige Kandidat.

```gdscript
	return kandidat
```
Nach allen Fliegen gibt die Funktion den Kandidaten zurueck. Gab es keinen, ist das `null`.

Warum heisst die Variable `kandidat` und nicht `getroffen`? Weil `getroffen` schon der Name des Signals ist. Zwei Dinge mit demselben Namen in einem Skript verwechselt man leicht, und Godot warnt davor.

```gdscript
func treffen(fliege: Node2D) -> void:
	steckt = true
	global_position.y = fliege.global_position.y
```
Erst den Schalter umlegen, damit die Nadel ab dem naechsten Bild nicht mehr fliegt. Dann setzt sich die Nadel genau auf die Hoehe der Fliege zurueck, denn im letzten Schritt war sie schon ein Stueck an ihr vorbeigeflogen. Die Spitze der Nadel ist ihr Punkt (siehe `nadel.tscn`). Sie sitzt jetzt also genau in der Fliege.

```gdscript
	fliege.gefangen = true
	fliege.global_position.x = global_position.x
```
Die Nadel legt den Schalter der Fliege um, die Fliege fliegt ab jetzt nicht mehr. Dann wird die Fliege seitlich genau auf die Nadel geschoben (um hoechstens 25 Pixel), damit sie sichtbar **an** der Nadel haengt und nicht daneben.

```gdscript
	fliege.reparent(self)
```
`reparent` haengt einen Knoten an einen neuen Eltern-Knoten, hier an die Nadel (`self`). Die Fliege bleibt dabei genau da, wo sie im Bild ist. Ab jetzt gilt aber: Kinder bewegen sich mit ihren Eltern (wie die Kamera mit der Kanone). Wenn die Uebergabe die Nadel zum Haken fliegen laesst, kommt die Fliege also von selbst mit.

```gdscript
	var fleck: Node2D = blutfleck_szene.instantiate()
	get_parent().add_child(fleck)
	fleck.global_position = global_position
```
So wie die Kanone die Nadel baut: aus dem Bauplan einen neuen Blutfleck machen, ihn in die Welt haengen (beim Eltern-Knoten der Nadel, also bei `Spiel`) und an die Trefferstelle setzen. Der Fleck haengt **nicht** an der Nadel, er bleibt also an der Stelle, auch wenn die Nadel weggeholt wird.

```gdscript
	getroffen.emit(self)
```
`emit` heisst: Das Signal jetzt rufen. Mitgeschickt wird die Nadel selbst. Ab hier uebernimmt die Uebergabe.

### `szenen/nadel.tscn` - geaendert

```
Nadel (Node2D, traegt nadel.gd)
└── Strich (ColorRect)
```

- **Waechter weg:** Den `VisibleOnScreenNotifier2D` und seine Verbindung zu `einholen` gibt es nicht mehr. Die Nadel zaehlt ihre Strecke jetzt selbst.
- **Strich umgedreht:** Vorher ging der Strich von y -50 bis 0, jetzt von 0 bis 50. Der Punkt der Nadel ist damit ihre **Spitze** (oben), der Strich haengt darunter. Wenn die Nadel "bei der Fliege steht", steckt also wirklich die Spitze in der Fliege. Beim Schuss sitzt die Nadel dadurch zuerst im Rohr und kommt dann oben heraus.
- **`blutfleck_szene = blutfleck.tscn`:** der Eintrag im Inspector fuer den Bauplan des Flecks.

### `skripte/blutfleck.gd` (die ganze Datei)

```gdscript
extends Node2D

# Wie lange der Fleck waechst und verblasst, in Sekunden.
@export var dauer: float = 0.6
```
Eine Zahl im Inspector: 0,6 Sekunden.

```gdscript
func _ready() -> void:
	var ablauf: Tween = create_tween()
```
Sobald der Fleck in der Welt ist, baut er sich einen **Tween**. Ein Tween ist ein Helfer von Godot, der einen Wert in einer bestimmten Zeit gleichmaessig von A nach B schiebt. Man nennt ihm nur Ziel und Dauer, die Rechnung fuer jedes Bild macht er selbst.

```gdscript
	ablauf.tween_property(self, "scale", Vector2(2.0, 2.0), dauer)
```
"Schiebe bei mir selbst (`self`) die Groesse (`scale`) in 0,6 Sekunden auf das Doppelte." Der Fleck startet bei halber Groesse (siehe `blutfleck.tscn`), waechst also auf das Vierfache seiner Startgroesse.

```gdscript
	ablauf.parallel().tween_property(self, "modulate:a", 0.0, dauer)
```
`modulate:a` ist die Deckkraft: 1 heisst voll sichtbar, 0 unsichtbar. `parallel()` heisst: **gleichzeitig** mit der Zeile davor, nicht danach. Der Fleck waechst also und verblasst dabei.

```gdscript
	ablauf.tween_callback(queue_free)
```
Ohne `parallel()` kommt dieser Schritt **danach**: Sind Wachsen und Verblassen fertig, ruft der Tween `queue_free` auf, und der Fleck loescht sich selbst.

### `szenen/blutfleck.tscn`

```
Blutfleck (Node2D, traegt blutfleck.gd, scale 0.5)
└── Fleck (Polygon2D)
```

- **scale = 0.5:** Der Fleck beginnt bei halber Groesse.
- **Fleck (Polygon2D):** eine gefuellte Flaeche aus Eckpunkten. Hier sind es acht Punkte im Abstand von etwa 30 Pixeln um die Mitte, das sieht fast aus wie ein Kreis. Farbe dunkelrot (0.75, 0.05, 0.05). Das ist die erste Farbe ausser Grau im Spiel, als Platzhalter (Annahme N19).

### `skripte/uebergabe.gd` (die ganze Datei)

```gdscript
extends Node
```
Ein `Node` ist der einfachste Knoten von Godot: ohne Position, ohne Bild. Die Uebergabe muss nirgends stehen, sie steuert nur andere Knoten.

```gdscript
# Wie lange die Fahrt hinueber dauert, in Sekunden. Arm und Nadel brauchen gleich lang, der Rueckweg auch.
@export var dauer: float = 0.48
```
Eine Zahl im Inspector, die die ganze Bewegung steuert (Entscheidung Z91). In 0,48 Sekunden faehrt der Arm hinueber, in derselben Zeit fliegt die Nadel zum Haken, und in noch einmal 0,48 Sekunden faehrt der Arm zurueck. Groesser heisst langsamer und gemuetlicher, kleiner heisst schneller. Warum Sekunden und nicht Pixel pro Sekunde? Weil man eine Dauer leichter einschaetzen kann: "eine halbe Sekunde" stellt man sich vor, "1000 Pixel pro Sekunde" nicht. Wie es sich anfuehlt, entscheidest du am Spiel (Annahme N25).

```gdscript
# Wie weit der Arm von der Mitte nach rechts faehrt, in Pixeln. Dort sitzt die rechte Hand.
@export var ziel_x: float = 480.0
```
Die Bildmitte ist 0, der rechte Bildrand liegt bei 720 (das Bild ist 1440 breit). Die rechte Hand beginnt bei 560. Bei 480 steht die Kanone also direkt neben ihr.

```gdscript
# Der Arm: linke Hand, Kanone und Muendung. Nur er faehrt, die Kamera bleibt stehen.
@export var arm: Node2D
# Die Stelle ueber der rechten Hand, an der die gefangenen Fliegen haengen.
@export var haken: Node2D
```
Zwei Knoten, die im Inspector eingetragen werden (in `spiel.tscn` steht `arm = NodePath("../Arm")`). So steht im Code kein Pfad, und wer den Arm umbenennt, aendert nur den Eintrag im Inspector.

```gdscript
# true heisst: Gerade laeuft eine Uebergabe. Die Kanone faehrt und schiesst dann nicht.
var laeuft: bool = false
```
Diesen Schalter fragt die Kanone in jedem Bild ab (siehe `kanone.gd`).

```gdscript
# Nadeln mit Fliege, die noch uebergeben werden muessen, der Reihe nach.
var warteschlange: Array[Node2D] = []
```
Ein `Array` ist eine Liste, `[]` heisst: am Anfang leer. `Array[Node2D]` heisst: In dieser Liste stehen nur Knoten. Warum eine Liste? Weil zwei Nadeln gleichzeitig fliegen koennen (Z81). Trifft die zweite, waehrend die erste noch uebergeben wird, muss sie warten, bis sie dran ist, wie an der Kasse.

```gdscript
func starten(nadel: Node2D) -> void:
	warteschlange.append(nadel)
	if not laeuft:
		uebergeben()
```
Diese Funktion hoert auf das Signal `getroffen` jeder Nadel (verbunden in `kanone.gd`). `append` stellt die Nadel hinten in die Schlange. Laeuft noch keine Uebergabe (`not laeuft`), wird eine gestartet. Laeuft schon eine, passiert hier nichts weiter: Die laufende Uebergabe holt sich die neue Nadel selbst aus der Schlange (siehe unten).

```gdscript
func uebergeben() -> void:
	laeuft = true
```
Ab jetzt ist die Kanone gesperrt.

```gdscript
	while warteschlange.size() > 0:
		var nadel: Node2D = warteschlange.pop_front()
```
`while` heisst: Die eingerueckten Zeilen wiederholen sich, **solange** die Bedingung stimmt, also solange noch eine Nadel in der Schlange steht (`size()` ist die Laenge der Liste). `pop_front` nimmt die vorderste Nadel heraus. Sie steht danach nicht mehr in der Liste.

```gdscript
		var hin: Tween = create_tween()
		hin.tween_property(arm, "position", Vector2(ziel_x, 0.0), dauer)
```
Ein Tween wie beim Blutfleck. Er schiebt den Arm in `dauer` Sekunden (0,48) nach rechts an die rechte Hand. Der Arm faehrt in `position`, also **relativ zur Kanone**: 480 Pixel rechts von ihr, 0 Pixel hoch.

```gdscript
		hin.parallel().tween_property(nadel, "global_position", haken.global_position, dauer)
```
`parallel()` heisst wie beim Blutfleck: **gleichzeitig** mit der Zeile davor. Die Nadel (mit der Fliege als Kind) fliegt also im selben Moment los wie der Arm und braucht genauso lange, `dauer`. Arm und Nadel kommen gleichzeitig an, nichts haengt hinterher (Philipps Wunsch vom 08.11.). Die Nadel hat dabei einen anderen, meist laengeren Weg als der Arm, sie fliegt also schneller. Das ist gewollt: gleiche Zeit, nicht gleiches Tempo.

Hier steht `global_position`, also Weltkoordinaten, weil Nadel und Haken verschiedene Eltern haben. Der Haken ist ein Kind der Kanone, die Nadel ein Kind von `Spiel`.

```gdscript
		await hin.finished
```
`finished` ist ein Signal, das der Tween ruft, wenn er fertig ist. `await` heisst: Hier warten, bis es kommt, erst dann geht es mit der naechsten Zeile weiter. Das restliche Spiel laeuft waehrenddessen normal weiter, die Fliegen fliegen.

```gdscript
		nadel.reparent(haken)
```
Am Haken angekommen, wird die Nadel ein Kind des Hakens. Ab jetzt faehrt sie mit der Kanone mit (der Haken ist ein Kind der Kanone) und bleibt immer oben rechts im Bild haengen, auch wenn man weiterfaehrt.

```gdscript
		var zurueck: Tween = create_tween()
		zurueck.tween_property(arm, "position", Vector2.ZERO, dauer)
		await zurueck.finished
```
Ein zweiter Tween faehrt den Arm in derselben Zeit zurueck. `Vector2.ZERO` ist der Punkt 0, 0, also genau auf der Kanone, wie am Anfang. Wieder wartet `await`, bis er da ist.

Danach springt `while` wieder nach oben. Hat in der Zwischenzeit eine zweite Nadel getroffen, steht sie jetzt in der Schlange, und alles beginnt fuer sie noch einmal: hin, abgeben, zurueck.

```gdscript
	laeuft = false
```
Die Schlange ist leer, die Kanone ist wieder frei.

**Geaendert am 08.11.:** Vorher fuhr erst der Arm hinueber und danach die Nadel, beide mit einem Tempo in Pixeln pro Sekunde (`tempo`, 1000), und dafuer gab es eine Hilfsfunktion `fahren`. Jetzt fahren beide gleichzeitig, und die Bewegung wird ueber eine Dauer in Sekunden gesteuert (`dauer`). `fahren` wurde nicht mehr gebraucht und ist weg.

### `skripte/kanone.gd` - geaendert in Abschnitt 3

Neu oder geaendert sind diese Stellen, der Rest ist wie in Abschnitt 1 und 2:

```gdscript
# Wie lange die Kanone nach einem Schuss nachlaedt, in Sekunden.
@export var nachladezeit: float = 0.5
```
Nur der Kommentar ist neu: "nach einem Schuss" statt "nachdem die Nadel weg ist".

**Weg** sind die Variable `var nadel` und die Funktion `nadel_ist_weg`. Die Kanone muss sich keine Nadel mehr merken, weil das Nachladen nicht mehr auf die Nadel wartet (Z81). Damit kippt Z21 aus Abschnitt 2 ("hoechstens eine Nadel"). Auch `nadel.muendung = $Muendung` ist weg, die Nadel kehrt ja nicht mehr zurueck.

```gdscript
func _process(delta: float) -> void:
	if $Uebergabe.laeuft:
		aktuelles_tempo = 0.0
		return
	fahren(delta)
	schiessen(delta)
```
Laeuft die Uebergabe, macht die Kanone nichts: kein Fahren, kein Schiessen. `aktuelles_tempo = 0.0` sorgt dafuer, dass sie danach aus dem Stand anfaehrt und nicht mit dem alten Schwung von vor der Uebergabe weiterrollt. `$Uebergabe` ist der Knoten `Uebergabe`, ein Kind der Kanone.

```gdscript
func schiessen(delta: float) -> void:
	nachladen_noch -= delta
	if nachladen_noch > 0.0:
		return
```
Die Sperre fragt nur noch das Nachladen ab. Vorher stand hier zusaetzlich `nadel != null or`, also "solange eine Nadel fliegt". Das ist weg.

```gdscript
	if Input.is_action_just_pressed("schiessen"):
		var nadel: Node2D = nadel_szene.instantiate()
		nadel.position = $Arm/Muendung.global_position
		get_parent().add_child(nadel)
```
Wie bisher, mit zwei Unterschieden. `var nadel` steht jetzt hier: Die Nadel ist nur noch eine Variable fuer diese paar Zeilen, nicht mehr fuer die ganze Kanone. Und die Muendung heisst `$Arm/Muendung`, weil sie jetzt im Arm steckt (siehe `spiel.tscn`).

```gdscript
		nadel.getroffen.connect($Uebergabe.starten)
```
"Wenn diese Nadel `getroffen` ruft, rufe `starten` in der Uebergabe auf." So wie vorher `tree_exited.connect(nadel_ist_weg)`, nur mit dem neuen Signal und einem anderen Zuhoerer.

```gdscript
		nachladen_noch = nachladezeit
```
Das Nachladen beginnt **jetzt, beim Schuss**, nicht erst, wenn die Nadel weg ist. Ein Fehlschuss kostet also genau 0,5 Sekunden (Z81).

### `szenen/spiel.tscn` - geaendert

```
Spiel
├── Boden ...                     (unveraendert)
├── Fliege1 bis Fliege5           neu
├── Kanone (Node2D, traegt kanone.gd)
│   ├── Arm (Node2D)              neu
│   │   ├── LinkeHand (ColorRect)     neu
│   │   ├── Koerper (ColorRect)       verschoben in den Arm
│   │   ├── Rohr (ColorRect)          verschoben in den Arm
│   │   └── Muendung (Marker2D)       verschoben in den Arm
│   ├── RechteHand (ColorRect)    neu
│   ├── Haken (Marker2D)          neu
│   ├── Kamera (Camera2D)         unveraendert
│   └── Uebergabe (Node, traegt uebergabe.gd)   neu
└── Bedienung ...                 (unveraendert)
```

- **Fliege1 bis Fliege5:** aus `fliege.tscn` gebaut (`instance=`), direkt unter `Spiel`:

| Fliege | Position (x, y) | tempo |
|--------|-----------------|-------|
| Fliege1 | -500, -500 | 150 |
| Fliege2 | -200, -750 | 120 |
| Fliege3 | 100, -450 | 180 |
| Fliege4 | 350, -650 | 150 |
| Fliege5 | 550, -850 | 100 |

  Die Kanone steht bei y 0, das Bild reicht von y -920 (oben) bis 160 (unten). Am Anfang sind also alle Fliegen zu sehen, auf verschiedenen Hoehen. Faehrt man weit weg, sind sie nicht mehr im Bild. Fliegen, die mitkommen, baut erst der Erzeuger in Abschnitt 4.
- **Arm:** ein leerer `Node2D` ohne eigenes Bild, nur ein Behaelter. Koerper, Rohr und Muendung haben ihre alten Zahlen behalten, sie sitzen nur eine Ebene tiefer. Siehe Trick 2.
- **LinkeHand:** ein graues Rechteck (0.6), 120 breit, unter dem Koerper (y -35 bis 5). Sie steht in der Liste **vor** dem Koerper, deshalb malt Godot sie zuerst, und der Koerper liegt darueber. Es sieht so aus, als halte die Hand die Kanone.
- **RechteHand:** ein graues Rechteck (0.6), x 560 bis 680, y -100 bis -20, also unten im rechten Fuenftel des Bildes (Annahme N23). Am Handy liegt sie halb unter der Pfeiltaste rechts. Das klaert sich mit den Fotos und den Handy-Streifen.
- **Haken (Marker2D):** ein unsichtbarer Punkt bei x 620, y -860, also oben ueber der rechten Hand, 60 Pixel unter dem oberen Bildrand. Dort haengen die gefangenen Fliegen (Annahme N24).
- **Uebergabe:** traegt `uebergabe.gd`. Im Inspector stehen `arm = ../Arm` und `haken = ../Haken` (`..` heisst: eine Ebene hoeher, also bei der Kanone nachsehen). Die Zeile `node_paths=...` in der Kopfzeile schreibt Godot selbst dazu, sobald ein `@export` auf einen Knoten zeigt.
- Oben in der Datei stehen zwei neue `ext_resource`-Zeilen, fuer `fliege.tscn` und `uebergabe.gd`. `load_steps` ist entsprechend gestiegen.

### `.uid`-Dateien (von Godot selbst angelegt)

`fliege.gd.uid`, `blutfleck.gd.uid` und `uebergabe.gd.uid`: Wie bei den anderen Skripten sind das Kennnummern. Nicht von Hand aendern.

### Drei Fragen zur Selbstkontrolle

1. Die Nadel fliegt 53 Pixel pro Bild, die Fliege ist nur 24 Pixel hoch. Warum fliegt die Nadel trotzdem nie durch eine Fliege hindurch?
2. Warum faehrt bei der Uebergabe der `Arm` und nicht die ganze `Kanone`?
3. Du schiesst zweimal kurz hintereinander, und beide Nadeln treffen. Was passiert, und welche Zeilen sorgen dafuer?

<details><summary>Antworten</summary>

1. Die Nadel merkt sich vor jedem Schritt `alte_y` und prueft danach das ganze Stueck dazwischen (`unterwegs`). Eine Fliege, an der sie vorbeigesprungen ist, liegt genau auf diesem Stueck.
2. Die Kamera ist ein Kind der Kanone. Fuehre die ganze Kanone, fuehre die Kamera mit, und man saehe im Bild keine Fahrt. Der Arm ist ein eigener Knoten in der Kanone. Faehrt nur er, bleibt die Kamera stehen.
3. Beide Nadeln rufen `getroffen`, beide landen ueber `starten` in der `warteschlange`. Die erste startet `uebergeben`. Die zweite wartet, weil `laeuft` schon `true` ist. Die `while`-Schleife holt sie nach der ersten mit `pop_front` heraus: Der Arm faehrt ein zweites Mal hin (die zweite Nadel gleichzeitig mit ihm), gibt ab und faehrt zurueck. Erst dann ist `laeuft` wieder `false`, und die Kanone darf fahren und schiessen.

</details>

## Abschnitt 3 - geaendert am 17.11. (Treffer und Uebergabe)

**Was sich aendert:** Drei Dinge, alle auf Philipps Ansage vom 17.11.

1. **Treffer:** Die Nadel fragt nicht mehr "lag auf meinem letzten Stueck eine Fliege?", sondern "steckt meine Spitze gerade **in** einer Fliege?". Dafuer ist die Fliege jetzt 100 mal 100 Pixel gross. Die Nadel bleibt genau dort stecken, wo sie die Fliege erwischt hat. Nichts rastet mehr ein.
2. **Uebergabe:** Die Fliege fliegt nicht mehr nach rechts zur Hand. Sie steigt nach oben in eine **Reihe in der Bildmitte**. Dort haengen die Fliegen nebeneinander. Seitlich bewegt sie sich nur das kleine Stueck bis zu ihrem Platz. Sie faehrt kurz **nach** dem Arm los und kommt **gleichzeitig** mit ihm an.
3. Die Uebergabe ruft jetzt ein Signal, sobald die Fliege oben haengt. Darauf hoert Abschnitt 4.

**Geaendert:** `skripte/nadel.gd`, `skripte/uebergabe.gd`, `skripte/fliege.gd`, `szenen/fliege.tscn`, `szenen/spiel.tscn` (Haken).

**Ueberholt in der Erklaerung von Abschnitt 3 oben:** "Der Trick 1", `nadel.gd`, `uebergabe.gd`, die Zeile zum Haken und Frage 1. Es gilt, was hier steht.

### Der neue Trick 1: Die Fliege ist groesser als ein Schritt der Nadel

Die Nadel fliegt 3200 Pixel pro Sekunde. Bei 60 Bildern pro Sekunde sind das etwa 53 Pixel pro Bild. Die Fliege ist jetzt 100 Pixel hoch. Ein Schritt (53) ist kleiner als die Fliege (100). Die Nadelspitze **muss** also in mindestens einem Bild in der Fliege stehen, sie kann nicht darueber hinwegspringen.

Vorher war die Fliege nur 24 Pixel hoch. Deshalb musste die Nadel das ganze geflogene Stueck pruefen, und bei einem Treffer stand sie oft schon **hinter** der Fliege und wurde zurueckgesetzt. Das sah falsch aus. Jetzt steckt die Spitze wirklich in der Fliege, wenn der Treffer gemeldet wird.

**Die Grenze dieser Loesung:** Sie stimmt nur, solange ein Schritt kleiner ist als die Fliege. Laeuft das Spiel mit weniger als 32 Bildern pro Sekunde (3200 / 100 = 32), wird ein Schritt groesser als 100 Pixel, und die Nadel kann durch eine Fliege springen. Dasselbe gilt, wenn man `tempo` der Nadel erhoeht oder die Fliege kleiner macht.

**Spaeter (Abschnitt 10, mit den Fotos):** Statt des Quadrats bekommt die Fliege einen Umriss aus Punkten, den Philipp von Hand nachfaehrt. In Godot heisst das `CollisionPolygon2D` (ein Umriss fuer Treffer) oder `Polygon2D` (ein Umriss zum Malen). Dann zaehlt nur ein Treffer **in der Form** der Fliege.

### `skripte/fliege.gd` - geaendert

Neu sind zwei Werte fuer den Inspector, der Rest ist unveraendert:

```gdscript
# Wie viel Flugkraft die Fliege gibt, wenn sie gefangen ist.
@export var flugkraft: int = 2
```
Eine normale Fliege gibt 2 Flugkraft (Feinkonzept). `int` heisst ganze Zahl. Diesen Wert liest spaeter die Uebergabe ab (Abschnitt 4).

```gdscript
# Die halbe Breite und die halbe Hoehe der Fliege, in Pixeln. 50 heisst: Die Fliege ist 100 mal 100 gross.
@export var halbe_groesse: float = 50.0
```
Die Position der Fliege ist ihre **Mitte**. Von der Mitte aus reicht sie 50 Pixel nach links, rechts, oben und unten. Darum steht hier die halbe Groesse: Die Nadel kann den Abstand zur Mitte direkt damit vergleichen. Die Fliege bewegt sich damit nicht anders, die Zahl ist nur fuer den Treffer da.

### `szenen/fliege.tscn` - geaendert

Die zwei grauen Rechtecke sind groesser, zusammen genau 100 mal 100 Pixel um die Mitte:

- **Fluegel:** x -40 bis 40, y -50 bis -25 (vorher 30 breit, 10 hoch).
- **Koerper:** x -50 bis 50, y -25 bis 50 (vorher 40 breit, 24 hoch).

Die Zahl `halbe_groesse` und die Rechtecke gehoeren zusammen. Wer das Bild groesser macht, muss auch die Zahl aendern, sonst trifft man Luft oder verfehlt die Fliege.

### `skripte/nadel.gd` (die ganze Datei, Stand 17.11.)

```gdscript
extends Node2D

# Wird gesendet, sobald die Nadel eine Fliege getroffen hat. Mit dabei: die Nadel selbst.
signal getroffen(nadel: Node2D)

# Wie schnell die Nadel fliegt, in Pixeln pro Sekunde.
@export var tempo: float = 3200.0
# Wie weit die Nadel fliegt, bevor sie verschwindet, in Pixeln. 2160 ist zweimal die Bildhoehe.
@export var reichweite: float = 2160.0
# Die Szene des Blutflecks. Bei jedem Treffer entsteht daraus ein neuer Fleck.
@export var blutfleck_szene: PackedScene
```
Wie bisher. **Weg** ist `trefferbreite`: Wie breit man treffen darf, sagt jetzt die Fliege selbst (`halbe_groesse`).

```gdscript
# Wie viele Pixel die Nadel schon geflogen ist.
var geflogen: float = 0.0
# true heisst: Die Nadel hat eine Fliege getroffen und steckt fest.
var steckt: bool = false
# Die Fliege, die an der Nadel steckt. null heisst: noch keine.
var fliege: Node2D = null
```
Neu ist `fliege`. Die Nadel merkt sich, welche Fliege an ihr steckt. `null` heisst "nichts". Die Uebergabe fragt spaeter ueber diese Variable nach der Flugkraft.

```gdscript
func _process(delta: float) -> void:
	if steckt:
		return
	position.y -= tempo * delta
	geflogen += tempo * delta
```
Wie bisher: Steckt die Nadel, passiert nichts. Sonst fliegt sie ein Stueck nach oben und zaehlt die Strecke mit. **Weg** ist `alte_y`, die Nadel muss sich die Stelle vor dem Schritt nicht mehr merken.

```gdscript
	var getroffene: Node2D = fliege_an_der_spitze()
	if getroffene != null:
		treffen(getroffene)
	elif geflogen >= reichweite:
		queue_free()
```
Nach dem Schritt fragt die Nadel: Steckt meine Spitze in einer Fliege? Kommt eine Fliege zurueck (`!= null`), wird getroffen. Sonst (`elif`): Ist die Nadel weit genug geflogen, loescht sie sich.

```gdscript
func fliege_an_der_spitze() -> Node2D:
	for kandidat in get_tree().get_nodes_in_group("fliegen"):
		if kandidat.gefangen:
			continue
```
Die Schleife geht alle Fliegen durch (alle Knoten der Gruppe `fliegen`). `continue` heisst: diese ueberspringen und mit der naechsten weitermachen. Gefangene Fliegen kann man nicht noch einmal treffen.

```gdscript
		var seitlich: float = absf(kandidat.global_position.x - global_position.x)
		var senkrecht: float = absf(kandidat.global_position.y - global_position.y)
```
Zwei Abstaende zwischen der Mitte der Fliege und der Nadelspitze: einmal seitlich, einmal in der Hoehe. `absf` macht aus einer negativen Zahl eine positive. Es ist egal, ob die Fliege links oder rechts, drueber oder drunter ist, es zaehlt nur, **wie weit**.

```gdscript
		if seitlich <= kandidat.halbe_groesse and senkrecht <= kandidat.halbe_groesse:
			return kandidat
	return null
```
Sind beide Abstaende hoechstens 50 Pixel, steht die Spitze im Quadrat der Fliege. `return kandidat` gibt diese Fliege zurueck und beendet die Funktion sofort. Laeuft die Schleife ohne Treffer durch, kommt `null` zurueck: keine Fliege an der Spitze.

```gdscript
func treffen(getroffene: Node2D) -> void:
	steckt = true
	fliege = getroffene
	fliege.gefangen = true
	fliege.reparent(self)
```
Die Nadel steckt, merkt sich die Fliege, die Fliege haelt still und wird ein Kind der Nadel. `reparent` haengt sie um, ohne dass sie im Bild springt. **Weg** sind die zwei Zeilen, die Nadel und Fliege aufeinander gesetzt haben. Beide bleiben, wo sie beim Treffer waren.

```gdscript
	var fleck: Node2D = blutfleck_szene.instantiate()
	get_parent().add_child(fleck)
	fleck.global_position = global_position
	getroffen.emit(self)
```
Wie bisher: Blutfleck an der Nadelspitze, dann das Signal `getroffen`.

### `skripte/uebergabe.gd` (die ganze Datei, Stand 17.11.)

```gdscript
extends Node

# Wird gesendet, sobald eine Fliege in der Reihe oben haengt. Mit dabei: ihre Flugkraft.
signal angekommen(flugkraft: int)
```
Ein neues Signal. Die Uebergabe ruft es, wenn eine Fliege an ihrem Platz ist, und sagt dazu, wie viel Flugkraft sie bringt. Wer zuhoert, weiss die Uebergabe nicht. In Abschnitt 4 hoert `spiel.gd` zu.

```gdscript
# Wie lange die Fahrt hinueber dauert, in Sekunden. Der Rueckweg dauert genauso lang.
@export var dauer: float = 0.48
# Wie lange die Fliege wartet, bevor sie losfaehrt, in Sekunden. Sie kommt trotzdem gleichzeitig mit dem Arm an.
@export var verzoegerung: float = 0.1
# Wie weit der Arm von der Mitte nach rechts faehrt, in Pixeln. Dort sitzt die rechte Hand.
@export var ziel_x: float = 480.0
# Wie weit zwei haengende Fliegen nebeneinander auseinander sind, in Pixeln.
@export var abstand: float = 110.0
```
Neu sind `verzoegerung` und `abstand`. Die Fliege ist 100 breit, mit 110 Abstand bleibt zwischen zwei Fliegen eine Luecke von 10 Pixeln.

```gdscript
# Der Arm: linke Hand, Kanone und Muendung. Nur er faehrt, die Kamera bleibt stehen.
@export var arm: Node2D
# Die Mitte der Reihe am oberen Bildrand, in der die gefangenen Fliegen haengen.
@export var haken: Node2D
```
Wie bisher. Der Haken sitzt aber nicht mehr rechts, sondern oben in der **Mitte** (siehe `spiel.tscn`).

```gdscript
# true heisst: Gerade laeuft eine Uebergabe. Die Kanone faehrt und schiesst dann nicht.
var laeuft: bool = false
# Nadeln mit Fliege, die noch uebergeben werden muessen, der Reihe nach.
var warteschlange: Array[Node2D] = []
# Wie viele Fliegen schon in der Reihe haengen.
var anzahl: int = 0
```
Neu ist `anzahl`. Daraus rechnet die Uebergabe aus, welcher Platz als naechster frei ist.

```gdscript
func starten(nadel: Node2D) -> void:
	nadel.reparent(haken)
	warteschlange.append(nadel)
	if not laeuft:
		uebergeben()
```
Neu ist die erste Zeile. Die Nadel wird **sofort beim Treffer** ein Kind des Hakens, nicht erst bei der Ankunft. `reparent` laesst sie dabei an ihrer Stelle im Bild. Warum so frueh? Der Haken ist ein Kind der Kanone. Seit Abschnitt 4 steigt die Kanone. Eine Nadel, die noch in der Welt haengt, wuerde dabei nach unten aus dem Bild rutschen. Als Kind des Hakens steigt sie mit.

```gdscript
func uebergeben() -> void:
	laeuft = true
	while warteschlange.size() > 0:
		var nadel: Node2D = warteschlange.pop_front()
		var hin: Tween = create_tween()
		hin.tween_property(arm, "position", Vector2(ziel_x, 0.0), dauer)
```
Wie bisher: Der Arm faehrt in `dauer` Sekunden nach rechts zur rechten Hand.

```gdscript
		hin.parallel().tween_property(nadel, "position", platz(anzahl), dauer - verzoegerung).set_delay(verzoegerung)
```
Die wichtigste Zeile der Aenderung, von links nach rechts:

- `parallel()`: gleichzeitig mit dem Arm, nicht danach.
- `nadel, "position"`: Die Nadel (mit der Fliege als Kind) faehrt in `position`, also **relativ zum Haken**. Vorher stand hier `global_position`. Das geht jetzt einfacher, weil die Nadel schon ein Kind des Hakens ist.
- `platz(anzahl)`: das Ziel, der naechste freie Platz in der Reihe (Funktion unten).
- `set_delay(verzoegerung)`: Die Nadel wartet erst 0,1 Sekunden.
- `dauer - verzoegerung`: Ihre Fahrt dauert dafuer nur 0,48 - 0,1 = 0,38 Sekunden. Warten plus Fahren ergibt wieder 0,48. Darum **hoeren** Arm und Fliege im selben Moment auf, obwohl die Fliege spaeter anfaengt.

Die Fliege wird in der Mitte gefangen, und die Reihe haengt in der Mitte. Seitlich hat sie also nur einen kurzen Weg und ist dabei langsam. Der lange Weg ist der nach oben.

```gdscript
		await hin.finished
		anzahl += 1
		angekommen.emit(nadel.fliege.flugkraft)
```
Warten, bis Arm und Fliege angekommen sind. Dann haengt eine Fliege mehr in der Reihe, und das Signal `angekommen` geht hinaus. `nadel.fliege.flugkraft` liest man von rechts: die Flugkraft der Fliege, die an dieser Nadel steckt. **Weg** ist hier `nadel.reparent(haken)`, das passiert jetzt schon in `starten`.

```gdscript
		var zurueck: Tween = create_tween()
		zurueck.tween_property(arm, "position", Vector2.ZERO, dauer)
		await zurueck.finished
	laeuft = false
```
Wie bisher: Arm zurueck, dann die naechste Nadel aus der Schlange oder Ende.

```gdscript
func platz(nummer: int) -> Vector2:
	var schritte: float = ceilf(nummer / 2.0)
	var seite: float = 1.0
	if nummer % 2 == 0:
		seite = -1.0
	return Vector2(seite * schritte * abstand, 0.0)
```
Diese Funktion rechnet aus, wo die Fliege mit der Nummer 0, 1, 2, 3 ... haengt. Die Reihe waechst von der Mitte abwechselnd nach rechts und links, damit sie in der Mitte bleibt und keine haengende Fliege verschoben werden muss:

| nummer | nummer / 2.0 | schritte (aufgerundet) | seite | x |
|--------|--------------|------------------------|-------|-----|
| 0 | 0,0 | 0 | -1 | 0 |
| 1 | 0,5 | 1 | 1 | 110 |
| 2 | 1,0 | 1 | -1 | -110 |
| 3 | 1,5 | 2 | 1 | 220 |
| 4 | 2,0 | 2 | -1 | -220 |

- `ceilf` rundet auf: aus 0,5 wird 1, aus 1,5 wird 2. `2.0` mit Punkt, damit Godot mit Kommazahlen teilt.
- `%` ist der Rest beim Teilen. `nummer % 2 == 0` heisst: Die Nummer ist gerade. Gerade Nummern haengen links (`seite = -1`), ungerade rechts.
- Das Ergebnis ist ein Punkt relativ zum Haken: x nach der Tabelle, y 0, also genau auf der Hoehe des Hakens.

**Platzhalter:** Bei 100 Pixel grossen Fliegen passen etwa 13 nebeneinander ins Bild. Fuer 100 Flugkraft braucht man 50. Das Zusammenruecken und Schrumpfen baut Abschnitt 5 (Faecher).

### `szenen/spiel.tscn` - geaendert (Haken)

- **Haken:** sitzt jetzt bei x 0, y -800 (vorher x 620, y -860), also oben in der Bildmitte. 60 Pixel tiefer als vorher, weil die Fliege bis zu 50 Pixel ueber der Nadelspitze haengen kann und sonst oben aus dem Bild ragt.

## Abschnitt 4 - Flugkraft und Hoehe

**Was der Abschnitt kann:** Oben links steht die Flugkraft, zum Beispiel `34 / 100`. Jede gefangene Fliege gibt 2 Flugkraft, sobald sie oben in der Reihe haengt. Dann gleitet die Kanone mit der Kamera nach oben, 300 Pixel je Punkt Flugkraft, also 600 Pixel je Fliege. Das ist mehr als ein halbes Bild. Der Boden verschwindet nach unten. Verpasste Fliegen ziehen nach unten aus dem Bild. Von oben kommen neue Fliegen nach, eine alle 250 Pixel Hoehe. Bei 100 erscheint "Im All!", und die Kanone steht still.

**Platzhalter:** Die Siegmeldung ist nur ein Wort. Neu anfangen kann man erst ab Abschnitt 7. Alle Fliegen sind gleich (2 Flugkraft), der Mix je Hoehe kommt in Abschnitt 9.

**Neue Dateien:** `skripte/spiel.gd`, `skripte/erzeuger.gd`. **Geaendert:** `szenen/spiel.tscn`.

### Wer macht was

- **`spiel.gd`** zaehlt die Flugkraft, schreibt die Anzeige, laesst die Kanone steigen und meldet den Sieg.
- **`erzeuger.gd`** setzt neue Fliegen ueber das Bild und loescht die, die unten weg sind.
- Die **Uebergabe** sagt nur "eine Fliege ist angekommen, sie bringt so viel Flugkraft". Was daraus wird, entscheidet `spiel.gd`.

### Der Trick: Steigen heisst, die Kanone geht in der Welt nach oben

Wie beim Fahren in Abschnitt 1: Nicht die Welt bewegt sich, sondern die Kanone. Die Kamera, die rechte Hand und der Haken sind Kinder der Kanone und kommen mit. Der Boden und die freien Fliegen bleiben, wo sie sind, und rutschen deshalb im Bild nach unten. In Godot zeigt y nach **unten**. Hoeher heisst also: y wird kleiner, und ueber dem Boden ist y negativ.

### `skripte/spiel.gd` (die ganze Datei)

```gdscript
extends Node2D
```
Das Skript haengt am obersten Knoten `Spiel`.

```gdscript
# Bei so viel Flugkraft ist man im All.
@export var ziel: int = 100
# Wie viele Pixel man fuer einen Punkt Flugkraft steigt.
@export var hoehe_je_flugkraft: float = 300.0
# Wie lange das Gleiten nach oben dauert, in Sekunden.
@export var steigdauer: float = 0.8
```
Drei Werte fuer den Inspector. Mit `hoehe_je_flugkraft` stellt man ein, wie viel Hintergrund an einem vorbeizieht: 100 Flugkraft mal 300 Pixel sind 30000 Pixel, etwa 28 Bilder uebereinander. Die Punkte bis 100 aendern sich dadurch nicht, nur der Weg.

```gdscript
# Die Flugkraft aller Fliegen, die oben in der Reihe haengen.
var flugkraft: int = 0
# Das Gleiten nach oben, das gerade laeuft. null heisst: Es gab noch keins.
var steigen: Tween = null
```
`flugkraft` ist der Spielstand. `steigen` merkt sich den Tween, der die Kanone gerade hebt, damit man ihn anhalten kann (siehe unten).

```gdscript
func _ready() -> void:
	$Kanone/Uebergabe.angekommen.connect(fliege_zaehlen)
	anzeige_schreiben()
```
`_ready` laeuft einmal am Anfang. Die erste Zeile heisst: "Wenn die Uebergabe `angekommen` ruft, rufe hier `fliege_zaehlen` auf." `$Kanone/Uebergabe` ist der Weg zum Knoten: erst `Kanone`, darin `Uebergabe`. Die zweite Zeile schreibt die Anzeige zum ersten Mal, damit dort von Anfang an `0 / 100` steht.

```gdscript
func fliege_zaehlen(dazu: int) -> void:
	flugkraft += dazu
	anzeige_schreiben()
```
`dazu` ist die Zahl, die das Signal mitbringt, also die Flugkraft der Fliege. Sie wird dazugezaehlt, dann wird die Anzeige neu geschrieben.

```gdscript
	if steigen != null:
		steigen.kill()
```
Kommt eine zweite Fliege an, waehrend die Kanone noch von der ersten steigt, laeuft noch ein alter Tween. `kill` haelt ihn an. Sonst wuerden zwei Tweens gleichzeitig an derselben Zahl ziehen, einer zum alten Ziel und einer zum neuen. Beim allerersten Mal ist `steigen` noch `null`, dann gibt es nichts anzuhalten.

```gdscript
	steigen = create_tween()
	steigen.tween_property($Kanone, "position:y", -flugkraft * hoehe_je_flugkraft, steigdauer)
```
Ein neuer Tween schiebt die Kanone in 0,8 Sekunden auf ihre neue Hoehe. `"position:y"` heisst: nur der y-Teil der Position, x bleibt, wie es ist. Das Ziel ist `-flugkraft * hoehe_je_flugkraft`: Bei 2 Flugkraft ist das -600, bei 4 ist es -1200. Das Minus steht da, weil oben in Godot negativ ist. Die Hoehe wird jedes Mal **aus dem ganzen Stand** ausgerechnet, nicht "600 dazu". So stimmt sie auch dann, wenn der alte Tween mittendrin angehalten wurde.

```gdscript
	if flugkraft >= ziel:
		$Bedienung/Sieg.visible = true
		$Kanone.set_process(false)
```
Ist das Ziel erreicht (`>=` heisst: gleich oder mehr), wird das Wort "Im All!" sichtbar. `set_process(false)` schaltet `_process` der Kanone ab: Sie faehrt und schiesst nicht mehr. Das Steigen laeuft trotzdem zu Ende, weil der Tween in `spiel.gd` laeuft und nicht in der Kanone.

```gdscript
func anzeige_schreiben() -> void:
	$Bedienung/Anzeige.text = str(flugkraft) + " / " + str(ziel)
```
`str` macht aus einer Zahl einen Text. Mit `+` werden Texte aneinandergehaengt: `"34"` und `" / "` und `"100"` ergibt `34 / 100`.

### `skripte/erzeuger.gd` (die ganze Datei)

```gdscript
extends Node2D

# Die Szene der Fliege. Daraus entsteht jede neue Fliege.
@export var fliege_szene: PackedScene
# Die Kanone. An ihr liest der Erzeuger ab, wie hoch man gerade ist.
@export var kanone: Node2D
```
Der Erzeuger braucht zwei Dinge aus dem Inspector: die Vorlage fuer Fliegen und die Kanone.

```gdscript
# Wie viele Pixel Hoehe zwischen zwei Fliegen liegen.
@export var abstand: float = 250.0
# Wie weit links oder rechts von der Kanone eine Fliege hoechstens entsteht, in Pixeln.
@export var breite: float = 400.0
```
Alle 250 Pixel Hoehe gibt es eine Fliege. Ein Bild ist 1080 hoch, es sind also etwa vier Fliegen zu sehen. Jede entsteht irgendwo zwischen 400 Pixel links und 400 Pixel rechts von der Kanone. Dazu kommt ihre eigene Strecke von 300 hin und her.

```gdscript
# Wie weit ueber der Kanone die oberste Fliege schon bereitsteht, in Pixeln. Der Bildrand liegt bei 920.
@export var vorlauf: float = 1200.0
# Wie weit unter der Kanone eine Fliege geloescht wird, in Pixeln. Der Bildrand liegt bei 160.
@export var loeschen_unter: float = 300.0
```
Das Bild reicht von 920 Pixel ueber der Kanone bis 160 Pixel unter ihr. `vorlauf` ist groesser als 920: Neue Fliegen entstehen ueber dem Bild, man sieht sie nie aufploppen. `loeschen_unter` ist groesser als 160: Geloescht wird erst, was sicher unten aus dem Bild ist.

```gdscript
# Das langsamste und das schnellste Tempo einer neuen Fliege, in Pixeln pro Sekunde.
@export var tempo_langsam: float = 100.0
@export var tempo_schnell: float = 180.0
```
Jede Fliege bekommt ein zufaelliges Tempo zwischen diesen beiden.

```gdscript
# Auf dieser Hoehe entsteht die naechste Fliege. Nach oben wird y kleiner.
var naechste_hoehe: float = -400.0
```
Die erste Fliege entsteht bei y -400, also 400 Pixel ueber dem Boden. Danach wandert diese Zahl immer weiter nach oben.

```gdscript
func _process(_delta: float) -> void:
	while naechste_hoehe > kanone.position.y - vorlauf:
```
In jedem Bild schaut der Erzeuger nach. `kanone.position.y - vorlauf` ist die Linie 1200 Pixel ueber der Kanone. Solange die naechste Fliege **unter** dieser Linie laege (groesseres y heisst weiter unten), wird sie jetzt gebaut. `while` wiederholt das, bis alles bis zur Linie gefuellt ist. Am Anfang baut die Schleife so gleich vier Fliegen, nach jedem Steigen zwei oder drei. Der Unterstrich in `_delta` sagt Godot: Diese Zahl wird hier nicht gebraucht.

```gdscript
		var fliege: Node2D = fliege_szene.instantiate()
		fliege.position.x = kanone.position.x + randf_range(-breite, breite)
		fliege.position.y = naechste_hoehe
		fliege.tempo = randf_range(tempo_langsam, tempo_schnell)
```
Eine neue Fliege aus der Vorlage. `randf_range(a, b)` liefert eine zufaellige Kommazahl zwischen a und b. Die Fliege entsteht seitlich in der Naehe der Kanone, **dort, wo die Kanone in diesem Moment ist**. Weil die Welt seitlich endlos ist, bleiben die Fliegen so immer in der Naehe. Die Hoehe ist `naechste_hoehe`, das Tempo zufaellig.

```gdscript
		add_child(fliege)
		naechste_hoehe -= abstand
```
Die Fliege wird ein Kind des Erzeugers und erscheint damit im Spiel. Dann rueckt `naechste_hoehe` um 250 nach oben (y wird kleiner). Irgendwann liegt sie ueber der Linie, und die `while`-Schleife hoert auf.

```gdscript
	for fliege in get_children():
		if fliege.position.y > kanone.position.y + loeschen_unter:
			fliege.queue_free()
```
Danach geht der Erzeuger alle seine Kinder durch, also alle freien Fliegen. Ist eine mehr als 300 Pixel unter der Kanone, wird sie geloescht. Das ist die verpasste Fliege, die unten aus dem Bild gezogen ist. Gefangene Fliegen sind hier nicht dabei: Sie sind beim Treffer Kinder der Nadel geworden und keine Kinder des Erzeugers mehr.

### `szenen/spiel.tscn` - geaendert

```
Spiel (Node2D, traegt spiel.gd)             Skript neu
├── Boden ...                               (unveraendert)
├── Erzeuger (Node2D, traegt erzeuger.gd)   neu
├── Kanone ...                              (nur der Haken ist verschoben, siehe oben)
└── Bedienung (CanvasLayer)
    ├── TasteLinks, TasteRechts, TasteSchuss    (unveraendert)
    ├── Anzeige (Label)                     neu
    └── Sieg (Label)                        neu
```

- **Spiel:** traegt jetzt `spiel.gd`.
- **Fliege1 bis Fliege5 sind weg.** Die Fliegen baut der Erzeuger.
- **Erzeuger:** ein `Node2D` bei 0, 0 ohne eigenes Bild. Im Inspector: `fliege_szene = fliege.tscn`, `kanone = ../Kanone`. Er muss bei 0, 0 bleiben, weil die Fliegen seine Kinder sind und ihre Positionen sonst verschoben waeren.
- **Anzeige:** ein `Label` oben links (x 40, y 30), Schriftgroesse 56. Der Text `0 / 100` in der Szene ist nur fuer den Editor, `spiel.gd` ueberschreibt ihn beim Start. Sie haengt im `CanvasLayer` `Bedienung` wie die Tasten und bleibt deshalb an ihrer Stelle im Bild, egal wohin die Kamera geht.
- **Sieg:** ein `Label` ueber die ganze Bildbreite, Text "Im All!", Schriftgroesse 140, mittig. `visible = false`: am Anfang unsichtbar, `spiel.gd` schaltet es bei 100 ein.
- Oben in der Datei stehen zwei neue `ext_resource`-Zeilen fuer `spiel.gd` und `erzeuger.gd`.

### `.uid`-Dateien (von Godot selbst angelegt)

`spiel.gd.uid` und `erzeuger.gd.uid`: Kennnummern wie bei den anderen Skripten. Nicht von Hand aendern.

### Drei Fragen zur Selbstkontrolle

1. Die Fliege faehrt 0,1 Sekunden nach dem Arm los. Warum kommen beide trotzdem im selben Moment an?
2. Du faengst zwei Fliegen kurz hintereinander, die zweite kommt an, waehrend die Kanone noch steigt. Auf welcher Hoehe landet die Kanone, und welche Zeilen sorgen dafuer?
3. Woher weiss der Erzeuger, wann er eine neue Fliege bauen muss, und warum sieht man sie nie aufploppen?

<details><summary>Antworten</summary>

1. Der Arm faehrt `dauer` lang (0,48). Die Fliege wartet `verzoegerung` (0,1, `set_delay`) und faehrt dann nur `dauer - verzoegerung` lang (0,38). 0,1 + 0,38 = 0,48.
2. Auf -1200 (4 Flugkraft mal 300). `steigen.kill()` haelt den ersten Tween an, der neue faehrt zum Ziel `-flugkraft * hoehe_je_flugkraft`. Das wird aus dem ganzen Stand gerechnet, nicht aus der Stelle, an der die Kanone gerade ist.
3. Er vergleicht in jedem Bild `naechste_hoehe` mit der Linie `kanone.position.y - vorlauf`. Steigt die Kanone, wandert die Linie nach oben, und die `while`-Schleife fuellt nach. Die Linie liegt 1200 Pixel ueber der Kanone, der Bildrand nur 920: Die Fliege entsteht ueber dem Bild.

</details>

---

## Abschnitt 5 - Faecher, Faeden und Leiste

**Was der Abschnitt kann:** Die gefangenen Fliegen haengen oben im Bild als **Faecher** nebeneinander. Die Reihe bleibt als Ganzes immer mittig: Kommt eine Fliege dazu, gleiten alle anderen ein halbes Stueck zur Seite. Neue Fliegen kommen abwechselnd links und rechts ans Ende. Wird der Faecher breiter als 1400 Pixel, werden alle Fliegen gemeinsam kleiner, gleitend ueber 1,5 Sekunden, gerade so weit, dass er wieder passt. Jede Nadel zieht einen grauen **Faden** hinter sich her, erst von der Muendung der Kanone. Bei der Uebergabe bringt der Arm den Faden zur rechten Hand, ab dann laeuft er von der Hand zur Fliege. Die Zahl `34 / 100` oben links ist weg, dafuer haengt unten an der Kanone eine **Leiste**, die sich von 0 bis 100 fuellt.

**Platzhalter:** Die Leiste hat das Standard-Aussehen von Godot. Spaeter kommt eine Leiste wie im Lautstaerke-Menue von Pineapple an die gebaute Kanone. Die Faeden sind graue Linien, damit man sieht, wie sehr sie stoeren. Wie man das loest, ist offen.

**Neue Dateien:** `skripte/faecher.gd`. **Geaendert:** `skripte/uebergabe.gd`, `skripte/nadel.gd`, `skripte/kanone.gd`, `skripte/spiel.gd`, `szenen/nadel.tscn`, `szenen/spiel.tscn`.

### Wer macht was

- **`faecher.gd`** kennt die Reihenfolge der Fliegen von links nach rechts, rechnet aus, wo jede hingehoert und wie gross alle sind, und laesst die schon haengenden dorthin gleiten.
- **`uebergabe.gd`** faehrt wie bisher den Arm hin und zurueck und bringt die **neue** Fliege an ihren Platz. Den Platz fragt sie jetzt beim Faecher nach, statt ihn selbst zu rechnen.
- **`nadel.gd`** zeichnet ihren Faden. Woran der Faden haengt, steht in `anker`: erst die Muendung, nach der Uebergabe die Hand.
- **`spiel.gd`** schreibt die Flugkraft in die Leiste statt in ein Label.

### Der Trick 1: Kein Wegdruecken, nur eine Liste

Im Feinkonzept druecken sich die Fliegen gegenseitig weg. Das waere Physik: Jede Fliege muesste ihre Nachbarn spueren. Hier ist es einfacher. Die Fliegen stehen in einer **Liste** von links nach rechts. Aus der Nummer in der Liste folgt der Platz: Die mittlere Nummer sitzt bei x 0, jede weitere ein `abstand` weiter. Kommt eine Fliege dazu, wird fuer **alle** der Platz neu gerechnet, und alle gleiten dorthin. Fuer das Auge sieht das aus wie Wegdruecken.

### Der Trick 2: Der Faecher faehrt nicht mit dem Arm

Der Faecher ist ein Kind der **Kanone**, nicht des **Arms**. Bei der Uebergabe faehrt nur der Arm nach rechts, die Kanone selbst steht. Deshalb bleibt der Faecher stehen. Beim Fahren und beim Steigen bewegt sich die Kanone mit der Kamera, der Faecher kommt mit und bleibt so immer am oberen Bildrand.

### `skripte/faecher.gd` (die ganze Datei)

```gdscript
extends Node2D
```
Das Skript haengt am Knoten `Faecher` unter der Kanone. Seine Position (0, -800) ist die Mitte des Faechers.

```gdscript
# Wie weit zwei Fliegen im Faecher auseinander sind, solange er noch nicht schrumpfen muss, in Pixeln.
@export var abstand: float = 110.0
```
Eine Fliege ist 100 breit, dazu 10 Luft. Diese Zahl stand vorher in `uebergabe.gd` und ist hierher umgezogen, weil jetzt der Faecher die Plaetze rechnet.

```gdscript
# Wie breit der Faecher hoechstens werden darf, in Pixeln. Das Bild ist 1440 breit.
@export var breite: float = 1400.0
```
1400 laesst links und rechts je 20 Pixel Rand. Mit 110 pro Fliege passen 12 Fliegen (1320) voll gross hinein. Ab der 13. (1430) muss er schrumpfen.

```gdscript
# Wie lange das Zusammenruecken und Schrumpfen dauert, in Sekunden. Lang heisst: man merkt es kaum.
@export var gleitdauer: float = 1.5
```
Deine Wahl Z11. Im Inspector aenderbar.

```gdscript
# Die Nadeln mit Fliege, die im Faecher haengen, von links nach rechts.
var reihe: Array[Node2D] = []
```
Eine Liste. `Array[Node2D]` heisst: Es duerfen nur Knoten vom Typ `Node2D` hinein. Gespeichert wird die **Nadel**, nicht die Fliege, denn die Fliege steckt als Kind an der Nadel. Bewegt man die Nadel, kommen Fliege und Faden mit.

```gdscript
# Das Gleiten, das gerade laeuft. null heisst: Es gab noch keins.
var gleiten: Tween = null
```
Wie `steigen` in `spiel.gd`: Wir merken uns den Tween, damit wir ihn anhalten koennen, wenn die naechste Fliege kommt, bevor das Gleiten fertig ist.

```gdscript
func aufnehmen(neue: Node2D) -> void:
	if reihe.size() % 2 == 0:
		reihe.push_front(neue)
	else:
		reihe.push_back(neue)
```
Die Uebergabe ruft das auf, sobald eine Nadel mit Fliege losfaehrt. `reihe.size()` ist die Zahl der Fliegen, die schon haengen. `% 2` ist der Rest beim Teilen durch 2: 0 bei gerader Zahl, 1 bei ungerader. Bei gerader Zahl kommt die neue Fliege nach **vorne** in die Liste (`push_front`, also ganz links), bei ungerader nach **hinten** (`push_back`, ganz rechts). So waechst der Faecher abwechselnd zu beiden Seiten. Bei der allerersten Fliege ist die Liste leer, dann ist vorne und hinten dasselbe.

```gdscript
	if gleiten != null:
		gleiten.kill()
```
Laeuft noch ein Gleiten von der letzten Fliege, wird es angehalten. Die Fliegen bleiben da stehen, wo sie gerade sind, und gleiten von dort zum neuen Platz. Darum gibt es keinen Sprung.

```gdscript
	if reihe.size() == 1:
		return
```
Ist die neue Fliege die einzige, gibt es nichts zu verschieben. `return` beendet die Funktion hier. Ohne diese Zeile wuerde ein leerer Tween gestartet, und Godot meldet dann einen Fehler.

```gdscript
	gleiten = create_tween()
	gleiten.set_parallel(true)
```
Ein neuer Tween. `set_parallel(true)` heisst: Alles, was wir gleich hineinlegen, laeuft **gleichzeitig** statt nacheinander. Sonst wuerde erst die erste Fliege gleiten, dann die zweite und so weiter.

```gdscript
	for nadel in reihe:
		if nadel == neue:
			continue
```
Die Schleife geht jede Nadel in der Liste durch. Die neue ueberspringen wir (`continue` springt zur naechsten Runde): Die bringt die Uebergabe an ihren Platz, im Takt mit dem Arm.

```gdscript
		gleiten.tween_property(nadel, "position", platz(nadel), gleitdauer)
		gleiten.tween_property(nadel, "scale", Vector2.ONE * groesse(), gleitdauer)
```
Zwei Bewegungen je Nadel: zur neuen Position und zur neuen Groesse. `scale` ist der Groessenfaktor eines Knotens: (1, 1) ist normal, (0.5, 0.5) halb so gross, und Kinder schrumpfen mit, also auch die Fliege. `Vector2.ONE` ist (1, 1), mal `groesse()` ergibt zum Beispiel (0.98, 0.98).

```gdscript
func groesse() -> float:
	return minf(1.0, breite / (reihe.size() * abstand))
```
Wie gross alle Fliegen gerade sein muessen. `reihe.size() * abstand` ist die Breite, die der Faecher bei voller Groesse braeuchte. `breite` geteilt dadurch sagt, wie viel davon hineinpasst. Beispiel 13 Fliegen: 1400 / 1430 = 0,979. Bei 5 Fliegen kaeme 1400 / 550 = 2,5 heraus, die Fliegen wuerden also groesser. `minf(1.0, ...)` nimmt die kleinere von zwei Zahlen, damit ist bei 1,0 Schluss. Bei 50 Fliegen (= 100 Flugkraft) ist der Faktor 0,25, die Fliegen sind dann etwa 25 Pixel gross.

```gdscript
func platz(nadel: Node2D) -> Vector2:
	var nummer: int = reihe.find(nadel)
	var mitte: float = (reihe.size() - 1) / 2.0
	return Vector2((nummer - mitte) * abstand * groesse(), 0.0)
```
Wo eine Nadel hingehoert, gemessen von der Mitte des Faechers. `reihe.find(nadel)` gibt ihre Nummer in der Liste (die erste hat 0). `mitte` ist die Nummer, die genau in der Mitte steht: bei 3 Fliegen 1, bei 4 Fliegen 1,5 (also zwischen zwei Fliegen). `nummer - mitte` ist dann negativ fuer links und positiv fuer rechts. Mal `abstand`, mal `groesse()`: Wenn die Fliegen schrumpfen, ruecken sie im selben Mass zusammen. Beispiel 3 Fliegen: -110, 0, 110. Beispiel 4 Fliegen: -165, -55, 55, 165. y ist immer 0, die Fliegen haengen also auf einer Linie.

### `skripte/uebergabe.gd` - geaendert in Abschnitt 5 (die ganze Datei)

Weg sind: `abstand`, `anzahl`, `haken` und die Funktion `platz`. Das macht jetzt der Faecher. Neu oder geaendert sind nur die markierten Stellen, der Rest ist wie in Abschnitt 3.

```gdscript
# Wird gesendet, sobald eine Fliege im Faecher oben haengt. Mit dabei: ihre Flugkraft.
signal angekommen(flugkraft: int)
```
Nur der Kommentar sagt jetzt "Faecher" statt "Reihe".

```gdscript
# Der Arm: linke Hand, Kanone und Muendung. Nur er faehrt, die Kamera und der Faecher bleiben stehen.
@export var arm: Node2D
# Der Faecher am oberen Bildrand, in dem die gefangenen Fliegen haengen.
@export var faecher: Node2D
# Der Punkt an der rechten Hand, an dem die Faeden der Fliegen im Faecher festhaengen.
@export var griff: Node2D
```
`faecher` ersetzt `haken`, es zeigt auf den Knoten `Faecher`. `griff` ist neu: ein Marker an der Oberkante der rechten Hand. Beide werden im Inspector eingetragen.

```gdscript
func starten(nadel: Node2D) -> void:
	nadel.reparent(faecher)
```
Wie vorher, nur heisst das Ziel jetzt `faecher`. Die Nadel wird schon beim Treffer Kind des Faechers, bleibt aber noch da, wo sie getroffen hat. In die Liste des Faechers kommt sie erst, wenn ihre Uebergabe startet.

```gdscript
		var nadel: Node2D = warteschlange.pop_front()
		faecher.aufnehmen(nadel)
```
Neu: Bevor der Arm losfaehrt, nimmt der Faecher die Nadel in seine Liste auf. Dabei gleiten die schon haengenden Fliegen los.

```gdscript
		var fahrzeit: float = dauer - verzoegerung
```
Neu, aber nur der Lesbarkeit wegen: Die Fliege faehrt 0,48 - 0,1 = 0,38 Sekunden. Vorher stand die Rechnung direkt im Tween, jetzt wird sie zweimal gebraucht.

```gdscript
		hin.parallel().tween_property(nadel, "position", faecher.platz(nadel), fahrzeit).set_delay(verzoegerung)
		hin.parallel().tween_property(nadel, "scale", Vector2.ONE * faecher.groesse(), fahrzeit).set_delay(verzoegerung)
```
Erste Zeile: Der Platz kommt jetzt vom Faecher (`faecher.platz(nadel)`). Zweite Zeile, neu: Die neue Fliege schrumpft auf dem Weg schon auf die Groesse, die alle gerade bekommen. So kommt sie gleich gross wie die anderen an. Die neue Fliege braucht nur 0,38 Sekunden, die anderen gleiten 1,5 Sekunden. Die Neue ist also zuerst fertig, die anderen ruecken danach langsam nach.

```gdscript
		await hin.finished
		nadel.anker = griff
```
Neu: Sobald Arm und Fliege angekommen sind, haengt der Faden nicht mehr an der Muendung, sondern am Griff der rechten Hand. Das ist die eigentliche Uebergabe des Fadens.

Der Rest (`angekommen.emit`, Rueckfahrt, `laeuft = false`) ist unveraendert.

### `skripte/nadel.gd` - geaendert in Abschnitt 5

```gdscript
# Der Punkt, an dem der Faden der Nadel festhaengt: erst die Muendung der Kanone, im Faecher die rechte Hand.
var anker: Node2D = null
```
Neu. Die Kanone traegt beim Schuss die Muendung ein, die Uebergabe spaeter den Griff. `null` heisst: kein Faden.

```gdscript
func _process(delta: float) -> void:
	if steckt:
		faden_spannen()
		return
	position.y -= tempo * delta
	geflogen += tempo * delta
	var getroffene: Node2D = fliege_an_der_spitze()
	if getroffene != null:
		treffen(getroffene)
	elif geflogen >= reichweite:
		queue_free()
	faden_spannen()
```
Neu sind die beiden Zeilen `faden_spannen()`. Steckt die Nadel, wird nur der Faden nachgezogen (Arm und Faecher bewegen sich ja noch). Fliegt sie, wird der Faden **nach** dem Weiterfliegen gezogen. Andersherum hinge der Faden ein Bild hinterher: Bei 3200 Pixeln pro Sekunde und 60 Bildern sind das 53 Pixel Luecke zwischen Faden und Nadel.

```gdscript
func faden_spannen() -> void:
	if anker == null:
		return
	$Faden.points = PackedVector2Array([anker.global_position, $Oese.global_position])
```
Neu. Ohne Anker gibt es nichts zu zeichnen. Sonst bekommt die Linie `Faden` genau zwei Punkte: den Anker und die `Oese`, das untere Ende der Nadel. `global_position` ist die Stelle in der Welt, egal wem der Knoten gehoert. `PackedVector2Array` ist die Art Liste, die eine `Line2D` fuer ihre Punkte verlangt. Das geht so einfach nur, weil der Faden `top_level` ist (siehe `nadel.tscn`).

### `skripte/kanone.gd` - geaendert in Abschnitt 5

```gdscript
		nadel.anker = $Arm/Muendung
```
Eine neue Zeile in `schiessen`, direkt nach dem Setzen der Position: Die neue Nadel bekommt die Muendung als Anker. Weil die Muendung am Arm haengt, faehrt der Faden bei der Uebergabe mit dem Arm zur Hand.

### `skripte/spiel.gd` - geaendert in Abschnitt 5

```gdscript
	$Kanone/Arm/Leiste.max_value = ziel
```
Neu in `_ready`: Die Leiste geht bis `ziel`, also bis 100. Steht in `spiel.gd` und nicht fest in der Szene, damit Leiste und Ziel nie auseinanderlaufen, wenn man `ziel` im Inspector aendert.

```gdscript
func anzeige_schreiben() -> void:
	$Kanone/Arm/Leiste.value = flugkraft
```
Statt Text in ein Label zu schreiben, setzt die Funktion jetzt den Wert der Leiste. Die Leiste fuellt sich selbst so weit, wie `value` von `max_value` ist. Der Kommentar ueber `flugkraft` sagt jetzt "Faecher" statt "Reihe".

### `szenen/nadel.tscn` - geaendert

```
Nadel (Node2D, traegt nadel.gd)
├── Strich (ColorRect)     (unveraendert)
├── Faden (Line2D)         neu
└── Oese (Marker2D)        neu
```

- **Faden:** eine `Line2D`, also eine Linie durch Punkte. Breite 3, grau. Die Punkte setzt `nadel.gd`. **`top_level = true`** heisst: Die Linie ignoriert Position und Groesse der Nadel und rechnet direkt in Welt-Koordinaten. Ohne das wuerde sie mit der Nadel mitfliegen und im Faecher mitschrumpfen, und man muesste jeden Punkt umrechnen.
- **Oese:** ein `Marker2D` bei (0, 50), am unteren Ende des Strichs. Dort haengt der Faden. Weil sie ein echtes Kind der Nadel ist, schrumpft ihr Abstand mit, wenn die Nadel im Faecher kleiner wird.

### `szenen/spiel.tscn` - geaendert

```
Kanone
├── Arm
│   ├── LinkeHand, Koerper, Rohr, Muendung   (unveraendert)
│   └── Leiste (ProgressBar)                  neu
├── RechteHand                                (unveraendert)
├── Griff (Marker2D)                          neu
├── Faecher (Node2D, traegt faecher.gd)       war "Haken"
├── Kamera                                    (unveraendert)
└── Uebergabe                                 Inspector geaendert
Bedienung
└── Anzeige (Label)                           geloescht
```

- **Leiste:** eine `ProgressBar` unter der Kanone (x -80 bis 80, y 15 bis 40), `show_percentage = false`, damit keine Prozentzahl darauf steht. Sie haengt am **Arm**, faehrt also bei der Uebergabe mit, wie der Rest der Kanone.
- **Griff:** ein `Marker2D` bei (620, -100), oben in der Mitte der rechten Hand.
- **Faecher:** Der alte `Haken` (ein `Marker2D` bei 0, -800) ist jetzt ein `Node2D` namens `Faecher` an derselben Stelle und traegt `faecher.gd`. Ein `Marker2D` ist nur ein Kreuz im Editor, fuer das Skript braucht es das nicht.
- **Uebergabe:** im Inspector `faecher = ../Faecher` und `griff = ../Griff` statt `haken = ../Haken`.
- **Anzeige** ist geloescht. Oben in der Datei steht eine neue `ext_resource`-Zeile fuer `faecher.gd`, und `load_steps` ist von 9 auf 10 gestiegen (eine Datei mehr zu laden).

### `.uid`-Dateien (von Godot selbst angelegt)

`faecher.gd.uid`: Kennnummer wie bei den anderen Skripten. Nicht von Hand aendern.

### So wurde es angeschaut

Ein Probelauf ausserhalb des Spielordners hat 50 Faenge nachgestellt und Bilder gemacht. Bei 13 Fliegen ist der Faecher genau 1400 breit, Groesse 0,979. Beim Schrumpfen bewegt sich jede Fliege hoechstens 2,2 Pixel pro Bild, es gibt also keinen Sprung. Bei 50 Fliegen ist die Groesse 0,25, die Leiste steht auf 100. Ob 1,5 Sekunden sich gut anfuehlen und wie sehr die Faeden stoeren, entscheidest du am Spiel.

### Drei Fragen zur Selbstkontrolle

1. Es haengen 4 Fliegen im Faecher. Wo genau (x) haengen sie, und wo kommt die 5. hin?
2. Warum bleibt der Faecher stehen, wenn der Arm zur Hand faehrt, aber der Faden der neuen Fliege faehrt mit?
3. Du faengst die 13. Fliege, und 0,8 Sekunden spaeter kommt schon die 14. an. Was passiert mit dem Gleiten der 13., und warum springt dabei nichts?

<details><summary>Antworten</summary>

1. `mitte` = (4 - 1) / 2 = 1,5. Nummern 0 bis 3 ergeben -1,5, -0,5, 0,5, 1,5 mal 110: also -165, -55, 55, 165. Bei 4 (gerade) kommt die 5. mit `push_front` nach ganz links. Danach rechnen alle neu mit `mitte` 2: -220, -110, 0, 110, 220. Die Neue landet bei -220, die anderen gleiten je 55 nach rechts.
2. Der Faecher ist ein Kind der Kanone, der Arm faehrt in der Kanone, also bewegt er den Faecher nicht. Der Faden haengt an `anker`, und das ist bis zum Ende der Fahrt die Muendung, und die sitzt am Arm. Erst danach setzt die Uebergabe `anker = griff`.
3. `aufnehmen` ruft `gleiten.kill()` auf. Die Fliegen bleiben, wo sie gerade sind (mitten im Weg), und ein neuer Tween laesst sie von dort zum neuen Platz und zur neuen Groesse gleiten. Ein Tween faengt immer beim aktuellen Wert an, darum springt nichts.

</details>

### Nachtrag Abschnitt 5 (gleicher Tag): Steigen, Hoehenversatz, hohe Hand

Philipp hat nach dem ersten Bau noch drei Dinge gewuenscht: Die Fliege soll erst auf die Hoehe des Faechers steigen und dann seitlich an ihren Platz gehen. Die Fliegen sollen nicht auf einer Linie haengen, sondern leicht versetzt. Und die Hand haelt die Faeden weiter oben, damit sie weniger vom Bild verdecken.

#### `skripte/faecher.gd` - geaendert

```gdscript
# Wie weit eine Fliege hoechstens ueber oder unter der Linie haengt, in Pixeln. Macht den Faecher natuerlicher.
@export var hoehen_streuung: float = 20.0
```
Neu. 20 heisst: Jede Fliege haengt irgendwo zwischen 20 Pixeln hoeher und 20 Pixeln tiefer als die Linie.

```gdscript
# Fuer jede Nadel ihr eigener Hoehenunterschied. Wird einmal beim Aufnehmen ausgewuerfelt.
var versatz: Dictionary = {}
```
Neu. Ein `Dictionary` ist eine Liste mit Schluesseln: Zu jeder Nadel (Schluessel) steht ihre Zahl (Wert). So behaelt jede Fliege ihren Versatz, auch wenn sie spaeter zur Seite gleitet. Wuerfelte man jedes Mal neu, wuerden alle Fliegen bei jedem Fang auf und ab huepfen.

```gdscript
	versatz[neue] = randf_range(-hoehen_streuung, hoehen_streuung)
```
Neu, erste Zeile in `aufnehmen`. `randf_range(a, b)` gibt eine zufaellige Kommazahl zwischen a und b. Die wird unter der neuen Nadel gespeichert.

```gdscript
	return Vector2((nummer - mitte) * abstand * groesse(), versatz[nadel])
```
Geaendert in `platz`: y ist nicht mehr immer 0, sondern der Versatz dieser Nadel.

#### `skripte/uebergabe.gd` - geaendert

```gdscript
		var ziel: Vector2 = faecher.platz(nadel)
		hin.parallel().tween_property(nadel, "position:y", ziel.y, fahrzeit / 2.0).set_delay(verzoegerung)
		hin.parallel().tween_property(nadel, "position:x", ziel.x, fahrzeit / 2.0).set_delay(verzoegerung + fahrzeit / 2.0)
```
Ersetzt die eine Zeile, die die Fliege schraeg zu ihrem Platz fahren liess. `"position:y"` bewegt nur die Hoehe, `"position:x"` nur die Seite. Die Fahrzeit (0,38 s) wird halbiert: Erst steigt die Fliege 0,19 s lang auf die Hoehe des Faechers, dann geht sie 0,19 s lang zur Seite. Die zweite Bewegung wartet dafuer `verzoegerung + fahrzeit / 2.0`, also 0,1 + 0,19 = 0,29 s. Zusammen 0,48 s: Die Fliege kommt weiter gleichzeitig mit dem Arm an. Die Zeile fuer `scale` bleibt, die Fliege schrumpft waehrend der ganzen Fahrt.

#### `szenen/spiel.tscn` - geaendert

- **RechteHand:** von y -100 bis -20 hoch nach y -560 bis -480. Im Bild sitzt sie jetzt rechts oben im oberen Drittel. Die Faeden kreuzen nur noch den Bereich ueber ihr. Nebenbei liegt sie nicht mehr auf der rechten Pfeiltaste fuers Handy.
- **Griff:** mit der Hand hoch, von (620, -100) nach (620, -560).
- Der Arm faehrt bei der Uebergabe weiter nach unten rechts (x 480). Am Ende springt der Faden deshalb von der Muendung hoch zur Hand. Ob das stoert, siehst du am Spiel.

#### Frage zur Selbstkontrolle

4. Warum wird der Hoehenversatz in `versatz` gespeichert, statt in `platz` jedes Mal neu ausgewuerfelt?

<details><summary>Antwort</summary>

4. `platz` wird bei jedem Fang fuer alle Fliegen neu aufgerufen. Wuerfelte es jedes Mal neu, bekaeme jede Fliege bei jedem Fang eine neue Hoehe und wuerde sichtbar hoch und runter gleiten. Gespeichert behaelt sie ihre Hoehe, nur x und die Groesse aendern sich.

</details>

## Abschnitt 6 - Hindernisse und Absturz

Ein gelbes Warnschild kuendigt eine Spalte an. Es waechst und blinkt immer schneller. Nach 3 Sekunden faellt ein grauer Klotz durch die Spalte und zermatscht jede Fliege darin, freie und gefangene. Fuer jede verlorene Fliege im Faecher stuerzt der Forscher um ihre Flugkraft ab. Waehrend des Falls kann man nicht schiessen, fahren geht weiter. Danach geht es auf der neuen Hoehe weiter.

### Wer macht was

- `hindernis_erzeuger.gd` wuerfelt alle 6 bis 10 Sekunden eine Spalte aus und setzt dort ein Hindernis hin.
- `hindernis.gd` warnt, faellt und zermatscht.
- `faecher.gd` nimmt eine getroffene Fliege aus der Reihe und meldet, wie viel Flugkraft weg ist (Signal `verloren`).
- `spiel.gd` zieht die Flugkraft ab, laesst die Kanone fallen und sperrt so lange das Schiessen.
- `kanone.gd` schiesst nicht, solange `gesperrt` true ist.

### Der Trick 1: Die Warnung klebt am Bildrand, nicht an der Welt

Das Hindernis ist ein Knoten in der Welt, damit es an einer festen Stelle x faellt. Waehrend der Warnung setzt es sich aber jedes Bild neu auf `kanone.position.y - 920`. Das ist der obere Bildrand, denn die Kamera haengt an der Kanone. Steigt man waehrend der Warnung, bleibt das Schild trotzdem oben im Bild.

### Der Trick 2: Fallen heisst gleiten mit fester Geschwindigkeit

Beim Steigen gibt es eine feste Dauer (0,8 s). Beim Fallen gibt es stattdessen eine feste Geschwindigkeit (`falltempo`, 1200 px/s). Die Dauer ist dann Strecke geteilt durch Geschwindigkeit. Eine verlorene Fliege (2 Flugkraft, 600 px) dauert 0,5 s, zehn verlorene Fliegen (6000 px) dauern 5 s. Wer mehr verliert, faellt laenger.

### `skripte/hindernis.gd` (die ganze Datei, neu)

```gdscript
extends Node2D
```
Das Hindernis ist ein `Node2D`: Es hat eine Position in der Welt.

```gdscript
# Wie lange die Warnung laeuft, bevor der Gegenstand faellt, in Sekunden.
@export var warnzeit: float = 3.0
# Wie breit die Spalte ist, in Pixeln. Jede Fliege darin wird zermatscht.
@export var breite: float = 200.0
# Wie hoch der fallende Gegenstand ist, in Pixeln.
@export var hoehe: float = 120.0
# Wie schnell der Gegenstand faellt, in Pixeln pro Sekunde. Muss schneller sein als der Absturz (falltempo in spiel.gd).
@export var falltempo: float = 1800.0
```
Die vier Werte, die du am Spiel einstellst. Warum der Klotz schneller fallen muss als der Forscher, steht unten bei `spiel.gd`.

```gdscript
# Wie lange ein Blinken der Warnung dauert, am Anfang und am Ende, in Sekunden. Kleiner heisst schneller.
@export var blinken_anfang: float = 0.5
@export var blinken_ende: float = 0.1
```
Am Anfang ist das Schild eine halbe Sekunde lang einmal an und aus, am Ende nur noch eine Zehntelsekunde: Es blinkt immer hektischer.

```gdscript
# Wie weit ueber der Kanone der obere Bildrand liegt, in Pixeln.
@export var bildrand: float = 920.0
# Wie weit unter der Kanone der Gegenstand verschwindet, in Pixeln. Der untere Bildrand liegt bei 160.
@export var weg_unter: float = 300.0
```
920 ist dieselbe Zahl wie im Fliegen-Erzeuger: Kamera 380 ueber der Kanone plus halbe Bildhoehe 540. Bei 300 unter der Kanone ist der Klotz sicher unten aus dem Bild und wird geloescht.

```gdscript
# Die Szene des Matsches. Bei jeder zermatschten Fliege entsteht daraus ein Fleck.
@export var matsch_szene: PackedScene
```
Im Inspector steht hier `blutfleck.tscn`. Der rote Fleck aus Abschnitt 3 ist bis Abschnitt 12 auch der Matsch.

```gdscript
# Die Kanone. Die Warnung bleibt ueber ihr am oberen Bildrand. Setzt der Hindernis-Erzeuger.
var kanone: Node2D = null
# Der Faecher. Aus ihm werden getroffene Fliegen entfernt. Setzt der Hindernis-Erzeuger.
var faecher: Node2D = null
```
Kein `@export`, denn das Hindernis entsteht erst im Spiel. Im Inspector gibt es da nichts einzutragen. Der Erzeuger setzt beide Werte, bevor er das Hindernis in die Welt haengt.

```gdscript
# Wie viele Sekunden schon gewarnt wird.
var gewarnt: float = 0.0
```
Zaehlt hoch. Ist er bei `warnzeit`, faellt der Klotz.

```gdscript
func _ready() -> void:
	$Spalte.offset_left = -breite / 2.0
	$Spalte.offset_right = breite / 2.0
	$Klotz.offset_left = -breite / 2.0
	$Klotz.offset_right = breite / 2.0
	$Klotz.offset_top = -hoehe
```
Die gelbe Spalte und der graue Klotz sind `ColorRect`s. Ihre Raender werden hier aus `breite` und `hoehe` gesetzt, mittig um x = 0. So reicht es, `breite` im Inspector zu aendern, und Bild und Treffer stimmen weiter ueberein.

```gdscript
func _process(delta: float) -> void:
	if gewarnt < warnzeit:
		warnen(delta)
	else:
		fallen(delta)
```
Jedes Bild: erst warnen, nach Ablauf der Warnzeit fallen.

```gdscript
func warnen(delta: float) -> void:
	gewarnt += delta
	position.y = kanone.position.y - bildrand
```
Zeit hochzaehlen und am oberen Bildrand bleiben (Trick 1).

```gdscript
	var anteil: float = gewarnt / warnzeit
	$Warnung.scale = Vector2.ONE * (0.5 + anteil)
```
`anteil` laeuft von 0 (Anfang) bis 1 (gleich faellt es). Das Schild waechst von halber Groesse (0,5) auf anderthalbfache (1,5).

```gdscript
	var takt: float = lerpf(blinken_anfang, blinken_ende, anteil)
	$Warnung.visible = fmod(gewarnt, takt) < takt / 2.0
```
`lerpf(a, b, anteil)` liegt zwischen a und b, je nach `anteil`: am Anfang 0,5, am Ende 0,1. `fmod(gewarnt, takt)` ist der Rest beim Teilen, er zaehlt immer wieder von 0 bis `takt` hoch. In der ersten Haelfte ist das Schild an, in der zweiten aus. Weil `takt` kleiner wird, blinkt es schneller.

```gdscript
func fallen(delta: float) -> void:
	$Warnung.visible = false
	$Spalte.visible = false
	position.y += falltempo * delta
```
Schild und Spalte weg, der Klotz faellt. Plus heisst nach unten.

```gdscript
	for fliege in get_tree().get_nodes_in_group("fliegen"):
		if im_klotz(fliege):
			zermatschen(fliege)
```
Jede Fliege im Spiel steckt in der Gruppe `fliegen`, frei oder gefangen. Jede, die gerade im Klotz steckt, wird zermatscht.

```gdscript
	if position.y > kanone.position.y + weg_unter:
		queue_free()
```
Unten aus dem Bild: weg damit.

```gdscript
func im_klotz(fliege: Node2D) -> bool:
	var groesse: float = fliege.halbe_groesse * fliege.global_scale.x
```
Die halbe Groesse der Fliege, so wie sie gerade im Bild ist. Im geschrumpften Faecher ist `global_scale.x` kleiner als 1, dann ist auch die Fliege kleiner.

```gdscript
	var seitlich: float = absf(fliege.global_position.x - global_position.x)
	var senkrecht: float = absf(fliege.global_position.y - (global_position.y - hoehe / 2.0))
	return seitlich <= breite / 2.0 + groesse and senkrecht <= hoehe / 2.0 + groesse
```
Dieselbe Idee wie der Treffer der Nadel in Abschnitt 3: Abstand der Mitten, seitlich und senkrecht. Die Mitte des Klotzes liegt `hoehe / 2` ueber seiner Position, denn der Klotz reicht von -120 bis 0. Zwei Rechtecke beruehren sich, wenn der Abstand der Mitten hoechstens die halbe Breite des einen plus die halbe Breite des anderen ist. Dasselbe gilt senkrecht.

```gdscript
func zermatschen(fliege: Node2D) -> void:
	if fliege.gefangen:
		var nadel: Node2D = fliege.get_parent()
		if not nadel.haengt:
			return
		faecher.entfernen(nadel)
		nadel.queue_free()
```
Eine gefangene Fliege steckt an ihrer Nadel, die Nadel ist ihr Elternknoten. Haengt die Nadel noch nicht fertig im Faecher (sie ist gerade unterwegs zur Hand), passiert nichts. Sonst nimmt der Faecher sie aus der Reihe, und die Nadel wird geloescht, mit Fliege und Faden.

Dazwischen steht `nadel.haengt = false`. `queue_free` loescht erst am Ende des Bildes. Fielen zwei Kloetze im selben Bild auf dieselbe Fliege, wuerde der zweite sie sonst noch einmal entfernen, und ihre Flugkraft waere doppelt abgezogen. So sieht der zweite: haengt nicht, nichts zu tun.

```gdscript
	else:
		fliege.queue_free()
```
Eine freie Fliege wird einfach geloescht.

```gdscript
	var matsch: Node2D = matsch_szene.instantiate()
	get_parent().add_child(matsch)
	matsch.global_position = fliege.global_position
```
An der Stelle der Fliege entsteht ein Fleck. Er haengt am Hindernis-Erzeuger, also in der Welt, nicht am Hindernis, das gleich geloescht wird. `queue_free` loescht erst am Ende des Bildes, darum kann man die Position der Fliege hier noch lesen.

### `skripte/hindernis_erzeuger.gd` (die ganze Datei, neu)

```gdscript
extends Node2D

# Die Szene des Hindernisses. Daraus entsteht jedes neue Hindernis.
@export var hindernis_szene: PackedScene
# Die Kanone. Um sie herum wird die Spalte ausgewuerfelt.
@export var kanone: Node2D
# Der Faecher. Wird an jedes Hindernis weitergegeben.
@export var faecher: Node2D
```
Wie beim Fliegen-Erzeuger: die Szene, aus der neue Hindernisse entstehen, und die zwei Knoten, die jedes Hindernis kennen muss. Im Inspector steht `hindernis.tscn`, `../Kanone` und `../Kanone/Faecher`.

```gdscript
# Die kuerzeste und die laengste Pause zwischen zwei Hindernissen, in Sekunden.
@export var pause_kurz: float = 6.0
@export var pause_lang: float = 10.0
# Wie weit links oder rechts von der Kanone die Spalte hoechstens liegt, in Pixeln. Das Bild reicht 720 zu jeder Seite.
@export var spielraum: float = 700.0
```
Deine Wahl Z11: alle 6 bis 10 Sekunden. 700 heisst: Die Spalte liegt immer im Bild.

```gdscript
# Wie viele Sekunden es noch bis zum naechsten Hindernis dauert.
var naechstes_in: float = 0.0


func _ready() -> void:
	naechstes_in = randf_range(pause_kurz, pause_lang)
```
Ein Countdown wie beim Nachladen der Kanone. Schon das erste Hindernis wartet eine zufaellige Pause ab.

```gdscript
func _process(delta: float) -> void:
	naechstes_in -= delta
	if naechstes_in > 0.0:
		return
```
Herunterzaehlen. Solange noch Zeit ist, passiert nichts.

```gdscript
	var hindernis: Node2D = hindernis_szene.instantiate()
	hindernis.position.x = kanone.position.x + randf_range(-spielraum, spielraum)
	hindernis.kanone = kanone
	hindernis.faecher = faecher
	add_child(hindernis)
	naechstes_in = randf_range(pause_kurz, pause_lang)
```
Neues Hindernis bauen, Spalte auswuerfeln, Kanone und Faecher mitgeben, in die Welt haengen. Dann eine neue Pause auswuerfeln. Die Hoehe y setzt das Hindernis selbst (oberer Bildrand).

### `szenen/hindernis.tscn` (neu)

```
Hindernis (Node2D, traegt hindernis.gd, matsch_szene = blutfleck.tscn)
├── Spalte (ColorRect)    gelb, 15 % deckend, 200 breit, 1080 hoch (eine Bildhoehe)
├── Klotz (ColorRect)     grau, 200 breit, von y -120 bis 0, also ueber dem Bildrand
└── Warnung (Polygon2D)   gelbes Dreieck bei y 80, z_index 1
    └── Zeichen (Label)   schwarzes "!"
```
- **Spalte und Klotz** haben `mouse_filter = 2` (Ignore). Ein `ColorRect` faengt sonst Mausklicks ab, und der linke Mausklick ist Schiessen.
- **Klotz** liegt waehrend der Warnung knapp ueber dem Bild. Er ist da, man sieht ihn nur noch nicht.
- **Warnung** hat `z_index = 1`. Die Fliegen im Faecher gehoeren zur Kanone, und die wird spaeter gezeichnet als die Hindernisse, sie laegen also davor. Mit `z_index` 1 liegt das Schild immer obenauf.
- Gelb ist die zweite Farbe nach dem roten Blut. Das ist eine Ausnahme von "Greybox zuerst", weil eine graue Warnung im grauen Bild nicht auffaellt.

### `skripte/faecher.gd` - geaendert in Abschnitt 6

```gdscript
# Wird gesendet, wenn eine Fliege aus dem Faecher entfernt wurde. Mit dabei: ihre Flugkraft.
signal verloren(flugkraft: int)
```
Neu. `spiel.gd` hoert darauf und zieht die Flugkraft ab.

```gdscript
func aufnehmen(neue: Node2D) -> void:
	versatz[neue] = randf_range(-hoehen_streuung, hoehen_streuung)
	if reihe.size() % 2 == 0:
		reihe.push_front(neue)
	else:
		reihe.push_back(neue)
	nachruecken()
```
Das Gleiten der anderen Fliegen stand vorher hier in `aufnehmen`. Es steht jetzt in einer eigenen Funktion `nachruecken`, denn auch `entfernen` braucht es.

```gdscript
func entfernen(nadel: Node2D) -> void:
	reihe.erase(nadel)
	versatz.erase(nadel)
	verloren.emit(nadel.fliege.flugkraft)
	nachruecken()
```
Neu. `erase` nimmt die Nadel aus der Liste und ihren Eintrag aus dem Dictionary (die Notiz N40 aus Abschnitt 5). Dann wird gemeldet, wie viel Flugkraft weg ist, und die anderen ruecken zusammen. Weil es eine weniger ist, rechnet `groesse()` vielleicht wieder groesser: Die Fliegen wachsen dabei zurueck.

```gdscript
func nachruecken() -> void:
	if gleiten != null:
		gleiten.kill()
```
Ein laufendes Gleiten anhalten, wie bisher.

```gdscript
	var haengende: Array[Node2D] = []
	for nadel in reihe:
		if nadel.haengt:
			haengende.append(nadel)
	if haengende.is_empty():
		return
```
Nur Fliegen gleiten lassen, die schon fertig haengen. Die neue, die gerade unterwegs ist, bewegt die Uebergabe. Frueher stand hier "ueberspringe die Neue", das ergibt dasselbe. Ist keine da, gibt es nichts zu tun. Ein Tween ohne Bewegung darin meldet Godot als Fehler.

```gdscript
	gleiten = create_tween()
	gleiten.set_parallel(true)
	for nadel in haengende:
		gleiten.tween_property(nadel, "position", platz(nadel), gleitdauer)
		gleiten.tween_property(nadel, "scale", Vector2.ONE * groesse(), gleitdauer)
```
Wie bisher: alle gleichzeitig an den neuen Platz und auf die neue Groesse.

### `skripte/nadel.gd` - geaendert in Abschnitt 6

```gdscript
# true heisst: Die Nadel haengt mit ihrer Fliege fertig im Faecher. Erst dann kann ein Hindernis sie treffen.
var haengt: bool = false
```
Neu. Warum Fliegen unterwegs nicht getroffen werden: Wuerde die Nadel mitten in der Uebergabe geloescht, wartet die Uebergabe (`await hin.finished`) auf einen Tween, dessen Ziel es nicht mehr gibt. Dann bliebe die Kanone fuer immer gesperrt.

### `skripte/uebergabe.gd` - geaendert in Abschnitt 6

```gdscript
		nadel.anker = griff
		nadel.haengt = true
```
Die zweite Zeile ist neu. Sobald die Fliege oben angekommen ist, haengt sie, und ab dann kann sie getroffen werden.

### `skripte/kanone.gd` - geaendert in Abschnitt 6

```gdscript
# true heisst: Die Kanone darf nicht schiessen, zum Beispiel waehrend des Absturzes. Setzt spiel.gd.
var gesperrt: bool = false
```
Neu.

```gdscript
	if nachladen_noch > 0.0:
		return
	if gesperrt:
		return
```
Die zweite Bedingung ist neu, in `schiessen`. Gesperrt heisst: kein Schuss. Das Nachladen zaehlt trotzdem weiter. Die Touch-Taste loest dieselbe Aktion `schiessen` aus, sie ist also mit gesperrt. Fahren ist nicht gesperrt.

### `skripte/erzeuger.gd` - geaendert in Abschnitt 6

Geloescht:

```gdscript
# Wie weit unter der Kanone eine Fliege geloescht wird, in Pixeln. Der Bildrand liegt bei 160.
@export var loeschen_unter: float = 300.0
...
	for fliege in get_children():
		if fliege.position.y > kanone.position.y + loeschen_unter:
			fliege.queue_free()
```
Deine Wahl Z31: Fliegen unter dem Bild bleiben. Sonst waere nach einem Absturz das Bild leer, denn der Erzeuger baut nur nach oben neue Fliegen. Jetzt haengen dort wieder die Fliegen, an denen du vorbeigestiegen bist. Bis 100 Flugkraft sind das hoechstens etwa 120 Fliegen. Was ausserhalb des Bildes ist, zeichnet Godot nicht. Das ist gerechnet, im Browser wird es in Abschnitt 8 gemessen.

### `skripte/spiel.gd` - geaendert in Abschnitt 6

```gdscript
# Wie schnell man abstuerzt, in Pixeln pro Sekunde. Wer mehr verliert, faellt tiefer und darum laenger.
# Muss langsamer sein als ein Hindernis faellt (falltempo in hindernis.gd), sonst holt der Faecher es ein.
@export var falltempo: float = 1200.0
```
Neu. Der Faecher faellt mit der Kanone mit. Waere er schneller als der Klotz (1800), wuerde er ihn von oben einholen und noch einmal hindurchfallen. Dann waeren weitere Fliegen weg, die gar nicht in der Spalte hingen.

```gdscript
	$Kanone/Faecher.verloren.connect(fliege_verlieren)
```
Neu in `_ready`: Meldet der Faecher einen Verlust, laeuft `fliege_verlieren`.

```gdscript
	steigen.tween_callback(entsperren)
```
Neu in `fliege_zaehlen`, gleich nach dem Steigen. Kommt waehrend eines Falls noch eine Fliege oben an (die Uebergabe lief schon), haelt `steigen.kill()` den Fall an, und dessen `entsperren` kaeme nie. Darum entsperrt auch das Steigen, wenn es fertig ist. War gar nichts gesperrt, aendert `entsperren` nichts. Sofort entsperren waere falsch: Das neue Gleiten kann noch weiter nach unten gehen, und waehrend des Falls darf man nicht schiessen.

```gdscript
		$Hindernisse.set_process(false)
		for hindernis in $Hindernisse.get_children():
			hindernis.queue_free()
```
Neu beim Sieg. Die erste Zeile haelt den Hindernis-Erzeuger an: Es kommen keine neuen Hindernisse. Ein Hindernis, das schon warnt oder faellt, hat aber sein eigenes `_process`. Darum werden alle Kinder des Erzeugers geloescht: laufende Hindernisse und die Matsch-Flecken, die dort haengen. Sonst koennte ein Klotz im All noch Fliegen zermatschen.

```gdscript
func fliege_verlieren(weg: int) -> void:
	flugkraft -= weg
	anzeige_schreiben()
	if steigen != null:
		steigen.kill()
```
Flugkraft abziehen, die Leiste zeigt es sofort. Ein laufendes Steigen oder Fallen anhalten.

```gdscript
	var neue_hoehe: float = -flugkraft * hoehe_je_flugkraft
	var strecke: float = absf(neue_hoehe - $Kanone.position.y)
```
Wo man hin muss (dieselbe Rechnung wie beim Steigen) und wie weit das von hier ist. `absf` macht die Zahl positiv. Sie koennte negativ sein, wenn man gerade noch am Steigen war und darum noch unter dem neuen Ziel ist.

```gdscript
	$Kanone.gesperrt = true
	steigen = create_tween()
	steigen.tween_property($Kanone, "position:y", neue_hoehe, strecke / falltempo)
	steigen.tween_callback(entsperren)
```
Schiessen sperren, hinuntergleiten. Dauer = Strecke / Geschwindigkeit (Trick 2). `tween_callback` ruft `entsperren` auf, wenn das Gleiten fertig ist. Trifft der Klotz zwei Fliegen kurz nacheinander, startet der zweite Aufruf das Gleiten neu, mit der restlichen Strecke.

```gdscript
func entsperren() -> void:
	$Kanone.gesperrt = false
```
Am Ziel: wieder schiessen.

### `szenen/spiel.tscn` - geaendert

```
Spiel
├── Boden, Erzeuger            (unveraendert)
├── Hindernisse (Node2D)       neu, traegt hindernis_erzeuger.gd
├── Kanone ...                 (unveraendert)
└── Bedienung                  (unveraendert)
```
- **Hindernisse** steht vor der Kanone in der Liste. Was frueher in der Liste steht, wird zuerst gezeichnet, die Kanone liegt also ueber dem fallenden Klotz. Der Forscher wird nie getroffen, und so sieht es auch aus.
- Inspector: `hindernis_szene = hindernis.tscn`, `kanone = ../Kanone`, `faecher = ../Kanone/Faecher`.
- Oben zwei neue `ext_resource`-Zeilen (Skript und Szene), `load_steps` von 10 auf 12.

### `.uid`-Dateien (von Godot selbst angelegt)

`hindernis.gd.uid`, `hindernis_erzeuger.gd.uid`: Kennnummern wie bei den anderen Skripten. Nicht von Hand aendern.

### So wurde es angeschaut

Ein Probelauf ausserhalb des Spielordners hat vier Faenge nachgestellt (Flugkraft 8, Kanone bei -2400) und ein Hindernis genau ueber die linke Fliege im Faecher gesetzt. Gemessen:
- Die Warnung ist oben im Bild sichtbar, ueber der Spalte und vor den Fliegen (Bild).
- Der Klotz trifft die linke Fliege und die zweite. Die liegt 110 daneben, und der Klotz reicht 100 + 50 zur Seite. Flugkraft 8 -> 4, Faecher 4 -> 2, `versatz` 2, Leiste 4.
- Die Kanone faellt von -2400 auf -1200, genau 4 x 300. Das dauert 1,0 s (1200 px bei 1200 px/s).
- Ein Schuss waehrend des Falls: keine Nadel. Derselbe Schuss danach: eine Nadel.
- Eine stehende freie Fliege in der Spalte ist weg, eine 400 daneben lebt.
- Der Klotz ist danach geloescht.

Wie sich 3 Sekunden Warnung und 6 bis 10 Sekunden Pause anfuehlen, entscheidest du am Spiel.

### Drei Fragen zur Selbstkontrolle

1. Du hast 6 Fliegen im Faecher, der Klotz trifft 2 davon. Wie tief faellst du, und wie lange dauert es?
2. Warum muss `falltempo` in `spiel.gd` kleiner sein als `falltempo` in `hindernis.gd`?
3. Eine Fliege faehrt gerade zur Hand, als der Klotz durch ihre Stelle faellt. Was passiert mit ihr, und warum ist das so gebaut?

<details><summary>Antworten</summary>

1. 2 Fliegen sind 4 Flugkraft, mal 300 also 1200 px. Bei 1200 px/s dauert das 1 Sekunde. Waehrenddessen kann man nicht schiessen.
2. Der Faecher faellt mit der Kanone. Waere er schneller als der Klotz, wuerde er ihn einholen, und der Klotz wuerde ein zweites Mal durch den Faecher gehen und noch mehr Fliegen treffen.
3. Nichts, sie ist sicher. `haengt` ist erst nach der Ankunft true. Wuerde man ihre Nadel loeschen, wartete die Uebergabe auf einen Tween, dessen Ziel weg ist, und die Kanone bliebe fuer immer gesperrt.

</details>

## Abschnitt 7 - Absturz bis zum Boden, Aufstehen, Neustart

Verliert man die letzte Fliege, faellt man auf den Boden (Flugkraft 0 heisst Hoehe 0, das konnte schon Abschnitt 6). Neu: Unten steht der Forscher kurz wieder auf, dann beginnt alles von vorn. Das Ende nach "Im All!" bleibt vorerst so, wie es ist. Dort kommt spaeter eine eigene Animation, danach geht es zurueck zur Totale (Abschnitt 13/14).

### `skripte/spiel.gd` - geaendert in Abschnitt 7

```gdscript
	$Kanone/Aufstehen.animation_finished.connect(neustart)
```
Neu in `_ready`. `Aufstehen` ist eine Bild-fuer-Bild-Animation (`AnimatedSprite2D`). Ist ihr letztes Bild durch, sendet sie `animation_finished`, und dann laeuft `neustart`. Das Signal kommt nur, wenn die Animation nicht in Schleife laeuft, darum steht in der Szene `loop` auf `false`.

```gdscript
	aufstehen_abbrechen()
```
Neu in `fliege_zaehlen`, gleich nach der Leiste. Es kann sein, dass alle haengenden Fliegen weg sind, aber eine gerade noch zur Hand unterwegs ist (die trifft kein Hindernis, Abschnitt 6). Dann faellt man auf 0, steht auf, und waehrenddessen kommt sie oben an. Dann darf es nicht neu starten. `aufstehen_abbrechen` haelt die Animation an, und weil sie angehalten und nicht fertig ist, kommt `animation_finished` nicht. Bei jedem normalen Fang laeuft die Zeile auch, sie aendert dann nichts, weil ohnehin nichts zu sehen ist.

```gdscript
	if flugkraft <= 0:
		steigen.tween_callback(aufstehen)
	else:
		steigen.tween_callback(entsperren)
```
Geaendert in `fliege_verlieren`, statt der einen Zeile `steigen.tween_callback(entsperren)`. Ist nach dem Verlust nichts mehr uebrig, kommt nach dem Fall nicht das Entsperren, sondern das Aufstehen. Die Kanone bleibt also gesperrt, bis neu gestartet wird. `<=` statt `==`: Sollte die Zahl je unter 0 rutschen, gilt das genauso als "alles weg".

```gdscript
func aufstehen() -> void:
	$Kanone/Arm.visible = false
	$Kanone/Aufstehen.visible = true
	$Kanone/Aufstehen.play("aufstehen")
	$Bedienung/Absturz.visible = true
```
Laeuft, wenn man unten angekommen ist. Die Kanone mit Hand und Leiste wird versteckt, statt ihrer ist der Forscher zu sehen, der aufsteht. `play` startet die Animation mit dem Namen `aufstehen`, oben im Bild steht "Abgestuerzt!".

```gdscript
func aufstehen_abbrechen() -> void:
	$Kanone/Aufstehen.stop()
	$Kanone/Aufstehen.visible = false
	$Kanone/Arm.visible = true
	$Bedienung/Absturz.visible = false
```
Das Gegenstueck: anhalten, alles wieder wie vorher. Erklaert oben bei `fliege_zaehlen`.

```gdscript
func neustart() -> void:
	get_tree().reload_current_scene()
```
`get_tree()` ist der Baum aller Knoten, die gerade laufen. `reload_current_scene()` wirft die ganze Szene `spiel.tscn` weg und laedt sie frisch, so wie beim Spielstart. Darum muss nichts einzeln zurueckgesetzt werden: Flugkraft 0, Kanone bei x 0, neue Fliegen, keine Hindernisse, leerer Faecher. Was spaeter dazukommt (Erzaehler, Totale), startet automatisch mit von vorn. Godot fuehrt das erst am Ende des Bildes aus, nicht mitten in der Funktion.

### `szenen/spiel.tscn` - geaendert in Abschnitt 7

```
Spiel
├── ...
├── Kanone
│   ├── Arm ...                   (unveraendert)
│   ├── Aufstehen (AnimatedSprite2D)  neu
│   └── ...
└── Bedienung
    ├── ... , Sieg                (unveraendert)
    └── Absturz (Label)           neu
```
- **Aufstehen:** unsichtbar, bis man unten ist. `position` (0, -100): Das Bild ist 200 hoch und wird um seine Mitte gezeichnet, so steht es mit den Fuessen auf der Hoehe der Kanone. Die Bilder stecken in `sprite_frames`, einer **SpriteFrames**-Resource direkt in der Szene, mit einer Animation `aufstehen`: drei Bilder, `speed` 5 Bilder pro Sekunde (also 0,6 s fuer alle drei), `loop` aus.
- **Die drei Bilder sind Platzhalter**: je eine `GradientTexture2D` (80 x 200), ein Farbverlauf von oben nach unten (`fill_to` (0, 1)), der oben durchsichtig ist und ab einer Stelle hart grau wird. "liegt": nur das untere Fuenftel grau (ab 0,8), "kniet": die untere Haelfte (ab 0,5), "steht": alles grau. So braucht es keine Bilddatei. Mit deinen Bildern (Abschnitt 10) klickst du im Inspector auf `sprite_frames`, und ziehst deine zwei oder drei Bilder in die Animation `aufstehen` statt der grauen. Kein Code aendert sich.
- **Absturz:** ein Label wie `Sieg`, gleiche Groesse und Stelle, Text "Abgestuerzt!", unsichtbar.
- Oben sieben neue `sub_resource`-Bloecke (drei Verlaeufe, drei Texturen, die SpriteFrames), `load_steps` von 12 auf 19.

### So wurde es angeschaut

Ein Probelauf ausserhalb des Spielordners (danach geloescht) hat Flugkraft 2 bei Hoehe -600 eingestellt und die letzte Fliege verlieren lassen. Gemessen:
- Nach 0,3 s: Kanone bei y -236, also mitten im Fall, Schiessen gesperrt.
- Nach 0,7 s: unten, Aufstehen sichtbar (zweites Bild), Kanone versteckt, "Abgestuerzt!" sichtbar.
- Nach 1,7 s: Szene neu geladen, Kanone bei x 0 / y 0, Flugkraft 0, Label weg, neue Fliegen da.
- Zweiter Fall: waehrend des Aufstehens kommt eine Fliege an. Kein Neustart, man steigt wieder auf -600, Kanone sichtbar und entsperrt.

Wie sich das anfuehlt und ob eine ganze Runde bis 100 Spass macht, entscheidest du beim Spass-Test nach Abschnitt 8 (Z31).

### Drei Fragen zur Selbstkontrolle

1. Du hast eine Fliege (Flugkraft 2) und verlierst sie. Wie lange dauert es vom Treffer bis zum Neustart?
2. Warum wird beim Neustart nicht jede Variable einzeln auf den Anfang gesetzt?
3. Was passiert, wenn waehrend des Aufstehens noch eine Fliege bei der Hand ankommt, und welche Zeile sorgt dafuer?

<details><summary>Antworten</summary>

1. 2 x 300 = 600 px Fall bei 1200 px/s sind 0,5 s, dann drei Bilder bei 5 pro Sekunde, also 0,6 s. Zusammen 1,1 s.
2. `reload_current_scene()` laedt die Szene frisch, alles steht wieder wie beim Start. Einzeln zuruecksetzen hiesse, an Fliegen, Hindernisse, Faecher, Faeden und spaeter den Erzaehler zu denken, und eins vergisst man.
3. `aufstehen_abbrechen()` in `fliege_zaehlen` haelt die Animation mit `stop()` an. Angehalten ist nicht fertig, darum kommt `animation_finished` nicht, und `neustart` laeuft nie. Man steigt wieder.

</details>

## Abschnitt 8 - Browser-Build

In diesem Abschnitt kam **kein neues Spielskript** dazu. Das Spiel lief schon seit Abschnitt 1 im Browser (`export_presets.cfg`, Preset `Web`). Neu ist nur eine Zeile in den Export-Einstellungen, und die ist **voruebergehend**.

### `export_presets.cfg` - geaendert in Abschnitt 8

```
html/head_include="<script>/*kit-messung*/ ... /*kit-messung-ende*/</script>"
```

- `html/head_include` ist Text, den Godot beim Web-Export oben in die `index.html` schreibt, bevor das Spiel startet. Bisher war er leer.
- Darin steht ein kleines JavaScript, die **Messseite**. Sie gehoert nicht zum Spiel und laeuft neben Godot im Browser. Sie zaehlt, wie oft der Browser pro Sekunde ein neues Bild zeichnet (`requestAnimationFrame`, damit zeichnet auch Godot).
- So benutzt du sie: am Handy im Spiel **dreimal schnell oben links in die Ecke tippen**, dann 15 Sekunden normal weiterspielen. Danach steht eine Zeile da: Bilder pro Sekunde, das langsamste Bild, wie viele Bilder laenger als 33 ms gedauert haben, dazu Geraet und Bildschirm. Mit **Teilen** schickst du die Zeile weiter, ohne abzuschreiben.
- Ohne die drei Tipps tut sie nichts.
- Alles steht in **einer** Zeile, weil Godot mehrzeilige Werte in dieser Datei still nicht einliest.
- **Nach dem Spass-Test fliegt die Zeile wieder raus** (`html/head_include=""`). Darum wird hier nicht jeder Befehl des JavaScripts erklaert: Er ist kein Spielcode und bleibt nicht.

### So wurde es angeschaut

Gemessen an einer Kopie des Spiels, nicht im Spielordner. Darin stellte ein Probeskript den schlimmsten Fall her: 98 Flugkraft, 49 Fliegen mit Nadel und Faden im Faecher, alle Fliegen, die der Erzeuger bis dahin baut. Das sind 170 Fliegen und 751 Knoten, am Start sind es 4 Fliegen und 57 Knoten. Hindernisse waren dabei aus.

| Wo | Start | Oben (170 Fliegen) |
|----|-------|--------------------|
| Godot am PC, ohne Bildbremse | 0,34 ms je Bild | 0,83 ms je Bild |
| Browser Chromium am PC | 60 Bilder/s, Rechenzeit 1,1 ms | 60 Bilder/s, Rechenzeit 3,6 ms |
| Browser WebKit (Safari-Engine) am PC | 64 Bilder/s, Rechenzeit 1,0 ms | 64 Bilder/s, Rechenzeit 4,0 ms |

Fuer 60 Bilder pro Sekunde hat jedes Bild 16,7 ms Zeit. Am PC bleiben also oben noch drei Viertel davon frei, kein einziges Bild war laenger als 33 ms. Ein Handy rechnet langsamer, darum misst du dort mit der Messseite. Wird es knapp, kommt die Loesung aus Abschnitt 6 zurueck: Fliegen unter dem Bild loeschen und nach einem Absturz neu auswuerfeln.

Tastatur und Maus im Browser (Chromium und WebKit, am Bild abgelesen): D und Pfeil rechts fahren nach rechts, Pfeil links nach links (die Pfostennummern wandern), Leertaste, W und linke Maustaste schiessen eine Nadel mit Faden.

### Drei Fragen zur Selbstkontrolle

1. Warum zaehlt die Messseite nicht als Spielcode, und wann verschwindet sie wieder?
2. Wie viel Zeit hat ein Bild bei 60 Bildern pro Sekunde, und wie viel davon brauchte das Spiel oben im Browser am PC?
3. Was wuerdest du aendern, wenn das Spiel am Handy oben ruckelt?

<details><summary>Antworten</summary>

1. Sie steckt nicht in einem Skript von Godot, sondern in der `index.html`, die der Web-Export baut. Sie misst nur, wie oft der Browser zeichnet. Nach dem Spass-Test wird `html/head_include` wieder leer.
2. 16,7 ms. Gebraucht wurden etwa 3,6 ms (Chromium) bis 4 ms (WebKit), also rund ein Viertel.
3. Die Fliegen unter dem Bild wieder loeschen (wie bis Abschnitt 5) und nach einem Absturz neu auswuerfeln, statt alle bis 100 aufzuheben.

</details>

## Spass-Test, Runde 1 - Aenderungen nach deinem ersten Durchspielen

Kein neuer Abschnitt, sondern das, was du nach dem Spielen am itch-Draft gesagt hast: Leiste an die rechte Hand, zweite Schusstaste, Lenken beim Steigen, Fliegen kommen von der Seite nach, mehr Warnzeit weiter oben, und zum Testen eine schnelle Fliegenart. Die richtigen Fliegenarten (Groesse, Flugmuster) baut Abschnitt 9.

### `skripte/fliege.gd` - geaendert

```gdscript
# Um diese Stelle fliegt die Fliege hin und her. Setzt der Erzeuger, bevor die Fliege ins Spiel kommt.
var mitte_x: float = 0.0
```
Hiess vorher `start_x` und wurde in `_ready` auf die Startstelle gesetzt. Jetzt kann eine Fliege **ausserhalb** des Bildes starten und trotzdem um eine Stelle **im** Bild hin und her fliegen. Darum sind Start und Mitte zwei verschiedene Dinge, und die Mitte setzt der Erzeuger. `_ready` ist weg, es hatte nur diese eine Zeile.

```gdscript
	if position.x > mitte_x + strecke:
		richtung = -1.0
	if position.x < mitte_x - strecke:
		richtung = 1.0
```
Dieselben Zeilen wie vorher, nur mit `mitte_x`. Der Trick beim Hereinfliegen steckt genau hier: Startet eine Fliege rechts weit draussen, ist sie schon "zu weit rechts", also dreht sie sofort nach links und fliegt ins Bild. Links draussen genauso andersherum. Es braucht dafuer keine einzige neue Zeile.

Auch der Kommentar von `strecke` sagt jetzt "von ihrer Mitte" statt "von ihrem Startpunkt".

### `skripte/erzeuger.gd` - neu geschrieben

Das ganze Skript, weil sich fast alles geaendert hat.

```gdscript
@export var fliege_szene: PackedScene
@export var kanone: Node2D
@export var abstand: float = 250.0
@export var breite: float = 400.0
@export var vorlauf: float = 1200.0
@export var tempo_langsam: float = 100.0
@export var tempo_schnell: float = 180.0
```
Wie bisher. `abstand` gilt jetzt nur noch fuer die Fliegen, die **oben ueber dem Bild** bereitstehen. `breite` ist jetzt, wie weit die **Mitte** einer Fliege von der Kanone liegen darf.

```gdscript
@export var anteil_schnell: float = 0.5
@export var flugkraft_normal: int = 3
@export var flugkraft_schnell: int = 10
```
Die Testart fuer den Spass-Test. `0.5` heisst: Jede Fliege ist mit halber Chance schnell. Normal gibt 3, schnell gibt 10. So kommst du schneller bis 100 und kannst das Ende testen.

```gdscript
@export var mindestens: int = 4
@export var naehe: float = 900.0
@export var einflug_x: float = 800.0
@export var einflug_oben: float = 850.0
@export var einflug_unten: float = 300.0
```
Das Nachfuellen. Sind weniger als 4 freie Fliegen **in der Naehe**, kommt eine von der Seite. "In der Naehe" heisst: hoechstens 900 px links oder rechts der Kanone und zwischen 300 und 850 px ueber ihr. Die Kanone steht in der Bildmitte, der Bildrand ist 720 px weg, die Naehe reicht also etwas ueber den Rand hinaus. Neue Fliegen starten bei 800, also ausserhalb des Bildes (720 + halbe Fliege 50 = 770). 300 bis 850 ueber der Kanone ist der Teil des Bildes ueber der Muendung (140) und unter dem oberen Rand (920), dort kann man sie treffen.

Wichtig: `einflug_x` muss groesser sein als `breite` + `strecke` der Fliege (400 + 300 = 700). Sonst liegt der Startpunkt innerhalb des Hin-und-her-Bereichs, und die Fliege dreht nicht sofort ins Bild.

```gdscript
@export var loeschen_seitlich: float = 2000.0
@export var loeschen_unten: float = 300.0
```
Freie Fliegen, die mehr als 2000 px seitlich weg sind oder mehr als 300 px unter der Kanone (unterer Bildrand: 160), werden geloescht. Das ist die Variante aus Abschnitt 6, die du damals als Ausweg genannt hattest (Z32): unten loeschen, und wenn man wieder herunterkommt, kommen neue nach. So bleiben es immer nur etwa ein Dutzend Fliegen statt bis zu 170, auch gut fuers Handy.

```gdscript
func _process(_delta: float) -> void:
	while naechste_hoehe > kanone.position.y - vorlauf:
		var x: float = kanone.position.x + randf_range(-breite, breite)
		fliege_bauen(x, x, naechste_hoehe)
		naechste_hoehe -= abstand
	aufraeumen()
	if freie_in_der_naehe() < mindestens:
		hereinfliegen()
```
Drei Dinge je Bild:
1. Die `while`-Schleife ist die alte: oben ueber dem Bild steht alle 250 px eine Fliege bereit, bevor man dorthin steigt. Neu ist nur, dass das Bauen in `fliege_bauen` steckt. Start und Mitte sind hier dieselbe Stelle `x`.
2. `aufraeumen()` loescht, was zu weit weg ist.
3. Fehlen Fliegen in der Naehe, kommt **eine** von der Seite. `if` statt `while` mit Absicht: hoechstens eine je Bild. Bei 60 Bildern pro Sekunde sind vier fehlende Fliegen trotzdem nach 4 Bildern da, und eine `while`-Schleife koennte sich aufhaengen, wenn eine neue Fliege knapp nicht mitgezaehlt wird.

```gdscript
func fliege_bauen(start_x: float, mitte_x: float, hoehe: float) -> void:
	var fliege: Node2D = fliege_szene.instantiate()
	fliege.position = Vector2(start_x, hoehe)
	fliege.mitte_x = mitte_x
	fliege.tempo = randf_range(tempo_langsam, tempo_schnell)
	fliege.flugkraft = flugkraft_normal
	if randf() < anteil_schnell:
		fliege.tempo *= 2.0
		fliege.flugkraft = flugkraft_schnell
	add_child(fliege)
```
Baut eine Fliege: an `start_x`, fliegt um `mitte_x`. Erst normal mit Tempo 100 bis 180 und 3 Flugkraft. `randf()` ist eine Zufallszahl zwischen 0 und 1, sie ist in der Haelfte der Faelle kleiner als 0.5. Dann wird das Tempo verdoppelt (`*= 2.0` heisst "mal 2 nehmen und wieder hineinschreiben") und die Fliege gibt 10. Aussehen tut sie gleich, du erkennst sie am Tempo (Greybox).

```gdscript
func hereinfliegen() -> void:
	var seite: float = 1.0
	if randf() < 0.5:
		seite = -1.0
	var start_x: float = kanone.position.x + seite * einflug_x
	var mitte_x: float = kanone.position.x + randf_range(-breite, breite)
	var hoehe: float = kanone.position.y - randf_range(einflug_unten, einflug_oben)
	fliege_bauen(start_x, mitte_x, hoehe)
```
Wuerfelt eine Seite (1 rechts, -1 links). Start 800 px neben der Kanone auf dieser Seite, Mitte irgendwo bis 400 px neben der Kanone, Hoehe zwischen 300 und 850 ueber ihr. Minus, weil nach oben y kleiner wird. Wie die Fliege dann hereinfliegt, steht oben bei `fliege.gd`.

```gdscript
func freie_in_der_naehe() -> int:
	var anzahl: int = 0
	for fliege in get_children():
		var seitlich: float = absf(fliege.position.x - kanone.position.x)
		var ueber: float = kanone.position.y - fliege.position.y
		if seitlich <= naehe and ueber >= einflug_unten and ueber <= einflug_oben:
			anzahl += 1
	return anzahl
```
Zaehlt. `get_children()` sind nur die **freien** Fliegen: Eine gefangene haengt seit Abschnitt 3 an ihrer Nadel (`reparent`), sie ist kein Kind des Erzeugers mehr. `absf` macht aus einer Zahl ihren Betrag ohne Minus, damit links und rechts gleich zaehlen. `ueber` ist, wie weit die Fliege ueber der Kanone ist. Eine Fliege, die gerade erst hereinfliegt, zaehlt schon mit (800 liegt unter 900). Sonst kaeme jedes Bild noch eine dazu, bis die erste im Bild ist.

```gdscript
func aufraeumen() -> void:
	for fliege in get_children():
		var zu_tief: bool = fliege.position.y > kanone.position.y + loeschen_unten
		var zu_weit: bool = absf(fliege.position.x - kanone.position.x) > loeschen_seitlich
		if zu_tief or zu_weit:
			fliege.queue_free()
```
Loescht freie Fliegen, die zu tief oder seitlich zu weit weg sind. `queue_free` loescht am Ende des Bildes, nicht sofort.

### `skripte/hindernis_erzeuger.gd` - geaendert

```gdscript
@export var warnzeit_unten: float = 3.0
@export var warnzeit_oben: float = 5.0
@export var hoehe_oben: float = 20000.0
```
Neu. Unten warnt ein Hindernis 3 Sekunden, ab 20000 px Hoehe 5 Sekunden, dazwischen waechst es gleichmaessig. Bis 100 Flugkraft steigt man 100 x 300 = 30000 px. Ein Drittel davon sind 10000 px, dort sind es 4 Sekunden, wie du es wolltest. Weiter gerechnet (1 Sekunde je Drittel) ist man bei zwei Dritteln, also 20000 px, bei 5 und bleibt dort. **Aendert man `hoehe_je_flugkraft` in `spiel.gd`, muss `hoehe_oben` mit**, sonst stimmen die Drittel nicht mehr.

```gdscript
	var anteil: float = clampf(-kanone.position.y / hoehe_oben, 0.0, 1.0)
	hindernis.warnzeit = lerpf(warnzeit_unten, warnzeit_oben, anteil)
```
Neu, bevor das Hindernis ins Spiel kommt. `-kanone.position.y` ist die Hoehe als positive Zahl. Geteilt durch 20000 ergibt das, wie weit man auf dem Weg zu den 5 Sekunden ist: 0 unten, 0.5 bei 10000, 1 bei 20000. `clampf` haelt die Zahl zwischen 0 und 1, darueber bleibt es also bei 1. `lerpf` (kennst du aus `hindernis.gd` vom Blinken) nimmt den Wert dazwischen: bei 0.5 genau die Mitte von 3 und 5, also 4. Die Warnzeit gilt fuer die Hoehe, in der das Hindernis entsteht.

### `skripte/kanone.gd` - geaendert

```gdscript
# Welcher Teil des Tempos waehrend Uebergabe und Steigen bleibt. 0.5 heisst: halb so schnell.
@export var steig_anteil: float = 0.5
...
# true heisst: Die Kanone steigt gerade nach einem Fang und faehrt darum langsamer. Setzt spiel.gd.
var steigt: bool = false
```
Neu.

```gdscript
func _process(delta: float) -> void:
	fahren(delta)
	if not $Uebergabe.laeuft:
		schiessen(delta)
```
Vorher stand die Kanone waehrend der Uebergabe (`aktuelles_tempo = 0.0` und `return`). Jetzt faehrt sie immer, nur schiessen geht waehrend der Uebergabe weiter nicht. Das geht ohne Umbau: Arm, rechte Hand, Faecher und Kamera sind Kinder der Kanone und fahren einfach mit. Der Arm faehrt seine Uebergabe-Strecke weiter relativ zur Kanone.

```gdscript
	var hoechstes: float = tempo
	if steigt or $Uebergabe.laeuft:
		hoechstes = tempo * steig_anteil
	var ziel_tempo: float = richtung * hoechstes
```
Neu in `fahren`. Normal ist das hoechste Tempo 250. Waehrend der Uebergabe oder des Steigens ist es halb so viel, 125. Das Anfahren und Abbremsen (`move_toward`) bleibt, die Kanone bremst also weich auf das halbe Tempo herunter statt zu springen.

### `skripte/spiel.gd` - geaendert

```gdscript
	$Kanone.steigt = true
```
Neu in `fliege_zaehlen`, bevor das Steigen anfaengt.

```gdscript
	$Kanone.steigt = false
```
Neu in `fliege_verlieren` (beim Absturz faehrt man wieder mit vollem Tempo, wie bisher) und in `entsperren`. `entsperren` laeuft am Ende jedes Steigens, darum ist das die Stelle, an der das halbe Tempo endet.

```gdscript
	$Kanone/RechteHand/Leiste.max_value = ziel
...
	$Kanone/RechteHand/Leiste.value = flugkraft
```
Nur der Pfad, weil die Leiste umgezogen ist.

### `szenen/spiel.tscn` - geaendert

```
Kanone
  Arm                 (Leiste ist hier weg)
  RechteHand
    Leiste            (neu hier, unter der Hand, 160 x 20)
Bedienung
  TasteSchussLinks    (neu, x 40, y 480, ueber der linken Pfeiltaste)
    Wort "Schuss"
  TasteSchuss         (y 460 -> 480, ueber der rechten Pfeiltaste)
```
- Die Leiste haengt jetzt an der rechten Hand. Dort sammeln sich die Fliegen, die Leiste zeigt also, was die Hand haelt. Sie faehrt bei der Uebergabe nicht mehr mit dem Arm. Beim Aufstehen bleibt sie sichtbar (versteckt wird nur der `Arm`).
- Die zweite Schusstaste ist eine Kopie der ersten mit derselben Aktion `schiessen`. Zwei Tasten, eine Aktion: Godot ist egal, welche gedrueckt wird. Beide sitzen 20 px tiefer als vorher, damit die Leiste unter der Hand die rechte Taste nicht beruehrt.
- Bekannt seit Abschnitt 8: Am PC sieht man die Schrift "Schuss" ohne Taste, jetzt auf beiden Seiten.

### So wurde es angeschaut

- Verify PASS, Schnellcheck aller fuenf Skripte PASS.
- Probe in einer Kopie des Spiels (nicht im Spielordner, danach geloescht), 60 Bilder pro Sekunde fest:
  - Beim Start 6 Fliegen, 4 in der Naehe, davon 2 gerade ausserhalb des Bildes beim Hereinfliegen.
  - Von 400 gebauten Fliegen 196 schnell (10) und 210 normal (3), also etwa die Haelfte.
  - Fahren nach rechts: frei 250 px/s, waehrend der Uebergabe 125, waehrend des Steigens 125, danach wieder 250.
  - Hoch bis 15000 px und dann auf 3000 gefallen: 2 Bilder spaeter 2 Fliegen in der Naehe (eine je Bild), nach 4 Sekunden 4, alle im Bild ueber der Muendung. An allen Messpunkten hoechstens 12 Fliegen insgesamt. 5000 px seitlich gefahren: die alten weg, 4 neue da.
  - Warnzeit bei 0 / 5000 / 10000 / 15000 / 20000 / 30000 px: 3,0 / 3,5 / 4,0 / 4,5 / 5,0 / 5,0 s.
- Bild mit sichtbaren Touch-Tasten: Leiste unter der rechten Hand, beide Schusstasten ueber den Pfeilen, nichts ueberdeckt sich.
- Handy-Probe (Browser, Safari-Engine und Chromium): Chromium alle vier Tasten ok. In der Safari-Engine ist die rechte Schusstaste ok. Die linke war im ersten Lauf am Bild zu sehen (Nadel mit Faden), die Probe meldet sie aber als FAIL: Die Nadel der rechten Taste davor war in ihrer Messflaeche noch nicht verschwunden. **Ob beide Tasten am iPhone ankommen, zeigt nur dein Geraet.**
- **Nicht gemessen:** wie es sich spielt. Das entscheidest du.

### Drei Fragen zur Selbstkontrolle

1. Warum fliegt eine Fliege, die 800 px rechts neben der Kanone entsteht, von selbst ins Bild, obwohl in `fliege.gd` keine Zeile fuers Hereinfliegen steht?
2. Wie lange warnt ein Hindernis bei 50 Flugkraft, und wie rechnest du das aus?
3. Warum steht beim Nachfuellen `if` und nicht `while`?

<details><summary>Antworten</summary>

1. Ihre Mitte liegt hoechstens 400 px neben der Kanone, sie fliegt 300 px zu jeder Seite. 800 ist also schon rechts ausserhalb ihres Bereichs, darum setzt die Zeile `if position.x > mitte_x + strecke` die Richtung sofort auf links.
2. 50 x 300 = 15000 px. 15000 / 20000 = 0,75. `lerpf(3, 5, 0.75)` = 3 + 0,75 x 2 = 4,5 Sekunden.
3. So kommt hoechstens eine Fliege je Bild dazu. Das reicht (4 Fliegen in 4 Bildern), und eine `while`-Schleife wuerde sich aufhaengen, falls eine neue Fliege einmal knapp nicht mitgezaehlt wird.

</details>

## Spass-Test, Runde 2 - Fliegen weichen aus, Kamera, Steigen beim Treffer

Deine zweite Runde Rueckmeldung: Die schnelle Fliege war zu leicht und gab zu viel. Die normale dreht sich jetzt und wippt. Fliegen in der unteren Bildhaelfte und oben beim Faecher fliegen aus dem Bild. Die Kamera zoomt beim Abheben heran, die Kanone sitzt dann unten am Rand. Man steigt schon beim Treffer und lenkt dabei nicht mehr. Das halbe Tempo aus Runde 1 ist damit wieder weg.

### `skripte/fliege.gd` - geaendert

```gdscript
@export var drehtempo: float = 0.0
@export var wipp_hoehe: float = 0.0
@export var wipp_tempo: float = 4.0
```
Neu. Drei Regler fuer Drehen und Wippen. 0 heisst: Die Fliege dreht oder wippt nicht. So kann dieselbe Szene beide Arten sein, der Erzeuger stellt die Werte ein. `drehtempo` ist im **Bogenmass** pro Sekunde, so rechnet Godot Winkel: Eine ganze Umdrehung ist `TAU`, etwa 6,28.

```gdscript
var flucht: float = 0.0
var grund_y: float = 0.0
var zeit: float = 0.0
```
Neu. `flucht` 0 heisst hin und her, 1 heisst ab nach rechts, -1 ab nach links. Das setzt der Erzeuger. `grund_y` ist die Hoehe, um die die Fliege wippt, `zeit` zaehlt die Sekunden fuers Wippen.

```gdscript
func _ready() -> void:
	grund_y = position.y
```
Wieder da, mit neuem Inhalt. Wenn die Fliege ins Spiel kommt, hat der Erzeuger ihre Hoehe schon gesetzt. Die merkt sie sich als Mitte des Wippens.

```gdscript
	zeit += delta
	rotation += drehtempo * delta
	position.y = grund_y + sin(zeit * wipp_tempo) * wipp_hoehe
```
Neu in `_process`, nach der Zeile `if gefangen: return`. Eine gefangene Fliege bleibt also in dem Winkel stehen, in dem sie getroffen wurde.
- `rotation` ist der Drehwinkel des Knotens. Jedes Bild kommt ein Stueck dazu, also dreht sie sich staendig.
- `sin` (Sinus) geht gleichmaessig zwischen -1 und 1 hin und her. Mal `wipp_hoehe` (25) ergibt das -25 bis 25 px um `grund_y`. `wipp_tempo` 4 heisst: Ein ganzes Auf und Ab dauert 2 x 3,14 / 4 = etwa 1,6 Sekunden.
- Bei der schnellen Fliege sind beide Regler 0, dort aendert sich nichts: `rotation` + 0 und `grund_y` + 0.

```gdscript
	if flucht != 0.0:
		position.x += flucht * tempo * delta
		return
```
Neu. Flieht die Fliege, fliegt sie nur noch geradeaus in ihre Fluchtrichtung, ohne umzudrehen. `return` ueberspringt das Hin und Her darunter. Geloescht wird sie vom Erzeuger, wenn sie weit genug draussen ist.

### `skripte/erzeuger.gd` - geaendert

Geloescht: `abstand`, `vorlauf`, `naechste_hoehe` und die `while`-Schleife, die oben ueber dem Bild alle 250 px eine Fliege bereitgestellt hat. Die wuerden jetzt beim Hereinsteigen sofort im oberen Viertel landen und fliehen. Alle Fliegen kommen nur noch von der Seite. Die Funktion `fliege_bauen` ist in `hereinfliegen` aufgegangen, weil es nur noch einen Weg gibt, eine Fliege zu bauen.

```gdscript
@export var flugkraft_normal: int = 2
@export var flugkraft_schnell: int = 6
@export var faktor_schnell: float = 4.0
@export var drehungen_normal: float = 1.0
@export var wippen_normal: float = 25.0
```
Normal gibt 2, schnell 6. Die schnelle ist viermal so schnell wie eine normale (vorher doppelt), also 400 bis 720 px/s. Die normale dreht sich einmal pro Sekunde und wippt 25 px.

```gdscript
@export var naehe: float = 1000.0
@export var einflug_x: float = 900.0
@export var einflug_oben: float = 750.0
@export var einflug_unten: float = 560.0
@export var flucht_unten: float = 520.0
@export var flucht_oben: float = 790.0
@export var loeschen_seitlich: float = 1100.0
```
Neue Zahlen und zwei neue Regler. In der Luft liegt der obere Bildrand jetzt 1060 px ueber der Kanone (siehe Kamera unten). Die Bildmitte ist also 520 ueber ihr, das obere Viertel beginnt bei 1060 - 270 = 790. **Nur zwischen 520 und 790 fliegen die Fliegen ruhig hin und her.** Darunter und darueber fliehen sie.
- Neue Fliegen kommen zwischen 560 und 750 herein. Das sind 40 px Abstand zu jeder Grenze, mehr als das Wippen (25), sonst wuerde eine wippende Fliege gleich fliehen.
- Start bei 900 statt 800: Am Boden ist herausgezoomt, das Bild reicht dort 847 px zur Seite. Bei 800 haette man die neue Fliege entstehen sehen.
- `naehe` und `loeschen_seitlich` wachsen mit, damit eine startende Fliege mitzaehlt und nicht sofort geloescht wird.

```gdscript
func _process(_delta: float) -> void:
	aufraeumen()
	fliehen_lassen()
	if freie_in_der_naehe() < mindestens:
		hereinfliegen()
```
Erst wegraeumen, dann pruefen, wer fliehen muss, dann nachfuellen.

```gdscript
func hereinfliegen() -> void:
	...
	fliege.tempo = randf_range(tempo_langsam, tempo_schnell)
	if randf() < anteil_schnell:
		fliege.tempo *= faktor_schnell
		fliege.flugkraft = flugkraft_schnell
	else:
		fliege.flugkraft = flugkraft_normal
		fliege.drehtempo = drehungen_normal * TAU
		fliege.wipp_hoehe = wippen_normal
	add_child(fliege)
```
Wie vorher, nur in einer Funktion. Neu ist das `else`: Nur die normale Fliege bekommt Drehen und Wippen. `drehungen_normal * TAU` rechnet Umdrehungen in Bogenmass um (1 x 6,28).

```gdscript
func fliehen_lassen() -> void:
	for fliege in get_children():
		if fliege.flucht != 0.0:
			continue
		var ueber: float = kanone.position.y - fliege.position.y
		if ueber < flucht_unten or ueber > flucht_oben:
			if fliege.position.x < kanone.position.x:
				fliege.flucht = -1.0
			else:
				fliege.flucht = 1.0
```
Neu. Fuer jede freie Fliege, die noch nicht flieht (`continue` springt zur naechsten): Liegt sie unter 520 oder ueber 790, flieht sie. Die Kanone steht immer in der Bildmitte, also ist der naehere Rand der auf ihrer Seite der Kanone: Ist sie links von der Kanone, geht es nach links, sonst nach rechts. Weil die Fliegen nur seitlich fliegen, kommen sie in diese Bereiche vor allem, **wenn du steigst**: Das Bild faehrt hoch, die Fliegen rutschen darin nach unten.

```gdscript
		if fliege.flucht == 0.0 and seitlich <= naehe:
			anzahl += 1
```
Geaendert in `freie_in_der_naehe`. Eine fliehende Fliege zaehlt nicht mehr mit, denn die ist gleich weg, und fuer sie soll schon eine neue kommen. Die Hoehe muss hier nicht mehr geprueft werden: Wer ausserhalb von 520 bis 790 ist, flieht schon, das hat `fliehen_lassen` kurz vorher erledigt.

### `skripte/uebergabe.gd` - geaendert

```gdscript
# Wird gesendet, sobald eine Fliege getroffen ist, noch vor der Fahrt zur Hand. Mit dabei: ihre Flugkraft.
signal gefangen(flugkraft: int)
```
Hiess `angekommen` und kam erst, wenn die Fliege oben im Faecher hing. Jetzt kommt es gleich in `starten`:

```gdscript
	nadel.reparent(faecher)
	gefangen.emit(nadel.fliege.flugkraft)
```
`spiel.gd` haengt am Signal das Steigen an, also steigst du ab dem Treffer. Die Uebergabe laeuft trotzdem wie bisher, nur waehrend du schon steigst. Das geht, weil Arm, Faecher und Hand Kinder der Kanone sind und mit hochfahren. Die Zeile `angekommen.emit(...)` weiter unten ist weg.

### `skripte/kanone.gd` - geaendert

```gdscript
# Welcher Teil des Tempos waehrend Uebergabe und Steigen bleibt. 0 heisst: Man lenkt dann gar nicht, 0.5 hiesse halb so schnell.
@export var steig_anteil: float = 0.0
```
Nur der Wert und der Kommentar: 0 statt 0.5. Du lenkst beim Steigen nicht mehr. Der Code aus Runde 1 bleibt, damit du es im Inspector wieder aufdrehen kannst. Faehrst du gerade, rollt die Kanone kurz aus (Abbremsen, `beschleunigung`) und steht dann.

### `skripte/hindernis.gd` - geaendert

```gdscript
@export var bildrand: float = 1060.0
```
920 -> 1060, weil der obere Bildrand in der Luft jetzt hoeher ueber der Kanone liegt. Am Boden (herausgezoomt) liegt er bei 1082, die Warnung steht dort also 22 px unter dem Rand. Nur der Kommentar von `weg_unter` ist sonst noch geaendert.

### `skripte/spiel.gd` - geaendert

```gdscript
@export var zoom_boden: float = 0.85
@export var versatz_boden: float = -447.0
@export var zoom_luft: float = 1.0
@export var versatz_luft: float = -520.0
...
var kamerafahrt: Tween = null
```
Neu. Zwei Einstellungen der Kamera:
- **Boden:** `zoom` 0.85 heisst, alles ist 85 Prozent so gross, man sieht mehr. Der Versatz (`offset` der Kamera) ist, wie weit ueber der Kanone die Bildmitte liegt. -447 = -380 / 0.85: So steht die Kanone im Bild genau dort, wo sie vorher war, nur kleiner.
- **Luft:** `zoom` 1, also die Groesse von vorher. Die Bildmitte liegt 520 ueber der Kanone, das Bild reicht 540 nach unten, die Kanone sitzt also 20 px ueber dem unteren Rand.

```gdscript
	$Kanone/Uebergabe.gefangen.connect(fliege_zaehlen)
	...
	$Kanone/Kamera.zoom = Vector2.ONE * zoom_boden
	$Kanone/Kamera.offset.y = versatz_boden
```
Das Signal heisst jetzt `gefangen`. Neu: Beim Start stellt `_ready` die Kamera auf den Boden. So gilt, was im Inspector bei `spiel.gd` steht, auch wenn in der Szene an der Kamera etwas anderes eingetragen ist.

```gdscript
	kamera_fahren(zoom_luft, versatz_luft, steigdauer)
```
Neu in `fliege_zaehlen`, bei jedem Fang. Beim ersten zoomt die Kamera heran, gleichzeitig mit dem Steigen (gleiche Dauer). Danach ist sie schon in der Luft, und die Fahrt aendert nichts mehr.

```gdscript
		kamera_fahren(zoom_boden, versatz_boden, strecke / falltempo)
```
Neu in `fliege_verlieren`, nur wenn alles weg ist (`flugkraft <= 0`). Waehrend du zum Boden faellst, zoomt die Kamera wieder heraus, genauso lang wie der Fall.

```gdscript
func kamera_fahren(zoom: float, versatz: float, dauer: float) -> void:
	if kamerafahrt != null:
		kamerafahrt.kill()
	kamerafahrt = create_tween()
	kamerafahrt.set_parallel(true)
	kamerafahrt.tween_property($Kanone/Kamera, "zoom", Vector2.ONE * zoom, dauer)
	kamerafahrt.tween_property($Kanone/Kamera, "offset:y", versatz, dauer)
```
Neu. Gleiches Muster wie `steigen`: eine laufende Fahrt abbrechen, eine neue anlegen. `set_parallel(true)` laesst Zoom und Versatz gleichzeitig gleiten statt nacheinander. `"offset:y"` heisst: nur die y-Zahl des Versatzes. `Vector2.ONE * zoom` ist (0.85, 0.85), gleich viel Zoom in beide Richtungen.

### `szenen/spiel.tscn` - geaendert

```
Boden/Streifen   unten 160 -> 300 (herausgezoomt sah man sonst darunter das Leere)
Kanone/RechteHand  y -560 -> -700
Kanone/Griff       y -560 -> -700
Kanone/Faecher     y -800 -> -940
Kanone/Kamera      offset -380 -> -447, zoom 1 -> 0.85
```
Hand, Griff und Faecher sind um 140 px nach oben gerueckt, genau um so viel, wie der obere Bildrand in der Luft hoeher liegt (1060 statt 920). Im Bild stehen sie also an derselben Stelle wie vorher. Die Kamera-Werte der Szene sind dieselben wie in `spiel.gd` und werden dort beim Start ohnehin gesetzt.

### So wurde es angeschaut

- Verify PASS, Schnellcheck aller sechs geaenderten Skripte PASS.
- Probe in einer Kopie des Spiels (ausserhalb des Spielordners), 60 Bilder pro Sekunde fest, Hindernisse aus:
  - Von 300 Fliegen 151 schnell (6 Flugkraft, Tempo 400-720, dreht nicht) und 149 normal (2, dreht, wippt).
  - Eine normale Fliege: 2,0 Umdrehungen in 2 Sekunden, wippt 50 px (25 hoch, 25 runter).
  - Neue Fliegen: 4, keine flieht beim Start. Nach 5 Bildern sind 3 noch ausserhalb des Bodenbildes, die vierte war schnell und schon 60 px weit.
  - Schuss auf eine Fliege: getroffen im 7. Bild, gestiegen im selben Bild. Rechts gehalten: 6 px Fahrt in den ersten 20 Bildern des Steigens (Ausrollen), danach wieder 250 px/s.
  - Kamera: Start Zoom 0,85 / Versatz -447, in der Luft 1,0 / -520, nach dem Absturz auf 0 wieder 0,85 / -447.
  - Nach dem Steigen: 8 Fliegen fliehen, alle zum naeheren Rand, keine falsch. 5 Sekunden spaeter 4 Fliegen, alle ruhig.
- Zwei Bilder (am Boden und in der Luft): Am Boden ist die Kanone kleiner und der Boden zu sehen. In der Luft sitzt die Kanone unten am Rand, kein Boden. Dabei gefunden und behoben: Unter dem Bodenstreifen war ein dunkler Rand.
- **Gesehen, nicht geaendert:** Die rechte Hand liegt in der Hoehe, in der Fliegen hin und her fliegen. Eine Fliege kann hinter der Hand durchfliegen. Das war vorher auch schon so.
- Handy-Probe: In der Safari-Engine kommen beide Schusstasten an. In Chromium meldet die Probe die linke als FAIL, am Bild hat sie aber geschossen und getroffen (Nadel steckt in einer Fliege). Der Arm fuhr gleich danach zur Hand, der Faden lief schraeg an der schmalen Messflaeche vorbei.
- **Nicht gemessen:** wie es sich spielt.

### Drei Fragen zur Selbstkontrolle

1. Warum flieht eine Fliege meistens dann, wenn du gerade eine andere gefangen hast?
2. Was passiert mit `rotation` und `position.y` bei einer schnellen Fliege, und warum muss dafuer kein `if` im Code stehen?
3. Warum stehen Faecher, Hand und Griff 140 px hoeher als vorher, und warum sieht man das im Bild nicht?

<details><summary>Antworten</summary>

1. Die Fliegen fliegen nur seitlich, ihre Hoehe aendert sich nicht. Steigst du, faehrt das Bild hoch, und die Fliegen rutschen darin nach unten in die untere Haelfte (unter 520 ueber der Kanone). Dort setzt `fliehen_lassen` ihre Flucht.
2. Nichts: `drehtempo` und `wipp_hoehe` sind 0. `rotation += 0` aendert nichts, und `grund_y + sin(...) * 0` ist immer `grund_y`.
3. Die Kamera zeigt in der Luft 140 px mehr ueber der Kanone (Rand bei 1060 statt 920), weil die Kanone jetzt unten am Rand sitzt. Alles, was oben am Bildrand bleiben soll, muss um genau so viel nach oben, dann steht es im Bild wieder an derselben Stelle.

</details>
