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
