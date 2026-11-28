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

## Spass-Test, Runde 3 - Hindernisse mittiger, laenger, leiser am Anfang

Hindernisse kommen oefter in der Mitte, warnen doppelt so lange, damit man vorher noch eine Fliege aus der Spalte holen kann, und kuendigen sich am Anfang leiser an.

### `skripte/hindernis_erzeuger.gd` - geaendert

```gdscript
@export var mitte: float = 240.0
@export var anteil_mitte: float = 0.7
```
Neu. Das Bild ist 1440 breit, ein Drittel davon 480, also reicht das innere Drittel 240 zu jeder Seite der Kanone. In 7 von 10 Faellen liegt die Spalte dort.

```gdscript
	var abstand: float = randf_range(-spielraum, spielraum)
	if randf() < anteil_mitte:
		abstand = randf_range(-mitte, mitte)
	hindernis.position.x = kanone.position.x + abstand
```
Erst wird wie bisher irgendwo im Bild gewuerfelt (bis 700 zu jeder Seite). Dann ein zweiter Wurf: Ist `randf()` kleiner als 0.7, wird der erste Wert ueberschrieben, mit einem Wert nur aus dem inneren Drittel. Insgesamt liegt die Spalte dadurch in etwa 80 von 100 Faellen innen: die 70 aus dem zweiten Wurf, und von den anderen 30 landet ein Drittel zufaellig auch innen (240 von 700).

```gdscript
@export var warnzeit_unten: float = 6.0
@export var warnzeit_oben: float = 10.0
```
Doppelt so lang wie vorher (3 und 5). Bei einem Drittel des Wegs sind es jetzt 8 Sekunden. Die Rechnung darunter ist dieselbe.

### `skripte/hindernis.gd` - geaendert

```gdscript
@export var blinken_anfang: float = 1.0
```
Vorher 0.5. Am Anfang dauert ein Blinken jetzt 1 Sekunde, also langsamer.

```gdscript
@export var groesse_anfang: float = 0.25
@export var groesse_ende: float = 1.5
@export var spalte_anfang: float = 0.3
```
Neu. Bisher stand im Code fest `0.5 + anteil`, also 0.5 bis 1.5. Jetzt beginnt das Schild bei einem Viertel seiner Groesse und ist als Regler einstellbar. Die gelbe Spalte beginnt bei 30 Prozent ihrer Deckkraft.

```gdscript
	$Warnung.scale = Vector2.ONE * lerpf(groesse_anfang, groesse_ende, anteil)
	$Spalte.modulate.a = lerpf(spalte_anfang, 1.0, anteil)
```
In `warnen`. `anteil` geht waehrend der Warnung von 0 auf 1. `lerpf` nimmt den Wert dazwischen: Schild von 0.25 auf 1.5, Spalte von 0.3 auf 1. `modulate.a` ist die Deckkraft, mit der ein Knoten gezeichnet wird, 1 heisst so, wie die Farbe in der Szene eingestellt ist (dort schon schwach gelb, 0.15).

### So wurde es angeschaut

- Verify PASS, Schnellcheck beider Skripte PASS.
- Probe in einer Kopie des Spiels: von 2000 Hindernissen 80,75 % im inneren Drittel, das weiteste 700 px neben der Kanone. Warnzeit bei 0 / 10000 / 20000 / 30000 px: 6 / 8 / 10 / 10 s. Schild am Anfang 0,25, Spalte 0,3; nach 3 s (bei 6 s Warnzeit) Schild 0,88, Spalte 0,65.
- **Folge, nicht geaendert:** Die Pause zwischen zwei Hindernissen (6 bis 10 s) zaehlt ab dem Erscheinen. Bei 6 bis 10 s Warnzeit laufen jetzt oft zwei Warnungen gleichzeitig.
- **Nicht gemessen:** wie es sich spielt, und ob man das leise Schild am Anfang noch sieht.

### Drei Fragen zur Selbstkontrolle

1. Warum liegen am Ende etwa 80 und nicht 70 von 100 Spalten im inneren Drittel?
2. Wie gross ist das Schild nach der Haelfte der Warnzeit?
3. Was muesstest du aendern, damit nie mehr als ein Hindernis gleichzeitig warnt?

<details><summary>Antworten</summary>

1. In den anderen 30 Faellen gilt der erste Wurf ueber das ganze Bild, und der landet auch manchmal innen: 240 von 700 px, also etwa jedes dritte Mal. 70 + 30 / 3 = 80.
2. `lerpf(0.25, 1.5, 0.5)` = 0.25 + 0.5 x 1.25 = 0.875, also knapp 0,9.
3. Die Pause muss laenger sein als die laengste Warnzeit plus Fall, zum Beispiel `pause_kurz` und `pause_lang` ueber 10 Sekunden. Oder der Erzeuger zaehlt erst los, wenn das letzte Hindernis weg ist.

</details>

## Spass-Test, Runde 4 - schnelle Fliege gibt 5

### `skripte/erzeuger.gd` - geaendert

```gdscript
@export var flugkraft_schnell: int = 5
```
Vorher 6. Die schnelle Fliege war dir noch zu stark. Sonst aendert sich nichts. Bis 100 brauchst du jetzt zum Beispiel 20 schnelle oder 50 normale.

So angeschaut: Verify PASS, Schnellcheck PASS. Wie es sich spielt, entscheidest du.

## Spass-Test, Runde 5 - Warnzeit wird oben wieder knapper, Schild zeigt die Restzeit

Bis zur halben Hoehe waechst die Warnzeit, danach wird sie knapper bis 5 Sekunden bei 100. Und das Warnschild sieht jetzt immer so aus, wie es bei der Zeit aussieht, die noch bleibt. Eine kurze Warnung beginnt also schon groesser und schneller blinkend.

### `skripte/hindernis_erzeuger.gd` - geaendert

```gdscript
@export var warnzeit_unten: float = 6.0
@export var warnzeit_spitze: float = 9.0
@export var warnzeit_ende: float = 5.0
@export var hoehe_spitze: float = 15000.0
@export var hoehe_ende: float = 30000.0
```
Ersetzt `warnzeit_oben` (10) und `hoehe_oben` (20000). Drei Punkte: unten 6 s, bei der halben Hoehe (50 Flugkraft = 15000 px) 9 s, bei 100 Flugkraft (30000 px) 5 s. Bis zur Spitze steigt es so schnell wie vorher (1 Sekunde je 5000 px), darum sind es dort 9 und nicht 10.

```gdscript
	hindernis.warnzeit = warnzeit_hier()
	hindernis.volle_warnzeit = warnzeit_spitze
```
Statt der zwei Zeilen mit `anteil` und `lerpf`. Die Rechnung steckt jetzt in einer eigenen Funktion, weil es zwei Strecken sind. Das Hindernis erfaehrt ausserdem, was die laengste Warnzeit ueberhaupt ist (9 s).

```gdscript
func warnzeit_hier() -> float:
	var hoehe: float = -kanone.position.y
	if hoehe < hoehe_spitze:
		return lerpf(warnzeit_unten, warnzeit_spitze, clampf(hoehe / hoehe_spitze, 0.0, 1.0))
	var anteil: float = (hoehe - hoehe_spitze) / (hoehe_ende - hoehe_spitze)
	return lerpf(warnzeit_spitze, warnzeit_ende, clampf(anteil, 0.0, 1.0))
```
Neu. Unter der Spitze: von 6 nach 9, je nachdem, wie weit man schon ist. `return` gibt den Wert zurueck und beendet die Funktion, die Zeilen darunter laufen dann nicht. Ueber der Spitze: `anteil` ist, wie weit man von 15000 bis 30000 schon ist (0 bis 1), und `lerpf` geht damit von 9 nach 5. `clampf` haelt den Anteil zwischen 0 und 1, ueber 30000 bleibt es also bei 5.

### `skripte/hindernis.gd` - geaendert

```gdscript
var volle_warnzeit: float = 9.0
```
Neu. Setzt der Erzeuger.

```gdscript
	var rest: float = warnzeit - gewarnt
	var anteil: float = clampf(1.0 - rest / volle_warnzeit, 0.0, 1.0)
```
Statt `var anteil: float = gewarnt / warnzeit`. Vorher lief jede Warnung von klein nach gross, egal wie lang sie war. Jetzt haengt das Aussehen nur an der **Restzeit**: Bei 9 s Rest ist `anteil` 0 (kleinstes Schild, langsamstes Blinken), bei 0 s Rest ist er 1. Eine Warnung mit nur 5 s faengt bei 1 - 5/9 = 0,44 an, also so, wie eine lange Warnung aussieht, wenn bei ihr noch 5 s uebrig sind. So kannst du am Schild ablesen, wie viel Zeit bleibt. Schild, Spalte und Blinken benutzen denselben `anteil` wie vorher.

Folge: Auch ganz unten (6 s) beginnt die Warnung nicht mehr ganz klein, sondern bei einem Drittel. Ganz klein beginnt nur die laengste Warnung bei halber Hoehe.

### So wurde es angeschaut

- Verify PASS, Schnellcheck beider Skripte PASS.
- Probe in einer Kopie: Warnzeit bei 0 / 25 / 50 / 75 / 100 / 110 Flugkraft: 6 / 7,5 / 9 / 7 / 5 / 5 s. Eine 9-s-Warnung startet mit Schild 0,25, eine 5-s-Warnung mit 0,81. Hat die 9-s-Warnung noch 5 s, steht ihr Schild auch bei 0,81 und die Spalte bei 0,61, genau wie bei der frischen 5-s-Warnung. Kurz vor Schluss beide 1,49.
- Nicht gemessen: wie es sich spielt.

### Drei Fragen zur Selbstkontrolle

1. Wie lange warnt ein Hindernis bei 80 Flugkraft?
2. Wie gross ist das Schild einer 6-s-Warnung ganz am Anfang?
3. Warum braucht das Hindernis `volle_warnzeit` und nicht nur seine eigene `warnzeit`?

<details><summary>Antworten</summary>

1. 80 x 300 = 24000 px. (24000 - 15000) / 15000 = 0,6. `lerpf(9, 5, 0.6)` = 9 - 0,6 x 4 = 6,6 s.
2. `anteil` = 1 - 6/9 = 0,33. `lerpf(0.25, 1.5, 0.33)` = 0,25 + 0,33 x 1,25 = etwa 0,67.
3. Mit nur der eigenen Zeit liefe jede Warnung von klein nach gross, eine kurze einfach schneller. Erst der Vergleich mit der laengsten zeigt, wie viel Zeit noch bleibt, und damit sieht dieselbe Restzeit immer gleich aus.

</details>

## Spass-Test, Runde 6 - Glas-Leiste, Tasten unten, Platzhalter-Toene

Deine Variante 2: Die Tasten liegen unten nebeneinander, die Leiste ist ein dickes, schraeges Glas, das zur rechten Hand hochlaeuft und sich von unten fuellt. Dazu hat jetzt jedes Ereignis einen Ton. Die Toene sind Platzhalter, du musst nichts auswaehlen. Abschnitt 11 ersetzt oder bestaetigt sie.

### `szenen/spiel.tscn` - geaendert: Leiste und Tasten

```
Kanone/RechteHand/Leiste   80 x 435, rotation 0.328, pivot_offset (40, 435), fill_mode 3
Bedienung/TasteLinks        (40, 880),   scale 0.85
Bedienung/TasteSchussLinks  (220, 880),  scale 0.85
Bedienung/TasteSchuss       (1050, 880), scale 0.85
Bedienung/TasteRechts       (1230, 880), scale 0.85
```
- Die Leiste ist weiter eine `ProgressBar`, nur hochkant: 80 breit, 435 lang.
- `fill_mode 3` heisst "von unten nach oben fuellen", wie ein Glas.
- `rotation` ist der Drehwinkel im Bogenmass: 0.328 sind etwa 19 Grad. So lehnt sie oben nach rechts, zur Hand.
- `pivot_offset` ist der Punkt, um den gedreht wird: (40, 435) ist unten in der Mitte. Der Fuss bleibt also stehen, nur die Spitze kippt zur Hand.
- Die Tasten sind mit `scale 0.85` kleiner (200 -> 170 px) und liegen nebeneinander ganz unten: links Pfeil aussen, Schuss innen; rechts Schuss innen, Pfeil aussen. Darueber ist auf der rechten Seite Platz fuer das Glas.

### Die Tondateien - `assets/audio/sfx/`

| Datei | Woher | Wofuer |
|-------|-------|--------|
| `schuss.wav` | Sonniss GDC 2026, Cinematic Sound Design, "Woosh Sweep Slide" | Schuss |
| `treffer.wav` | Sonniss GDC 2026, Epic Stock Media, "Hit Blood Spill Splat" | Fang |
| `arm.wav` | Sonniss GDC 2026, Epic Stock Media, "Robot Motor Servo Whine" | Arm faehrt zur Hand |
| `steigen.ogg` | Sonniss GDC 2026, 344 Audio, "Wind Rush Whoosh" | Steigen, tiefer abgespielt auch Absturz |
| `warnung.wav` | Sonniss GDC 2026, InMotionAudio, "Thermometer Beep" | Warnpiepen |
| `klotz.wav` | Sonniss GDC 2026, 344 Audio, "Metal Slow Whoosh Rattle" | Hindernis faellt |
| `matsch.wav` | Sonniss GDC 2026, Epic Stock Media, "Gore Heavy Impact Smash" | Fliege zermatscht |
| `aufstehen.wav` | Sonniss GDC 2026, Epic Stock Media, "Cloth Canvas Bag Slide" | Aufstehen |
| `sieg.ogg` | Sonniss GDC 2026, Epic Stock Media, "Power Up Bright Positive" | Im All |
| `summen.ogg` | selbst erzeugt (Saegezahn 180 Hz, Fluegelschlag 30 Hz), Platzhalter | Fliegen summen |

Alle wurden vorher gleich laut gemacht (der lauteste Teil auf -18 dB), Stille vorn und hinten weggeschnitten und in Mono gespeichert. Die Sonniss-Klaenge darf man in Spielen frei verwenden, ohne Namensnennung. In der Bibliothek gab es kein Fliegensummen, darum ist `summen.ogg` erzeugt. In `summen.ogg.import` steht `loop=true`: Godot spielt die Datei als Schleife, ohne Ende.

### Die Szenen - Tonspieler

- `szenen/fliege.tscn`: neuer Knoten `Summen` (`AudioStreamPlayer2D`), `autoplay`, `volume_db` -10, `max_distance` 760.
- `szenen/nadel.tscn`: `TonTreffer` (-3 dB).
- `szenen/hindernis.tscn`: `TonWarnung` (-16 dB, wird im Skript geaendert), `TonKlotz` (0 dB), `TonMatsch` (-3 dB).
- `szenen/spiel.tscn`: `Kanone/TonSchuss` (-4 dB), `Kanone/Uebergabe/TonArm` (-10 dB), dazu ein Knoten `Ton` mit `Steigen` (0 dB), `Absturz` (dieselbe Datei, `pitch_scale` 0.6, also tiefer und langsamer), `Aufstehen` (-6 dB), `Sieg` (+2 dB).

Ein `AudioStreamPlayer` spielt eine Tondatei ab, wenn man `play()` aufruft. `volume_db` ist die Lautstaerke in Dezibel: 0 heisst so laut wie die Datei, minus heisst leiser (-6 ist etwa halb so laut).

Das Summen ist ein `AudioStreamPlayer2D`: Der hat einen Ort in der Welt. Godot macht ihn leiser, je weiter er von der Mitte der Kamera weg ist, und ab `max_distance` (760 px) ist er stumm. Der Bildrand liegt 720 px neben der Mitte. Darum ist eine Fliege in der Mitte am lautesten und am Rand still, **ohne eine Zeile Code**. Links und rechts verteilt Godot den Ton dabei auch ein wenig auf die beiden Lautsprecher. `autoplay` heisst: Er faengt von selbst an, sobald die Fliege ins Spiel kommt.

### `skripte/fliege.gd` - geaendert

```gdscript
@export var tonhoehe_tief: float = 0.8
@export var tonhoehe_hoch: float = 1.4
...
	$Summen.pitch_scale = randf_range(tonhoehe_tief, tonhoehe_hoch)
```
Neu, die letzte Zeile in `_ready`. `pitch_scale` ist die Tonhoehe: 1 wie die Datei, 1.4 hoeher (und schneller), 0.8 tiefer. Jede Fliege wuerfelt ihre eigene, darum klingen mehrere Fliegen wie ein Chor.

### `skripte/nadel.gd` - geaendert

```gdscript
	fliege.get_node("Summen").stop()
	$TonTreffer.play()
```
Neu in `treffen`. Eine gefangene Fliege summt nicht mehr, und der Fang klatscht. `get_node("Summen")` holt den Knoten `Summen` aus der Fliege, so wie `$Summen` es in ihrem eigenen Skript tut.

### `skripte/kanone.gd` - geaendert

```gdscript
		$TonSchuss.play()
```
Neu, letzte Zeile beim Schuss.

### `skripte/uebergabe.gd` - geaendert

```gdscript
		$TonArm.play()
```
Neu, gleich nach `faecher.aufnehmen(nadel)`: Wenn der Arm losfaehrt, surrt der Motor.

### `skripte/spiel.gd` - geaendert

```gdscript
	$Ton/Steigen.play()      # in fliege_zaehlen
	$Ton/Sieg.play()         # dort, wenn das Ziel erreicht ist
	$Ton/Absturz.play()      # in fliege_verlieren
	$Ton/Aufstehen.play()    # in aufstehen
```
Je eine neue Zeile an der Stelle, an der das Ereignis passiert.

### `skripte/hindernis.gd` - geaendert

```gdscript
@export var ton_leise: float = -16.0
@export var ton_laut: float = 0.0
```
Neu. Wie laut das Piepen am Anfang und am Ende der Warnung ist.

```gdscript
	var an: bool = fmod(gewarnt, takt) < takt / 2.0
	if an and not $Warnung.visible:
		$TonWarnung.volume_db = lerpf(ton_leise, ton_laut, anteil)
		$TonWarnung.play()
	$Warnung.visible = an
	if gewarnt >= warnzeit:
		$TonKlotz.play()
```
Geaendert in `warnen`. Vorher stand `$Warnung.visible = fmod(...) < ...` direkt da. Jetzt wird das Ergebnis erst in `an` gemerkt. Ist das Schild jetzt an, war es aber eben noch aus, beginnt gerade ein Blinken: Dann piept es, und zwar umso lauter, je weiter die Warnung ist (`anteil`, wie bei der Groesse des Schilds). Danach wird das Schild wie vorher gezeigt oder versteckt. Ist die Warnzeit gerade um, faellt der Klotz, und sein Ton startet. Das passiert genau einmal, denn im naechsten Bild laeuft schon `fallen` statt `warnen`.

```gdscript
	$TonMatsch.play()
```
Neu in `zermatschen`.

### So wurde es angeschaut

- Verify PASS, Schnellcheck aller sechs geaenderten Skripte PASS.
- **Am aufgenommenen Ton gemessen** (Godot Movie Maker, ein gesteuerter Lauf in einer Kopie, Ton als WAV): Stille -46,7 dB. Eine Fliege mitten im Bild -31,5 dB, 360 px seitlich -38,1 dB, am Bildrand (720 px) und ausserhalb: kein Ton. Schuss bei 5,0 s (-20 dB), Warnpiepen ab 6,2 s, Klotz bei 8,0 s, Fang mit Steigen ab 8,5 s, alle in der Aufnahme zu finden.
- Handy-Probe: Pfeiltasten und rechte Schusstaste ok. Die linke Schusstaste meldet die Probe als FAIL. Am Bild schiesst sie in beiden Engines: in Chromium trifft sie eine Fliege (der Arm faehrt danach weg, der Faden verfehlt die Messflaeche), in der Safari-Engine steht die Nadel mit Faden im Bild (dort stoerte eine gelbe Warnspalte die Messung).
- **Nicht gemessen:** ob die Toene passen und zusammen gut klingen. Das hoerst du. Bekannt: Am Ende einer Warnung blinkt das Schild alle 0,1 s, das Piepen dauert 0,19 s, es wird dann fast ein Dauerton.

### Drei Fragen zur Selbstkontrolle

1. Warum braucht das Leiserwerden der Fliegen zum Rand keine Zeile Code?
2. Warum piept die Warnung nicht in jedem Bild, obwohl `warnen` in jedem Bild laeuft?
3. Warum klingt `Absturz` anders als `Steigen`, obwohl es dieselbe Datei ist?

<details><summary>Antworten</summary>

1. Das Summen ist ein `AudioStreamPlayer2D`. Godot rechnet selbst aus, wie weit er von der Kamera weg ist, und macht ihn bis `max_distance` (760) immer leiser.
2. Es piept nur, wenn das Schild gerade angeht (`an` ist wahr, aber `$Warnung.visible` war noch falsch). Das ist einmal je Blinken.
3. `pitch_scale` 0.6: Die Datei laeuft langsamer und tiefer.

</details>

### `export_presets.cfg` - geaendert in Spass-Test, Runde 6

In `html/head_include` steht jetzt vorn ein zweites kleines JavaScript, vor der Messseite. Es gehoert nicht zum Spiel, sondern zur Webseite, die der Export baut, und es bleibt (anders als die Messseite):
- `navigator.audioSession.type='playback'` sagt dem iPhone: Diese Seite spielt Ton wie eine Musik-App. Ohne die Zeile ist jeder Ton stumm, solange der Stummschalter am iPhone an ist.
- Der Rest weckt den Ton wieder auf, wenn der Browser ihn nach einem Wechsel in eine andere App angehalten hat, bei der naechsten Beruehrung oder Taste.
- Nebenwirkung: Laeuft am Handy Musik aus einer anderen App, haelt sie an, wenn das Spiel Ton macht.

## Spass-Test, Runde 7 - Ton bricht nicht mehr ab

Du hast gemeldet: Bei vielen Fliegen, Hindernissen und einem Treffer "kackt der Ton ab". Gemessen an einer Aufnahme im vollen Betrieb (8 Fliegen in der Mitte, zwei Warnungen gleichzeitig, Klotz trifft Fliegen, vier Schuesse mit Fang): Die Summe aller Toene erreichte die Obergrenze (0,0 dBFS, 17 Samples ueber -1 dBFS). Darueber wird das Signal abgeschnitten, das klingt kratzig und abgehackt. Dazu kamen zwei echte Abbrueche, siehe unten.

**Was es nicht war:** Der Treffer-Ton wird nicht abgeschnitten, obwohl die Nadel gleich danach umgehaengt wird (`reparent`). In der Aufnahme laeuft er volle 0,3 Sekunden.

### Lautstaerken in den Szenen - geaendert

Jeder Tonspieler ist 8 dB leiser, das Summen 10 dB leiser (es summen viele Fliegen gleichzeitig, ihre Lautstaerken addieren sich):

| Spieler | vorher | jetzt |
|---------|--------|-------|
| `Kanone/TonSchuss` | -4 | -12 |
| `Kanone/Uebergabe/TonArm` | -10 | -18 |
| `Ton/Steigen`, `Ton/Absturz` | 0 | -8 |
| `Ton/Aufstehen` | -6 | -14 |
| `Ton/Sieg` | 2 | -6 |
| `nadel.tscn` `TonTreffer` | -3 | -11 |
| `fliege.tscn` `Summen` | -10 | -20 |
| `hindernis.tscn` `TonWarnung` (Startwert) | -16 | -24 |
| `TonKlotz` | 0 | -8 |
| `TonMatsch` | -3 | -11 |

Alles klingt im Verhaeltnis wie vorher, nur mit Platz nach oben. Ist es dir insgesamt zu leise, dreht man das am Geraet lauter, nicht im Spiel.

### `szenen/hindernis.tscn` und `szenen/spiel.tscn` - Klotz und Matsch umgezogen

`TonKlotz` und `TonMatsch` sind aus der Hindernis-Szene heraus und haengen jetzt in `spiel.tscn` unter `Hindernisse` (dem Hindernis-Erzeuger). Grund: Ein Hindernis loescht sich selbst (`queue_free`), sobald es unter dem Bild ist, etwa 0,75 Sekunden nach dem Fall. Mit ihm verschwanden seine Tonspieler, und ihr Ton brach mitten drin ab (Klotz 1 Sekunde, Matsch 0,8 Sekunden lang). Der Erzeuger wird nie geloescht, dort laufen die Toene aus.

`max_polyphony` 3 bzw. 4: So viele Male darf derselbe Spieler gleichzeitig klingen. Standard ist 1, dann bricht jedes neue `play()` den laufenden Ton ab. Werden zwei Fliegen im selben Moment zermatscht, klingen jetzt beide.

Nebenbei: Beim Sieg loescht `spiel.gd` alle Kinder von `Hindernisse`, also jetzt auch diese zwei Spieler. Das schadet nicht, danach kommen keine Hindernisse mehr.

### `skripte/hindernis.gd` - geaendert

```gdscript
@export var ton_leise: float = -24.0
@export var ton_laut: float = -8.0
```
Wie oben, 8 dB leiser.

```gdscript
	if an and not $Warnung.visible and not $TonWarnung.playing:
```
Neu ist `and not $TonWarnung.playing`. Am Ende einer Warnung blinkt das Schild alle 0,1 Sekunden, das Piepen dauert aber 0,19. Vorher startete jedes Blinken das Piepen neu und schnitt das alte ab, das klang abgehackt. Jetzt piept es erst wieder, wenn das letzte Piepen fertig ist. `playing` ist wahr, solange der Spieler noch spielt.

```gdscript
		get_parent().get_node("TonKlotz").play()
...
	get_parent().get_node("TonMatsch").play()
```
Statt `$TonKlotz` und `$TonMatsch`. `get_parent()` ist der Hindernis-Erzeuger (das Hindernis ist sein Kind), dort liegen die beiden Spieler jetzt. So wird auch der Matsch-Fleck schon seit Abschnitt 6 in `get_parent()` gesetzt.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Aufnahme mit dem Movie Maker im vollen Betrieb, gleicher Ablauf vorher und nachher: Spitze **0,0 -> -5,7 dBFS**, Samples ueber -1 dBFS **17 -> 0**.
- Treffer-Ton allein aufgenommen: laeuft 0,3 s durch (das war es nicht).
- **Nicht gemessen:** im Browser am Handy. Dort spielt Godot die Toene ueber den Browser ab, das kann am PC nicht aufgenommen werden. Ob es am Handy jetzt sauber klingt, zeigt nur dein Geraet.

### Drei Fragen zur Selbstkontrolle

1. Warum kann ein Ton abbrechen, wenn sein Knoten geloescht wird, und wie wurde das hier geloest?
2. Was bedeutet `max_polyphony` 4?
3. Warum wurde nicht nur das Summen leiser gemacht?

<details><summary>Antworten</summary>

1. Ein Tonspieler spielt nur, solange er im Szenenbaum ist. Das Hindernis loescht sich, sobald es unten raus ist, und seine Kinder mit. Die Spieler fuer Klotz und Matsch haengen jetzt am Hindernis-Erzeuger, der bleibt.
2. Derselbe Spieler darf bis zu vier Mal gleichzeitig klingen. Ein fuenftes `play()` stoppt den aeltesten.
3. Uebersteuert hat die Summe aller Toene, nicht ein einzelner. Alle gleich viel leiser haelt das Verhaeltnis gleich und schafft Platz nach oben.

</details>

## Spass-Test, Runde 8 - Warnpiepen leiser

### `skripte/hindernis.gd` und `szenen/hindernis.tscn` - geaendert

```gdscript
@export var ton_leise: float = -30.0
@export var ton_laut: float = -20.0
```
Vorher -24 und -8. Das Piepen hat dich gestoert, jetzt ist es auch am Ende der Warnung leiser als alle anderen Toene (die liegen bei -8 bis -14). In der Szene steht der Startwert von `TonWarnung` passend auf -30. Schneller wird es weiterhin, wie das Blinken.

So angeschaut: Verify PASS, Schnellcheck PASS. Wie es klingt, entscheidest du.

## Spass-Test, Runde 9 - grober Hintergrund

Damit man sieht, dass man nach links oder rechts faehrt (und wie hoch man steigt), liegt jetzt hinter allem ein grobes Schachbrett. Kein Code, nur Knoten in der Szene.

### `szenen/spiel.tscn` - geaendert

```
Spiel
  Hintergrund   (Parallax2D, ganz oben im Baum)
    Feld1       (ColorRect 400 x 400 bei 0, 0)
    Feld2       (ColorRect 400 x 400 bei 400, 400)
```
- `Hintergrund` steht als erstes Kind von `Spiel`. Godot zeichnet von oben nach unten im Baum, also liegt er hinter allem anderen.
- Ein `Parallax2D` kennst du vom Boden (Abschnitt 1): Er wiederholt seinen Inhalt. `repeat_size` (800, 800) heisst: alle 800 px nach rechts und nach unten kommt dasselbe noch einmal, diesmal in beide Richtungen, nicht nur seitlich. `repeat_times` 3 legt genug Kopien daneben, dass auch das herausgezoomte Bild am Boden voll ist.
- In einem 800er-Quadrat liegen zwei hellere Felder schraeg gegenueber, die anderen zwei Viertel bleiben die normale Hintergrundfarbe. So entsteht das Schachbrett. Die helleren Felder sind 0.34 grau, der Hintergrund etwa 0.30, also nur ein leichter Unterschied.
- `scroll_scale` (0.5, 0.5): Der Hintergrund bewegt sich halb so schnell wie die Welt. Dadurch wirkt er weiter weg. Man sieht die Bewegung trotzdem.
- `mouse_filter` 2 heisst: Die Felder fangen keine Mausklicks ab.

### So wurde es angeschaut

- Verify PASS.
- Bild am Boden und in der Luft: Schachbrett zu sehen, Fliegen gut lesbar.
- Kanone 200 px nach rechts: Die Kante des Musters wandert im Bild um etwa 83 px nach links (200 x 0,5 x Zoom 0,85), es bewegt sich also mit.

## Spass-Test, Runde 10 - Mehrfach-Treffer, schnellerer Fall mit Wackeln, Faecher mittiger, groessere Trefferflaeche

### `skripte/nadel.gd` - neu geschrieben

Die Nadel kann jetzt mehrere Fliegen aufspiessen (Double Kill, Triple Kill). Liegt ueber der getroffenen Fliege auf dem Bildschirm noch eine in ihrer Bahn, fliegt sie weiter und nimmt die getroffene mit. Sie bleibt in der letzten stecken.

```gdscript
signal getroffen(nadel: Node2D)
```
Gleicher Name wie vorher, aber das Signal kommt jetzt erst, wenn die Nadel in ihrer **letzten** Fliege stecken bleibt. Erst dann beginnt die Uebergabe.

```gdscript
@export var trefferzugabe: float = 1.125
@export var spiess_abstand: float = 110.0
```
Neu. `trefferzugabe`: Die Trefferflaeche einer Fliege ist ein Achtel groesser als die Fliege selbst (100 -> 112,5 px, also 56,25 zu jeder Seite). Gilt nur fuer die Nadel, Hindernisse treffen weiter genau die Fliege (zu deinen Gunsten). `spiess_abstand`: so weit haengen die Fliegen am Spiess untereinander, 10 px mehr als eine Fliege hoch ist, damit sie sich nicht beruehren.

```gdscript
var aufgespiesste: Array[Node2D] = []
```
Ersetzt `var fliege`. Statt einer Fliege merkt sich die Nadel eine Liste, in der Reihenfolge der Treffer.

```gdscript
func _process(delta: float) -> void:
	if steckt:
		faden_spannen()
		return
	position.y -= tempo * delta
	geflogen += tempo * delta
	var getroffene: Node2D = fliege_an_der_spitze()
	if getroffene != null:
		aufspiessen(getroffene)
	if not aufgespiesste.is_empty():
		if geflogen >= reichweite or not noch_eine_darueber():
			stecken_bleiben()
	elif geflogen >= reichweite:
		queue_free()
	faden_spannen()
```
Der Anfang ist wie vorher: fliegen, zaehlen, an der Spitze nach einer Fliege suchen. Neu:
- Eine getroffene Fliege wird aufgespiesst, die Nadel fliegt aber weiter.
- Hat die Nadel schon Fliegen, prueft sie jedes Bild: Ist darueber im Bild noch eine in meiner Bahn? Wenn nicht mehr (oder die Reichweite ist um), bleibt sie stecken. "Jedes Bild" ist wichtig: Fliegt eine Fliege aus der Bahn, bevor die Nadel sie erreicht, bleibt die Nadel trotzdem stehen und verschwindet nicht mit ihrer Beute.
- Hat sie keine Fliege und die Reichweite ist um, verschwindet sie wie bisher (`elif` heisst "sonst, wenn").

```gdscript
func trifft(kandidat: Node2D, nur_darueber: bool) -> bool:
	if kandidat.gefangen:
		return false
	var halb: float = kandidat.halbe_groesse * trefferzugabe
	var seitlich: float = absf(kandidat.global_position.x - global_position.x)
	if seitlich > halb:
		return false
	if nur_darueber:
		return kandidat.global_position.y < global_position.y and kandidat.global_position.y > bildrand_oben()
	return absf(kandidat.global_position.y - global_position.y) <= halb
```
Neu. Eine Frage fuer zwei Faelle, darum ein Schalter `nur_darueber`.
- Gefangene Fliegen zaehlen nie.
- Seitlich muss die Fliege nah genug an der Nadel sein (mit der groesseren Trefferflaeche).
- Fall 1, `nur_darueber` falsch: Steckt die Spitze gerade in der Fliege? Das ist die alte Rechnung aus `fliege_an_der_spitze`.
- Fall 2, `nur_darueber` wahr: Liegt die Fliege ueber der Spitze (kleineres y) und noch im Bild (groesseres y als der obere Bildrand)?

```gdscript
func fliege_an_der_spitze() -> Node2D:
	for kandidat in get_tree().get_nodes_in_group("fliegen"):
		if trifft(kandidat, false):
			return kandidat
	return null


func noch_eine_darueber() -> bool:
	for kandidat in get_tree().get_nodes_in_group("fliegen"):
		if trifft(kandidat, true):
			return true
	return false
```
Zwei kurze Schleifen ueber alle Fliegen, die eine fragt Fall 1, die andere Fall 2.

```gdscript
func bildrand_oben() -> float:
	var kamera: Camera2D = get_viewport().get_camera_2d()
	return kamera.get_screen_center_position().y - 540.0 / kamera.zoom.y
```
Neu. `get_viewport().get_camera_2d()` holt die Kamera, die gerade das Bild zeigt. `get_screen_center_position()` ist die Mitte des Bildes in der Welt. Das Bild ist 1080 hoch, also liegt der obere Rand 540 darueber, beim Zoom 0.85 entsprechend mehr (540 / 0.85).

```gdscript
func aufspiessen(getroffene: Node2D) -> void:
	for alte in aufgespiesste:
		alte.position.y += spiess_abstand
	aufgespiesste.append(getroffene)
	getroffene.gefangen = true
	getroffene.get_node("Summen").stop()
	$TonTreffer.play()
	getroffene.reparent(self)
	getroffene.position = Vector2.ZERO
	...Blutfleck wie bisher
```
Hiess `treffen`. Neu:
- Alle schon aufgespiessten Fliegen rutschen um 110 px nach unten. Die neue kommt an die Spitze (`Vector2.ZERO`, also genau auf die Nadel). So haengen sie immer mit gleichem Abstand untereinander, ohne Physik.
- Vorher blieb die Fliege dort, wo die Spitze sie gerade erwischt hatte. Das schwankt um bis zu 56 px, und beim Spiess haetten sich zwei Fliegen dann ueberlappt. Gemessen, darum geaendert.
- `append` haengt die neue Fliege hinten an die Liste.

```gdscript
func stecken_bleiben() -> void:
	steckt = true
	getroffen.emit(self)


func flugkraft() -> int:
	var summe: int = 0
	for fliege in aufgespiesste:
		summe += fliege.flugkraft
	return summe
```
Neu. `stecken_bleiben` ist das alte Ende von `treffen`. `flugkraft()` zaehlt die Flugkraft aller Fliegen am Spiess zusammen.

### `skripte/uebergabe.gd` und `skripte/faecher.gd` - geaendert

```gdscript
	gefangen.emit(nadel.flugkraft())        # uebergabe.gd, starten
	verloren.emit(nadel.flugkraft())        # faecher.gd, entfernen
```
Statt `nadel.fliege.flugkraft`. Ein Spiess mit drei Fliegen bringt alle drei Werte, und verliert man ihn, sind alle drei weg (der Faden reisst).

```gdscript
@export var breite: float = 1152.0
```
In `faecher.gd`, vorher 1400. Das Bild ist 1440 breit, je ein Zehntel (144 px) Rand zu jeder Seite: 1440 - 2 x 144 = 1152. Ab dieser Breite schrumpft der Faecher.

### `skripte/hindernis.gd` - geaendert

```gdscript
@export var falltempo: float = 3000.0
```
Vorher 1800. Der Klotz muss schneller fallen als du abstuerzt, sonst holt dich der fallende Faecher ihn von oben ein und verliert Fliegen, die gar nicht in der Spalte hingen. Dein Absturz ist jetzt 2400.

### `skripte/spiel.gd` - geaendert

```gdscript
@export var falltempo: float = 2400.0
@export var wackeln_fall: float = 5.0
@export var wackeln_aufprall: float = 28.0
@export var aufprall_dauer: float = 0.4
...
var wackel_staerke: float = 0.0
var wackel_zeit: float = 0.0
```
Doppelt so schneller Fall (vorher 1200). Dazu die Regler fuers Wackeln der Kamera: beim Fallen hoechstens 5 px zur Seite, beim Aufprall 28 px fuer 0,4 Sekunden.

```gdscript
func _process(delta: float) -> void:
	if wackel_zeit > 0.0:
		wackel_zeit -= delta
		$Kanone/Kamera.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * wackel_staerke
	else:
		$Kanone/Kamera.position = Vector2.ZERO


func wackeln(staerke: float, dauer: float) -> void:
	wackel_staerke = staerke
	wackel_zeit = dauer
```
Neu. Solange Wackelzeit uebrig ist, springt die Kamera jedes Bild an eine zufaellige Stelle um ihren Platz, hoechstens `wackel_staerke` weit. Danach steht sie wieder genau an ihrem Platz (`Vector2.ZERO`). Es wird die `position` der Kamera bewegt, nicht ihr `offset`, denn den braucht schon die Kamerafahrt beim Zoomen. Die Tasten liegen im `CanvasLayer` und wackeln nicht mit.

```gdscript
	wackel_zeit = 0.0                                  # in fliege_zaehlen
	wackeln(wackeln_fall, strecke / falltempo)          # in fliege_verlieren
	wackeln(wackeln_aufprall, aufprall_dauer)           # in aufstehen
```
Faengst du mitten im Fall eine Fliege, hoert das Wackeln auf. Beim Fall wackelt es genau so lange, wie der Fall dauert. Am Boden (`aufstehen` laeuft nur, wenn man unten bei 0 ankommt) wackelt es einmal kraeftig.

### So wurde es angeschaut

- Verify PASS, Schnellcheck aller fuenf Skripte PASS.
- Probe in einer Kopie, dreimal hintereinander gleich: Trefferflaeche 55 px daneben trifft, 58 px daneben nicht. Drei Fliegen uebereinander in der Bahn: alle drei aufgespiesst, eine vierte ausserhalb des Bildes nicht, +6 Flugkraft, Abstaende genau 0 / 110 / 220 px. Fall 400 px in 10 Bildern (2400 px/s). Wackeln beim Fall bis etwa 7 px (5 in jede Richtung, schraeg mehr), beim Aufprall bis etwa 35 px.
- Bild in der Luft: Dreier-Spiess haengt untereinander am Faecher, Faden zur Hand.
- **Gesehen, nicht geaendert:** Ein langer Spiess haengt weit nach unten, ein Dreier bis etwa in die Hoehe der rechten Hand und in den Streifen, in dem freie Fliegen fliegen. Der Faden geht von der obersten Fliege zur Hand, die unteren haengen darunter.
- **Nicht gemessen:** wie es sich spielt.

### Drei Fragen zur Selbstkontrolle

1. Warum prueft die Nadel in jedem Bild, ob noch eine Fliege darueber ist, und nicht nur einmal beim ersten Treffer?
2. Warum muss der Klotz jetzt schneller fallen als vorher?
3. Wie viel Flugkraft bringt ein Spiess aus einer schnellen (5) und zwei normalen Fliegen (2)?

<details><summary>Antworten</summary>

1. Die Fliegen fliegen weiter. Ist die obere aus der Bahn, bevor die Nadel sie erreicht, muss die Nadel trotzdem stehen bleiben, sonst flöge sie mit ihrer Beute bis zur Reichweite und verschwaende.
2. Weil man jetzt mit 2400 px/s abstuerzt. Waere der Klotz langsamer, faellt der Faecher an ihm vorbei durch ihn hindurch und verliert weitere Fliegen.
3. 5 + 2 + 2 = 9, `flugkraft()` zaehlt alle zusammen.

</details>

## Spass-Test, Runde 11 - Fliegen haengen am Seil, Faecher lockerer

### `skripte/nadel.gd` - geaendert

```gdscript
	for alte in aufgespiesste:
		alte.position.y += spiess_abstand
```
Geloescht aus `aufspiessen`. Die Fliegen werden nicht mehr senkrecht unter die Nadel geschoben.

```gdscript
	getroffene.get_node("Loch").visible = true
```
Neu in `aufspiessen`: Die getroffene Fliege zeigt ihr Schussloch (siehe `fliege.tscn`).

```gdscript
	var richtung: Vector2 = $Oese.global_position.direction_to(anker.global_position)
	var anzahl: int = aufgespiesste.size()
	for nummer in anzahl:
		var fliege: Node2D = aufgespiesste[nummer]
		var schritte: int = anzahl - 1 - nummer
		fliege.global_position = $Oese.global_position + richtung * spiess_abstand * global_scale.x * schritte
		fliege.global_rotation = richtung.angle() - PI / 2.0
```
Neu am Ende von `faden_spannen`, laeuft also jedes Bild:
- `richtung` ist die Richtung des Fadens, von der Oese der Nadel zum Anker (erst die Muendung, im Faecher die Hand). `direction_to` gibt einen Pfeil der Laenge 1 in diese Richtung.
- Jede Fliege kommt auf den Faden: die neueste direkt an die Oese (`schritte` 0), die davor 110 px weiter den Faden entlang, die davor 220 px. Ihr Schussloch sitzt in der Mitte, also genau auf dem Faden.
- `global_scale.x`: Schrumpft der Faecher die Nadel, ruecken die Fliegen am Faden genauso zusammen.
- `global_rotation` dreht jede Fliege so, wie der Faden laeuft. `angle()` ist der Winkel des Pfeils. Minus `PI / 2` (90 Grad), weil die Fliege "nach unten" auf ihrer y-Achse hat, nicht auf der x-Achse. Dreht sich der Faden (der Arm faehrt zur Hand), drehen sich die Fliegen mit.

### `szenen/fliege.tscn` - geaendert

Neuer Knoten `Loch` (`ColorRect`, 16 x 16, dunkelrot, in der Mitte der Fliege, unsichtbar). Wird beim Aufspiessen sichtbar.

### `skripte/faecher.gd` - geaendert

```gdscript
@export var abstand: float = 90.0
@export var hoehen_streuung: float = 60.0
```
Vorher 110 und 20. Die Fliegen ruecken naeher zusammen (unter 100 ueberlappen sie sich leicht) und haengen bis zu 60 px hoeher oder tiefer. So liegen sie nicht mehr auf einer Linie, sondern auch mal ueber- oder untereinander.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Bilder (in einer Kopie, gesteuerte Schuesse): Dreier-Spiess im Flug, die Fliegen mit Schussloch am Faden schraeg zur Kanone. Faecher nach zehn Schuessen mit 14 Fliegen, locker verteilt, Spiesse am Seil Richtung Hand.
- Nicht gemessen: wie es sich spielt.

### Drei Fragen zur Selbstkontrolle

1. Warum liegt das Schussloch immer auf dem Faden?
2. Warum muss `faden_spannen` die Fliegen jedes Bild neu setzen und nicht nur einmal beim Treffer?
3. Was aendert sich, wenn du `hoehen_streuung` auf 0 stellst?

<details><summary>Antworten</summary>

1. Das Loch ist die Mitte der Fliege, und genau die Mitte wird auf einen Punkt des Fadens gesetzt (Oese plus Richtung mal Abstand).
2. Der Faden bewegt sich: Die Nadel fliegt, der Arm faehrt zur Hand, der Faecher rueckt zusammen. Die Fliegen sollen an ihm bleiben.
3. Alle Fliegen haengen wieder genau auf einer Linie.

</details>

### Nachtrag Runde 11 - Nagel gerade, Seil schraeg

```gdscript
	getroffene.rotation = 0.0                  # in aufspiessen
	for nummer in anzahl - 1:                  # in faden_spannen, vorher: in anzahl
```
Die Fliege, in der der Nagel steckt, haengt am Nagel, und der Nagel ist gerade. Darum steht sie gerade (`rotation` 0, eine drehende Fliege hoert dabei auf, schief zu stehen) und bleibt an der Spitze. `anzahl - 1` heisst: Die Schleife laesst die letzte, neueste Fliege aus. Nur die vorher durchstochenen sind auf das Seil gerutscht und drehen sich mit ihm. Bei `schritte` ist die erste davon 110 px den Faden entlang, die naechste 220.

Angeschaut am Bild: im Flug und im Faecher steht die Nagel-Fliege gerade, die Seil-Fliegen liegen schraeg in Fadenrichtung.

## Spass-Test, Runde 12 - Seil-Fliegen aufrecht, Faecher in zwei Reihen

### `skripte/nadel.gd` - geaendert

```gdscript
		fliege.global_rotation = richtung.angle() - PI / 2.0
```
Geloescht. Auch die Fliegen am Seil haengen jetzt aufrecht, Fluegel oben. Ihr Loch sitzt weiter genau auf dem Faden.

### `szenen/fliege.tscn` und `szenen/hindernis.tscn` - geaendert

- `Fliege` hat `z_index` 1. Der `z_index` sagt, was vorne gezeichnet wird: hoeher heisst weiter vorn. Der Faden hat 0, er liegt also hinter jeder Fliege. Er verschwindet am Rand der Fliege und kommt auf der anderen Seite wieder heraus. Mit dem roten Loch in der Mitte sieht es aus, als ginge er hindurch. Fuer die echten Bilder (Abschnitt 10) wird jede Fliege in Vorder- und Hinterteil geteilt, dann laeuft der Faden zwischen den beiden Teilen.
- `Warnung` (das Schild) und `Klotz` haben jetzt `z_index` 2, damit sie vor den Fliegen bleiben.

### `skripte/faecher.gd` - geaendert

```gdscript
@export var hoehen_streuung: float = 30.0
@export var reihen_abstand: float = 90.0
```
Streuung 60 -> 30, dafuer neu: Die Fliegen haengen in zwei Reihen, die untere 90 px tiefer.

```gdscript
func groesse() -> float:
	return minf(1.0, breite / (reihe.size() * abstand / 2.0))
```
`/ 2.0` ist neu. Weil sich zwei Reihen die Breite teilen, braucht jede Fliege nur noch einen halben Abstand Breite. Der Faecher schrumpft also erst bei doppelt so vielen Fliegen (ab etwa 26 statt 13).

```gdscript
	var unten: float = 0.0
	if nummer % 2 == 1:
		unten = reihen_abstand
	return Vector2((nummer - mitte) * abstand / 2.0 * groesse(), unten + versatz[nadel])
```
In `platz`. `nummer % 2` ist der Rest beim Teilen durch 2: 0 bei geraden, 1 bei ungeraden Plaetzen. Jede zweite Fliege haengt eine Reihe tiefer. Seitlich liegen die Plaetze nur noch einen halben Abstand auseinander. So entsteht ein Zickzack: oben, unten, oben, unten, jede halb versetzt, wie zusammengedraengte Luftballons. Dazu kommt wie bisher der zufaellige Hoehenversatz.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Bilder in einer Kopie: Dreier-Spiess im Flug mit aufrechten Fliegen, Faden hinter ihnen. Faecher nach zehn Schuessen mit 14 Fliegen in zwei versetzten Reihen, rund 550 px breit, Spiess-Fliegen darunter am Seil.
- Nicht gemessen: wie es sich spielt.

### Drei Fragen zur Selbstkontrolle

1. Wo haengt die Fliege auf Platz 4 und wo die auf Platz 5?
2. Ab wie vielen Fliegen schrumpft der Faecher jetzt (`breite` 1152, `abstand` 90)?
3. Warum sieht der Faden durch die Fliege durchgezogen aus, obwohl nichts geteilt ist?

<details><summary>Antworten</summary>

1. 4 % 2 = 0, also oben. 5 % 2 = 1, also eine Reihe (90 px) tiefer. Seitlich 45 px auseinander.
2. Sobald Anzahl x 45 groesser als 1152 ist, also ab 26 Fliegen.
3. Der Faden liegt hinter der Fliege (`z_index` 0 gegen 1). Man sieht ihn bis zum Rand, dann das Loch, dann wieder ab dem anderen Rand.

</details>

## Spass-Test, Runde 13 - ab der Haelfte haeufigere und mittigere Hindernisse

Weil der Faecher jetzt mittiger und enger haengt, wichen die Hindernisse zu leicht aus. Die erste Haelfte bleibt mit Absicht entspannt. Ab 50 Flugkraft wird es gleitend schwerer bis 100.

### `skripte/hindernis_erzeuger.gd` - geaendert

```gdscript
@export var pause_kurz_oben: float = 4.0
@export var pause_lang_oben: float = 6.0
@export var anteil_mitte_oben: float = 0.9
```
Neu. Die Werte ganz oben bei 100 Flugkraft: Pause 4 bis 6 Sekunden statt 6 bis 10, und 9 von 10 Spalten im inneren Drittel statt 7 von 10.

```gdscript
func anteil_oben() -> float:
	var hoehe: float = -kanone.position.y
	return clampf((hoehe - hoehe_spitze) / (hoehe_ende - hoehe_spitze), 0.0, 1.0)
```
Neu, aus `warnzeit_hier` herausgezogen, weil jetzt drei Stellen sie brauchen. Unter der Haelfte (15000 px) kommt 0 heraus, bei 100 Flugkraft (30000 px) 1, dazwischen gleitend. `clampf` haelt die Zahl zwischen 0 und 1.

```gdscript
	if randf() < lerpf(anteil_mitte, anteil_mitte_oben, anteil_oben()):
```
Statt `randf() < anteil_mitte`. Unten 0.7, ab der Haelfte gleitend bis 0.9.

```gdscript
	var kurz: float = lerpf(pause_kurz, pause_kurz_oben, anteil_oben())
	var lang: float = lerpf(pause_lang, pause_lang_oben, anteil_oben())
	naechstes_in = randf_range(kurz, lang)
```
Statt `randf_range(pause_kurz, pause_lang)`. Die Grenzen der Pause gleiten ab der Haelfte von 6-10 auf 4-6 Sekunden.

```gdscript
	return lerpf(warnzeit_spitze, warnzeit_ende, anteil_oben())
```
In `warnzeit_hier`, dieselbe Rechnung wie vorher, nur ueber die neue Funktion. Die Warnzeit bleibt also: 6 s unten, 9 s bei der Haelfte, 5 s bei 100.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Probe mit je 2000 Hindernissen:

| Flugkraft | im inneren Drittel | Pause | Warnzeit |
|-----------|--------------------|-------|----------|
| 0 | 80 % | 6-10 s (Mittel 8) | 6 s |
| 25 | 78 % | 6-10 s | 7,5 s |
| 50 | 81 % | 6-10 s | 9 s |
| 75 | 86 % | 5-8 s (Mittel 6,5) | 7 s |
| 100 | 93 % | 4-6 s (Mittel 5) | 5 s |

(Ueber 70 % bzw. 90 %, weil auch die freien Wuerfe manchmal innen landen.) Wie schwer es sich anfuehlt, entscheidest du.

### Drei Fragen zur Selbstkontrolle

1. Was ist `anteil_oben()` bei 25 Flugkraft, und was bei 80?
2. Wie lang ist die Pause bei 75 Flugkraft hoechstens?
3. Warum ist `anteil_oben` eine eigene Funktion geworden?

<details><summary>Antworten</summary>

1. Bei 25: 7500 px, unter der Haelfte, also 0. Bei 80: (24000 - 15000) / 15000 = 0,6.
2. `lerpf(10, 6, 0.5)` = 8 Sekunden.
3. Pause, Anteil in der Mitte und Warnzeit brauchen dieselbe Zahl. In einer Funktion steht die Rechnung einmal, statt dreimal.

</details>

## Abschnitt 9 - Hoehenzonen und sechs Fliegenarten

Was neu ist, in einem Absatz: Es gibt jetzt sechs Arten von Fliegen. Jede Art hat ein eigenes kurzes Skript und eine eigene Szene. Am Boden schwirrt zum Start ein kleiner Schwarm aus allen Arten ausser dem Boss. Darueber gibt es fuenf Test-Zonen, die an der Hoehe der Kanone haengen, in jeder fliegt eine andere Art herein. Mit den Zifferntasten springt man zum Testen in eine Zone. Die Kanone faehrt ein Achtel schneller. Die Hindernisse sind unveraendert.

### Ein neuer Gedanke: `extends` mit einem eigenen Skript

Bisher stand in jedem Skript oben `extends Node2D`. Das heisst: "Dieses Skript ist ein Node2D und kann alles, was ein Node2D kann, dazu kommt, was hier steht."

Neu ist diese Zeile in den Skripten der Arten:

```gdscript
extends "res://skripte/fliege.gd"
```

Das heisst: "Dieses Skript ist eine Fliege und kann alles, was in `fliege.gd` steht, dazu kommt, was hier steht." Man nennt das Vererbung. In `fliege.gd` steht alles, was jede Fliege braucht: Tempo, Flugkraft, Groesse, gefangen sein, fliehen, summen. In `fliege_normal.gd`, `fliege_schnell.gd` und so weiter steht nur noch, wie diese eine Art fliegt.

Dazu gehoert ein zweiter Gedanke: ueberschreiben. In `fliege.gd` gibt es drei leere Funktionen (`losfliegen`, `fliegen`, `angeschossen`). Schreibt eine Art eine Funktion mit demselben Namen, dann gilt fuer diese Art ihre eigene Fassung. `fliege.gd` ruft `fliegen(delta)` auf, und je nach Art laeuft dann ein anderer Code.

Warum so: Vorher stand alles in einer `fliege.gd`, und der Erzeuger hat die Unterschiede von aussen eingestellt. Mit sechs Arten waere das ein langes Skript mit vielen "wenn Art gleich ..."-Stellen geworden. So ist jede Art fuer sich lesbar.

### `skripte/fliege.gd` - neu geschrieben (das Gemeinsame)

```gdscript
extends Node2D
```
Unveraendert. Die Fliege ist ein Node2D.

```gdscript
@export var tempo_langsam: float = 100.0
@export var tempo_schnell: float = 180.0
```
Neu. Zwischen diesen beiden Werten wuerfelt jede Fliege ihr Tempo. Vorher standen die Werte im Erzeuger. Jetzt stehen sie an der Art selbst, im Inspector der jeweiligen Szene (die schnelle hat dort 400 und 720).

```gdscript
@export var flugkraft: int = 2
@export var halbe_groesse: float = 50.0
```
Unveraendert.

```gdscript
@export var leben: int = 1
```
Neu. Wie oft man die Fliege treffen muss. Bei allen 1, nur in der Szene des Bosses steht 3.

```gdscript
@export var flieht: bool = true
```
Neu. Der Erzeuger laesst Fliegen fliehen, die zu tief oder zu hoch im Bild sind. Der Boss steigt absichtlich nach oben, bei ihm steht darum `false`.

```gdscript
@export var tonhoehe_tief: float = 0.8
@export var tonhoehe_hoch: float = 1.4
```
Unveraendert.

```gdscript
var tempo: float = 0.0
```
Geaendert: war ein `@export`, ist jetzt eine normale Variable. Sie wird beim Start ausgewuerfelt.

```gdscript
var kanone: Node2D = null
```
Neu. Die scheue und die Koeder-Fliege muessen wissen, wo die Kanone ist. Der Erzeuger traegt sie ein.

```gdscript
var mitte_x: float = 0.0
var richtung: float = 1.0
var gefangen: bool = false
```
Unveraendert.

```gdscript
var flucht: Vector2 = Vector2.ZERO
```
Geaendert: war eine Zahl (1 oder -1), ist jetzt ein `Vector2`, also eine Richtung mit x und y. So kann eine Fliege auch nach oben fliehen. `Vector2.ZERO` ist (0, 0) und heisst: Sie flieht nicht.

```gdscript
var grund_y: float = 0.0
var zeit: float = 0.0
```
Unveraendert.

```gdscript
var steckende: Array[Node2D] = []
```
Neu. Eine Liste der Nadeln, die im Boss stecken, solange er noch nicht gefangen ist. Bei allen anderen bleibt sie leer.

```gdscript
func _ready() -> void:
	tempo = randf_range(tempo_langsam, tempo_schnell)
	grund_y = position.y
	if mitte_x < position.x:
		richtung = -1.0
	$Summen.pitch_scale = randf_range(tonhoehe_tief, tonhoehe_hoch)
	losfliegen()
```
`_ready` laeuft einmal, wenn die Fliege ins Spiel kommt. Neu sind drei Dinge: Das Tempo wird ausgewuerfelt. Liegt die Mitte links von der Fliege, fliegt sie zuerst nach links (sie kommt ja von rechts herein). Und am Ende wird `losfliegen()` aufgerufen, damit eine Art dort ihre eigenen Startwerte setzen kann.

```gdscript
func _process(delta: float) -> void:
	if gefangen:
		return
	zeit += delta
	if flucht != Vector2.ZERO:
		position += flucht * tempo * delta
		return
	fliegen(delta)
```
Laeuft in jedem Bild. Gefangen: nichts tun. Sonst die Zeit weiterzaehlen. Flieht die Fliege, geht sie in ihrer Fluchtrichtung mit ihrem Tempo weiter (`flucht` ist (1, 0), (-1, 0) oder (0, -1), mal Tempo mal Zeit ergibt die Strecke). Sonst fliegt sie so, wie ihre Art es in `fliegen` festlegt. Ein Unterschied zu vorher: Eine fliehende Fliege dreht und wippt nicht mehr, sie fliegt gerade hinaus. Das Drehen und Wippen steht jetzt in `fliegen` der normalen Fliege, und `fliegen` wird bei der Flucht nicht aufgerufen.

```gdscript
func losfliegen() -> void:
	pass

func fliegen(_delta: float) -> void:
	pass

func angeschossen() -> void:
	pass
```
Die drei leeren Funktionen. `pass` heisst: nichts tun. Sie stehen hier, damit `fliege.gd` sie aufrufen kann, auch wenn eine Art sie nicht ueberschreibt. Der Unterstrich vor `_delta` sagt Godot: Der Wert wird hier absichtlich nicht benutzt.

Weggefallen sind `strecke`, `drehtempo`, `wipp_hoehe`, `wipp_tempo` und das Hin-und-her-Fliegen. Das steht jetzt in `fliege_normal.gd`.

### `skripte/fliege_normal.gd` - neu

```gdscript
extends "res://skripte/fliege.gd"
```
Die normale Fliege ist eine Fliege, siehe oben.

```gdscript
@export var strecke: float = 300.0
@export var drehtempo: float = 6.28
@export var wipp_hoehe: float = 50.0
@export var wipp_tempo: float = 4.0
```
Wie bisher, nur stehen die Werte jetzt hier statt im Erzeuger. 6.28 ist eine ganze Umdrehung pro Sekunde (2 mal Pi). Das Wippen ist doppelt so stark wie vorher (50 statt 25 px).

```gdscript
@export var langsam_anteil: float = 0.5
@export var tempo_wechsel: float = 1.5
```
Neu. Die Fliege wird zwischendurch langsamer, hoechstens bis auf die Haelfte ihres Tempos. `tempo_wechsel` sagt, wie schnell das schwankt.

```gdscript
func fliegen(delta: float) -> void:
	rotation += drehtempo * delta
	position.y = grund_y + sin(zeit * wipp_tempo) * wipp_hoehe
```
Drehen und Wippen wie bisher. `sin` schwingt gleichmaessig zwischen -1 und 1, mal 50 ergibt 50 px hoch und 50 px runter.

```gdscript
	var welle: float = (sin(zeit * tempo_wechsel) + 1.0) / 2.0
```
Neu. `sin` liefert -1 bis 1. Plus 1 ergibt 0 bis 2, geteilt durch 2 ergibt 0 bis 1. `welle` wandert also langsam zwischen 0 und 1 hin und her.

```gdscript
	var jetzt: float = tempo * lerpf(langsam_anteil, 1.0, welle)
```
`lerpf(a, b, t)` liefert einen Wert zwischen a und b: bei t = 0 genau a, bei t = 1 genau b. Hier: zwischen 0.5 und 1. Das Tempo in diesem Bild liegt also zwischen dem halben und dem vollen Tempo.

```gdscript
	position.x += richtung * jetzt * delta
	if position.x > mitte_x + strecke:
		richtung = -1.0
	if position.x < mitte_x - strecke:
		richtung = 1.0
```
Wie bisher: seitlich fliegen und am Ende der Strecke umdrehen.

### `skripte/fliege_schnell.gd` - neu

Die schnelle Fliege fliegt gerade und immer gleich schnell. Am Ende der Strecke fliegt sie eine Schleife, wie eine halbe liegende Acht, und kommt auf derselben Linie zurueck.

Der Trick: Die Fliege merkt sich einen Winkel, in den sie fliegt. In jedem Bild geht sie ein Stueck in diese Richtung, immer gleich weit. Zum Wenden wird nur der Winkel gedreht. Darum bleibt das Tempo von selbst gleich.

```gdscript
@export var strecke: float = 300.0
@export var schleife: float = 60.0
```
Wie weit sie fliegt, bevor sie wendet, und der Radius des Kreises in der Schleife.

```gdscript
const ERSTES_STUECK: float = PI / 3.0
const WENDE_GANZ: float = TAU + PI / 3.0
```
`const` ist ein fester Wert, der sich nie aendert. `PI` ist ein halber Kreis im Bogenmass, `TAU` ein ganzer. `PI / 3` ist ein Sechstel Kreis (60 Grad). Die Schleife besteht aus drei Stuecken: ein Sechstel Kreis nach oben lenken, fuenf Sechstel Kreis nach unten herum, ein Sechstel wieder nach oben. Zusammen sieben Sechstel, das ist `TAU + PI / 3`. Mit genau diesen Winkeln landet sie wieder auf ihrer Linie (ausgerechnet, und in der Probe gemessen: 4,5 px daneben, den Rest rastet die Zeile `position.y = grund_y` ein).

```gdscript
var winkel: float = 0.0
var wendet: bool = false
var gelenkt: float = 0.0
```
Die Flugrichtung als Winkel (0 ist rechts, `PI` ist links), ob sie gerade wendet, und wie viel von der Schleife sie schon gelenkt hat.

```gdscript
func losfliegen() -> void:
	if richtung < 0.0:
		winkel = PI
```
Ueberschreibt die leere Funktion aus `fliege.gd`. Fliegt sie zuerst nach links, zeigt der Winkel nach links.

```gdscript
func fliegen(delta: float) -> void:
	position += Vector2.from_angle(winkel) * tempo * delta
```
`Vector2.from_angle(winkel)` macht aus einem Winkel eine Richtung mit der Laenge 1. Mal Tempo mal Zeit ist der Schritt in diesem Bild. Das ist die einzige Zeile, die die Fliege bewegt, darum ist sie immer gleich schnell.

```gdscript
	if not wendet:
		var rechts_draussen: bool = richtung > 0.0 and position.x > mitte_x + strecke
		var links_draussen: bool = richtung < 0.0 and position.x < mitte_x - strecke
		if rechts_draussen or links_draussen:
			wendet = true
			gelenkt = 0.0
		return
```
Solange sie geradeaus fliegt: Ist sie ueber das Ende der Strecke hinaus, beginnt die Wende. `return` beendet die Funktion fuer dieses Bild.

```gdscript
	var schritt: float = tempo / schleife * delta
	gelenkt += schritt
```
Wie viel sie in diesem Bild lenkt. Auf einem Kreis gilt: Winkel pro Sekunde = Tempo geteilt durch Radius. Ein kleiner Radius heisst enge Kurve.

```gdscript
	if gelenkt < ERSTES_STUECK or gelenkt > TAU:
		winkel -= schritt * richtung
	else:
		winkel += schritt * richtung
```
Im ersten und im letzten Stueck lenkt sie nach oben, dazwischen nach unten herum. In Godot zeigt y nach unten, darum heisst "Winkel kleiner" bei einer Fliege nach rechts: nach oben. `* richtung` spiegelt das fuer die Fliege, die nach links fliegt.

```gdscript
	rotation = richtung * TAU * gelenkt / WENDE_GANZ
```
Sie dreht sich waehrend der Wende einmal ganz um sich selbst. `gelenkt / WENDE_GANZ` geht von 0 bis 1, mal `TAU` ist eine volle Umdrehung. Am Ende steht sie wieder aufrecht.

```gdscript
	if gelenkt >= WENDE_GANZ:
		wendet = false
		richtung = -richtung
		rotation = 0.0
		position.y = grund_y
		winkel = 0.0
		if richtung < 0.0:
			winkel = PI
```
Wende fertig: Richtung umkehren, aufrecht stellen, genau auf die Linie setzen und den Winkel genau nach rechts oder links stellen. So sammeln sich keine kleinen Rechenfehler an.

### `skripte/fliege_scheu.gd` - neu

Die scheue Fliege will immer einen bestimmten Abstand zur Kanone haben. Faehrt die Kanone auf sie zu, weicht sie zurueck. Sie ist langsamer als die Kanone (190 bis 230 gegen 281), man holt sie also ein.

```gdscript
@export var abstand_nah: float = 200.0
@export var abstand_weit: float = 450.0
@export var wipp_hoehe: float = 15.0
@export var wipp_tempo: float = 6.0
var abstand: float = 0.0
```
Jede Fliege wuerfelt ihren Wunschabstand zwischen 200 und 450 px. Sonst staenden alle scheuen Fliegen genau uebereinander.

```gdscript
func losfliegen() -> void:
	abstand = randf_range(abstand_nah, abstand_weit)
```
Einmal am Start auswuerfeln.

```gdscript
func fliegen(delta: float) -> void:
	position.y = grund_y + sin(zeit * wipp_tempo) * wipp_hoehe
```
Leichtes, schnelles Wippen.

```gdscript
	var seite: float = 1.0
	if position.x < kanone.position.x:
		seite = -1.0
```
Auf welcher Seite der Kanone ist die Fliege? 1 heisst rechts, -1 links.

```gdscript
	var wunsch_x: float = kanone.position.x + seite * abstand
	position.x = move_toward(position.x, wunsch_x, tempo * delta)
```
Ihr Wunschplatz liegt auf ihrer Seite, `abstand` Pixel neben der Kanone. `move_toward(von, nach, schritt)` geht von einem Wert auf einen anderen zu, aber hoechstens `schritt` weit. Die Fliege geht also mit ihrem Tempo auf den Wunschplatz zu. Faehrt die Kanone naeher, wandert der Wunschplatz weg, und die Fliege hinterher. Faehrt die Kanone unter ihr durch, wechselt die Seite, und sie weicht in die andere Richtung aus.

### `skripte/fliege_koeder.gd` - neu

Die Koeder-Fliege pendelt auf kleinem Raum. Wird ein Hindernis angekuendigt, schwingt sie im Bogen unter die Warnung und zappelt dort. Wer sie will, muss mit dem Faecher unter die Warnung. Kurz bevor der Klotz faellt, weicht sie zur Seite aus.

```gdscript
@export var pendelweite: float = 144.0
@export var pendelweite_warnung: float = 100.0
@export var hoehen: float = 40.0
@export var faktor_warnung: float = 3.0
@export var tempo_eilig: float = 900.0
@export var bogen: float = 80.0
@export var ausweich_zeit: float = 0.25
@export var ausweich_weite: float = 230.0
@export var sichtweite: float = 720.0
```
Die Werte, alle im Inspector aenderbar. Die Kommentare im Skript sagen, was jeder ist. Wichtig: 144 ist ein Zehntel der Bildbreite. 230 ist so gewaehlt, dass sie knapp neben dem Klotz landet (halbe Spalte 100, halbe Fliege 50, halbes Pendeln 72: 230 - 72 = 158, das sind 8 px Luft).

```gdscript
var ziel: Vector2 = Vector2.ZERO
var seite: float = 1.0
var unter_warnung: bool = false
var schwingt: bool = false
var schwung_von_x: float = 0.0
var schwung_von_y: float = 0.0
```
Der Punkt, zu dem sie gerade pendelt, auf welcher Seite der liegt, ob sie unter einer Warnung ist, ob sie gerade im Bogen schwingt, und wo der Schwung angefangen hat.

```gdscript
func losfliegen() -> void:
	neues_ziel()
```
Am Start den ersten Pendelpunkt bestimmen.

```gdscript
func fliegen(delta: float) -> void:
	nach_warnung_sehen()
	if schwingt:
		schwingen(delta)
		return
```
In jedem Bild zuerst nachsehen, ob es eine Warnung gibt. Schwingt sie gerade, macht `schwingen` die Bewegung.

```gdscript
	var jetzt: float = tempo
	if unter_warnung:
		jetzt = tempo * faktor_warnung
	position = position.move_toward(ziel, jetzt * delta)
```
Sonst pendelt sie: auf den Punkt `ziel` zu, unter einer Warnung dreimal so schnell. `position.move_toward(ziel, schritt)` ist dasselbe wie `move_toward` oben, nur fuer einen Punkt mit x und y.

```gdscript
	if position == ziel:
		seite = -seite
		neues_ziel()
```
Angekommen: die Seite wechseln und den naechsten Punkt bestimmen. `==` klappt hier, weil `move_toward` am Ende genau auf dem Ziel landet.

```gdscript
func nach_warnung_sehen() -> void:
	var warnung: Node2D = warnung_im_bild()
	if warnung == null:
		unter_warnung = false
		return
```
Gibt es keine Warnung, ist nichts zu tun.

```gdscript
	var wohin: float = warnung.position.x
	var rest: float = warnung.warnzeit - warnung.gewarnt
	unter_warnung = rest >= ausweich_zeit
```
`wohin` ist die Mitte der Spalte. `rest` ist, wie lange die Warnung noch laeuft (beide Werte stehen in `hindernis.gd`). Solange noch mindestens 0,25 s uebrig sind, bleibt sie darunter.

```gdscript
	if not unter_warnung:
		if position.x < warnung.position.x:
			wohin -= ausweich_weite
		else:
			wohin += ausweich_weite
```
In den letzten 0,25 s weicht sie aus: 230 px neben die Mitte, auf die Seite, auf der sie gerade ist.

```gdscript
	if absf(wohin - mitte_x) > 1.0:
		mitte_x = wohin
		schwingt = true
		schwung_von_x = position.x
		schwung_von_y = position.y
```
Liegt das neue Ziel woanders als ihre jetzige Mitte, beginnt ein Schwung dorthin. `absf` ist der Betrag (ohne Vorzeichen). Der Vergleich mit 1 statt mit 0 verhindert, dass winzige Rechenunterschiede einen neuen Schwung ausloesen.

```gdscript
func warnung_im_bild() -> Node2D:
	for hindernis in get_tree().get_nodes_in_group("hindernisse"):
		var warnt_noch: bool = hindernis.gewarnt < hindernis.warnzeit
		var seitlich: float = absf(hindernis.position.x - kanone.position.x)
		if warnt_noch and seitlich <= sichtweite:
			return hindernis
	return null
```
Geht alle Hindernisse durch (sie sind jetzt in der Gruppe `hindernisse`, siehe Szene). Das erste, das noch warnt und im Bild liegt (hoechstens 720 px neben der Kanone), wird zurueckgegeben. Gibt es keins: `null`.

```gdscript
func schwingen(delta: float) -> void:
	position.x = move_toward(position.x, mitte_x, tempo_eilig * delta)
	if position.x == mitte_x:
		schwingt = false
		position.y = schwung_von_y
		neues_ziel()
		return
```
Seitlich mit 900 px/s auf die neue Mitte zu. Angekommen: Schwung vorbei, zurueck auf die Hoehe vom Anfang, neuen Pendelpunkt bestimmen.

```gdscript
	var anteil: float = (position.x - schwung_von_x) / (mitte_x - schwung_von_x)
	position.y = schwung_von_y + sin(anteil * PI) * bogen
```
Der Bogen. `anteil` ist, wie viel vom Weg geschafft ist: 0 am Anfang, 1 am Ziel. `sin(anteil * PI)` ist am Anfang 0, in der Mitte 1 und am Ende wieder 0. Mal 80 heisst: In der Mitte des Wegs haengt sie 80 px tiefer, wie ein Pendel. (Geteilt wird nie durch 0, weil ein Schwung nur beginnt, wenn Ziel und Start mehr als 1 px auseinander liegen.)

```gdscript
func neues_ziel() -> void:
	var weite: float = pendelweite
	if unter_warnung:
		weite = pendelweite_warnung
	ziel = Vector2(mitte_x + seite * weite / 2.0, grund_y + randf_range(-hoehen, hoehen))
```
Der naechste Pendelpunkt: eine halbe Pendelweite links oder rechts der Mitte, und in der Hoehe zufaellig bis zu 40 px ueber oder unter der Grundhoehe. So fliegt sie mal etwas hoeher, mal etwas tiefer.

### `skripte/fliege_teleport.gd` - neu

```gdscript
@export var strecke: float = 150.0
@export var pause_kurz: float = 1.5
@export var pause_lang: float = 3.0
@export var flacker_zeit: float = 0.3
@export var flacker_takt: float = 0.1
@export var flacker_blass: float = 0.25
@export var sprung_nah: float = 150.0
@export var sprung_weit: float = 300.0
var sprung_in: float = 0.0
```
Die Werte: Strecke, Pause zwischen zwei Spruengen, wie lange und wie schnell sie vorher flackert, wie blass sie dabei wird, und wie weit sie springt. `sprung_in` zaehlt die Sekunden bis zum naechsten Sprung herunter.

```gdscript
func losfliegen() -> void:
	sprung_in = randf_range(pause_kurz, pause_lang)
```
Die erste Pause auswuerfeln.

```gdscript
func fliegen(delta: float) -> void:
	position.x += richtung * tempo * delta
	if position.x > mitte_x + strecke:
		richtung = -1.0
	if position.x < mitte_x - strecke:
		richtung = 1.0
```
Hin und her wie die Fliege aus Abschnitt 3.

```gdscript
	sprung_in -= delta
	modulate.a = 1.0
	if sprung_in < flacker_zeit and fmod(sprung_in, flacker_takt) < flacker_takt / 2.0:
		modulate.a = flacker_blass
```
Herunterzaehlen. `modulate.a` ist die Deckkraft: 1 ist voll sichtbar. In den letzten 0,3 s flackert sie: `fmod` ist der Rest beim Teilen, hier laeuft er immer wieder von 0 bis 0,1. In der ersten Haelfte davon ist sie blass, in der zweiten voll. Das ist die Ankuendigung: Wer das Flackern sieht, weiss, dass sie gleich springt.

```gdscript
	if sprung_in <= 0.0:
		springen()

func springen() -> void:
	var weit: float = randf_range(sprung_nah, sprung_weit)
	if randf() < 0.5:
		weit = -weit
	position.x += weit
	mitte_x += weit
	modulate.a = 1.0
	sprung_in = randf_range(pause_kurz, pause_lang)
```
Der Sprung: 150 bis 300 px, in der Haelfte der Faelle nach links. Auch die Mitte springt mit, damit sie um die neue Stelle weiterfliegt. Danach wieder voll sichtbar, und die naechste Pause wird ausgewuerfelt.

### `skripte/fliege_boss.gd` - neu

```gdscript
@export var steigtempo: float = 75.0
@export var wipp_hoehe: float = 20.0
@export var wipp_tempo: float = 2.0
@export var absacken: float = 200.0
@export var sacktempo: float = 600.0
var sack_rest: float = 0.0
```
Wie schnell er steigt, wie er wippt, wie weit er bei einem Treffer absackt und wie schnell. `sack_rest` ist, wie viele Pixel er noch absacken muss. Dass er 3 Treffer braucht, 15 Flugkraft gibt und 300 x 300 gross ist, steht im Inspector der Szene (`leben`, `flugkraft`, `halbe_groesse` aus `fliege.gd`).

```gdscript
func fliegen(delta: float) -> void:
	position.x += richtung * tempo * delta
	grund_y -= steigtempo * delta
```
Er fliegt seitlich durch und seine Grundhoehe steigt dabei (kleineres y ist weiter oben).

```gdscript
	var stueck: float = minf(sack_rest, sacktempo * delta)
	sack_rest -= stueck
	grund_y += stueck
```
Das Absacken, auf mehrere Bilder verteilt, damit er nicht springt. `minf` nimmt den kleineren Wert: In jedem Bild sinkt er hoechstens `sacktempo * delta`, aber nie mehr, als noch uebrig ist.

```gdscript
	position.y = grund_y + sin(zeit * wipp_tempo) * wipp_hoehe
```
Leichtes, langsames Wippen um die Grundhoehe.

```gdscript
func angeschossen() -> void:
	sack_rest += absacken
```
Ueberschreibt die leere Funktion aus `fliege.gd`. Die Nadel ruft sie bei einem Treffer auf, dann sackt er 200 px ab.

### `skripte/nadel.gd` - geaendert (Boss)

```gdscript
	if getroffene != null:
		if getroffene.leben > 1:
			stecken_in(getroffene)
			return
		aufspiessen(getroffene)
```
In `_process`. Neu sind die drei mittleren Zeilen. Braucht die getroffene Fliege noch mehr als einen Treffer, bleibt die Nadel nur in ihr stecken. Beim letzten noetigen Treffer (`leben` ist 1) wird sie wie jede Fliege aufgespiesst und gefangen.

```gdscript
	if kandidat.leben > 1 and not aufgespiesste.is_empty():
		return false
```
In `trifft`. Eine Nadel, die schon Fliegen traegt, trifft den Boss nicht. Sonst haette man einen Spiess, der im Boss steckt und trotzdem schon gefangene Fliegen traegt.

```gdscript
	getroffene.modulate.a = 1.0
```
In `aufspiessen`. Eine Teleport-Fliege kann im Moment des Treffers gerade blass sein. Gefangen soll sie voll sichtbar sein.

```gdscript
	for alte in getroffene.steckende:
		alte.faden_loesen()
```
In `aufspiessen`. Wird der Boss gefangen, loesen sich die Faeden der Nadeln, die schon in ihm steckten. Nur die letzte Nadel haelt ihn.

```gdscript
func stecken_in(grosse: Node2D) -> void:
	steckt = true
	grosse.leben -= 1
	grosse.steckende.append(self)
	grosse.angeschossen()
	$TonTreffer.play()
	var fleck: Node2D = blutfleck_szene.instantiate()
	get_parent().add_child(fleck)
	fleck.global_position = global_position
	reparent(grosse)
```
Neu. Die Nadel fliegt nicht mehr (`steckt`). Der Boss verliert ein Leben, merkt sich die Nadel in seiner Liste und sackt ab. Treffer-Ton und Blutfleck wie bei jedem Treffer. `reparent(grosse)` macht die Nadel zum Kind des Bosses, sie bewegt sich ab jetzt mit ihm. `self` ist die Nadel selbst. Der Faden bleibt an der Muendung, weil `_process` fuer eine steckende Nadel weiter `faden_spannen` aufruft. Fliegt der Boss aus dem Bild, loescht ihn der Erzeuger, und mit ihm seine Kinder, also auch die Nadeln und Faeden.

```gdscript
func faden_loesen() -> void:
	anker = null
	$Faden.clear_points()
```
Neu. Ohne Anker spannt `faden_spannen` nichts mehr, und `clear_points` loescht die Linie.

### `skripte/zone.gd` - neu

```gdscript
extends Node

@export var ab_flugkraft: float = 0.0
@export var fliegen: Array[PackedScene] = []
@export var mindestens: int = 4
@export var farbe: Color = Color.WHITE
```
Dieses Skript rechnet nichts. Es gibt einem Knoten vier Felder im Inspector: ab welcher Hoehe (in Flugkraft) die Zone beginnt, welche Fliegen-Szenen dort hereinfliegen, wie viele freie Fliegen mindestens da sein sollen, und die Farbe des Hintergrunds. `Array[PackedScene]` ist eine Liste von Szenen. Steht eine Szene zweimal in der Liste, wird sie doppelt so oft ausgewuerfelt.

### `skripte/zonen.gd` - neu

```gdscript
extends Node

@export var kanone: Node2D
@export var hintergrund: Node2D
@export var anzeige: Label
```
Der Knoten `Zonen` kennt die Kanone, den Hintergrund und das Schild oben links. Seine Kinder sind die Zonen, von unten nach oben.

```gdscript
func _process(_delta: float) -> void:
	var zone: Node = aktuelle()
	hintergrund.modulate = zone.farbe
	anzeige.text = "Zone: " + str(zone.name)
```
In jedem Bild: die aktuelle Zone holen, den Hintergrund in ihrer Farbe toenen (`modulate` multipliziert die Farbe von allem, was darunter haengt) und ihren Namen auf das Schild schreiben. `zone.name` ist der Name des Knotens, `str` macht daraus Text.

```gdscript
func aktuelle() -> Node:
	var hoehe: float = -kanone.position.y / get_parent().hoehe_je_flugkraft
	var gefunden: Node = get_child(0)
	for zone in get_children():
		if hoehe >= zone.ab_flugkraft:
			gefunden = zone
	return gefunden
```
Die Hoehe der Kanone in Flugkraft: y ist nach oben negativ, darum das Minus, geteilt durch 300 (`hoehe_je_flugkraft` steht in `spiel.gd`, `get_parent()` ist der Knoten `Spiel`). Dann alle Zonen von unten nach oben durchgehen. Jede, deren Anfang schon erreicht ist, ersetzt die vorige. Uebrig bleibt die hoechste erreichte Zone. Weil die Zone an der Hoehe haengt und nicht am Zaehler, wechselt sie beim Absturz erst, wenn man wirklich unten ist.

### `skripte/erzeuger.gd` - neu geschrieben

Weggefallen: `fliege_szene`, `tempo_langsam`, `tempo_schnell`, `anteil_schnell`, `flugkraft_normal`, `flugkraft_schnell`, `faktor_schnell`, `drehungen_normal`, `wippen_normal`, `mindestens`. Diese Werte stehen jetzt an den Arten und an den Zonen.

```gdscript
@export var kanone: Node2D
@export var zonen: Node
@export var schwarm_szenen: Array[PackedScene] = []
@export var schwarm_breite: float = 500.0
@export var breite: float = 400.0
```
Neu sind `zonen` (der Knoten mit den Zonen), `schwarm_szenen` (die fuenf Arten fuer den Schwarm am Boden) und `schwarm_breite`.

```gdscript
@export var naehe: float = 1000.0
@export var einflug_x: float = 900.0
@export var einflug_oben: float = 750.0
@export var einflug_unten: float = 560.0
@export var flucht_unten: float = 520.0
@export var flucht_oben: float = 790.0
```
Unveraendert.

```gdscript
@export var rand_seitlich: float = 847.0
@export var rand_oben: float = 1082.0
```
Neu. Wie weit der Bildrand am Boden von der Kanone weg ist (dort ist herausgezoomt). Daran misst der Schwarm, welcher Rand am naechsten ist.

```gdscript
@export var loeschen_seitlich: float = 1100.0
@export var loeschen_unten: float = 300.0
@export var loeschen_oben: float = 1400.0
```
`loeschen_oben` ist neu: Fliegen, die nach oben geflohen sind, und der entkommene Boss werden 1400 px ueber der Kanone geloescht.

```gdscript
var schwarm: bool = true
```
Neu. Solange der Schwarm vom Anfang da ist, fliegt nichts nach.

```gdscript
func _ready() -> void:
	for szene in schwarm_szenen:
		for nummer in randi_range(1, 2):
			var fliege: Node2D = szene.instantiate()
			fliege.kanone = kanone
			fliege.position.x = kanone.position.x + randf_range(-schwarm_breite, schwarm_breite)
			fliege.position.y = kanone.position.y - randf_range(einflug_unten, einflug_oben)
			fliege.mitte_x = fliege.position.x
			add_child(fliege)
```
Der Schwarm. Zwei Schleifen ineinander: Die aeussere geht die fuenf Szenen durch. Die innere laeuft einmal oder zweimal (`randi_range(1, 2)` wuerfelt 1 oder 2, `for nummer in 2` laeuft zweimal). Jede Fliege bekommt die Kanone, einen zufaelligen Platz bis 500 px neben der Kanone und 560 bis 750 px ueber ihr, und ihre Mitte ist dort, wo sie startet. Es sind also 5 bis 10 Fliegen.

```gdscript
func _process(_delta: float) -> void:
	aufraeumen()
	if schwarm:
		if get_child_count() == 0:
			schwarm = false
		return
	fliehen_lassen()
	if kanone.steigt:
		return
	var zone: Node = zonen.aktuelle()
	if freie_in_der_naehe() < zone.mindestens:
		hereinfliegen(zone)
```
Solange der Schwarm da ist, wird nur aufgeraeumt. Ist keine Fliege mehr uebrig (zum Beispiel alle zermatscht), endet der Schwarm von selbst, sonst gaebe es nie wieder Fliegen. Danach wie bisher, mit zwei Aenderungen: Waehrend die Kanone steigt, fliegt nichts herein (vorher entstand in jedem Bild des Steigens eine Fliege, die sofort wieder floh). Und wie viele Fliegen da sein sollen und welche kommen, sagt die aktuelle Zone.

```gdscript
func schwarm_aufloesen(_dazu: int) -> void:
	if not schwarm:
		return
	schwarm = false
	for fliege in get_children():
		var nach_links: float = fliege.position.x - (kanone.position.x - rand_seitlich)
		var nach_rechts: float = (kanone.position.x + rand_seitlich) - fliege.position.x
		var nach_oben: float = fliege.position.y - (kanone.position.y - rand_oben)
		if nach_oben < nach_links and nach_oben < nach_rechts:
			fliege.flucht = Vector2.UP
		elif nach_links < nach_rechts:
			fliege.flucht = Vector2.LEFT
		else:
			fliege.flucht = Vector2.RIGHT
```
Wird beim ersten Fang aufgerufen. Das Signal `gefangen` der Uebergabe schickt die Flugkraft mit, die hier nicht gebraucht wird, darum `_dazu`. Fuer jede Fliege werden drei Strecken ausgerechnet: bis zum linken, zum rechten und zum oberen Bildrand. Sie flieht zum naechsten. `Vector2.UP` ist (0, -1), `LEFT` ist (-1, 0), `RIGHT` ist (1, 0). `elif` heisst "sonst, wenn".

```gdscript
func hereinfliegen(zone: Node) -> void:
	var seite: float = 1.0
	if randf() < 0.5:
		seite = -1.0
	var szene: PackedScene = zone.fliegen.pick_random()
	var fliege: Node2D = szene.instantiate()
	fliege.kanone = kanone
	fliege.position.x = kanone.position.x + seite * einflug_x
	fliege.position.y = kanone.position.y - randf_range(einflug_unten, einflug_oben)
	fliege.mitte_x = kanone.position.x + randf_range(-breite, breite)
	add_child(fliege)
```
Wie bisher, aber die Szene kommt aus der Liste der Zone: `pick_random()` nimmt zufaellig einen Eintrag. Tempo und Flugkraft setzt der Erzeuger nicht mehr, die bringt die Art selbst mit.

```gdscript
func fliehen_lassen() -> void:
	for fliege in get_children():
		if fliege.flucht != Vector2.ZERO or not fliege.flieht:
			continue
		var ueber: float = kanone.position.y - fliege.grund_y
		if ueber < flucht_unten or ueber > flucht_oben:
			if fliege.position.x < kanone.position.x:
				fliege.flucht = Vector2.LEFT
			else:
				fliege.flucht = Vector2.RIGHT
```
Drei Aenderungen: Arten mit `flieht = false` (der Boss) werden uebersprungen. Gemessen wird die Grundhoehe `grund_y` statt der Position, sonst wuerde das staerkere Wippen oder die Schleife eine Fliege aus dem ruhigen Band tragen und sie floehe grundlos. Und die Flucht ist jetzt eine Richtung (`Vector2.LEFT`) statt einer Zahl.

```gdscript
func freie_in_der_naehe() -> int:
	...
		if fliege.flucht == Vector2.ZERO and seitlich <= naehe:
```
Nur der Vergleich hat sich geaendert (`Vector2.ZERO` statt `0.0`).

```gdscript
func aufraeumen() -> void:
	for fliege in get_children():
		var zu_tief: bool = fliege.position.y > kanone.position.y + loeschen_unten
		var zu_hoch: bool = fliege.position.y < kanone.position.y - loeschen_oben
		var zu_weit: bool = absf(fliege.position.x - kanone.position.x) > loeschen_seitlich
		if zu_tief or zu_hoch or zu_weit:
			fliege.queue_free()
```
Neu ist `zu_hoch`.

### `skripte/spiel.gd` - geaendert

```gdscript
	$Kanone/Uebergabe.gefangen.connect($Erzeuger.schwarm_aufloesen)
```
In `_ready`. Dasselbe Signal, das die Flugkraft zaehlt, loest jetzt auch den Schwarm auf. Ein Signal kann mit mehreren Funktionen verbunden sein.

```gdscript
func springen(auf: int) -> void:
	flugkraft = auf
	$Erzeuger.schwarm_aufloesen(0)
	fliege_zaehlen(0)
```
Neu, nur zum Testen. Setzt den Zaehler auf einen Wert, loest den Schwarm auf und ruft `fliege_zaehlen(0)` auf: "0 dazu". Diese Funktion faehrt die Kanone schon auf die Hoehe, die zum Zaehler passt, und stellt die Kamera auf Luft. So muss das hier nicht noch einmal geschrieben werden. Achtung: Der Faecher bleibt dabei, wie er ist. Der Zaehler stimmt nach einem Sprung also nicht mit den haengenden Fliegen ueberein. Und Taste 1 (Sprung auf 0) zeigt die Kamera der Luft, nicht die des Bodens. Den echten Start am Boden gibt Taste 0.

### `skripte/test_sprung.gd` - neu (kommt vor der Abgabe wieder heraus)

```gdscript
extends Node

@export var zonen: Node
```
Der Knoten mit den Zonen.

```gdscript
func _unhandled_key_input(taste: InputEvent) -> void:
```
Diese Funktion ruft Godot bei jedem Tastendruck auf, den sonst niemand verbraucht hat. `taste` beschreibt den Tastendruck.

```gdscript
	if not taste.pressed or taste.echo:
		return
```
Nur das Herunterdruecken zaehlt, nicht das Loslassen. `echo` ist die Wiederholung, wenn man eine Taste haelt.

```gdscript
	if taste.keycode == KEY_0:
		get_tree().reload_current_scene()
		return
```
Die 0 laedt die Szene neu, man steht wieder am Boden mit einem neuen Schwarm.

```gdscript
	var nummer: int = taste.keycode - KEY_1
	if nummer >= 0 and nummer < zonen.get_child_count():
		var zone: Node = zonen.get_child(nummer)
		get_parent().springen(int(zone.ab_flugkraft))
```
Jede Taste hat eine Nummer (`keycode`), und die Ziffern liegen hintereinander. Taste 1 minus `KEY_1` ist 0, Taste 2 ergibt 1 und so weiter. Gibt es eine Zone mit dieser Nummer, springt das Spiel an ihren Anfang. `int(...)` macht aus der Kommazahl eine ganze Zahl. Kommt eine sechste Zone dazu, geht die Taste 6 von selbst.

### `skripte/kanone.gd` - geaendert

```gdscript
@export var tempo: float = 281.0
```
250 -> 281, ein Achtel schneller (250 x 1,125 = 281,25).

### Szenen - geaendert

- `szenen/fliege.tscn` heisst jetzt `szenen/fliege_normal.tscn`. Dazu fuenf neue: `fliege_schnell.tscn`, `fliege_scheu.tscn`, `fliege_koeder.tscn`, `fliege_teleport.tscn`, `fliege_boss.tscn`. Alle sind gleich gebaut: `Fluegel`, `Koerper`, `Summen`, `Loch`, dazu neu ein `Label` namens `Art` mit einem Buchstaben (N, S, SCH, K, T, BOSS), damit man die grauen Kaesten unterscheidet. Jede Szene haengt am Skript ihrer Art, und im Inspector stehen ihre Werte:

| Szene | Tempo | Flugkraft | Sonst |
|-------|-------|-----------|-------|
| normal | 100-180 | 2 | |
| schnell | 400-720 | 5 | |
| scheu | 190-230 | 3 | |
| koeder | 120-160 | 4 | |
| teleport | 100-180 | 8 | |
| boss | 110-130 | 15 | `halbe_groesse` 150, `leben` 3, `flieht` aus |

- `Fluegel` und `Koerper` haben in allen Fliegen-Szenen `mouse_filter = 2`. Das heisst: Die grauen Flaechen fangen keine Mausklicks ab, ein Klick auf eine Fliege schiesst wie ueberall sonst.
- Zu jedem neuen Skript hat Godot eine Datei `.gd.uid` angelegt (eine feste Kennnummer des Skripts, wie in den Abschnitten davor). Die schreibt Godot selbst, darin steht kein Code.
- `szenen/hindernis.tscn`: Der Knoten `Hindernis` ist in der Gruppe `hindernisse`. So findet die Koeder-Fliege alle Hindernisse.
- `szenen/spiel.tscn`: Am `Erzeuger` sind `zonen` und `schwarm_szenen` (fuenf Szenen) eingetragen. Neu: Knoten `Zonen` (`zonen.gd`) mit fuenf Kindern (`zone.gd`). Neu in `Bedienung`: die Labels `Zone` und `TestHinweis`. Neu: Knoten `TestSprung` (`test_sprung.gd`).

| Zone | ab Flugkraft | Fliegen | mindestens | Farbe |
|------|--------------|---------|------------|-------|
| Anfang | 0 | normal, schnell | 4 | unveraendert |
| Scheue | 20 | scheu | 4 | gruenlich |
| Koeder | 40 | koeder | 3 | orange |
| Teleport | 60 | teleport | 3 | blaeulich |
| Boss | 80 | boss, schnell, schnell | 3 | rosa |

Die Zonen sind eine Testaufteilung. Du aenderst sie im Editor am Knoten `Zonen`: Zone anklicken, Werte im Inspector. Eine neue Zone ist ein neuer Kindknoten mit `zone.gd`. Die Kinder muessen von unten nach oben sortiert sein.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS fuer alle 14 Skripte.
- Probe ohne Bildschirm, 60 Bilder pro Sekunde fest (Wegwerfskript ausserhalb des Spielordners, geloescht):

| Was | Gemessen |
|-----|----------|
| Schwarm, 5 Starts | 5 bis 8 Fliegen, je Art 1 oder 2, kein Boss |
| Erster Fang | Schwarm aufgeloest, alle uebrigen fliehen. In 20 Starts: 125 nach oben, 10 nach links, 15 nach rechts (der obere Rand ist meist der naechste) |
| Schnelle | Tempo 719, gemessen in jedem Bild 719 px/s, auch in der Schleife. Schleife 55 px ueber bis 65 px unter der Linie, 178 px ueber das Streckenende hinaus, landet 4,5 px neben der Linie |
| Normale | Tempo 102: seitlich 51 bis 102 px/s, wippt 50 px hoch und runter |
| Scheue | haelt 241 px (ihr Wunsch), weicht mit 212 px/s vor der Kanone (281 px/s), eingeholt nach 3,1 s |
| Koeder | Warnung 700 px entfernt: nach 0,63 s darunter, zappelt in der Spalte, Bogen 63 px tief, steht beim Fall 230 px neben der Mitte, lebt danach |
| Teleport | in 15 s fuenf Spruenge (212 bis 263 px), davor 9 blasse Bilder |
| Boss ohne Treffer | nach 5,2 s am oberen Rand, 486 px im Bild (ein Drittel sind 480) |
| Boss, Treffer 1 und 2 | Leben 3 -> 2 -> 1, Nadel steckt als Kind im Boss, er liegt danach 150 px tiefer, Flugkraft bleibt 0 |
| Boss, Treffer 3 | gefangen, Flugkraft 15, haengt im Faecher, die zwei alten Faeden sind weg |
| Boss entkommt mit Nadel | nach 8,1 s geloescht, Nadel mit ihm, Flugkraft unveraendert |
| Sprung in jede Zone | Name und Farbe stimmen, es fliegen nur die Arten der Zone, in Zone Boss kam in drei von vier Laeufen in 30 s mindestens ein Boss |

- Bilder mit Fenster angesehen: Schwarm am Boden mit Buchstaben, Schleife als Spur (Tropfenform), drei Koeder-Fliegen in der gelben Spalte, Boss mit zwei Nadeln und zwei Faeden zur Muendung, gefangener Boss im Faecher.
- Gesehen, nicht geaendert: Der gefangene Boss ragt oben halb aus dem Bild, der Faecher rechnet seine Groesse nicht ein (Abschnitt 10).
- Nicht gemessen: wie sich die Arten spielen, ob die Zahlen stimmen. Das entscheidest du. Am Handy nicht geprueft (die Sprungtasten gibt es nur auf der Tastatur).

### Drei Fragen zur Selbstkontrolle

1. Warum bleibt die schnelle Fliege in der Schleife gleich schnell?
2. Die Koeder-Fliege ruft `warnung.gewarnt` ab. In welchem Skript steht diese Variable, und woher weiss die Fliege, welche Hindernisse es gibt?
3. Was passiert der Reihe nach, wenn die dritte Nadel den Boss trifft?

<details><summary>Antworten</summary>

1. Bewegt wird sie nur in einer Zeile: Richtung mal `tempo` mal `delta`. Zum Wenden aendert sich nur der Winkel, nie das Tempo.
2. In `hindernis.gd`. Die Hindernisse sind in der Gruppe `hindernisse`, und `get_tree().get_nodes_in_group("hindernisse")` liefert alle.
3. `leben` ist 1, also nicht mehr groesser als 1: Die Nadel ruft `aufspiessen` statt `stecken_in`. Der Boss wird Kind der Nadel und gilt als gefangen, die Faeden der zwei alten Nadeln loesen sich. Ist keine Fliege mehr darueber, bleibt die Nadel stecken und sendet `getroffen`. Die Uebergabe sendet `gefangen` mit 15, `spiel.gd` zaehlt und steigt, der Arm bringt Nadel und Boss in den Faecher.

</details>

## Spass-Test, Runde 14 - Nadel bleibt ueber der Kanone, Teleport reagiert, Boss steiler, vier Zonen

### `skripte/nadel.gd` - geaendert

```gdscript
var kanone: Node2D = null
```
Neu. Die Kanone, die die Nadel geschossen hat.

```gdscript
	position.x = kanone.position.x
	position.y -= tempo * delta
```
In `_process`. Die erste Zeile ist neu: Solange die Nadel fliegt, steht sie seitlich genau dort, wo die Kanone ist. Faehrt die Kanone zur Seite, faehrt die Nadel mit. Die Zeile steht hinter `if steckt: ... return`, eine steckende Nadel bleibt also, wo sie getroffen hat. Vorher flog die Nadel an der Stelle hoch, an der sie abgeschossen wurde (so entschieden am 06.11., jetzt geaendert).

### `skripte/kanone.gd` - geaendert

```gdscript
@export var tempo: float = 300.0
```
281 -> 300.

```gdscript
		nadel.kanone = self
```
In `schiessen`. Die Kanone traegt sich selbst in die neue Nadel ein. `self` ist der Knoten, an dem das Skript haengt.

### `skripte/fliege_teleport.gd` - neu geschrieben

Vorher sprang sie nach einer zufaelligen Pause. Jetzt springt sie, wenn die Kanone unter ihr ist, dreimal hintereinander, und braucht dann eine Pause.

```gdscript
@export var ausloese_weite: float = 120.0
@export var spruenge: int = 3
@export var erholzeit: float = 2.5
@export var flacker_zeit: float = 0.2
@export var sprung_nah: float = 200.0
@export var sprung_weit: float = 350.0
```
Neu oder geaendert: wie nah die Kanone seitlich sein muss (120 px), wie viele Spruenge sie hat (3), wie lange sie sich danach erholt (2,5 s). Das Flackern ist kuerzer (0,2 statt 0,3 s), der Sprung weiter (200 bis 350 statt 150 bis 300). `pause_kurz` und `pause_lang` sind weg. `strecke`, `flacker_takt` und `flacker_blass` sind unveraendert.

```gdscript
var uebrig: int = 0
var erholt_in: float = 0.0
var flackert_noch: float = 0.0
```
Wie viele Spruenge sie noch hat, wie lange die Erholung noch dauert, und wie lange sie noch flackert, bevor sie springt.

```gdscript
func losfliegen() -> void:
	uebrig = spruenge
```
Am Start hat sie alle Spruenge.

```gdscript
func fliegen(delta: float) -> void:
	position.x += richtung * tempo * delta
	if position.x > mitte_x + strecke:
		richtung = -1.0
	if position.x < mitte_x - strecke:
		richtung = 1.0
	modulate.a = 1.0
```
Hin und her wie bisher, und zuerst voll sichtbar.

```gdscript
	if uebrig == 0:
		erholt_in -= delta
		if erholt_in <= 0.0:
			uebrig = spruenge
		return
```
Hat sie keinen Sprung mehr, zaehlt die Erholung herunter. Ist sie um, hat sie wieder alle Spruenge. `return`: In der Erholung passiert sonst nichts, das ist das Fenster zum Fangen.

```gdscript
	if flackert_noch > 0.0:
		flackert_noch -= delta
		if fmod(flackert_noch, flacker_takt) < flacker_takt / 2.0:
			modulate.a = flacker_blass
		if flackert_noch <= 0.0:
			springen()
		return
```
Flackert sie gerade, zaehlt das Flackern herunter. In jeder ersten Haelfte des Takts ist sie blass. Ist es um, springt sie.

```gdscript
	if absf(position.x - kanone.position.x) < ausloese_weite:
		flackert_noch = flacker_zeit
```
Sonst: Ist die Kanone seitlich naeher als 120 px, beginnt das Flackern.

```gdscript
func springen() -> void:
	...
	uebrig -= 1
	if uebrig == 0:
		erholt_in = erholzeit
```
Der Sprung selbst ist wie bisher. Neu: Ein Sprung ist verbraucht. War es der letzte, beginnt die Erholung.

### `skripte/fliege_boss.gd` - geaendert

```gdscript
@export var steigtempo: float = 150.0
@export var absacken: float = 100.0
```
Steigen 75 -> 150 (doppelt so steil), Absacken 200 -> 100 (halb so tief).

### `skripte/zone.gd` - geaendert

```gdscript
@export var einmalig: Array[PackedScene] = []
```
Neu. Szenen, die genau einmal hereinfliegen, wenn man die Zone von unten betritt. In der Zone `Boss` steht hier der Boss.

### `skripte/erzeuger.gd` - geaendert

```gdscript
var letzte_zone: Node = null
```
Neu. Die Zone, in der man zuletzt war.

```gdscript
	letzte_zone = zonen.get_child(0)
```
In `_ready`. Am Anfang ist das die unterste Zone.

```gdscript
	var zone: Node = zonen.aktuelle()
	if zone != letzte_zone:
		if zone.ab_flugkraft > letzte_zone.ab_flugkraft:
			for szene in zone.einmalig:
				hereinfliegen(szene)
		letzte_zone = zone
	if freie_in_der_naehe() < zone.mindestens:
		hereinfliegen(zone.fliegen.pick_random())
```
In `_process`. Neu ist der mittlere Block: Ist man in einer anderen Zone als zuletzt, und liegt die neue hoeher, fliegt jede Szene aus `einmalig` einmal herein. Dann merkt sich der Erzeuger die neue Zone. Faellt man hinunter und steigt wieder hinein, kommt der Boss noch einmal. Der Block steht hinter `if kanone.steigt: return`, der Boss kommt also erst, wenn das Steigen fertig ist.

```gdscript
func hereinfliegen(szene: PackedScene) -> void:
```
Geaendert: Die Funktion bekommt jetzt die Szene statt der Zone. So kann sie auch den Boss hereinbringen. Die Zeile `var szene: PackedScene = zone.fliegen.pick_random()` ist darum aus der Funktion in den Aufruf gewandert.

### Szenen - geaendert

- `szenen/fliege_scheu.tscn`: Tempo 190-230 -> 255-285 (85 bis 95 Prozent der Kanone).
- `szenen/spiel.tscn`: vier Zonen statt fuenf, in jeder zwei Arten. Der Hinweis oben links sagt "Tasten 1 bis 4".

| Zone | ab Flugkraft | Fliegen | einmalig | mindestens |
|------|--------------|---------|----------|------------|
| Anfang | 0 | normal, schnell | | 4 |
| Scheue | 25 | scheu, schnell | | 4 |
| Koeder | 50 | koeder, normal | | 3 |
| Boss | 75 | teleport | boss | 3 |

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS (6 Skripte).
- Probe ohne Bildschirm (Wegwerfskript ausserhalb des Spielordners):

| Was | Gemessen |
|-----|----------|
| Nadel | Kanone faehrt 300 px/s, Nadel 0,68 s im Flug, seitlicher Abstand zur Kanone hoechstens 0,0 px |
| Scheue | 262 px/s gegen 300, bei 359 px Abstand eingeholt nach 8,5 s (vorher 212 gegen 281: 3,1 s) |
| Teleport, Kanone weit weg | 5 s lang kein Sprung |
| Teleport, verfolgt | je drei Spruenge (231 bis 352 px), dann 2,5 s keiner |
| Boss ohne Treffer | nach 2,6 s am oberen Rand, erst 112 px im Bild (vorher 5,2 s, 486 px) |
| Boss, ein Treffer | nach 0,5 s 25 px tiefer als vorher (100 Absacken, 75 schon wieder gestiegen) |
| Zonen | Anfang: normal, schnell. Scheue: scheu, schnell. Koeder: in 10 Starts 14 Koeder und 16 normale. Boss: Teleport und in 30 s genau ein Boss (drei Laeufe). Nach Fall und neuem Betreten ein neuer Boss |

- Nicht gemessen: wie es sich spielt. Der Boss ist nach diesen Zahlen sehr knapp. Am Handy und im Browser nicht geprueft.

### Drei Fragen zur Selbstkontrolle

1. Warum faehrt eine Nadel, die in einer Fliege steckt, nicht mehr mit der Kanone mit?
2. Wann kann man eine Teleport-Fliege fangen?
3. Woran merkt der Erzeuger, dass der Boss kommen soll?

<details><summary>Antworten</summary>

1. Die neue Zeile steht hinter `if steckt: ... return`. Fuer eine steckende Nadel wird sie nie erreicht.
2. In der Erholung nach dem dritten Sprung (2,5 s), oder wenn man sie trifft, ohne naeher als 120 px zu kommen und laenger als 0,2 s darunter zu sein.
3. `zonen.aktuelle()` ist nicht mehr `letzte_zone`, und die neue Zone beginnt hoeher. Dann fliegt alles aus `einmalig` herein.

</details>

## Spass-Test, Runde 14 - Nachtrag: Knopf "Neustart"

Nur zum Testen, kommt mit dem Sprung-Werkzeug vor der Abgabe wieder heraus. Neu starten geht jetzt auf vier Wegen: Knopf oben rechts mit der Maus, derselbe Knopf mit dem Finger, Taste R, Taste 0. Das geht jederzeit, auch nach "Im All!".

### `skripte/test_sprung.gd` - geaendert

```gdscript
@export var knopf: Button
```
Neu. Der Knopf "Neustart" aus der Szene.

```gdscript
func _ready() -> void:
	knopf.pressed.connect(neustart)
```
Neu. Ein `Button` sendet das Signal `pressed`, wenn man ihn mit der Maus anklickt. Es wird mit der Funktion `neustart` verbunden.

```gdscript
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("neustart"):
		neustart()
```
Neu. Die Aktion `neustart` ist in `project.godot` neu angelegt, mit der Taste R. Die Touch-Taste auf dem Knopf loest dieselbe Aktion aus. So gehen Tastatur und Finger ueber eine Zeile.

```gdscript
func neustart() -> void:
	get_tree().reload_current_scene()
```
Neu, als eigene Funktion, weil drei Stellen sie brauchen. Die Szene wird neu geladen, alles ist wie beim Start: Flugkraft 0, Kanone am Boden, neuer Schwarm, man kann fahren und schiessen.

```gdscript
	if taste.keycode == KEY_0:
		neustart()
		return
```
Geaendert: Die Taste 0 ruft jetzt dieselbe Funktion auf.

### `project.godot` und `szenen/spiel.tscn` - geaendert

- `project.godot`: neue Aktion `neustart` mit der Taste R (wie `links`, `rechts`, `schiessen`).
- `spiel.tscn`: In `Bedienung` der neue `Button` namens `Neustart`, oben rechts. `focus_mode = 0` heisst: Der Knopf nimmt nie den Tastatur-Fokus. Sonst wuerde die Leertaste nach einem Klick den Knopf druecken statt zu schiessen. Sein Kind `TasteNeustart` ist ein `TouchScreenButton` mit der Aktion `neustart`, sichtbar nur auf Touchscreens. Ein `Button` reagiert in diesem Projekt nicht auf Finger, weil Fingertipps nicht als Mausklick zaehlen (`emulate_mouse_from_touch=false`, Abschnitt 2). Darum liegt fuer den Finger eine Touch-Taste darueber.
- `TestSprung` hat den Knopf eingetragen. Der Hinweis oben links nennt jetzt "0 oder R = Neustart".
- Nebenwirkung: Ein Mausklick auf den Knopf ist auch ein Schuss (linke Maustaste). Das stoert nicht, weil gleich danach neu geladen wird.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Probe ohne Bildschirm: Nach dem Sieg (Flugkraft 100, Kanone steht, "Im All!" sichtbar) Knopf ausgeloest: Flugkraft 0, Kanone bei y 0 und laeuft wieder, "Im All!" weg, 8 Fliegen im Schwarm, Kanone faehrt (228 px in 1 s). Dasselbe ueber die Aktion `neustart` und ueber Taste 0.
- Nicht geprueft: ein echter Mausklick und ein echter Fingertipp auf den Knopf (in der Probe wurde das Signal bzw. die Aktion direkt ausgeloest).

## Spass-Test, Runde 15 - schnelle Fliege auf dem geraden Stueck doppelt so schnell

### `skripte/fliege_schnell.gd` - geaendert

```gdscript
@export var faktor_gerade: float = 2.0
```
Neu. Auf dem geraden Stueck fliegt sie so viel schneller als in der Schleife. Ihr `tempo` bleibt 400 bis 720, gerade sind das jetzt 800 bis 1440 px/s.

```gdscript
	if not wendet:
		position += Vector2.from_angle(winkel) * tempo * faktor_gerade * delta
```
Die Bewegungszeile stand vorher einmal ganz oben in `fliegen` und galt immer. Jetzt gibt es sie zweimal: Diese hier gilt auf dem geraden Stueck, mit `faktor_gerade` multipliziert.

```gdscript
	position += Vector2.from_angle(winkel) * tempo * delta
	var schritt: float = tempo / schleife * delta
```
Und diese gilt in der Schleife, mit dem einfachen Tempo wie bisher. Sie steht hinter dem `return` des geraden Stuecks, wird also nur waehrend der Wende erreicht. Die Schleife sieht darum aus wie vorher und dauert gleich lang. Die Fliege ist jetzt nicht mehr ueberall gleich schnell: Sie bremst in die Schleife hinein auf die Haelfte und schiesst danach wieder los.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Probe ohne Bildschirm: bei Tempo 484 gerade 967 px/s, in der Schleife 484 px/s, landet 6,7 px neben der Linie (den Rest rastet `position.y = grund_y` ein), 6 Wenden in 10 s.
- Nicht gemessen: wie es sich spielt.

## Fehler behoben - Koeder-Fliege blieb nach dem Ausweichen stehen

### `skripte/fliege_koeder.gd` - geaendert

Vorher, in `schwingen`:

```gdscript
	position.x = move_toward(position.x, mitte_x, tempo_eilig * delta)
	if position.x == mitte_x:
```

Jetzt:

```gdscript
	var neues_x: float = move_toward(position.x, mitte_x, tempo_eilig * delta)
	position.x = neues_x
	if neues_x == mitte_x:
```

Der Fehler: Godot speichert `position` mit weniger Nachkommastellen als eine normale Variable wie `mitte_x`. Schreibt man eine Zahl in `position.x` und liest sie wieder aus, kann sie darum ein winziges Stueck anders sein (gemessen: 0,000015 px). Der Vergleich `position.x == mitte_x` war dann nie wahr, der Schwung hoerte nie auf, und die Fliege stand, bis die naechste Warnung einen neuen Schwung ausloeste. Das traf etwa jede dritte Fliege nach dem Ausweichen, je nachdem, ob die Zahl zufaellig genau passte.

Die Loesung: Das Ergebnis von `move_toward` kommt erst in die eigene Variable `neues_x`. Die wird verglichen, bevor irgendetwas gerundet ist. `move_toward` liefert am Ziel genau `mitte_x` zurueck, der Vergleich stimmt also immer.

Merksatz: Kommazahlen nie mit `==` vergleichen, nachdem sie in `position` gesteckt wurden. Der Vergleich `position == ziel` weiter oben im Skript ist in Ordnung, weil dort beide Seiten gleich genau gespeichert sind (beide sind `Vector2`).

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Nachgestellt: 60 einzelne Ausweichmanoever, je eine Fliege und ein Hindernis. Vorher standen 20 von 60 Fliegen zwei Sekunden nach dem Klotz unbewegt (`schwingt` blieb `true`). Nachher 0 von 60.

## Spass-Test, Runde 16 - Koeder-Fliege allein in ihrer Zone

### `szenen/spiel.tscn` - geaendert

Am Knoten `Zonen/Koeder` steht in `fliegen` nur noch die Koeder-Fliege. Die normale Fliege ist dort raus. Kein Code geaendert.

| Zone | ab Flugkraft | Fliegen |
|------|--------------|---------|
| Anfang | 0 | normal, schnell |
| Scheue | 25 | scheu, schnell |
| Koeder | 50 | koeder |
| Boss | 75 | teleport, einmal der Boss |

### So wurde es angeschaut

- Verify PASS.
- Probe: siehe `game_spec.md`, Changelog vom 21.11.

## Spass-Test, Runde 17 - weniger Punkte, normale Fliege mit Bremse, knappe Hindernisse oben

### `szenen/fliege_scheu.tscn`, `fliege_schnell.tscn`, `fliege_teleport.tscn` - geaendert

Nur der Wert `flugkraft` im Inspector. Kein Code geaendert.

| Fliege | vorher | jetzt |
|--------|--------|-------|
| normal | 2 | 2 |
| scheu | 3 | 1 |
| schnell | 5 | 4 |
| koeder | 4 | 4 |
| teleport | 8 | 7 |
| boss | 15 | 15 |

Die Zonen bleiben bei 0, 25, 50 und 75. Weil die Fliegen weniger geben, braucht man in den Zonen mehr Faenge.

### `skripte/fliege_normal.gd` - geaendert

```gdscript
@export var drehtempo: float = 12.56
```
Vorher 6.28, also eine Umdrehung pro Sekunde. Jetzt zwei.

```gdscript
@export var bremse_alle: float = 2.0
@export var bremse_dauer: float = 0.5
@export var bremse_anteil: float = 0.5
```
Neu. Alle 2 Sekunden bremst die Fliege fuer eine halbe Sekunde auf die Haelfte ab. Das kommt zum bisherigen langsamen Schwanken dazu, ersetzt es nicht.

```gdscript
	if fmod(zeit, bremse_alle) > bremse_alle - bremse_dauer:
		jetzt = jetzt * bremse_anteil
```
`fmod(zeit, 2.0)` ist der Rest beim Teilen durch 2: Er zaehlt von 0 bis 2 hoch und faengt dann wieder bei 0 an. Ist er groesser als 1,5, steckt die Fliege in der letzten halben Sekunde dieser 2 Sekunden. Dann wird ihr Tempo von gerade eben noch einmal halbiert.

### `skripte/hindernis_erzeuger.gd` - geaendert

```gdscript
@export var knapp_anteil_oben: float = 0.5
@export var knapp_kurz: float = 3.0
@export var knapp_lang: float = 4.0
```
Neu. Ab der Haelfte kommen knappe Hindernisse dazu, mit nur 3 bis 4 Sekunden Warnzeit. Ganz oben bei 100 Flugkraft ist es jedes zweite.

```gdscript
	if randf() < knapp_anteil_oben * anteil_oben():
		return randf_range(knapp_kurz, knapp_lang)
```
Steht in `warnzeit_hier` hinter der Zeile fuer die erste Haelfte, gilt also erst ab der Haelfte. `anteil_oben()` ist an der Haelfte 0 und oben 1. Mal 0.5 heisst: An der Haelfte ist keins knapp, bei 75 Flugkraft jedes vierte, oben jedes zweite. Trifft der Wurf nicht, gilt die Warnzeit von vorher (9 Sekunden an der Haelfte, gleitend bis 5 oben).

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS fuer beide Skripte.
- Nicht gemessen: wie es sich spielt. Dafuer der Draft auf itch.

## Spass-Test, Runde 18 - Teleport-Fliege zeigt ihre Spruenge mit Schimmer und Summen

### `szenen/fliege_teleport.tscn` - geaendert

Neuer erster Kindknoten `Schimmer` (`Sprite2D`). Sein Bild ist eine `GradientTexture2D`, 240 x 240 Pixel, mit `fill = 1`: Das heisst kreisfoermig, von der Mitte (`fill_from` 0.5, 0.5) bis zum Rand (`fill_to` 0.5, 0). Der Verlauf geht von hellem Tuerkis (Deckkraft 0.8) zu voellig durchsichtig. So entsteht ein weicher Lichthof. Weil er der erste Kindknoten ist, wird er zuerst gemalt und liegt damit hinter Fluegel und Koerper.

### `skripte/fliege_teleport.gd` - geaendert

```gdscript
@export var summen_voll: float = -20.0
@export var summen_leer: float = -32.0
@export var tonhoehe_leer: float = 0.6
```
Neu. Mit allen Spruengen summt sie so laut wie bisher (-20 dB). Ohne Spruenge ist sie 12 dB leiser und klingt tiefer, nur noch 0.6 ihrer eigenen Tonhoehe.

```gdscript
var eigene_tonhoehe: float = 1.0
```
Neu. `fliege.gd` wuerfelt in `_ready` fuer jede Fliege eine eigene Tonhoehe aus. Die wird hier gemerkt, sonst wuerde das Tieferwerden sie ueberschreiben.

```gdscript
	eigene_tonhoehe = $Summen.pitch_scale
```
In `losfliegen`. Das laeuft am Ende von `_ready`, die Tonhoehe ist dann schon ausgewuerfelt.

```gdscript
	var ladung: float = ladung_jetzt()
	$Schimmer.modulate.a = ladung
	$Summen.volume_db = lerpf(summen_leer, summen_voll, ladung)
	$Summen.pitch_scale = eigene_tonhoehe * lerpf(tonhoehe_leer, 1.0, ladung)
```
In `fliegen`, also in jedem Bild. `ladung` ist eine Zahl von 0 bis 1. Der Schimmer bekommt sie direkt als Deckkraft. Lautstaerke und Tonhoehe werden mit `lerpf` zwischen dem Wert fuer leer und dem fuer voll gemischt.

```gdscript
func ladung_jetzt() -> float:
	if uebrig == 0:
		return 1.0 - erholt_in / erholzeit
	return float(uebrig) / float(spruenge)
```
Neu. Hat sie noch Spruenge, ist die Ladung `uebrig` geteilt durch `spruenge`: 3 von 3 ist 1, 2 von 3 ist 0.67, 1 von 3 ist 0.33. Das `float(...)` ist noetig, weil beide ganze Zahlen sind und `2 / 3` sonst 0 ergibt. Erholt sie sich, zaehlt `erholt_in` von 2,5 auf 0 herunter. `erholt_in / erholzeit` geht also von 1 nach 0, und `1.0 - ...` davon waechst von 0 nach 1. Schimmer und Summen kommen so in 2,5 Sekunden gleitend zurueck.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Probe ohne Bildschirm (Kanone immer genau unter der Fliege): Schimmer 1,00 -> 0,67 -> 0,33 -> 0, Summen -20 -> -24 -> -28 -> -32 dB. Danach in 2,5 s gleitend zurueck auf 1,00, dann springt sie wieder.
- Nicht angeschaut: wie der Schimmer aussieht und wie das Summen klingt. Gefangen behaelt sie den Schimmer, den sie gerade hatte, auch am Faden.

## Spass-Test, Runde 19 - Teleport-Fliege: nur die Tonhoehe aendert sich

### `skripte/fliege_teleport.gd` - geaendert

Weg sind diese drei Zeilen aus Runde 18:

```gdscript
@export var summen_voll: float = -20.0
@export var summen_leer: float = -32.0
	$Summen.volume_db = lerpf(summen_leer, summen_voll, ladung)
```
Die Fliege summt jetzt immer gleich laut, mit den -20 dB aus der Szene. Mit der Ladung aendert sich nur noch die Tonhoehe: 3 Spruenge die eigene, 2 Spruenge x0,87, 1 Sprung x0,73, keiner x0,6 (am tiefsten). Die Kommentarzeilen oben im Skript sagen jetzt dasselbe.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Nicht angehoert.

## Abschnitt 13 - Totale als Start

Was neu ist, in einem Absatz: Das Spiel beginnt weit herausgezoomt. Auf einer Wiese steht eine ganze Figur (noch aus grauen Rechtecken), die Kanone haelt sie in der Faust. Der Arm zielt auf den Mauszeiger, die Maustaste schiesst schraeg dorthin. Die Pfeiltasten kippen die Figur um ihre Fuesse. Trifft man eine Fliege, flieht der Schwarm, die Figur hebt eine Kopfhoehe ab und schwankt zwei Sekunden an der Fliege, dann zoomt das Bild auf die Kanone und das Spiel laeuft wie bisher. Stuerzt man auf 0 ab, faellt die Figur auf die Wiese, steht auf, und alles beginnt wieder in der Totale. Auf der Wiese sitzt eine Einstellungsfliege. Schiesst man sie an, faehrt die Wiese als gruene Wand hoch, darauf zwei Regler fuer die Lautstaerke. Am Handy gibt es statt der Pfeiltasten einen Joystick.

Fuenf neue Skripte, jedes mit einer Aufgabe: `start_totale.gd` (die Figur), `joystick.gd`, `einstellungsfliege.gd`, `einstellungen.gd` (die Wand), `regler.gd` (ein Balken). Geaendert sind `nadel.gd`, `erzeuger.gd`, `kanone.gd` und `spiel.gd`.

### Die Masse, einmal vorweg

Der Zoom der Totale ist 0,43. Das heisst: Alles ist 43 Prozent so gross, das Bild zeigt 1080 / 0,43 = 2512 Pixel Hoehe und 1440 / 0,43 = 3349 Pixel Breite der Welt.

Die Figur ist 990 Pixel gross. Das kommt aus der Vorgabe: unteres Viertel Wiese, darueber die Figur mit gestrecktem Arm, Kanone und vier Kopfhoehen Platz. Ueber der Wiese bleiben 810 Bildpixel, das sind 810 / 0,43 = 1884 Pixel Welt. Ein Mensch reicht mit gestrecktem Arm etwa 1,27 mal so hoch, wie er gross ist, der Kopf ist etwa ein 7,5tel. Also: 1,27 x Groesse + 100 fuer die Kanone + 4 Koepfe = 1884. Das ergibt eine Groesse von 990, einen Kopf von 132, die Schulter auf 812 und einen Arm von 400 bis zur Faust.

Die Kanone des Spiels sitzt wie bisher auf Hoehe 0. Die Faust der Figur liegt genau dort, die Fuesse stehen darum 812 + 400 = 1212 Pixel tiefer. Die Wiese beginnt bei 1212.

### `skripte/start_totale.gd` - neu

Das Skript haengt am Knoten `Figur`. `Figur` ist ein Kind der Kanone und liegt mit seinem Nullpunkt an den Fuessen.

```gdscript
extends Node2D
```
Die Figur ist ein Node2D. Sie hat einen Platz und laesst sich drehen.

```gdscript
signal spielstart(nadel: Node2D)
```
Ein eigenes Signal. Die Figur sendet es, wenn die Einstiegs-Sequenz vorbei ist, und gibt die Nadel mit der ersten Fliege mit. `spiel.gd` hoert darauf.

```gdscript
@export var nadel_szene: PackedScene
@export var kanone: Node2D
@export var erzeuger: Node2D
@export var joystick: Node2D
```
Vier Dinge, die die Figur von aussen braucht. Sie werden im Inspector eingetragen: die Szene der Nadel (dieselbe wie bei der Kanone), die Kanone, der Erzeuger der Fliegen und der Joystick.

```gdscript
@export var nachladezeit: float = 0.5
```
Wie die Kanone laedt auch die Figur nach jedem Schuss eine halbe Sekunde nach.

```gdscript
@export var kippwinkel: float = 20.0
@export var kipptempo: float = 80.0
```
So weit kippt die Figur hoechstens (20 Grad nach jeder Seite) und so schnell (80 Grad pro Sekunde, sie braucht also eine Viertelsekunde bis ganz nach aussen).

```gdscript
@export var einstieg_dauer: float = 2.0
@export var abheben: float = 132.0
@export var schwanken: float = 8.0
```
Die Einstiegs-Sequenz: 2 Sekunden lang, die Figur hebt 132 Pixel ab (eine Kopfhoehe) und schwankt 8 Grad nach jeder Seite.

```gdscript
var aktiv: bool = true
```
Solange `aktiv` wahr ist, steuert man die Figur. Ab dem ersten Treffer ist es falsch.

```gdscript
var wand_offen: bool = false
```
Wahr, solange die Wand mit den Einstellungen oben ist. Das setzt `einstellungen.gd`. Die Figur wartet dann, sonst wuerde jeder Klick auf einen Regler auch schiessen.

```gdscript
var maus_zielt: bool = false
```
Erst wenn die Maus sich einmal bewegt hat, folgt der Arm ihr. Am Handy gibt es keine Maus, dort bliebe der Mauszeiger sonst auf einer zufaelligen Stelle stehen und der Arm zeigte dorthin.

```gdscript
var nachladen_noch: float = 0.0
var erste_nadel: Node2D = null
```
Der Zaehler fuer das Nachladen, wie in `kanone.gd`. Und ein Platz fuer die Nadel, die als erste getroffen hat.

```gdscript
func _input(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseMotion:
		maus_zielt = true
```
`_input` ruft Godot bei jeder Eingabe auf: Tastendruck, Mausbewegung, Finger. `ereignis is InputEventMouseMotion` fragt: Ist das eine Mausbewegung? Wenn ja, zielt ab jetzt die Maus.

```gdscript
func _process(delta: float) -> void:
	if not aktiv or wand_offen:
		return
	kippen(delta)
	zielen()
	schiessen(delta)
```
In jedem Bild: Ist die Figur nicht mehr dran oder ist die Wand oben, passiert nichts. Sonst drei Schritte nacheinander.

```gdscript
func kippen(delta: float) -> void:
	var ziel: float = Input.get_axis("links", "rechts") * kippwinkel
	rotation_degrees = move_toward(rotation_degrees, ziel, kipptempo * delta)
```
`Input.get_axis("links", "rechts")` gibt -1 fuer links, 1 fuer rechts und 0 fuer nichts. Mal 20 ist das der Winkel, zu dem die Figur will. `rotation_degrees` ist die Drehung der Figur in Grad. `move_toward` geht von der jetzigen Drehung ein Stueck in Richtung Ziel, hoechstens `kipptempo * delta` Grad in diesem Bild. Laesst man los, ist das Ziel 0 und die Figur richtet sich wieder auf. Gedreht wird um den Nullpunkt des Knotens, und der liegt an den Fuessen.

```gdscript
func zielen() -> void:
	if joystick.richtung != Vector2.ZERO:
		maus_zielt = false
		$Schulter.rotation = wrapf(joystick.richtung.angle() + PI / 2.0, -PI, PI)
```
Zeigt der Joystick irgendwohin, gilt er, und die Maus ist abgemeldet. `angle()` gibt den Winkel eines Pfeils, gemessen von "nach rechts". Der Arm ist in der Szene aber nach oben gezeichnet, darum kommt eine Vierteldrehung dazu (`PI / 2.0`, das sind 90 Grad). `wrapf(..., -PI, PI)` haelt den Winkel zwischen -180 und +180 Grad. Ohne das wuerde der Arm sich in der Sequenz manchmal den langen Weg herum nach oben drehen.

```gdscript
	elif maus_zielt:
		var zur_maus: Vector2 = get_global_mouse_position() - $Schulter.global_position
		$Schulter.rotation = wrapf(zur_maus.angle() + PI / 2.0, -PI, PI)
```
Sonst zielt die Maus. `get_global_mouse_position()` ist die Stelle des Mauszeigers in der Welt. Minus die Stelle der Schulter ergibt den Pfeil von der Schulter zur Maus. Der Arm bekommt dessen Winkel. Schulter, Kanonenspitze und Mauszeiger liegen damit auf einer Linie.

Wichtig: `rotation` ist die Drehung gegenueber dem Elternknoten, also gegenueber der Figur. Kippt die Figur, kippt der Arm mit, die Spitze zeigt dann um den Kippwinkel neben die Maus. Das ist so gewollt.

```gdscript
func schiessen(delta: float) -> void:
	nachladen_noch -= delta
	if nachladen_noch > 0.0:
		return
	if Input.is_action_just_pressed("schiessen"):
```
Wie in `kanone.gd`: herunterzaehlen, waehrend des Nachladens nichts tun, sonst auf die Aktion `schiessen` warten (Leertaste, W, linke Maustaste, am Handy die Schuss-Taste).

```gdscript
		var nadel: Node2D = nadel_szene.instantiate()
		nadel.position = $Schulter/Spitze.global_position
```
Eine neue Nadel entsteht an der Kanonenspitze. `Spitze` ist ein Marker am Ende des Rohrs.

```gdscript
		nadel.rotation = $Schulter.global_rotation
		nadel.richtung = Vector2.UP.rotated($Schulter.global_rotation)
```
`global_rotation` ist die Drehung des Arms in der Welt, also Kippen der Figur plus Drehung des Arms. Die Nadel wird genauso gedreht, damit sie in Flugrichtung zeigt. `Vector2.UP` ist der Pfeil nach oben, `rotated` dreht ihn um denselben Winkel. Das ist die Flugrichtung, sie kommt in die neue Variable `richtung` der Nadel.

```gdscript
		nadel.anker = $Schulter/Spitze
		kanone.get_parent().add_child(nadel)
```
Der Faden der Nadel haengt an der Spitze. `kanone.get_parent()` ist der Knoten `Spiel`. Dort kommt die Nadel hinein, wie die Nadeln der Kanone auch. `nadel.kanone` bleibt leer, daran erkennt die Nadel, dass sie frei fliegt.

```gdscript
		nadel.getroffen.connect(erster_treffer)
		nachladen_noch = nachladezeit
		kanone.get_node("TonSchuss").play()
```
Trifft die Nadel, ruft sie `erster_treffer`. Dann beginnt das Nachladen, und der Schuss-Ton der Kanone spielt.

```gdscript
func erster_treffer(nadel: Node2D) -> void:
	if not aktiv or wand_offen:
		nadel.queue_free()
		return
```
Trifft eine zweite Nadel, waehrend die Sequenz schon laeuft, wird sie samt ihrer Fliege geloescht. Es zaehlt nur der erste Treffer. Dasselbe gilt fuer eine Nadel, die noch unterwegs war und erst trifft, wenn die Wand schon oben ist. Sonst begaenne das Spiel hinter der Wand.

```gdscript
	aktiv = false
	erste_nadel = nadel
	kanone.steigt = true
	erzeuger.schwarm_aufloesen()
```
Ab jetzt steuert man die Figur nicht mehr. Die Nadel wird gemerkt. `kanone.steigt = true` sagt dem Erzeuger, dass man gerade abhebt: Solange das wahr ist, schickt er keine neuen Fliegen ins Bild. Dann flieht der Schwarm.

```gdscript
	var viertel: float = einstieg_dauer / 4.0
	var ablauf: Tween = create_tween()
```
Die Sequenz besteht aus vier gleich langen Stuecken von je einer halben Sekunde. Ein Tween fuehrt sie nacheinander aus.

```gdscript
	ablauf.tween_property(kanone, "position:y", -abheben, viertel)
	ablauf.parallel().tween_property(self, "rotation_degrees", schwanken, viertel)
```
Erstes Stueck: Die Kanone steigt um 132 Pixel. Die Figur haengt an ihr und steigt mit. `parallel()` heisst: gleichzeitig mit dem Schritt davor. Gleichzeitig kippt die Figur 8 Grad nach rechts.

```gdscript
	ablauf.tween_property(self, "rotation_degrees", -schwanken, viertel)
	ablauf.tween_property(self, "rotation_degrees", schwanken, viertel)
```
Zweites und drittes Stueck: nach links schwanken, wieder nach rechts.

```gdscript
	ablauf.tween_property(self, "rotation_degrees", 0.0, viertel)
	ablauf.parallel().tween_property($Schulter, "rotation", 0.0, viertel)
	ablauf.parallel().tween_property(nadel, "rotation", 0.0, viertel)
```
Viertes Stueck: Die Figur richtet sich auf, gleichzeitig dreht der Arm gerade nach oben und die Nadel mit der Fliege dreht sich aufrecht. Am Ende steht die Kanone in der Faust genau dort und genau so wie die Kanone des Spiels. Darum sieht man den Tausch der beiden nicht.

```gdscript
	ablauf.tween_callback(sequenz_fertig)


func sequenz_fertig() -> void:
	spielstart.emit(erste_nadel)
```
Ganz am Ende ruft der Tween `sequenz_fertig`, und die sendet das Signal mit der Nadel.

```gdscript
func ausschalten() -> void:
	aktiv = false
	rotation = 0.0
	$Schulter.visible = false
```
Das ruft `spiel.gd` beim Spielstart. Die Figur steht gerade, ihr Arm mit der Kanone wird unsichtbar. Der Rest der Figur bleibt und haengt unter der Kanone, im Spiel liegt er unter dem Bildrand.

### `skripte/joystick.gd` - neu

```gdscript
extends Node2D

@export var radius: float = 120.0
```
So weit geht der Knopf hoechstens aus der Mitte.

```gdscript
var richtung: Vector2 = Vector2.ZERO
var finger: int = -1
```
`richtung` ist das Ergebnis: ein Pfeil, wohin der Joystick zeigt. Losgelassen ist er `Vector2.ZERO`, ganz am Rand hat er die Laenge 1. Andere Skripte lesen nur diese eine Variable. `finger` merkt sich, welcher Finger den Joystick haelt. Jeder Finger auf dem Bildschirm hat eine Nummer, -1 heisst keiner.

```gdscript
func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
```
Den Joystick sieht man nur, wenn das Geraet einen Touchscreen hat.

```gdscript
func _input(ereignis: InputEvent) -> void:
	if not visible:
		return
```
Ohne Touchscreen tut das Skript nichts.

```gdscript
	if ereignis is InputEventScreenTouch:
		if ereignis.pressed and finger == -1 and ereignis.position.distance_to(global_position) <= radius * 1.5:
			finger = ereignis.index
			auslenken(ereignis.position)
```
`InputEventScreenTouch` kommt, wenn ein Finger aufsetzt oder abhebt. Setzt er auf (`pressed`), haelt noch kein Finger den Joystick, und liegt die Stelle nah genug an der Mitte (bis zum Anderthalbfachen des Radius), dann gehoert der Joystick diesem Finger.

```gdscript
		elif not ereignis.pressed and ereignis.index == finger:
			finger = -1
			richtung = Vector2.ZERO
			$Knopf.position = Vector2.ZERO
```
Hebt genau dieser Finger ab, ist der Joystick wieder frei, zeigt nirgendwohin, und der Knopf springt in die Mitte.

```gdscript
	if ereignis is InputEventScreenDrag and ereignis.index == finger:
		auslenken(ereignis.position)
```
`InputEventScreenDrag` kommt, wenn ein Finger ueber den Bildschirm zieht. Ist es der Finger am Joystick, folgt der Knopf.

```gdscript
func auslenken(stelle: Vector2) -> void:
	var weg: Vector2 = (stelle - global_position).limit_length(radius)
	$Knopf.position = weg
	richtung = weg / radius
```
`stelle - global_position` ist der Pfeil von der Mitte zum Finger. `limit_length(radius)` kuerzt ihn auf hoechstens 120 Pixel. Dorthin kommt der Knopf. Geteilt durch den Radius wird daraus ein Pfeil mit einer Laenge von 0 bis 1.

### `skripte/einstellungsfliege.gd` - neu

```gdscript
extends Node2D

signal angeschossen

@export var halbe_groesse: float = 100.0
```
Die Fliege sitzt fest in der Welt. Sie hat ein Signal und eine Groesse: 100 nach jeder Seite, also 200 mal 200 Pixel.

```gdscript
func _process(_delta: float) -> void:
	if not visible:
		return
```
Ist sie unsichtbar (die Wand ist oben), prueft sie nichts.

```gdscript
	for nadel in get_tree().get_nodes_in_group("nadeln"):
		var abstand: Vector2 = nadel.global_position - global_position
		if absf(abstand.x) <= halbe_groesse and absf(abstand.y) <= halbe_groesse:
			nadel.queue_free()
			angeschossen.emit()
```
In jedem Bild geht sie alle Nadeln durch. Die Nadeln stehen dafuer in der Gruppe `nadeln` (neu in `nadel.tscn`). `abstand` ist der Pfeil von der Fliege zur Nadelspitze. Ist er seitlich und in der Hoehe hoechstens 100 lang, steckt die Spitze im Quadrat der Fliege. Dann verschwindet die Nadel, und die Fliege meldet den Treffer. Das ist dieselbe Rechnung wie beim Treffer einer normalen Fliege in `nadel.gd`, nur von der anderen Seite.

### `skripte/einstellungen.gd` - neu

Das Skript haengt an einem `CanvasLayer`. Was in einem CanvasLayer liegt, klebt am Bildschirm und bewegt sich nicht mit der Kamera, wie die Tasten in `Bedienung`.

```gdscript
extends CanvasLayer

@export var fliege: Node2D
@export var figur: Node2D
@export var fahrdauer: float = 0.6
@export var wiesenkante: float = 810.0
```
Die Einstellungsfliege und die Figur werden im Inspector eingetragen. Die Wand braucht 0,6 Sekunden fuer ihren Weg. 810 ist die Bildhoehe, auf der in der Totale die Oberkante der Wiese liegt (drei Viertel von 1080).

```gdscript
func _ready() -> void:
	fliege.angeschossen.connect(oeffnen)
```
Meldet die Fliege einen Treffer, wird `oeffnen` gerufen.

```gdscript
func oeffnen() -> void:
	if figur.wand_offen:
		return
	figur.wand_offen = true
	fliege.visible = false
```
Ist die Wand schon oben, passiert nichts. Sonst: Die Figur wartet ab jetzt, die Fliege auf der Wiese wird unsichtbar. Auf der Wand ist dieselbe Fliege noch einmal gezeichnet, an derselben Stelle im Bild.

```gdscript
	$Wand.position.y = wiesenkante
	$Wand.visible = true
	var fahrt: Tween = create_tween()
	fahrt.tween_property($Wand, "position:y", 0.0, fahrdauer)
```
Die Wand ist ein gruenes Rechteck in der Farbe der Wiese, so gross wie das Bild. Sie startet mit ihrer Oberkante genau auf der Wiesenkante und faehrt in 0,6 Sekunden bis ganz nach oben. Es sieht aus, als stiege die Wiese.

```gdscript
func schliessen() -> void:
	var fahrt: Tween = create_tween()
	fahrt.tween_property($Wand, "position:y", wiesenkante, fahrdauer)
	fahrt.tween_callback(zu)
```
Der Rueckweg: wieder herunter bis zur Wiesenkante, danach `zu`.

```gdscript
func zu() -> void:
	$Wand.visible = false
	fliege.visible = true
	figur.wand_offen = false
```
Die Wand verschwindet, die Fliege sitzt wieder auf der Wiese, die Figur ist wieder dran.

```gdscript
func _input(ereignis: InputEvent) -> void:
	if not $Wand.visible:
		return
	if ereignis is InputEventMouseButton or ereignis is InputEventScreenTouch:
		if ereignis.pressed and $Wand/Fliege.get_global_rect().has_point(ereignis.position):
			schliessen()
```
Nur wenn die Wand sichtbar ist: Kommt ein Mausklick oder ein Fingertipp, und liegt er im Rechteck der Fliege oben an der Kante, faehrt die Wand herunter. `get_global_rect()` gibt das Rechteck eines Bedien-Knotens auf dem Bildschirm, `has_point` fragt, ob ein Punkt darin liegt.

Warum kein fertiger Knopf von Godot: Im Projekt ist seit Abschnitt 2 abgestellt, dass ein Fingertipp als Mausklick zaehlt (sonst wuerde jeder Tipp schiessen). Die fertigen Knoepfe und Schieberegler hoeren aber nur auf die Maus. Darum fragt das Skript Maus und Finger selbst ab.

### `skripte/regler.gd` und `szenen/regler.tscn` - neu

Die Szene: ein `Control` als Wurzel, darin die Schrift `Name`, ein dunkler `Balken` (800 mal 60) und darin die helle `Fuellung`. Die Szene wird zweimal in die Wand gesetzt, einmal fuer Musik, einmal fuer Effekte.

```gdscript
extends Control

@export var bus: String = "Effekte"
```
Ein Bus ist ein Tonkanal. Alle Toene, die durch denselben Bus laufen, lassen sich gemeinsam lauter und leiser stellen. Hier steht der Name des Busses, den dieser Regler stellt.

```gdscript
var zieht: bool = false
```
Wahr, solange Maus oder Finger den Balken festhaelt.

```gdscript
func _ready() -> void:
	$Name.text = bus
	zeigen(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus)))
```
Der Name des Busses steht als Schrift ueber dem Balken. Dann zeigt der Balken die Lautstaerke, die der Bus gerade hat. `AudioServer` ist die Tonanlage von Godot. `get_bus_index` sucht die Nummer des Busses zu seinem Namen, `get_bus_volume_linear` gibt seine Lautstaerke als Zahl von 0 (stumm) bis 1 (voll). Das ist noetig, weil die Szene nach einem Absturz neu geladen wird, die Tonanlage aber ihre Einstellung behaelt.

```gdscript
func _input(ereignis: InputEvent) -> void:
	if not is_visible_in_tree():
		return
```
Ist die Wand unsichtbar, tut der Regler nichts.

```gdscript
	if ereignis is InputEventMouseButton or ereignis is InputEventScreenTouch:
		zieht = ereignis.pressed and $Balken.get_global_rect().has_point(ereignis.position)
		if zieht:
			setzen(ereignis.position.x)
```
Bei Klick oder Tipp: `zieht` wird wahr, wenn gedrueckt wurde und die Stelle im Balken liegt. Beim Loslassen ist `pressed` falsch, also wird `zieht` falsch. Liegt die Stelle im Balken, springt der Regler sofort dorthin.

```gdscript
	if ereignis is InputEventMouseMotion or ereignis is InputEventScreenDrag:
		if zieht:
			setzen(ereignis.position.x)
```
Bewegt sich Maus oder Finger, waehrend der Balken gehalten wird, folgt der Regler.

```gdscript
func setzen(x: float) -> void:
	var wert: float = clampf((x - $Balken.global_position.x) / $Balken.size.x, 0.0, 1.0)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus), wert)
	zeigen(wert)
```
`x - $Balken.global_position.x` ist, wie weit die Stelle vom linken Rand des Balkens entfernt ist. Geteilt durch die Breite wird daraus eine Zahl von 0 (ganz links) bis 1 (ganz rechts). `clampf` haelt sie in diesen Grenzen, auch wenn der Finger ueber den Rand hinauszieht. Diese Zahl bekommt der Bus als Lautstaerke.

```gdscript
func zeigen(wert: float) -> void:
	$Balken/Fuellung.size.x = $Balken.size.x * wert
```
Die helle Fuellung wird so breit, wie der Wert sagt: bei 0,5 der halbe Balken.

### `default_bus_layout.tres` - neu

Die Datei legt die Busse des Spiels fest. Godot laedt sie von selbst, weil sie so heisst und im Hauptordner liegt. Darin stehen zwei neue Busse, `Musik` und `Effekte`, beide in voller Lautstaerke, beide senden weiter an den Hauptbus `Master`. Alle 16 Tonspieler in den Szenen haben die neue Zeile `bus = &"Effekte"` bekommen (die sechs Fliegen, das Hindernis, die Nadel und acht in `spiel.tscn`). Durch `Musik` laeuft noch nichts, die Musik kommt mit Abschnitt 11. Der Musik-Regler stellt bis dahin nichts Hoerbares.

### `skripte/nadel.gd` - geaendert in Abschnitt 13

```gdscript
var richtung: Vector2 = Vector2.UP
```
Neu. In diese Richtung fliegt die Nadel. Ohne weitere Angabe nach oben, wie bisher.

```gdscript
	if kanone != null:
		position.x = kanone.position.x
	position += richtung * tempo * delta
```
Vorher stand hier: `position.x = kanone.position.x` und `position.y -= tempo * delta`. Neu ist die Frage `if kanone != null`: Nur eine Nadel aus der Kanone bleibt ueber ihr. Eine Nadel aus der Totale hat keine Kanone und fliegt frei. Die zweite Zeile bewegt die Nadel in ihrer Richtung. Fuer `Vector2.UP` ist das dasselbe wie vorher, denn `Vector2.UP` ist (0, -1).

```gdscript
		if geflogen >= reichweite or kanone == null or not noch_eine_darueber():
```
Neu ist `or kanone == null`. Eine Nadel aus der Totale bleibt in der ersten Fliege stecken. Die Suche nach einer weiteren Fliege senkrecht darueber passt nur zum senkrechten Schuss.

In `szenen/nadel.tscn` steht am Wurzelknoten neu `groups=["nadeln"]`. Jede Nadel ist damit in der Gruppe `nadeln`, die die Einstellungsfliege durchsucht.

### `skripte/erzeuger.gd` - geaendert in Abschnitt 13

```gdscript
@export var schwarm_breite: float = 900.0
@export var schwarm_unten: float = 250.0
@export var schwarm_oben: float = 600.0
```
`schwarm_breite` war 500. Die beiden anderen sind neu: Der Schwarm fliegt 250 bis 600 Pixel ueber der Kanone. Vorher flog er 560 bis 750 darueber, das laege in der Totale ueber dem Bildrand (der liegt 672 ueber der Kanone).

```gdscript
@export var flucht_faktor: float = 3.0
```
Neu. Auf der Flucht ist der Schwarm dreimal so schnell wie sonst.

```gdscript
@export var loeschen_seitlich: float = 1800.0
```
War 1100. In der Totale sieht man 1675 Pixel zu jeder Seite. Mit 1100 waeren fliehende Fliegen mitten im Bild verschwunden.

Im Kommentar ueber `einflug_x` ist der Hinweis auf den alten Bildrand am Boden (847) gestrichen. Weg sind `rand_seitlich` und `rand_oben`. Sie haben den kuerzesten Weg zum Bildrand gemessen, das braucht die neue Flucht nicht mehr.

```gdscript
			fliege.position.y = kanone.position.y - randf_range(schwarm_unten, schwarm_oben)
```
In `_ready`: Der Schwarm nimmt seine eigenen Hoehen statt `einflug_unten` und `einflug_oben`.

```gdscript
func schwarm_aufloesen() -> void:
	if not schwarm:
		return
	schwarm = false
	for fliege in get_children():
		fliege.flucht = kanone.position.direction_to(fliege.position)
		fliege.tempo *= flucht_faktor
```
Neu geschrieben. Vorher flog jede Fliege zum naechsten Bildrand (links, rechts oder oben). Jetzt: `direction_to` gibt den Pfeil von der Kanone zur Fliege, mit der Laenge 1. Jede Fliege flieht also geradewegs von der Kanone weg, jede in ihre eigene Richtung. `tempo *= flucht_faktor` macht sie dreimal so schnell. Die Funktion hat keine Angabe in der Klammer mehr, weil sie nicht mehr am Signal `gefangen` haengt. Die Figur ruft sie direkt.

### `skripte/kanone.gd` - geaendert in Abschnitt 13

```gdscript
@export var joystick: Node2D
```
Neu. Der Joystick, im Inspector eingetragen.

```gdscript
	var richtung: float = Input.get_axis("links", "rechts") + joystick.richtung.x
	richtung = clampf(richtung, -1.0, 1.0)
```
In `fahren`. Zu den Pfeiltasten kommt der Ausschlag des Joysticks nach links oder rechts. `joystick.richtung.x` ist der waagrechte Teil seines Pfeils, von -1 bis 1. Hoch und runter am Joystick bewirkt im Spiel nichts. `clampf` sorgt dafuer, dass Taste und Joystick zusammen nicht schneller sind als eins von beiden.

### `skripte/spiel.gd` - geaendert in Abschnitt 13

```gdscript
@export var zoom_totale: float = 0.43
@export var versatz_totale: float = 584.0
```
Ersetzen `zoom_boden` (0,85) und `versatz_boden` (-447). Am Boden gibt es jetzt nur noch die Totale. 584 schiebt die Bildmitte 584 Pixel unter die Kanone. Die Rechnung: Die Fuesse stehen 1212 unter der Kanone und sollen auf drei Vierteln der Bildhoehe liegen, also ein Viertel des Bildes (2512 / 4 = 628) unter der Mitte. 1212 - 628 = 584.

```gdscript
	$Kanone/Figur.spielstart.connect(erster_fang)
```
In `_ready`. Ersetzt die Zeile, die `gefangen` mit `schwarm_aufloesen` verbunden hat. Meldet die Figur den Spielstart, laeuft `erster_fang`.

```gdscript
	$Kanone/Kamera.zoom = Vector2.ONE * zoom_totale
	$Kanone/Kamera.offset.y = versatz_totale
	$Kanone/Arm.visible = false
	$Kanone/RechteHand.visible = false
	$Kanone.set_process(false)
	$Hindernisse.set_process(false)
```
In `_ready`. Die Kamera startet in der Totale. Die Kanone des Spiels und die rechte Hand mit der Leiste sind unsichtbar, man sieht stattdessen die Figur. `set_process(false)` schaltet das `_process` eines Knotens ab: Die Kanone faehrt und schiesst nicht, und es kommen keine Hindernisse, solange man in der Totale ist.

```gdscript
func losgehen() -> void:
	$Kanone/Figur.ausschalten()
	$Kanone/Arm.visible = true
	$Kanone/RechteHand.visible = true
	$Kanone.set_process(true)
	$Hindernisse.set_process(true)
```
Neu. Das Ende der Totale, genau das Gegenteil der Zeilen in `_ready`: Figur aus, Kanone und Hand sichtbar, Kanone und Hindernisse laufen.

```gdscript
func erster_fang(nadel: Node2D) -> void:
	losgehen()
	nadel.anker = $Kanone/Arm/Muendung
	$Kanone/Uebergabe.starten(nadel)
```
Neu. Wird von der Figur gerufen, mit der Nadel der ersten Fliege. Der Faden haengt ab jetzt an der Muendung der Kanone. Dann bekommt die Uebergabe die Nadel, genau wie bei jedem Treffer im Spiel: Sie sendet `gefangen`, man steigt, die Kamera zoomt heran, der Arm faehrt zur rechten Hand.

```gdscript
	losgehen()
	$Erzeuger.schwarm_aufloesen()
```
In `springen` (nur zum Testen). Wer mit einer Zifferntaste in eine Zone springt, ueberspringt die Totale.

```gdscript
		kamera_fahren(zoom_totale, versatz_totale, strecke / falltempo)
```
In `fliege_verlieren`. Faellt man auf 0, faehrt die Kamera waehrend des Falls zurueck in die Totale.

```gdscript
	$Kanone/Figur.visible = false
```
In `aufstehen`. Waehrend der Aufsteh-Animation ist die Figur unsichtbar, man sieht die drei Platzhalter-Bilder an ihrer Stelle.

```gdscript
	$Kanone/Figur.visible = true
```
In `aufstehen_abbrechen`. Kommt waehrend des Aufstehens doch noch eine Fliege an, ist die Figur wieder da.

Nach dem Aufstehen laedt `neustart` die Szene neu wie bisher. Weil die Szene jetzt in der Totale beginnt, steht man danach wieder auf der Wiese.

### `szenen/spiel.tscn` - geaendert in Abschnitt 13

- `Boden`: neu `scroll_offset = Vector2(0, 1212)`, das schiebt den ganzen Boden 1212 Pixel nach unten, an die Fuesse der Figur. `repeat_times = 4`, damit er auch in der breiten Totale bis an beide Raender reicht. Der `Streifen` ist jetzt 1300 hoch und gruen (die Wiese).
- `Hintergrund`: `repeat_times` 3 -> 6, aus demselben Grund.
- `Kanone`: neuer Eintrag `joystick`.
- `Kanone/Aufstehen`: `position` (-130, 717) und `scale` (3.5, 4.95). Die drei Platzhalter-Bilder sind 200 hoch, mal 4,95 sind das 990, so gross wie die Figur. Sie stehen an ihrer Stelle.
- Neu `Kanone/Figur` an (-130, 1212) mit `start_totale.gd`. Darin drei Rechtecke, gemessen von den Fuessen nach oben (nach oben ist minus): `Beine` 140 breit von 0 bis -470, `Rumpf` 300 breit von -470 bis -850, `Kopf` 132 mal 132 von -858 bis -990. Dazu `Schulter` (ein Node2D an (130, -812), der Drehpunkt des Arms) mit `Arm` (60 breit, 400 lang), `Faust`, `Koerper`, `Rohr` und dem Marker `Spitze` (540 ueber der Schulter, am Ende des Rohrs). `Faust`, `Koerper` und `Rohr` sind dieselben Rechtecke wie in `Kanone/Arm`, nur 400 Pixel hoeher, am Ende des Arms. Die Figur steht 130 links von der Kanone, damit ihre rechte Schulter genau unter der Kanone liegt.
- `Bedienung`: `TasteLinks`, `TasteRechts` und `TasteSchussLinks` sind weg. Neu `Joystick` an (170, 910) mit `joystick.gd`, darin die Bilder `Grund` und `Knopf`. Beide benutzen das helle 200er-Quadrat der Tasten: `Grund` mit `scale` 1.2 (240 Pixel, so breit wie der Weg des Knopfs von Rand zu Rand), `Knopf` mit `scale` 0.5 (100 Pixel). `TasteSchuss` sitzt jetzt ganz rechts (1230, 880).
- Neu `Einstellungsfliege` an (700, 1312) mit `einstellungsfliege.gd`: ein dunkles Quadrat mit der Schrift "Einst.", es sitzt in der Oberkante der Wiese.
- Neu `Einstellungen` (CanvasLayer, `layer = 2`, liegt also ueber den Tasten) mit `einstellungen.gd`. Darin `Wand` (gruen, zuerst unsichtbar) mit `Fliege` (dieselbe Fliege, so gross wie sie im Bild der Totale ist: 86 Pixel), `Titel`, den zwei Reglern `Musik` und `Effekte` und einem `Hinweis`.

### Was noch Platzhalter ist

- Die Figur, die Wiese, die Einstellungsfliege und die Wand sind graue und gruene Rechtecke. Die Bilder kommen mit Abschnitt 10.
- Fall und Aufprall haben noch keine eigenen Bilder. Die Figur faellt aufrecht, danach laufen die drei Aufsteh-Platzhalter.
- Die Schrift "Schuss" sieht man auch am PC (bekannt seit Abschnitt 8).

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS fuer alle neun Skripte.
- Probe mit Fenster, Eingaben nachgestellt, Bilder angesehen:
  - Totale: Fuesse im Bild bei y 810 von 1080 (drei Viertel), Kanonenspitze bei 229, der Schwarm zwischen 23 und 197.
  - Zielen: Schulter, Spitze und Maus auf einer Linie, Abweichung 0,14 Grad. Kippen: 20,0 Grad, nach dem Loslassen 0.
  - Einstellungsfliege angeschossen: Wand faehrt hoch. Klick bei einem Viertel des Balkens: Lautstaerke 0,25. Ziehen auf 0,6: 0,60. Finger auf dem Musik-Balken bis 0,8: 0,80. Klick auf die Fliege oben: Wand weg, Figur wieder dran. Kein Schuss, waehrend die Wand oben war.
  - Erster Treffer: nach 1 Sekunde 132 Pixel abgehoben, Figur schwankt, keine neue Fliege im Bild. Spielstart nach 2,1 bis 2,2 Sekunden. Danach Zoom 1, eine Fliege im Faecher, Hindernisse laufen.
  - Joystick nach rechts oben: Arm 45 Grad. Im Spiel 1 Sekunde nach rechts: Kanone 182 Pixel weiter, Hoehe unveraendert.
  - Absturz auf 0: Kamera wieder 0,43, Aufstehen, Szene neu geladen, Figur wieder aktiv.
- Handy-Probe (Chromium und WebKit, iPhone-Profil): Joystick dreht den Arm, die Schuss-Taste schiesst. Der erste Lauf meldete in WebKit einen Fehler: Die Probe kann dort den Joystick nicht halten, die Messflaeche lag darum an der falschen Stelle. Mit eigener Messflaeche fuer WebKit bestanden.
- Nicht angeschaut: wie sich Zielen, Einstieg und Zoom anfuehlen und ob der erste Fang zu schwer ist. Die Toene nicht angehoert. Am echten Handy nicht ausprobiert.

### Drei Fragen zur Selbstkontrolle

1. Warum zeigt die Kanonenspitze nicht mehr genau auf den Mauszeiger, wenn man die Figur mit den Pfeiltasten kippt? Welche Zeile muesste man aendern, damit sie es doch tut?
2. Woran erkennt die Nadel, dass sie aus der Totale kommt, und an welchen zwei Stellen in `nadel.gd` macht das einen Unterschied?
3. Warum zeigt der Regler nach einem Absturz noch die eingestellte Lautstaerke, obwohl die ganze Szene neu geladen wurde?

## Abschnitt 13, Nachtrag - zwei Marker fuer den Arm

Wozu: Wenn die Bilder kommen, muss der Arm genau an der Schulter des Koerpers sitzen und sich um die richtige Stelle drehen. Beides stellt man jetzt im Editor mit zwei Markern ein, ohne Zahlen im Code.

### `szenen/spiel.tscn` - geaendert

- Neu `Kanone/Figur/Schulterpunkt` (Marker2D) an (130, -812). Er liegt auf dem Koerper und sagt: Hier sitzt die Schulter.
- Neu `Kanone/Figur/Schulter/Armbild` (Node2D). Alles, was zum Arm gehoert, liegt jetzt darin: `Arm`, `Faust`, `Koerper`, `Rohr`, `Spitze`. Vorher lagen sie direkt in `Schulter`.
- Neu `Kanone/Figur/Schulter/Armbild/Drehpunkt` (Marker2D) an (0, 0). Er liegt auf dem Arm und sagt: Um diese Stelle dreht sich der Arm.

Mit dem Armbild verschiebt man im Editor nur noch die beiden Marker: `Schulterpunkt` auf die Schulter im Koerperbild, `Drehpunkt` auf das Schultergelenk im Armbild.

### `skripte/start_totale.gd` - geaendert

```gdscript
func _ready() -> void:
	$Schulter.position = $Schulterpunkt.position
	$Schulter/Armbild.position = -$Schulter/Armbild/Drehpunkt.position
```
Neu. `_ready` laeuft einmal beim Start. Erste Zeile: Der Knoten `Schulter`, der sich dreht, springt auf den `Schulterpunkt` des Koerpers. Zweite Zeile: Das Armbild wird um den Weg zum `Drehpunkt` zurueckgeschoben, darum das Minus. Liegt der `Drehpunkt` zum Beispiel 40 Pixel rechts im Armbild, rutscht das Armbild 40 Pixel nach links. Danach liegt der `Drehpunkt` genau auf dem Nullpunkt von `Schulter`, und um den Nullpunkt dreht Godot einen Knoten.

```gdscript
		nadel.position = $Schulter/Armbild/Spitze.global_position
		nadel.anker = $Schulter/Armbild/Spitze
```
In `schiessen`. Nur der Pfad ist laenger, weil `Spitze` jetzt im `Armbild` liegt.

Zu beachten: Damit man den Tausch gegen die Kanone des Spiels nach dem Einstieg nicht sieht, muss die Faust bei senkrechtem Arm genau auf der Kanone liegen. Mit den jetzigen Werten tut sie das (Schulterpunkt 812 ueber den Fuessen, Faust 400 ueber dem Drehpunkt, Figur 1212 unter der Kanone).

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Probe ohne Bildschirm: Mit den Markern an ihren Startwerten liegt die Spitze an derselben Stelle wie vorher. Drehpunkt um (40, 0) verschoben: Das Armbild liegt bei (-40, 0).

## Musik - Schleife, Ende im All, leise in der Totale, gedaempft in den Einstellungen

Was neu ist, in einem Absatz: Es gibt Musik. Ein Stueck laeuft in einer Endlosschleife. In der Totale ist es ganz leise, mit dem Spielstart wird es laut, nach einem Absturz auf 0 wieder leise. Bei "Im All!" setzt ein eigenes Ende ein und die Schleife verklingt. Solange die Wand mit den Einstellungen oben ist, klingt die Musik dumpf.

### Die zwei Tondateien

Geliefert wurden zwei Stuecke. Sie sind bis Sekunde 115,2 gleich, das zweite geht danach 51 Sekunden weiter und hat das Ende. Gemessen: Ein Schlag dauert 0,8 Sekunden, 115,2 Sekunden sind genau 144 Schlaege, also 36 Takte. Darum laesst sich das Stueck dort ohne Stolpern an den Anfang haengen.

Daraus sind zwei neue Dateien geschnitten, die gelieferten bleiben unveraendert:

- `assets/audio/musik/musik_schleife.ogg`: das erste Stueck von 0 bis 115,2 Sekunden.
- `assets/audio/musik/musik_ende.ogg`: das zweite Stueck ab 115,2 Sekunden bis zum Schluss (52,3 Sekunden).

In `musik_schleife.ogg.import` steht `loop=true`. Das sagt Godot: Am Ende der Datei geht es am Anfang weiter. Man stellt das im Editor im Reiter "Import" der Datei ein (Haken bei "Loop", dann "Reimport").

### `skripte/musik.gd` - neu

```gdscript
extends Node
```
Die Musik braucht keinen Platz im Bild, darum ein einfacher `Node`. Er hat zwei Kinder, beide `AudioStreamPlayer`: `Schleife` und `Ende`.

```gdscript
@export var laut_db: float = -12.0
@export var leise_db: float = -30.0
```
Die Lautstaerke im Spiel und in der Totale, in Dezibel. 0 waere die volle Lautstaerke der Datei. Jede 6 Dezibel weniger halbieren den Pegel etwa, -30 ist also sehr leise.

```gdscript
@export var blenddauer: float = 1.5
@export var ende_blenddauer: float = 0.5
```
So lange dauert der Wechsel zwischen leise und laut, und so schnell verklingt die Schleife, wenn das Ende einsetzt.

```gdscript
var blende: Tween = null
```
Der Wechsel der Lautstaerke, der gerade laeuft.

```gdscript
func _ready() -> void:
	$Schleife.volume_db = leise_db
	$Schleife.play()
```
Beim Start: leise stellen und abspielen. Das Spiel beginnt in der Totale.

```gdscript
func laut() -> void:
	blenden(laut_db)


func leise() -> void:
	blenden(leise_db)
```
Zwei kurze Funktionen mit sprechenden Namen. `spiel.gd` ruft sie auf.

```gdscript
func blenden(ziel_db: float) -> void:
	if blende != null:
		blende.kill()
	blende = create_tween()
	blende.tween_property($Schleife, "volume_db", ziel_db, blenddauer)
```
Laeuft noch ein Wechsel, wird er abgebrochen. Dann faehrt ein neuer Tween die Lautstaerke der Schleife in 1,5 Sekunden auf den Zielwert. Dasselbe Muster wie bei der Kamerafahrt in `spiel.gd`.

```gdscript
func ende_spielen() -> void:
	$Ende.volume_db = laut_db
	$Ende.play()
```
Das Ende spielt sofort, so laut wie die Musik im Spiel.

```gdscript
	if blende != null:
		blende.kill()
	blende = create_tween()
	blende.tween_property($Schleife, "volume_db", -60.0, ende_blenddauer)
	blende.tween_callback($Schleife.stop)
```
Gleichzeitig wird die Schleife in einer halben Sekunde auf -60 Dezibel gefahren, das ist unhoerbar, und danach angehalten. Fuer diese halbe Sekunde hoert man beide uebereinander. Das Ende setzt sofort ein, nicht erst am naechsten Takt.

### `default_bus_layout.tres` - geaendert

Der Bus `Musik` hat jetzt einen Effekt: `AudioEffectLowPassFilter` mit `cutoff_hz = 600.0`. Ein Tiefpass laesst nur die tiefen Toene durch, hier alles unter etwa 600 Hertz. Die Musik klingt damit dumpf, wie durch eine Wand. `bus/1/effect/0/enabled = false` heisst: Der Effekt ist beim Start aus.

### `skripte/einstellungen.gd` - geaendert

```gdscript
	musik_daempfen(true)
```
In `oeffnen`: Sobald die Wand hochfaehrt, ist der Daempfer an.

```gdscript
	musik_daempfen(false)
```
In `zu`: Ist die Wand wieder unten, ist er aus.

```gdscript
func musik_daempfen(an: bool) -> void:
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Musik"), 0, an)
```
Neu. `set_bus_effect_enabled` schaltet einen Effekt auf einem Bus ein oder aus. Die drei Angaben: die Nummer des Busses `Musik`, die Nummer des Effekts auf diesem Bus (0 ist der erste, es gibt nur den einen) und an oder aus.

```gdscript
func _exit_tree() -> void:
	musik_daempfen(false)
```
Neu. `_exit_tree` ruft Godot, wenn ein Knoten aus dem Spiel verschwindet, zum Beispiel beim Neustart der Szene. Der Daempfer gehoert zur Tonanlage und nicht zur Szene, er uebersteht einen Neustart. Wer bei offener Wand neu startet (Taste R), haette sonst fuer immer dumpfe Musik.

### `skripte/spiel.gd` - geaendert

```gdscript
	$Musik.laut()
```
In `losgehen`: Mit dem Spielstart wird die Musik laut.

```gdscript
		$Musik.leise()
```
In `fliege_verlieren`, im Zweig fuer den Absturz auf 0: Waehrend des Falls zurueck in die Totale wird sie wieder leise.

```gdscript
		$Musik.ende_spielen()
```
In `fliege_zaehlen`, beim Sieg: Das Ende setzt ein.

### `szenen/spiel.tscn` - geaendert

Neu der Knoten `Musik` mit `musik.gd` und den zwei Tonspielern `Schleife` und `Ende`. Beide haben `bus = &"Musik"`. Damit stellt der Regler "Musik" auf der Wand jetzt wirklich die Musik.

### Was man wissen muss

- Nach dem Aufstehen laedt die Szene neu, die Musik beginnt dann von vorn.
- Im Browser startet Ton erst nach dem ersten Klick oder Tipp. Bis dahin ist es still.
- Nach dem Ende im All bleibt es still.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Die gelieferten Dateien haben vor und nach dem Schneiden dieselbe Pruefsumme.
- Probe mit Fenster, Pegel auf dem Bus `Musik` gemessen: Totale -32,1 dB, im Spiel -14,4 dB (18 dB Unterschied, wie eingestellt). Mit Daempfer jeweils 1,5 dB weniger Spitze. Schleife: 1,6 Sekunden nach Sekunde 114,4 spielt sie weiter und steht bei 0,8. Im All: Schleife aus, Ende laeuft mit -14,4 dB. Nach dem Ende spielt nichts mehr.
- Nicht angehoert: ob der Uebergang der Schleife sauber klingt, ob leise und laut passen, wie dumpf der Daempfer wirkt, wie der Einsatz des Endes klingt.

### Drei Fragen zur Selbstkontrolle

1. Warum wird in der Totale die Lautstaerke des Tonspielers geaendert und nicht die des Busses `Musik`?
2. Was passiert, wenn man `_exit_tree` in `einstellungen.gd` loescht und bei offener Wand die Taste R drueckt?
3. Warum darf die Schleife genau 115,2 Sekunden lang sein und nicht 116?

## Abschnitt 13, Aenderung nach dem ersten Anspielen - Einstieg kurz, Kanone im rechten Arm

Was sich aendert: Nach dem ersten Treffer sah man die Figur zwei Sekunden lang schwanken. Das war zu lang. Jetzt nimmt sie nur noch in 0,3 Sekunden den Arm nach oben, dann steigt man sofort und das Bild zoomt heran. Und die Kanone sitzt jetzt im rechten Arm der Figur. Die Figur schaut uns an, ihr rechter Arm ist darum im Bild links.

### `skripte/start_totale.gd` - geaendert

```gdscript
@export var einstieg_dauer: float = 0.3
```
War 2.0. So lange braucht die Figur nach dem Treffer, um den Arm gerade nach oben zu nehmen.

Weg ist `@export var schwanken`. Die Figur schwankt nicht mehr.

```gdscript
	var ablauf: Tween = create_tween()
	ablauf.tween_property(kanone, "position:y", -abheben, einstieg_dauer)
	ablauf.parallel().tween_property(self, "rotation_degrees", 0.0, einstieg_dauer)
	ablauf.parallel().tween_property($Schulter, "rotation", 0.0, einstieg_dauer)
	ablauf.parallel().tween_property(nadel, "rotation", 0.0, einstieg_dauer)
	ablauf.tween_callback(sequenz_fertig)
```
In `erster_treffer`. Vorher waren es vier Stuecke nacheinander (abheben, links, rechts, aufrichten). Jetzt ist es ein einziges Stueck von 0,3 Sekunden, in dem vier Dinge gleichzeitig laufen (`parallel()`): Die Figur hebt eine Kopfhoehe ab, sie richtet sich auf, falls sie gekippt war, der Arm dreht nach oben, die Nadel mit der Fliege dreht sich aufrecht. Danach kommt wie bisher `sequenz_fertig`, das Spiel beginnt, man steigt um die Flugkraft der Fliege und die Kamera zoomt in 0,8 Sekunden heran.

Die 0,3 Sekunden bleiben, weil der Arm erst gerade stehen muss. Sonst saehe man, wie der schraege Arm verschwindet und die Kanone des Spiels senkrecht auftaucht.

### `szenen/spiel.tscn` - geaendert

- `Kanone/Figur`: `position` (130, 1212) statt (-130, 1212). Die Figur steht jetzt rechts neben der Kanone.
- `Kanone/Figur/Schulterpunkt` und `Schulter`: (-130, -812) statt (130, -812). Die Schulter liegt auf der linken Seite des Rumpfs im Bild, das ist die rechte Schulter der Figur. 130 nach rechts und 130 zurueck nach links: Die Faust liegt weiter genau auf der Kanone.
- `Kanone/Aufstehen`: `position` (130, 717), damit die Aufsteh-Bilder dort stehen, wo die Figur steht.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS.
- Probe mit Fenster: vom Treffer bis zum Spielstart 0,30 Sekunden (vorher 2,1 bis 2,2), bis der Zoom fertig ist 1,10 Sekunden. Kanonenspitze weiter 140 ueber der Kanone. Im Bild: Arm links vom Rumpf.
- Nicht angeschaut: ob sich der Einstieg jetzt richtig anfuehlt.

## Spass-Test, Runde 20 - Teleport-Fliege entkommt wirklich, schnelle Fliege wendet schneller

Was sich aendert: Die Teleport-Fliege flackert 0,2 Sekunden, bevor sie springt. In dieser Zeit konnte man sie noch treffen. Jetzt fliegt die Nadel waehrenddessen durch sie hindurch, das Flackern ist nur noch zum Ansehen. Sie gibt 6 statt 7 Flugkraft, damit die letzte Zone laenger dauert. Die schnelle Fliege fliegt ihre Schleife an der Wende doppelt so schnell.

### `skripte/fliege.gd` - geaendert

```gdscript
var entkommt: bool = false
```
Neu, bei allen Fliegen vorhanden. Wahr heisst: Die Nadel kann diese Fliege gerade nicht treffen. Nur die Teleport-Fliege setzt es auf wahr. Es steht im gemeinsamen Skript, weil die Nadel jede Fliege danach fragt.

### `skripte/nadel.gd` - geaendert

```gdscript
	if kandidat.gefangen or kandidat.entkommt:
		return false
```
In `trifft`. Vorher stand dort nur `kandidat.gefangen`. Eine Fliege, die gerade entkommt, zaehlt fuer die Nadel nicht, genau wie eine schon gefangene. Die Nadel fliegt weiter.

### `skripte/fliege_teleport.gd` - geaendert

```gdscript
		flackert_noch = flacker_zeit
		entkommt = true
```
In `fliegen`, an der Stelle, an der die Kanone nah genug ist und das Flackern beginnt. Die zweite Zeile ist neu: Mit dem ersten Flackern ist sie schon entkommen.

```gdscript
	modulate.a = 1.0
	entkommt = false
	uebrig -= 1
```
In `springen`. Die mittlere Zeile ist neu: Nach dem Sprung, an der neuen Stelle, kann man sie wieder treffen. Fangen kann man sie also, wenn die Kanone weiter als 120 Pixel seitlich steht (das geht nur mit einer Nadel, die schon fliegt) oder in den 2,5 Sekunden Erholung nach dem dritten Sprung.

In `szenen/fliege_teleport.tscn`: `flugkraft = 6` statt 7.

### `skripte/fliege_schnell.gd` - geaendert

```gdscript
@export var faktor_schleife: float = 2.0
```
Neu. So viel schneller als ihr einfaches Tempo fliegt sie die Schleife. Bisher flog sie die Schleife mit dem einfachen Tempo, das entspricht einer 1.

```gdscript
	position += Vector2.from_angle(winkel) * tempo * faktor_schleife * delta
	var schritt: float = tempo * faktor_schleife / schleife * delta
```
In `fliegen`, im Teil fuer die Schleife. In beiden Zeilen ist `* faktor_schleife` neu. Die erste bewegt die Fliege, die zweite rechnet, wie weit sie in diesem Bild lenkt. Beide muessen zusammen schneller werden, sonst wuerde der Kreis groesser statt schneller. Die Schleife bleibt gleich gross (Radius 60), sie dauert nur halb so lang. Die Wende ist die Stelle, an der man die schnelle Fliege am leichtesten erwischt, weil sie dort lange in einer Spalte bleibt.

### So wurde es angeschaut

- Verify PASS, Schnellcheck PASS fuer die vier Skripte.
- Probe ohne Bildschirm: Teleport-Fliege ruhig: Nadel an ihrer Stelle trifft. Kanone unter ihr, sie flackert: `entkommt` wahr, Nadel trifft nicht. Nach dem Sprung: trifft wieder, zwei Spruenge uebrig. Flugkraft 6.
- Schnelle Fliege mit Tempo 560: eine Schleife dauert 24 Bilder, das sind 0,4 Sekunden (vorher gerechnet 0,79). Danach liegt sie wieder genau auf ihrer Hoehe.
- Nicht angeschaut: ob die beiden jetzt schwer genug sind.

## Abschnitt 10, erster Teil - Riffelpappe, Wiese und drei Fliegen als Bilder (ohne Forscher)

Die grauen Flaechen werden zum ersten Mal durch Bilder ersetzt. Der Forscher bleibt noch grau. Geaendert in Abschnitt 10: `zone.gd` und `zonen.gd` aus Abschnitt 9, `spiel.tscn`, drei Fliegenszenen aus Abschnitt 3 und 9.

### Die Bilder

- `assets/hintergrund/riffel/riffel-1-blau.png` bis `riffel-8-fast-schwarz.png`: deine Riffelpappe (`geriffelt.png`) achtmal umgefaerbt, in dieser Reihenfolge von unten nach oben: blau, gelb, creme, weiss, gruen (ein helles Alien-Gruen, fast Neon, aber gedaempft), indigo, nachtblau, fast schwarz. Je zwei gehoeren zu einer Zone. Die beiden hellsten (Creme, Weiss) bilden zusammen die helle Zone, Das Gruen fuehrt danach zu den dunklen Weltall-Farben hin (Helligkeit 78, Rillen-Streuung 12, Buntheit 75, Z153). Blau hat Kontrast und Buntheit des Grases (gemessen im Farbraum LAB wie `boden2.png`: Streuung der Helligkeit 18, Buntheit 55) bei der Helligkeit 68 (Z13). Gelb hat schwaechere Rillen (Streuung 10), weil es sonst sticht. Creme ist sehr hell (88) und kaum bunt, Weiss ist ganz ohne Farbe (Helligkeit 93, Rillen-Streuung 9), die drei Weltall-Pappen werden immer dunkler bis 10. Die dunklen Rillen sind auf halben Abstand zur Mitte geholt (Z42). An jedem Rand sind 4 Pixel abgeschnitten, dort hatte das Foto eine helle Linie.
- `assets/hintergrund/wiese.png`: `boden2.png` zweimal nebeneinander, die rechte Haelfte gespiegelt. Aus demselben Grund: Die Wiese wiederholt sich seitlich ohne sichtbare Naht.
- Die Fliegen nutzen `fliege-1.png`, `fliege-fuehler-gruen.png` und `fliege-ruessel-orange.png` unveraendert.

### `skripte/zone.gd` - geaendert

Die Zeilen `farbe` (mit ihrem Kommentar) sind weg. Die Zone toent den Hintergrund nicht mehr, das macht jetzt `hintergrund.gd`. Die Zonen bestimmen weiter, welche Fliegen kommen.

### `skripte/zonen.gd` - geaendert

Weg sind `@export var hintergrund: Node2D` (mit Kommentar) und in `_process` die Zeile `hintergrund.modulate = zone.farbe`. Grund wie oben: Die Farbe haengt nicht mehr an der Zone, sondern an der Hoehe, alle 10 Flugkraft eine neue (Z51). So bleibt offen, wie viele Zonen es am Ende gibt.

### `skripte/hintergrund.gd` - neu

```gdscript
extends CanvasLayer
```
Das Skript haengt am Knoten `Hintergrund`, einer `CanvasLayer`, und kann darum alles, was eine `CanvasLayer` kann.

```gdscript
@export var kanone: Node2D
```
Die Kanone. Ihre Hoehe entscheidet, welche Pappe zu sehen ist.

```gdscript
@export var bilder: Array[Texture2D] = []
```
Die Pappen, von unten nach oben. `Array[Texture2D]` ist eine Liste, in der nur Bilder stehen duerfen. Im Inspector kann man Bilder hinzufuegen, tauschen oder umsortieren.

```gdscript
@export var flugkraft_je_bild: float = 10.0
```
Nach so viel Flugkraft Hoehe kommt die naechste Pappe. Im Skript steht 10, in der Szene ist es auf 12,5 gestellt: 8 Pappen mal 12,5 ergibt 100, das Ziel. Bei vier Zonen (ab 0, 25, 50, 75) gehoeren so genau zwei Pappen zu jeder Zone.

```gdscript
@export var uebergang: float = 1.8
```
So viele Flugkraft vor dem Wechsel beginnt die naechste Pappe einzublenden. 1,8 Flugkraft sind 540 Pixel Steigen (1,8 x 300), ein halber Bildschirm: Der Wechsel ist vorbei, bevor man einen halben Bildschirm hochgeflogen ist (dein Wunsch, Z171; vorher 4). Groesser heisst: laengerer, weicherer Uebergang.

```gdscript
func _process(_delta: float) -> void:
	var hoehe: float = -kanone.position.y / get_parent().hoehe_je_flugkraft
```
Jedes Bild: Wie hoch ist die Kanone, in Flugkraft gerechnet? Nach oben ist `y` in Godot negativ, darum das Minus. `get_parent()` ist der Knoten `Spiel`, dort steht, wie viele Pixel eine Flugkraft hoch ist (300). Dieselbe Rechnung steht in `zonen.gd`.

```gdscript
	var nummer: int = int(hoehe / flugkraft_je_bild)
```
Die wievielte Pappe ist dran? Mit 12,5: Bei Hoehe 0 bis unter 12,5 kommt 0 heraus, bei 12,5 bis unter 25 kommt 1 heraus, und so weiter. `int(...)` schneidet die Nachkommastellen ab.

```gdscript
	nummer = clampi(nummer, 0, bilder.size() - 1)
```
`clampi` haelt die Zahl zwischen 0 und der letzten Stelle der Liste. Ueber 100 bleibt es bei der letzten Pappe, und beim Wackeln unter dem Boden (Hoehe knapp unter 0) bei der ersten. Ohne diese Zeile gaebe es einen Fehler, wenn die Nummer ausserhalb der Liste liegt.

```gdscript
	var naechste: int = mini(nummer + 1, bilder.size() - 1)
```
Die Nummer der Pappe, die als naechste kommt. `mini` nimmt die kleinere von zwei ganzen Zahlen: Bei der letzten Pappe gibt es keine naechste, dann bleibt es die letzte.

```gdscript
	$Pappe.texture = bilder[nummer]
	$Naechste.texture = bilder[naechste]
```
Der Bild-Knoten `Pappe` bekommt die Pappe mit dieser Nummer, der Bild-Knoten `Naechste` (er liegt genau darueber) die folgende. Die Liste zaehlt ab 0, `bilder[0]` ist also Blau.

```gdscript
	var schon_geflogen: float = hoehe - nummer * flugkraft_je_bild
```
Wie weit die Kanone schon in den Abschnitt der jetzigen Pappe hineingeflogen ist, in Flugkraft. Am Anfang des Abschnitts 0, kurz vor dem Wechsel fast 12,5.

```gdscript
	var beginn: float = flugkraft_je_bild - uebergang
```
Ab hier beginnt die Ueberblendung: 12,5 - 1,8 = 10,7 Flugkraft in den Abschnitt hinein.

```gdscript
	$Naechste.modulate.a = clampf((schon_geflogen - beginn) / uebergang, 0.0, 1.0)
```
`modulate.a` ist die Deckkraft: 0 ist unsichtbar, 1 ist voll da. Vor dem Beginn kommt etwas unter 0 heraus, `clampf` macht 0 daraus: Man sieht nur die jetzige Pappe. Zwischen 10,7 und 12,5 waechst der Wert gleichmaessig von 0 bis 1, die naechste Pappe wird also langsam sichtbar. Weil alle Pappen aus demselben Foto gefaerbt sind und genau uebereinanderliegen, bleibt das Muster stehen, nur die Farbe fliesst. Bei 12,5 springt `nummer` eins weiter: Jetzt ist die naechste Pappe unten und voll sichtbar, die obere wieder unsichtbar. Man sieht keinen Sprung, weil vorher und nachher dieselbe Farbe zu sehen ist.

### `szenen/spiel.tscn` - geaendert

- **Hintergrund:** Vorher ein `Parallax2D` mit `Feld1` und `Feld2` (das graue Schachbrett), das sich wiederholte und beim Steigen halb so schnell mitlief. Jetzt eine `CanvasLayer` (eine eigene Zeichenebene, die nicht mit der Kamera mitfaehrt) mit `layer = -1`, also hinter allem anderen. Sie traegt `hintergrund.gd`, `kanone` zeigt auf `../Kanone`, `bilder` enthaelt die acht Pappen, `flugkraft_je_bild = 12.5`. Darin `Pappe` und darueber `Naechste`, zwei gleiche `TextureRect` (ein Kasten, der ein Bild zeigt), am Anfang mit der blauen und der gelben Pappe. `Naechste` hat `modulate = Color(1, 1, 1, 0)`, ist also am Anfang unsichtbar. Die vier `anchor`-Zeilen (`anchors_preset = 15`) spannen den Kasten ueber den ganzen Bildschirm. `expand_mode = 1` erlaubt dem Kasten, groesser zu sein als das Bild; ohne `stretch_mode` wird das Bild auf die Kastengroesse gezogen. So deckt ein einziges Bild den Hintergrund ab, nichts wiederholt sich (dein Wunsch). Folge: Die Pappe steht still. Dass man steigt, sieht man an Fliegen, Hindernissen und am Farbwechsel. `mouse_filter = 2`: Der Kasten nimmt keine Klicks weg.
- **Boden:** `Streifen` (der gruene Kasten) ist weg. Neu ist `Wiese`, ein `Sprite2D` mit `wiese.png`, 5,23-fach vergroessert (`scale`). Warum 5,23: In der Totale ist die Kamera auf 0,43 gezoomt, 5,23 x 0,43 = 2,25. Auf dem Bildschirm ist die Wiese dann genau so gross wie auf der Wand in den Einstellungen (dort 2,25-fach), und beim Hochfahren der Wand springt nichts. `position = (0, -429)`: Im Bild beginnt das Gras 82 Pixel unter dem oberen Rand, 82 x 5,23 = 429. So stehen die Halme oben ueber der Linie, auf der die Figur steht. `repeat_size = (6694, 0)`: Bildbreite 1280 x 5,23.
- **Zonen:** Die Zeile `hintergrund = NodePath("../Hintergrund")` ist weg, ebenso die `farbe`-Zeilen der Zonen Scheue, Koeder und Boss.
- **Wand (Einstellungen):** Die Farbe ist jetzt durchsichtig (`Color(0, 0, 0, 0)`), die Wand selbst zeigt nichts mehr. Neu als erstes Kind: `Wiese`, ein `TextureRect` (ein Bild-Knoten fuer Bedienflaechen) mit `wiese.png`, 2,25-fach (`scale = (2.25, 2.25)`). Der Kasten ist 640 breit, also nur die linke, ungespiegelte Haelfte des Bilds; 640 x 2,25 = 1440, genau die Bildschirmbreite. Er ist 640 hoch, 640 x 2,25 = 1440, das reicht ueber die 1080 des Bildschirms hinaus. `offset_top = -184.5`: Das Gras beginnt im Bild bei 82, mal 2,25. Die Halme stehen also ueber der Oberkante der Wand, und die Kante liegt da, wo in der Totale die Wiese anfaengt. `stretch_mode = 1` heisst Kacheln: Das Bild wird in Originalgroesse gezeigt und nicht verzerrt. `mouse_filter = 2`: Das Bild nimmt keine Klicks weg, der Klick auf die Fliege oben an der Kante kommt weiter an. Weil es das erste Kind ist, wird es zuerst gezeichnet und liegt hinter Titel, Reglern und Fliege.

- **Schrift:** Die Beschriftungen ueber dem Spiel (`Bedienung/Zone`, `Bedienung/TestHinweis`, `Bedienung/Sieg`, `Bedienung/Absturz` und `Bedienung/TasteSchuss/Wort`) bekommen je zwei Zeilen: `theme_override_colors/font_outline_color = Color(0, 0, 0, 1)` setzt die Farbe der Kontur auf Schwarz, `theme_override_constants/outline_size = 8` macht sie 8 Pixel dick. `theme_override` heisst: nur fuer diesen Knoten, statt der allgemeinen Einstellung. So bleibt die weisse Schrift auch auf den hellen Pappen lesbar.

### `szenen/fliege_normal.tscn`, `fliege_schnell.tscn`, `fliege_scheu.tscn` - geaendert

- `Fluegel`, `Koerper` und `Art` bekommen `visible = false`. Sie bleiben in der Szene, nur unsichtbar. So muss kein Skript umgebaut werden, und man kann sie zum Vergleichen wieder einschalten.
- Neu: `Bild`, ein `Sprite2D` mit dem Fliegenbild. Normal: `fliege-1.png`, 0,068-fach. Schnell: `fliege-fuehler-gruen.png`, 0,25-fach. Scheu: `fliege-ruessel-orange.png`, 0,22-fach. Die Faktoren machen jede Fliege etwa 130 Pixel breit, ungefaehr so gross wie das graue Quadrat (100 Pixel), das weiter fuer den Treffer zaehlt.

### So wurde es angeschaut

- Schnellcheck PASS fuer `hintergrund.gd`, `zone.gd` und `zonen.gd`, Verify PASS.
- Bildschirmfotos aus dem laufenden Spiel (Probe ausserhalb des Spielordners): Totale mit blauer Pappe und Wiese, Wand oben mit den Grasreihen, Hoehen 1, 10, 30, 55 und 80. Erste Fassung zeigte Kanten zwischen den Pappe-Kacheln, eine Naht in der Wiese und unten an der Wand einen Streifen ohne Gras, zweite Fassung eine helle Linie in der Pappe und eine gespiegelte Stelle auf der Wand. Darum die beschnittenen Bilder und die Wand mit nur der ungespiegelten Haelfte. Danach (auf deinen Wunsch) die Pappe als ein einziges, bildschirmfuellendes Bild statt Kacheln, heller, mit weicheren Rillen und acht Farben nach Hoehe. Bildschirmfotos bei Hoehe 5, 18, 30, 43, 55, 68, 80, 93: jede zeigt die erwartete Pappe. Gesehen: Auf Creme und Weiss war die weisse Schrift (Zone, Schuss) kaum lesbar, darum die dunkle Kontur. Mit Kontur auf Weiss lesbar (Bildschirmfoto bei Hoehe 43).
- Nicht angeschaut: Stil und Wirkung (das entscheidest du), am Handy.

### Drei Fragen zur Selbstkontrolle

1. Warum ist die Wiese im Spiel 5,23-fach vergroessert und auf der Wand nur 2,25-fach?
2. Welche Pappe ist bei Flugkraft 37 zu sehen, und wie stark ist bei Flugkraft 11 die naechste schon eingeblendet?
3. Warum werden `Koerper` und `Fluegel` nur unsichtbar gemacht und nicht geloescht?

## Abschnitt 10, zweiter Teil - deine Fliegenbilder, Heuschrecke und Stechfliege

Deine Zuordnung: Normal = `insekt-bleistift-skizze.png`, Schnell = `fliege-skizze.png`, Scheu = `fliege-ohne-fluegel.png`, Koeder = `fliege-fuehler-gruen.png`, Teleport = `fliege-1.png`, Boss = `bockkaefer-skizze.png`. Neu: Heuschrecke = `heuschrecke-skizze.png`, Stechfliege = `fliege-ruessel-orange.png`. Deine Antworten: Arm = der Arm des Forschers (Z12), der Stich tut nichts, nur Gag (Z21), die Heuschrecke kann man fangen (Z31).

### Die Bilder

`assets/fliegen/spiel/` enthaelt Kopien deiner Bilder, auf das Bild selbst zugeschnitten (der durchsichtige Rand ist weg, damit die Mitte des Bilds die Mitte der Fliege ist) und hoechstens 600 Pixel breit. Deine Originale in `assets/fliegen/` bleiben unveraendert. Die Bleistiftskizze ist im Original 5729 Pixel breit und 60 MB gross, die Kopie 600 Pixel.

### Die sieben Fliegenszenen - geaendert bzw. neu

In jeder Szene zeigt `Bild` (ein `Sprite2D`) das neue Bild. `scale` macht es im Spiel etwa so breit: Normal 140, Schnell 130, Scheu 130, Koeder 120, Teleport 140, Boss 340, Heuschrecke 140 Pixel. In `fliege_koeder.tscn`, `fliege_teleport.tscn` und `fliege_boss.tscn` werden `Fluegel`, `Koerper` und `Art` unsichtbar (`visible = false`), wie vorher bei den drei anderen. Der `Schimmer` der Teleport-Fliege bleibt. Die Bildzeile (`ext_resource`) muss in einer Szene vor den `sub_resource`-Zeilen stehen, sonst kann Godot die Datei nicht lesen (so entstand ein FAIL beim ersten Verify, danach PASS).

`szenen/fliege_heuschrecke.tscn` ist eine Kopie von `fliege_schnell.tscn` mit dem Heuschrecken-Skript, dem Heuschrecken-Bild und `flugkraft = 5` (die schnelle gibt 4; die Heuschrecke ist schwerer zu treffen).

### `skripte/fliege_heuschrecke.gd` - neu

```gdscript
extends "res://skripte/fliege.gd"
```
Baut auf dem Gemeinsamen aller Fliegen auf, wie die anderen Arten. Treffen, Fangen und Fliehen kommen von dort, hier steht nur die Flugweise.

```gdscript
@export var sprungweite: float = 360.0
@export var sprungdauer: float = 0.2
@export var bogen: float = 60.0
@export var pause: float = 1.0
@export var wippen: float = 8.0
@export var strecke: float = 400.0
```
Die Werte zum Einstellen: Ein Sprung geht 360 Pixel weit, zwei Spruenge sind ein halber Bildschirm (1440 / 2). Er dauert 0,2 Sekunden, das sind 1800 Pixel pro Sekunde, viel schneller als die schnelle Fliege (hoechstens 1440 auf dem geraden Stueck). Der Sprung ist ein Bogen, in der Mitte 60 Pixel hoch. Danach schwebt sie 1 Sekunde und wippt 8 Pixel auf und ab. Weiter als 400 Pixel von ihrer Mitte springt sie nicht, sonst dreht sie um.

```gdscript
var springt: bool = false
var sprung_nummer: int = 0
var uhr: float = 0.0
var start_x: float = 0.0
```
Was sie sich merkt: ob sie gerade springt, der wievielte Sprung es ist (1 oder 2), eine Uhr fuer Sprung oder Pause, und wo der Sprung angefangen hat.

```gdscript
func fliegen(delta: float) -> void:
	uhr += delta
```
`fliegen` wird von `fliege.gd` in jedem Bild aufgerufen, solange die Fliege frei ist. Die Uhr laeuft weiter.

```gdscript
	if springt:
		var anteil: float = minf(uhr / sprungdauer, 1.0)
```
Wie weit der Sprung schon ist: 0 am Anfang, 1 am Ende. `minf` sorgt dafuer, dass es nie ueber 1 geht.

```gdscript
		position.x = start_x + richtung * sprungweite * anteil
		position.y = grund_y - sin(PI * anteil) * bogen
```
Zur Seite geht es gleichmaessig. Nach oben geht es mit einem Sinus: `sin(PI * anteil)` ist am Anfang 0, in der Mitte 1 und am Ende wieder 0. Das ergibt den Bogen. Minus, weil oben in Godot kleinere y-Werte hat.

```gdscript
		if anteil >= 1.0:
			if sprung_nummer < 2:
				sprung_beginnen()
			else:
				springt = false
				uhr = 0.0
		return
```
Ist der Sprung fertig: Nach dem ersten kommt gleich der zweite, nach dem zweiten beginnt die Pause (die Uhr faengt neu an). `return` beendet die Funktion, der Rest gilt nur fuer die Pause.

```gdscript
	position.y = grund_y + sin(uhr * TAU) * wippen
```
In der Pause wippt sie auf und ab. `TAU` ist ein ganzer Kreis: Einmal hoch und runter dauert genau eine Sekunde.

```gdscript
	if uhr >= pause:
		if absf(position.x + richtung * sprungweite * 2.0 - mitte_x) > strecke:
			richtung = -richtung
		sprung_nummer = 0
		sprung_beginnen()
```
Ist die Pause vorbei, springt sie wieder. Vorher prueft sie: Wuerde sie nach den zwei Spruengen weiter als `strecke` von ihrer Mitte landen? Dann dreht sie die Richtung um. So bleibt sie in der Naehe.

```gdscript
func sprung_beginnen() -> void:
	springt = true
	sprung_nummer += 1
	uhr = 0.0
	start_x = position.x
	$Bild.flip_h = richtung < 0.0
```
Ein Sprung faengt an: Nummer eins weiter, Uhr auf 0, Startpunkt merken. `flip_h` spiegelt das Bild, wenn sie nach links springt, damit sie in Sprungrichtung schaut. Gespiegelt wird nur das Bild, nicht die ganze Fliege, weil `hindernis.gd` mit der Groesse der Fliege rechnet und eine negative Groesse dort falsch waere.

### `skripte/stechfliege.gd` - neu

Haengt an `szenen/stechfliege.tscn`. Die Szene ist nicht in der Gruppe `fliegen`, darum findet die Nadel sie nicht: Man kann sie nicht treffen.

```gdscript
@export var flugzeit: float = 0.4
@export var sitzzeit: float = 0.8
@export var sitz_drehung: float = PI / 2.0
@export var anflug_von: Vector2 = Vector2(-600.0, -900.0)
@export var abflug_nach: Vector2 = Vector2(600.0, -900.0)
@export var ausholen: float = 300.0
@export var stich_szene: PackedScene
@export var stich_dauer: float = 3.0
```
Anflug und Abflug dauern je 0,4 Sekunden (aehnlich schnell wie die Heuschrecke), sie sitzt 0,8 Sekunden. Zum Sitzen dreht sie sich um eine Vierteldrehung (`PI / 2`), also hochkant. Schaut sie dabei falsch herum, stellt man `-PI / 2` ein. Sie kommt von 600 links und 900 ueber der Stelle (also von oben) und fliegt nach rechts oben weg. Der Bogen holt 300 Pixel zur Seite aus. Der rote Punkt verblasst in 3 Sekunden.

```gdscript
var ziel: Vector2 = Vector2.ZERO
var bogen_start: Vector2 = Vector2.ZERO
var bogen_ende: Vector2 = Vector2.ZERO
var bogen_mitte: Vector2 = Vector2.ZERO
```
`ziel` ist die Stelle auf dem Arm, die setzt der Stecher. Die drei anderen beschreiben den Bogen, der gerade geflogen wird.

```gdscript
func _ready() -> void:
	position = ziel + anflug_von
	bogen_setzen(position, ziel, -ausholen)
```
Beim Start steht sie oben links und legt den Bogen bis zur Stelle auf dem Arm fest.

```gdscript
	var ablauf: Tween = create_tween()
	ablauf.tween_method(bogen_fliegen, 0.0, 1.0, flugzeit)
	ablauf.tween_property(self, "rotation", sitz_drehung, 0.15)
	ablauf.tween_callback(stechen)
	ablauf.tween_interval(sitzzeit)
	ablauf.tween_property(self, "rotation", 0.0, 0.15)
	ablauf.tween_callback(abflug_vorbereiten)
	ablauf.tween_method(bogen_fliegen, 0.0, 1.0, flugzeit)
	ablauf.tween_callback(queue_free)
```
Der ganze Ablauf als ein Tween, Schritt fuer Schritt nacheinander: `tween_method` ruft `bogen_fliegen` mit einer Zahl auf, die in 0,4 Sekunden von 0 auf 1 waechst (der Anflug). Dann dreht sie sich in 0,15 Sekunden hochkant, sticht, wartet (`tween_interval`), dreht sich zurueck, legt den Bogen fuer den Abflug fest, fliegt ihn, und loescht sich zum Schluss selbst (`queue_free`).

```gdscript
func bogen_setzen(von: Vector2, nach: Vector2, seite: float) -> void:
	bogen_start = von
	bogen_ende = nach
	bogen_mitte = (von + nach) / 2.0 + Vector2(seite, 0.0)
```
Ein Bogen hat einen Anfang, ein Ende und eine Mitte, die zur Seite verschoben ist. Laege die Mitte genau zwischen Anfang und Ende, waere es eine gerade Linie.

```gdscript
func bogen_fliegen(anteil: float) -> void:
	var erstes: Vector2 = bogen_start.lerp(bogen_mitte, anteil)
	var zweites: Vector2 = bogen_mitte.lerp(bogen_ende, anteil)
	position = erstes.lerp(zweites, anteil)
```
`lerp` sucht einen Punkt zwischen zwei Punkten: bei 0 der erste, bei 1 der zweite, bei 0,5 die Mitte. Hier zweimal hintereinander: ein Punkt auf der Strecke Anfang-Mitte, einer auf Mitte-Ende, und dazwischen noch einmal. Das ergibt eine gleichmaessige Kurve (eine Bezier-Kurve), die bei Anfang und Ende genau ankommt und zur Mitte hin ausholt.

```gdscript
func stechen() -> void:
	var stich: Node2D = stich_szene.instantiate()
	stich.position = ziel
	get_parent().add_child(stich)
```
Der rote Punkt wird an die Stelle gesetzt, an der sie sitzt. Er haengt an der Kanone (dem Elternknoten der Fliege), so faehrt er mit dem Arm mit.

```gdscript
	var verblassen: Tween = stich.create_tween()
	verblassen.tween_property(stich, "modulate:a", 0.0, stich_dauer)
	verblassen.tween_callback(stich.queue_free)
```
Der Punkt verblasst in 3 Sekunden und loescht sich dann. Der Tween gehoert dem Punkt, nicht der Fliege: Die Fliege ist laengst weg, wenn der Punkt verblasst ist.

```gdscript
func abflug_vorbereiten() -> void:
	bogen_setzen(ziel, ziel + abflug_nach, ausholen)
```
Der Bogen fuer den Abflug: von der Stelle auf dem Arm nach rechts oben, zur anderen Seite ausgeholt.

### `szenen/stich.tscn` - neu

Der rote Punkt: ein `Sprite2D` mit einem runden Farbverlauf (`GradientTexture2D`, `fill = 1` heisst rund), innen rot, aussen durchsichtig, 28 Pixel gross. Platzhalter, bis dein PNG kommt: dann nur `texture` tauschen.

### `skripte/stecher.gd` - neu

```gdscript
@export var stechfliege_szene: PackedScene
@export var kanone: Node2D
@export var zonen: Node
@export var zone: Node
@export var stichstelle: Control
@export var abstand_kurz: float = 6.0
@export var abstand_lang: float = 12.0
```
Was der Stecher braucht: die Szene der Stechfliege, die Kanone (die Fliege wird an sie gehaengt und faehrt mit), die Zonen, die eine Zone, in der sie kommt (Scheue), das Rechteck auf dem Arm und den Abstand zwischen zwei Stechfliegen: zwischen 6 und 12 Sekunden.

```gdscript
var uhr: float = 0.0

func _ready() -> void:
	uhr = randf_range(abstand_kurz, abstand_lang)
```
Die Uhr zaehlt rueckwaerts bis zur naechsten Stechfliege. Am Anfang wird ein Abstand ausgewuerfelt.

```gdscript
func _process(delta: float) -> void:
	if zonen.aktuelle() != zone:
		return
	uhr -= delta
	if uhr > 0.0:
		return
```
Nur in der richtigen Zone laeuft die Uhr. Ist sie noch nicht abgelaufen, passiert nichts.

```gdscript
	uhr = randf_range(abstand_kurz, abstand_lang)
	var flaeche: Rect2 = stichstelle.get_global_rect()
	var punkt: Vector2 = flaeche.position + Vector2(randf() * flaeche.size.x, randf() * flaeche.size.y)
```
Neue Wartezeit auswuerfeln. Dann eine zufaellige Stelle im Rechteck: `get_global_rect` gibt das Rechteck in Weltkoordinaten, `randf()` ist eine Zufallszahl zwischen 0 und 1.

```gdscript
	var fliege: Node2D = stechfliege_szene.instantiate()
	fliege.ziel = kanone.to_local(punkt)
	kanone.add_child(fliege)
```
Die Stechfliege entsteht und bekommt die Stelle. `to_local` rechnet die Stelle in Koordinaten der Kanone um, weil die Fliege an der Kanone haengt.

### `szenen/spiel.tscn` - geaendert

- Neu: `Kanone/RechteHand/Stichstelle`, ein `ReferenceRect`. Das ist ein Rechteck, das nur im Editor zu sehen ist (rote Linie, 3 Pixel). Im Spiel ist es unsichtbar. Du verschiebst es im Editor dorthin, wo sich die Stechfliege auf den Arm setzen soll, und ziehst es groesser oder kleiner. Es haengt an der Hand und bewegt sich mit ihr. Kommt das Foto des Arms, ziehst du es auf das Foto.
- Neu: `Stecher` mit `stecher.gd`, Zone `Zonen/Scheue`.
- Zone `Scheue`: In `fliegen` steht statt der schnellen Fliege die Heuschrecke. In der Zone Anfang bleibt die schnelle.

### So wurde es angeschaut

- Schnellcheck PASS fuer die drei neuen Skripte, Verify PASS (davor ein FAIL, siehe oben).
- Probe ausserhalb des Spielordners: eine Heuschrecke 3 Sekunden beobachtet, alle 0,1 Sekunden die Stelle: zwei Spruenge in 0,4 Sekunden, zusammen 720 Pixel, Bogen bis etwa 57 Pixel hoch, dann Pause mit Wippen bis 7 Pixel, danach zurueck in die andere Richtung (sie waere sonst zu weit weg gewesen).
- Stechfliege in fuenf Bildern: Anflug von oben links, sitzt hochkant auf dem Arm, roter Punkt bleibt nach dem Abflug.
- Nicht angeschaut: Gefuehl, ob die Heuschrecke zu schwer oder zu leicht zu fangen ist, wie oft die Stechfliege kommen soll, ob sie richtig herum sitzt (dein Blick).

### Drei Fragen zur Selbstkontrolle

1. Warum kann die Nadel die Stechfliege nicht treffen?
2. Was rechnet `sin(PI * anteil)` im Sprung der Heuschrecke, und was kommt bei `anteil = 0.5` heraus?
3. Warum gehoert der Tween zum Verblassen dem roten Punkt und nicht der Stechfliege?

## Kanone als Bild, Triebwerke und Feuer (26.11.2026)

Die Kanone ist jetzt ein Bild statt zweier grauer Rechtecke. Links und rechts sitzt ein Triebwerk, daran brennt Feuer, wenn du lenkst. Triebwerk und Feuerbilder kommen aus Pineapple Boss Fight. Die Lage der Triebwerke ist vorlaeufig, du setzt sie in Photoshop selbst.

### Die Bilder

- `assets/kanone/kanone.png`: Tonne, Draht, Lauf und die zwei Triebwerke in einem Bild. Das rechte Triebwerk ist gespiegelt, wie in Pineapple.
- `assets/kanone/feuer/feuer-1.png` bis `feuer-6.png`: sechs Bilder einer Flamme. In Pineapple sind sie 1024 mal 576 Pixel gross und fast leer, die Flamme sitzt unten in der Mitte. Hier sind sie auf die Flamme zugeschnitten (247 mal 201 Pixel). Damit liegt der Knoten dort, wo die Flamme ist, und der Browser muss weniger laden.

### `szenen/spiel.tscn` - geaendert

- `Kanone/Arm/Koerper` und `Kanone/Arm/Rohr` (graue Rechtecke) sind weg. Neu: `Kanone/Arm/Bild`, ein `Sprite2D` mit `kanone.png`. `scale` 0,21 heisst: Das Bild wird auf 21 Prozent verkleinert. `position` (-2, 0) ist so gewaehlt, dass die Oberkante des Laufs genau an der `Muendung` (0, -140) liegt. Die Muendung selbst ist nicht verschoben, die Nadel startet also wie bisher.
- Dasselbe in der Totale: `Kanone/Figur/Schulter/Armbild/Bild` statt `Koerper` und `Rohr`, die Oberkante des Laufs liegt an der `Spitze`.
- Neu: `Kanone/Arm/FeuerLinks` und `FeuerRechts`, zwei `AnimatedSprite2D`. Ein `AnimatedSprite2D` zeigt mehrere Bilder nacheinander. Welche, steht in `sprite_frames`: die sechs Feuerbilder, 16 Bilder pro Sekunde (`speed`), in Schleife (`loop`). `autoplay = "default"` heisst: Die Animation laeuft von selbst los, dafuer braucht es keinen Code. `visible = false`: Am Anfang sieht man das Feuer nicht.
- Die Feuerbilder zeigen eine Flamme, die nach oben brennt. `rotation` dreht sie um 90 Grad (1,5707964 ist ein Viertelkreis im Bogenmass), damit sie zur Seite zeigt: rechts im Uhrzeigersinn, links dagegen. `flip_h` spiegelt das linke Feuer, damit es das genaue Spiegelbild des rechten ist.
- Die beiden Feuer stehen in der Liste vor `Bild`. Was weiter oben steht, wird zuerst gemalt, das Feuer liegt also hinter der Kanone.

### Woher die Zahlen am Feuer kommen

In Pineapple ist das Triebwerk auf 22 Prozent verkleinert und das Feuer auf 70 Prozent, die Mitte der Flamme liegt 137 Pixel neben der Mitte des Triebwerks. Hier ist das Triebwerk kleiner, naemlich 7,35 Prozent (in Photoshop 35 Prozent, im Spiel davon 21 Prozent). Das ist ein Drittel von 22 Prozent (7,35 / 22 = 0,334). Also wird alles andere auch ein Drittel so gross: Feuer 0,7 mal 0,334 = 0,234 und Abstand 137 mal 0,334 = 46 Pixel. So sitzt die Flamme im Verhaeltnis genauso am Triebwerk wie in Pineapple. Aendert sich die Groesse der Triebwerke, werden diese zwei Zahlen neu gerechnet.

### `skripte/kanone.gd` - geaendert

```gdscript
	feuer_zeigen(richtung)
```
Neue Zeile in `fahren`, direkt nachdem `richtung` feststeht. `richtung` ist negativ, wenn du nach links lenkst, positiv nach rechts, 0 wenn du nicht lenkst.

```gdscript
func feuer_zeigen(richtung: float) -> void:
	$Arm/FeuerLinks.visible = richtung > 0.0
	$Arm/FeuerRechts.visible = richtung < 0.0
```
`richtung > 0.0` ist entweder wahr oder falsch. Dieses Ergebnis wird direkt in `visible` geschrieben. Lenkst du nach rechts, ist das linke Feuer zu sehen: Das linke Triebwerk schiebt die Kanone nach rechts. Lenkst du nach links, brennt das rechte. Lenkst du nicht, sind beide Vergleiche falsch und beide Feuer aus. Die Funktion laeuft in jedem Bild, darum geht das Feuer sofort aus, wenn du loslaesst.

### So wurde es angeschaut

- Schnellcheck PASS fuer `kanone.gd`, Verify PASS.
- Zwei Bilder aus dem laufenden Spiel: die Totale beim Start (Kanone am Arm) und die Kanone gross mit beiden Feuern an.
- Nicht angeschaut: wie es beim Lenken wirkt, ob die Kanone zu gross oder zu klein ist (dein Blick).

### Drei Fragen zur Selbstkontrolle

1. Warum brennt beim Lenken nach rechts das linke Feuer?
2. Warum braucht das Feuer keinen `play()`-Aufruf im Skript?
3. Warum wird das Feuer kleiner, wenn die Triebwerke kleiner werden, und um wie viel?

### Geaendert in Abschnitt 10: Groesse der Fliege per Ziehen (`skripte/fliege.gd`, `szenen/fliege_boss.tscn`)

Dein Wunsch: Die Groesse einer Fliege stellt man ein, indem man in ihrer Szene das Bild groesser oder kleiner zieht.

Weg sind diese zwei Zeilen (mit dem Kommentar darueber):
```gdscript
@export var halbe_groesse: float = 50.0
```
Vorher war die Trefferflaeche eine feste Zahl, unabhaengig vom Bild. Zog man das Bild groesser, blieb die Flaeche gleich, und die Nadel ging durch den Rand der Fliege hindurch.

Neu, bei den anderen Variablen:
```gdscript
var halbe_groesse: float = 50.0
```
Keine `@export` mehr, weil man die Zahl nicht mehr selbst eintraegt. Sie wird beim Start berechnet. Den Namen behaelt sie, weil `nadel.gd` und `hindernis.gd` sie lesen.

Neu in `_ready`:
```gdscript
	var bild_groesse: Vector2 = $Bild.texture.get_size() * $Bild.scale.abs()
	halbe_groesse = (bild_groesse.x + bild_groesse.y) / 4.0
```
`texture.get_size()` ist die Groesse der Bilddatei in Pixeln, `scale` ist, wie stark du das Bild in der Szene gezogen hast. Malgenommen ergibt das die Groesse auf dem Bildschirm. `abs()` macht negative Werte positiv, falls das Bild gespiegelt ist. Die Trefferflaeche ist weiter ein Quadrat: Seine halbe Seite ist der Durchschnitt aus halber Breite und halber Hoehe des Bilds (Breite plus Hoehe, durch 4). Eine flache, breite Fliege bekommt so ein Quadrat, das etwas breiter ist als sie hoch und etwas schmaler als sie breit ist. Genauer wird es erst mit der Polygon-Form (spaeter).

In `fliege_boss.tscn` ist die Zeile `halbe_groesse = 150.0` weg, weil es das Feld im Inspector nicht mehr gibt.

So stellst du die Groesse ein: Fliegenszene oeffnen, den Knoten `Bild` auswaehlen, an den Ecken ziehen (oder im Inspector `scale` aendern). Gemessen (Probe): Normal 48, Schnell 45, Scheu 65, Koeder 60, Teleport 56, Boss 166, Heuschrecke 51 Pixel halbe Seite; Bild der normalen Fliege doppelt so gross gezogen: 96.

Frage zur Selbstkontrolle: Warum wuerde ohne `abs()` eine gespiegelte Fliege eine kleinere Trefferflaeche bekommen?

## Kanone in drei Teilen, Drahtrolle als Animation (26.11.2026, Nachtrag)

Die Kanone ist jetzt aus drei Bildern zusammengesetzt, damit sich die Drahtrolle bewegen kann, waehrend Tonne und Lauf stehen. Die Rolle wechselt zwischen deinen fuenf Rollenfotos, der Draht laeuft von ihrer rechten Kante zur Spitze des Laufs und wandert dabei zwischen deinen zwei Markierungen hoch und runter. Die zehn Bilder kommen aus deiner Krita-Datei.

### Die Bilder

- `assets/kanone/kanone-hinten.png`: Triebwerke und Lauf. Liegt ganz hinten.
- `assets/kanone/drahtrolle-anim/drahtrolle-01.png` bis `-10.png`: Rolle mit Draht, ein Bild je Schritt der Animation.
- `assets/kanone/kanone-tonne.png`: die Tonne. Liegt vorn und verdeckt den unteren Teil der Rolle.
- `assets/kanone/kanone.png`: alles zusammen, Bild 1 der Animation. Nur noch fuer die Totale, dort bewegt sich nichts.

Alle drei Teile sind mit derselben Groesse (`scale` 0,21) aus derselben Leinwand geschnitten. Ihre Positionen sind so gerechnet, dass die Mitte der Laufspitze genau auf der `Muendung` (0, -140) liegt. Darum passen sie aufeinander, ohne dass man sie im Editor ausrichten muss.

### `szenen/spiel.tscn` - geaendert

- `Kanone/Arm/Bild` zeigt jetzt `kanone-hinten.png`.
- Neu: `Kanone/Arm/Drahtrolle`, ein `AnimatedSprite2D` mit den zehn Bildern, 12 Bilder pro Sekunde, in Schleife. Diesmal ohne `autoplay`: Es laeuft nur, wenn das Skript es startet.
- Neu: `Kanone/Arm/Tonne`, ein `Sprite2D` mit `kanone-tonne.png`. Es steht in der Liste als Letztes, wird also zuletzt und damit ganz vorn gemalt.
- `FeuerLinks` und `FeuerRechts` sind verschoben, weil du die Triebwerke in Photoshop anders gesetzt hast. Gerechnet wie vorher, nur mit der neuen Lage.

### `skripte/kanone.gd` - geaendert

```gdscript
var ziehende: Array[Node2D] = []
```
Eine Liste der Nadeln, die gerade noch Draht aus der Kanone ziehen. `Array[Node2D]` heisst: In der Liste duerfen nur Knoten vom Typ `Node2D` stehen.

```gdscript
		ziehende.append(nadel)
```
In `schiessen`, direkt nach dem Schuss: Die neue Nadel kommt in die Liste.

```gdscript
	draht_zeigen()
```
Neue Zeile in `_process`, laeuft also in jedem Bild.

```gdscript
func draht_zeigen() -> void:
	var noch: Array[Node2D] = []
	for nadel in ziehende:
		if is_instance_valid(nadel) and not nadel.steckt:
			noch.append(nadel)
	ziehende = noch
```
Eine neue, leere Liste `noch`. Jede Nadel aus der alten Liste kommt nur hinein, wenn sie noch Draht zieht. `is_instance_valid(nadel)` ist falsch, wenn die Nadel geloescht wurde: Sie ist ins Leere geflogen, ihre `reichweite` (2160 Pixel) war um, und `nadel.gd` hat `queue_free()` gerufen. `nadel.steckt` ist wahr, wenn sie in einer Fliege steckt. Danach ersetzt `noch` die alte Liste.

Warum eine neue Liste und nicht einfach die alte Nadel herausloeschen? Eine geloeschte Nadel laesst sich aus einer Liste mit festem Typ nicht mehr entfernen, Godot meldet dann in jedem Bild einen Fehler. Das hat die Probe gezeigt (siehe unten).

```gdscript
	if ziehende.is_empty():
		$Arm/Drahtrolle.pause()
	elif not $Arm/Drahtrolle.is_playing():
		$Arm/Drahtrolle.play()
```
Zieht keine Nadel mehr Draht, haelt die Rolle an. `pause()` haelt sie genau bei dem Bild an, das gerade zu sehen ist (`stop()` wuerde auf Bild 1 zurueckspringen). Zieht mindestens eine Nadel und die Rolle laeuft noch nicht, startet `play()` sie wieder, und zwar dort, wo sie angehalten hat.

### So wurde es angeschaut

- Schnellcheck PASS fuer `kanone.gd`, Verify PASS.
- Probe ausserhalb des Spielordners: Schuss ins Leere, die Rolle laeuft 0,7 Sekunden und haelt an, sobald die Nadel weg ist. Schuss auf eine Fliege 400 Pixel ueber der Kanone: Die Rolle laeuft, bis die Nadel steckt (nach 0,12 Sekunden), und steht im naechsten Bild still.
- Die Probe hat beim ersten Lauf einen Fehler gefunden (geloeschte Nadel nicht aus der Liste entfernbar), darum die neue Liste.
- Bild aus dem Spiel: Rolle, Lauf und Tonne sitzen aufeinander, in Ruhe und waehrend die Rolle laeuft.
- Nicht angeschaut: wie es beim Spielen wirkt, ob der Draht im Spiel dick genug ist (dort ist er gut 1 Pixel breit).

### Drei Fragen zur Selbstkontrolle

1. Warum haelt die Rolle mit `pause()` an und nicht mit `stop()`?
2. Wann verschwindet eine Nadel aus der Liste `ziehende`? Nenne beide Faelle.
3. Warum muss die Tonne in der Szene unter der Drahtrolle stehen?

### Nachtrag: Draht verschwindet hinter dem Visierblock (26.11.2026)

Nur Bilder und zwei Positionen geaendert, kein Code. Der Draht laeuft von der rechten Kante der Rolle schraeg nach oben und verschwindet hinter der unteren Ecke des Visierblocks am Lauf. Dafuer liegt er jetzt **hinter** dem Lauf: Beim Bauen der Bilder wird er ueberall dort ausgeblendet, wo der Lauf deckt, erst danach kommt die Rolle davor. So bleibt es im Spiel bei einem einzigen `AnimatedSprite2D` fuer Rolle und Draht. (Ein Zwischenstand, bei dem der Draht oben ueber den Rand in die Oeffnung bog, ist damit ersetzt.)

In `szenen/spiel.tscn` hat sich die Position von `Kanone/Arm/Drahtrolle` geaendert (-28,1 / -24,7), weil die Bilder jetzt einen anderen Ausschnitt haben. Die Position gleicht das aus, damit Rolle und Draht an derselben Stelle bleiben.

Frage: Warum kann der Draht hinter dem Lauf liegen, obwohl Rolle und Draht in einem Bild stecken, das vor dem Lauf gemalt wird?

### Nachtrag: Kanone ragt von unten ins Bild (26.11.2026)

Nur `szenen/spiel.tscn`, kein Code.

- `Kanone/Arm/LinkeHand` (graues Rechteck aus der Greybox) ist geloescht, die Kanone ersetzt es.
- Alles im `Arm` ist 65 Pixel nach oben gerueckt: `Bild` (-95,7), `Drahtrolle` (-89,7), `Tonne` (-3,9), beide Feuer (y -4,2) und die `Muendung` (0, -205 statt -140).

Warum: In der Luft zeigt die Kamera die Kanone mit `versatz_luft` -520. Die halbe Bildhoehe ist 540, also liegt der untere Bildrand 20 Pixel unter dem Nullpunkt der Kanone (-520 + 540 = 20). Die Duesen reichten bis 79 Pixel darunter und wurden abgeschnitten. Jetzt enden sie bei 14, das Bild schneidet die Tonne knapp unter den Duesen ab, die Kanone ragt von unten ins Bild.

Warum die Kanone verschoben und nicht die Kamera: Mehrere Skripte rechnen mit dem oberen Bildrand 1060 ueber der Kanone (Erzeuger, Hindernisse). Eine andere Kamera haette all diese Zahlen falsch gemacht. Die Muendung rueckt mit, damit die Nadel weiter oben aus dem Lauf kommt.

Frage: Wo liegt der untere Bildrand, wenn `versatz_luft` -500 waere?

## Geaendert in Abschnitt 10: Lautstaerke-Regler als Brett mit Naegeln

Dein Wunsch: zwei Bretter auf der Wiese in den Einstellungen, mittig und fett, vorne "Musik" und "SFX" in deiner Pinselschrift (Freckle Face, Z191). Darauf 20 Naegel nebeneinander: je mehr stecken, desto lauter. Wo keiner steckt, sieht man nur seinen Schatten. Bedienung: klicken oder ziehen entlang der Naegel (Z201, mein Vorschlag, von dir nicht anders entschieden).

### Die Bilder und die Schrift

- `assets/einstellungen/brett-balken.png`: dein ausgeschnittenes Brett (`assets/hintergrund/brett.png`), auf das Brett selbst zugeschnitten.
- `assets/einstellungen/nagel.png`: der Nagel aus `assets/nadel/nagel_platzhalter.png`, zugeschnitten und auf 240 Pixel Hoehe verkleinert.
- `assets/schrift/FreckleFace-Regular.ttf` mit `OFL-FreckleFace.txt`: die Schrift und ihre Lizenz (SIL Open Font License). Die Lizenz verlangt, dass der Text mitgeliefert wird.

### `szenen/regler_nagel.tscn` - neu

Ein einzelner Nagel: ein `TextureRect` mit dem Nagelbild. `size_flags_horizontal = 3` heisst: Er nimmt sich so viel Breite, wie da ist, alle Naegel teilen sich die Reihe gleichmaessig. `expand_mode = 1` und `stretch_mode = 5` (mittig, Seitenverhaeltnis behalten): Das Bild wird auf die Hoehe der Reihe gezogen, ohne verzerrt zu werden. `mouse_filter = 2`: Der Nagel nimmt keine Klicks weg.

### `szenen/regler.tscn` - geaendert

Vorher: Schrift oben, darunter ein dunkler Balken mit heller Fuellung. Jetzt:
- `Brett`: ein `TextureRect` mit dem Brett, 1000 x 140 Pixel, 40 Pixel unter der Oberkante des Reglers.
- `Name`: die Schrift vorne auf dem Brett, Freckle Face (`theme_override_fonts/font`), 72 gross, dunkelbraun wie Farbe auf Holz. `vertical_alignment = 1`: senkrecht mittig auf dem Brett.
- `Naegel`: ein `HBoxContainer`, ein Kasten, der seine Kinder von selbst nebeneinander anordnet. Er liegt rechts von der Schrift (300 bis 980) und reicht von der Oberkante des Reglers bis 150. Die Naegel ragen also oben ueber das Brett hinaus und stecken unten im Brett. `separation = 0`: kein extra Abstand, die Naegel teilen sich die Breite.
- `Balken` und `Fuellung` sind weg.

### `skripte/regler.gd` - geaendert

```gdscript
@export var beschriftung: String = "SFX"
```
Neu. Was vorne auf dem Brett steht. Vorher stand dort der Name des Tonkanals ("Effekte"); jetzt kann es etwas anderes sein ("SFX").

```gdscript
@export var nagel_szene: PackedScene
@export var anzahl: int = 20
@export var schatten: Color = Color(0.0, 0.0, 0.0, 0.35)
```
Neu. Die Nagel-Szene, wie viele Naegel auf das Brett kommen, und wie ein fehlender Nagel aussieht: schwarz mit 35 Prozent Deckkraft, also ein Schatten.

```gdscript
	$Name.text = beschriftung
	for nummer in anzahl:
		$Naegel.add_child(nagel_szene.instantiate())
```
In `_ready`. Die Schrift kommt jetzt aus `beschriftung`. Dann werden 20 Naegel aus der Nagel-Szene erzeugt und in die Reihe gehaengt. `for nummer in anzahl` wiederholt die Zeile 20 Mal. Der `HBoxContainer` stellt sie von selbst nebeneinander.

```gdscript
		zieht = ereignis.pressed and $Naegel.get_global_rect().has_point(ereignis.position)
```
Geaendert: Gegriffen wird jetzt auf der Nagelreihe (`$Naegel`) statt auf dem alten Balken.

```gdscript
func setzen(x: float) -> void:
	var wert: float = clampf((x - $Naegel.global_position.x) / $Naegel.size.x, 0.0, 1.0)
	var stecken: int = ceili(wert * anzahl)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus), float(stecken) / anzahl)
	zeigen(float(stecken) / anzahl)
```
Geaendert. Wie weit rechts in der Reihe man ist, 0 ganz links, 1 ganz rechts. Daraus die Zahl der Naegel: `ceili` rundet auf. Wer auf den dritten Nagel klickt, bekommt drei Naegel, nicht zweieinhalb. Die Lautstaerke ist dann genau ein Zwanzigstel je Nagel, damit Bild und Ton zusammenpassen. Ganz links ausserhalb der Reihe (beim Ziehen) kommt 0 heraus: kein Nagel, stumm.

```gdscript
func zeigen(wert: float) -> void:
	var stecken: int = roundi(wert * anzahl)
	for nummer in anzahl:
		var nagel: Control = $Naegel.get_child(nummer)
		if nummer < stecken:
			nagel.modulate = Color.WHITE
		else:
			nagel.modulate = schatten
```
Geaendert. Vorher wurde die Fuellung breiter oder schmaler. Jetzt geht die Funktion alle Naegel durch: Die ersten `stecken` sind normal (`Color.WHITE` heisst unveraendert), die restlichen werden zum Schatten. `roundi` rundet auf die naechste ganze Zahl, weil die Lautstaerke beim Start aus der Tonanlage kommt und nicht genau ein Zwanzigstel sein muss.

### `szenen/spiel.tscn` - geaendert

Die beiden Regler `Einstellungen/Wand/Musik` und `Effekte` sind 1000 breit und stehen mittig (220 bis 1220 auf der 1440 breiten Wand), Musik bei 320, SFX bei 560 von oben. `Musik` hat `beschriftung = "Musik"`, `Effekte` behaelt die Vorgabe "SFX".

### Nachtrag: Wand mit den Forschern, Schild "Einstellungen" und Dank

Du hast in `assets/hintergrund/psd/boden2.psd` zwei Forscher in die Grasreihen gesetzt (liegend mit den Beinen nach oben, und von hinten). Die PSD ist gespeichert.

- `assets/einstellungen/wand.png`: die PSD als ein Bild (alle Ebenen zusammen), ohne Metadaten. Nur die Wand zeigt es. Die Wiese draussen bleibt `wiese.png` ohne Forscher, sonst wuerden sie sich dort seitlich wiederholen.
- `assets/einstellungen/brett-halb.png`: die linke Haelfte des Bretts, fuer die kurzen Schilder.

#### `szenen/schild.tscn` und `skripte/schild.gd` - neu

Ein Holzschild mit Schrift: ein `TextureRect` mit dem halben Brett, darin ein `Label` `Schrift` in Freckle Face. Die vier `anchor`-Zeilen und die `offset`-Werte (16 links und rechts) spannen die Schrift ueber das ganze Schild mit etwas Rand. `horizontal_alignment = 1` und `vertical_alignment = 1`: mittig. `autowrap_mode = 3`: Ist der Text zu lang fuer eine Zeile, bricht er um.

```gdscript
extends TextureRect
```
Das Skript haengt am Schild selbst.

```gdscript
@export_multiline var schrift: String = "Schild"
@export var groesse: int = 64
```
Was auf dem Schild steht und wie gross. `@export_multiline` gibt im Inspector ein grosses Textfeld, in dem man auch neue Zeilen schreiben kann.

```gdscript
func _ready() -> void:
	$Schrift.text = schrift
	$Schrift.add_theme_font_size_override("font_size", groesse)
```
Beim Start bekommt das Label den Text und die Groesse. `add_theme_font_size_override` ist dasselbe wie im Inspector unter "Theme Overrides" die Schriftgroesse zu setzen, nur aus dem Skript.

#### `szenen/regler.tscn` - nochmal geaendert

`Brett` und `Naegel` haengen jetzt an den Raendern des Reglers (`anchor_right = 1.0`), statt feste 1000 Pixel breit zu sein. So passt sich das Brett an, wenn man den Regler in der Wand breiter oder schmaler zieht. Die Naegel enden 20 Pixel vor dem rechten Rand (`offset_right = -20`).

#### `szenen/spiel.tscn` - Wand neu aufgeteilt

- `Wiese` in der Wand zeigt `wand.png` (mit den Forschern) statt `wiese.png`.
- `Titel` ist jetzt ein Schild (Instanz von `schild.tscn`) mit "Einstellungen", Groesse 60, in der obersten Grasreihe (380 bis 920, 30 bis 170). Es endet links von der Zurueck-Fliege, damit man sie sieht.
- `Musik` und `SFX` stehen rechts von den Forschern (470 bis 1390), in der zweiten und dritten Reihe (205 und 450 von oben).
- Neu: `Dank`, ein Schild mit "Thanks to" und den Namen. Auf deinen Wunsch 1,5-mal so gross wie zuerst: 920 x 315 Pixel (470 bis 1390, 760 bis 1075), Schrift 51 statt 34. Es ist links und rechts buendig mit Musik und SFX (470 und 1390) und unten 5 Pixel ueber dem Bildrand. So gross passt es nicht mehr in die unterste Grasreihe (sie ist 240 hoch), es reicht oben in die vierte hinein. `\n` im Text ist der Zeilenumbruch nach "Thanks to".

Angeschaut: Bild der hochgefahrenen Wand. Schilder und Regler liegen neben den Forschern, nichts deckt sie zu, die Zurueck-Fliege ist frei. Regler funktionieren weiter (Musik 40 Prozent: 0,40).

### Nachtrag: Schild faehrt von oben herein und schliesst die Einstellungen (`skripte/einstellungen.gd`, `szenen/spiel.tscn`)

Dein Wunsch: Das Schild "Einstellungen" kommt von oben herein, waehrend die Wiese hochfaehrt, und ist ein Knopf zum Schliessen. Geoeffnet wird nur ueber die Fliege. Der Satz "Zurueck: die Fliege oben an der Kante antippen" ist weg.

In `spiel.tscn` haengt `Titel` jetzt direkt an `Einstellungen` statt an der Wand. Sonst wuerde es mit der Wand von unten kommen. Am Anfang ist es unsichtbar (`visible = false`) und steht ueber dem Bildrand (`offset_top = -150`). Der Knoten `Hinweis` ist geloescht.

```gdscript
@export var titel_oben: float = 0.0
@export var titel_versteckt: float = -150.0
```
Neu. Wo das Schild steht, wenn die Wand oben ist (0: es stoesst oben an den Bildrand, ohne Abstand), und wo es wartet (150 Pixel ueber dem Bild, also unsichtbar ausserhalb).

```gdscript
	$Titel.position.y = titel_versteckt
	$Titel.visible = true
```
Neu in `oeffnen`: Das Schild wird ueber das Bild gesetzt und eingeschaltet.

```gdscript
	fahrt.parallel().tween_property($Titel, "position:y", titel_oben, fahrdauer)
```
Neu in `oeffnen`, nach der Fahrt der Wand. `parallel()` heisst: gleichzeitig mit dem Schritt davor, nicht danach. Waehrend die Wiese von unten hochfaehrt, faehrt das Schild in derselben Zeit (0,6 Sekunden) von oben herein.

```gdscript
	fahrt.parallel().tween_property($Titel, "position:y", titel_versteckt, fahrdauer)
```
Neu in `schliessen`: dasselbe rueckwaerts, das Schild faehrt nach oben hinaus, waehrend die Wiese herunterfaehrt.

```gdscript
	$Titel.visible = false
```
Neu in `zu`: Wenn alles unten ist, wird das Schild ausgeschaltet.

```gdscript
		if not ereignis.pressed:
			return
		if $Wand/Fliege.get_global_rect().has_point(ereignis.position) or $Titel.get_global_rect().has_point(ereignis.position):
			schliessen()
```
Geaendert in `_input`. Vorher: nur ein Klick auf die Fliege schloss. Jetzt: Erst wird geprueft, ob gedrueckt wurde (Loslassen zaehlt nicht, sonst wuerde ein Klick zweimal zaehlen). Dann schliesst ein Klick auf die Fliege **oder** (`or`) auf das Schild.

Angeschaut (Probe): nach 0,3 Sekunden steht die Wiese halb oben und das Schild halb im Bild; nach 0,9 Sekunden ist alles oben. Klick auf die Mitte des Schilds: Wand und Schild fahren weg, danach sind beide aus und die Figur ist wieder frei (`wand_offen` falsch).

Frage zur Selbstkontrolle: Was wuerde passieren, wenn `parallel()` fehlte?

### So wurde es angeschaut

- Schnellcheck PASS fuer `regler.gd`, Verify PASS.
- Probe: Wand hochgefahren, Bild aufgenommen: zwei Bretter mit Schrift und je 20 Naegeln. Musik auf 40 Prozent gesetzt: Tonkanal Musik 0,40, auf dem Bild 8 Naegel und 12 Schatten. SFX auf den ersten Nagel: Tonkanal 0,05, 1 Nagel und 19 Schatten.
- Nicht angeschaut: am Handy mit dem Finger, und wie es sich anfuehlt.

### Drei Fragen zur Selbstkontrolle

1. Warum rundet `setzen` mit `ceili` auf, `zeigen` aber mit `roundi`?
2. Was passiert, wenn man im Inspector `anzahl` auf 10 stellt?
3. Warum ordnet der `HBoxContainer` die Naegel von selbst an, ohne dass das Skript Positionen ausrechnet?

### Nachtrag: Kanone 1,5-mal so gross, Triebwerke oben an der Tonne (26.11.2026)

Nur Bilder und `szenen/spiel.tscn`, kein Code.

- Die Triebwerke sitzen im Bild jetzt oben an der Tonne: Ihre Oberkante liegt dort, wo der Tonnenrand an den Seiten ist. Dafuer sind sie auf der Leinwand 252 Pixel nach oben gerueckt (`kanone-hinten.png` neu gebaut).
- Alle Teile im `Arm` haben `scale` 0,315 statt 0,21, also 1,5-mal so gross. Die Feuer 0,351 statt 0,234 (auch mal 1,5, damit sie im Verhaeltnis zu den Triebwerken gleich bleiben).
- Die Positionen sind neu gerechnet: Der untere Bildrand in der Luft liegt 20 Pixel unter dem Nullpunkt der Kanone. Die Unterkante der Triebwerke liegt jetzt knapp darueber, so schneidet das Bild die Kanone gerade unter den Triebwerken ab. Daraus ergibt sich die `Muendung` bei (0, -230,7).
- In der Totale bleibt die Kanone so gross wie vorher (0,21), dort haengt sie an der Figur.

Rechnung fuer die Muendung: Unterkante der Triebwerke plus 6 Pixel Rand liegt auf der Leinwand bei 989, die Laufspitze bei 193. Der Abstand ist 796 Leinwand-Pixel, im Spiel 796 mal 0,315 = 250,7. Die Unterkante soll bei 20 liegen, also die Muendung bei 20 - 250,7 = -230,7.

Frage: Warum muss die Muendung hoeher rutschen, wenn die Kanone groesser wird, obwohl der Bildrand gleich bleibt?

## Fluegel, die schlagen: normale Fliege (27.11.2026)

Die normale Fliege hat jetzt zwei Fluegel aus deinem ausgeschnittenen Foto, und ein `AnimationPlayer` laesst sie schlagen. Die Farbe ist Magenta statt Blau, damit sie sich von allen Pappen abhebt (gemessen, siehe unten).

### Die Bilder

- `assets/fluegel/fluegel-blau.png`: dein Ausschnitt, unveraendert.
- `assets/fluegel/fluegel-rosa.png`, `-tuerkis.png`, `-violett.png`, `-orange.png`: dieselbe Datei, aber nur die blauen Felder zwischen den Adern haben einen anderen Farbton (gedreht, zum Beispiel um 130 Grad von Blau nach Rosa). Adern, Rand und Glanz behalten ihre Farbe, Saettigung und Helligkeit bleiben wie im Foto, darum schimmert der Fluegel weiter. Ausserdem ist der leere Rand abgeschnitten.

Warum Magenta: Fuer jede Pappe wurde der Farbabstand zwischen Fluegel und Pappe gemessen (OKLab, eine Farbskala, in der gleiche Zahlen auch fuer das Auge gleich weit auseinander liegen). Das blaue Original hatte auf der blauen Pappe nur 0,13, kaum zu sehen. Magenta ist auf keiner Pappe schwaecher als 0,23. Rosa, Orange, Violett und Tuerkis haben jeweils eine Pappe, auf der sie fast verschwinden.

### `szenen/fliege_normal.tscn` - geaendert

- Neu: `FluegelHinten` (vor `Bild` in der Liste, also hinter dem Koerper gemalt) und `FluegelVorn` (nach `Bild`, also davor). Beide sind `Sprite2D` mit `fluegel-magenta.png`.
- `centered = false` und `offset = Vector2(-1, -23)`: Normalerweise sitzt der Drehpunkt eines Bildes in seiner Mitte. Hier soll sich der Fluegel um seine Wurzel drehen, wie ein echter Fluegel am Ruecken. Die Wurzel liegt im Bild bei Pixel (1, 23), der `offset` schiebt das Bild so, dass genau dieser Pixel auf dem Drehpunkt liegt.
- `flip_h = true` spiegelt das Bild, weil die Wurzel im Foto rechts ist, die Fliege aber nach links schaut und die Fluegel nach hinten (rechts) zeigen sollen.
- `position = Vector2(-18, -14)`: Dort ist die Wurzel auf dem Ruecken. `scale` 0,093: Der Fluegel ist rund 90 Pixel lang. `modulate` mit 0,85 Deckkraft: leicht durchscheinend.
- Neu: `Flattern`, ein `AnimationPlayer`. Er veraendert Werte anderer Knoten ueber die Zeit. Seine Animation `flattern` ist 0,12 Sekunden lang und wiederholt sich (`loop_mode = 1`). Sie hat zwei Spuren: die Drehung (`rotation`) von `FluegelVorn` und von `FluegelHinten`. Bei 0 Sekunden steht der vordere Fluegel auf -0,8 (Bogenmass, etwa 46 Grad), bei 0,06 Sekunden auf -1,5 (etwa 86 Grad), dann wieder zurueck. Der hintere schlaegt genauso, nur etwas steiler. `autoplay` startet die Animation, sobald die Fliege ins Spiel kommt.
- Der alte graue Platzhalter `Fluegel` (unsichtbar) ist noch da.

Die Animation ist im Editor zu sehen und zu aendern: Knoten `Flattern` anklicken, unten erscheint die Zeitleiste mit den beiden Spuren.

### `skripte/nadel.gd` - geaendert

```gdscript
	if getroffene.has_node("Flattern"):
		getroffene.get_node("Flattern").pause()
```
In `aufspiessen`, direkt nach dem Abschalten des Summens: Hat die getroffene Fliege einen Knoten `Flattern`, haelt er an. Eine aufgespiesste Fliege schlaegt nicht mehr mit den Fluegeln. (Am 27.11. wieder entfernt, siehe unten: die Fluegel schlagen jetzt weiter.) `has_node` fragt zuerst, ob es den Knoten gibt, denn bisher hat nur die normale Fliege Fluegel. Ohne die Frage gaebe es bei allen anderen einen Fehler.

### So wurde es angeschaut

- Schnellcheck PASS fuer `nadel.gd`, Verify PASS.
- Probe ausserhalb des Spielordners: die normale Fliege fuenffach vergroessert, vier Bilder ueber einen Fluegelschlag. Die Fluegel drehen sich um die Wurzel auf dem Ruecken.
- Nicht angeschaut: ob das Anhalten beim Treffer im Spiel wirklich greift (nicht nachgestellt), wie gross und wie schnell die Fluegel wirken sollen (dein Blick).

### Drei Fragen zur Selbstkontrolle

1. Warum braucht der Fluegel `centered = false` und einen `offset`?
2. Was passiert mit der Fluegelstellung, wenn die Animation 0,09 Sekunden laeuft?
3. Warum steht in `nadel.gd` zuerst `has_node`?

## Zonen genau an den Pappen, Fluegelfarbe je Zone (27.11.2026)

Jede Zone gehoert jetzt zu genau zwei Pappen: Anfang = Blau und Gelb, Scheue = Creme und Weiss, Koeder = Gruen und Indigo, Boss = Nachtblau und Fast-Schwarz. Fliegen einer Zone gibt es nur dort.

### Woher die Grenzen 24,1 / 49,1 / 74,1 kommen

Der Hintergrund wechselt alle 12,5 Flugkraft die Pappe (`flugkraft_je_bild` in `spiel.tscn`). Die naechste Pappe wird 1,8 Flugkraft vorher eingeblendet (`uebergang`). Der Wechsel von Gelb zu Creme laeuft also von 23,2 bis 25. Die Mitte davon ist 24,1, dort beginnt jetzt die Zone `Scheue`. Genauso 49,1 (Weiss zu Gruen) und 74,1 (Indigo zu Nachtblau).

Wichtig: Aendert jemand `flugkraft_je_bild` oder `uebergang`, muessen diese drei Zahlen neu gerechnet werden. Sie stehen im Inspector an `Zonen/Scheue`, `Zonen/Koeder` und `Zonen/Boss` (`ab_flugkraft`).

### `skripte/erzeuger.gd` - geaendert

```gdscript
		fremde_fliehen_lassen(zone)
```
Neue Zeile in `_process`, dort, wo der Erzeuger merkt, dass man in einer neuen Zone ist. Neue Fliegen kamen schon vorher nur aus der aktuellen Zone. Aber die Fliegen der alten Zone blieben einfach da. Jetzt werden sie weggeschickt.

```gdscript
func fremde_fliehen_lassen(zone: Node) -> void:
	for fliege in get_children():
		if fliege.flucht != Vector2.ZERO or not fliege.flieht:
			continue
```
Jede Fliege, die der Erzeuger gemacht hat, wird angeschaut. Flieht sie schon (`flucht` ist nicht null) oder darf sie gar nicht fliehen (der Boss), geht es mit der naechsten weiter (`continue`).

```gdscript
		var gehoert_dazu: bool = false
		for szene in zone.fliegen + zone.einmalig:
			if szene.resource_path == fliege.scene_file_path:
				gehoert_dazu = true
```
`zone.fliegen + zone.einmalig` haengt die beiden Listen der Zone aneinander. `resource_path` ist der Dateipfad einer Szene, zum Beispiel `res://szenen/fliege_normal.tscn`. `scene_file_path` ist der Pfad der Szene, aus der die Fliege gemacht wurde. Sind beide gleich, gehoert die Fliege zur Zone.

```gdscript
		if not gehoert_dazu:
			if fliege.position.x < kanone.position.x:
				fliege.flucht = Vector2.LEFT
			else:
				fliege.flucht = Vector2.RIGHT
```
Gehoert sie nicht dazu, fliegt sie zum naeheren Rand davon, genau wie eine Fliege, die zu tief im Bild ist (`fliehen_lassen`). Ausserhalb des Bildes loescht `aufraeumen` sie.

Das gilt in beide Richtungen: Faellt man nach einem Treffer in eine tiefere Zone, fliehen die Fliegen der hoeheren.

### Fluegelfarbe je Zone

Rosa fuer Anfang (Blau, Gelb), Tuerkis fuer Scheue (Creme, Weiss), Violett fuer Koeder (Gruen, Indigo), Orange fuer Boss (Nachtblau, Fast-Schwarz). Jede Fliegenart gehoert zu genau einer Zone, darum bekommt jede Art einfach die Fluegel ihrer Zone in ihrer Szene. Bisher hat nur die normale Fliege Fluegel, sie fliegt in der Zone Anfang und hat darum `fluegel-rosa.png`.

### So wurde es angeschaut

- Schnellcheck PASS fuer `erzeuger.gd`, Verify PASS.
- Probe ausserhalb des Spielordners: Kanone knapp unter und knapp ueber jede Grenze gesetzt. Bei 24,0 ist die Creme-Pappe zu 44 Prozent eingeblendet, Zone Anfang, nur normale und schnelle Fliegen. Bei 24,2 sind es 56 Prozent, Zone Scheue, neue Fliegen sind Heuschrecken und scheue, die vier alten fliehen. Bei 49,1 und 74,1 genauso. Rueckweg nach unten ebenfalls richtig.
- Nicht angeschaut: wie es sich spielt.

### Drei Fragen zur Selbstkontrolle

1. Warum liegt die Grenze bei 24,1 und nicht bei 25?
2. Woran erkennt `fremde_fliehen_lassen`, ob eine Fliege zur Zone gehoert?
3. Warum flieht der Boss nicht, auch wenn man unter seine Zone faellt?

## Geaendert in Abschnitt 10: Steine als Hindernisse, Warnschild als Bild (`skripte/hindernis.gd`, `szenen/hindernis.tscn`)

Deine fuenf ausgeschnittenen Fotos (`assets/hintergrund/hindernisse/stein-1.png` bis `stein-5.png`) fallen jetzt statt des grauen Klotzes. Fuer das Spiel liegen angepasste Kopien in `assets/hintergrund/hindernisse/spiel/`: zugeschnitten, Stein 1 und Stein 5 (der Turm) um 90 Grad gedreht, damit sie quer liegen, und in der Breite angeglichen, damit sie nicht so unterschiedlich sind: Stein 1 270, Stein 2 220, Stein 3 300, Stein 4 240, Stein 5 260 Pixel breit (vorher 62 bis 655). Stein 1 und 3 sind dabei kleiner geworden, Stein 5 breiter. Stein 2, 4 und 5 waren als Ausschnitt kleiner und sind vergroessert, darum etwas weicher. Das Warndreieck ist dein ausgeschnittenes Warnschild, 120 Pixel breit (`spiel/warnschild.png`).

### `szenen/hindernis.tscn`

- `Klotz` ist jetzt ein `Sprite2D` (ein Knoten, der ein Bild zeigt) statt eines grauen Rechtecks.
- `Warnung` ist jetzt ein `Sprite2D` mit dem Warnschild statt eines gelben Dreiecks mit "!". Das Kind `Zeichen` ist weg, das Ausrufezeichen ist im Bild.
- Neu am Hindernis: `steine`, die Liste der fuenf Steinbilder.

### `skripte/hindernis.gd`

Weg sind die zwei `@export`-Zeilen `breite` und `hoehe` (mit Kommentar). Neu:

```gdscript
@export var steine: Array[Texture2D] = []
```
Die Steine, die fallen koennen. Neue Steine zieht man im Inspector der Hindernis-Szene in diese Liste.

```gdscript
var breite: float = 200.0
var hoehe: float = 120.0
```
Jetzt normale Variablen statt `@export`: Sie werden beim Start aus dem Bild des Steins berechnet. Den Namen behalten sie, weil `im_klotz` damit rechnet.

```gdscript
func _ready() -> void:
	$Klotz.texture = steine.pick_random()
	breite = $Klotz.texture.get_width()
	hoehe = $Klotz.texture.get_height()
	$Klotz.position.y = -hoehe / 2.0
	$Spalte.offset_left = -breite / 2.0
	$Spalte.offset_right = breite / 2.0
```
`pick_random()` nimmt einen zufaelligen Stein aus der Liste. Breite und Hoehe sind die Groesse seines Bilds. Ein `Sprite2D` zeigt sein Bild um seinen Punkt herum (mittig), darum setzt die vierte Zeile ihn um die halbe Hoehe nach oben: Die Unterkante des Steins liegt dann genau auf dem Punkt des Hindernisses, wie vorher beim grauen Klotz. Die gelbe Spalte ist so breit wie der Stein. Die Zeilen fuer `$Klotz.offset_...` sind weg, weil ein Bild-Knoten keine Raender hat.

Angeschaut (Probe): fuenf Hindernisse nebeneinander, je ein Stein. Waehrend der Warnung oben das Warnschild, danach fallen die Steine, Fliegen in der Spalte werden zermatscht. Verify PASS, Schnellcheck PASS.

Frage zur Selbstkontrolle: Warum muss `$Klotz.position.y` auf `-hoehe / 2.0` stehen und nicht auf 0?

### Nachtrag: kraeftigere Skizzen (27.11.2026)

Nur Bilder und zwei Pfade, kein Code. Die Skizzen sind 600 Pixel breit und werden im Spiel auf knapp ein Viertel verkleinert (`scale` 0,2333). Dabei verschwimmen duenne, helle Striche fast ganz. Darum gibt es zwei neue Dateien, die Originale bleiben unveraendert:

- `assets/fliegen/spiel/insekt-bleistift-skizze-kraeftig.png` (normale Fliege): Papier fast weiss, Bleistiftstriche schwarz und auf etwa 7 Pixel verdickt.
- `assets/fliegen/spiel/fliege-skizze-kraeftig.png` (schnelle Fliege): Papier fast weiss, Kugelschreiberstriche sehr dunkel und satt blau, nur wenig verdickt (3 Pixel), weil die Schraffur dicht ist und sonst zu einer Flaeche zusammenlaeuft.

Die Schnittkante des Ausschnitts zaehlt nicht als Strich: Nur wo das Bild 2 Pixel ringsum ganz deckt, wird dunkel gefaerbt, und verdickte Striche wachsen nicht ueber den Ausschnitt hinaus. Sonst entsteht ein schwarzer Rand um die ganze Fliege. Folge: sehr duenne Teile (der Fuehler) bleiben hell. Ganz schwache Graustufen gelten als Papierstruktur und werden weiss, sonst wuerde die Verstaerkung das Papier fleckig machen.

- `assets/fliegen/spiel/heuschrecke-skizze-kraeftig.png` (Heuschrecke): wie die blaue Fliege, aber schwaecher (Stufe 1). Der Bockkaefer bleibt, wie er ist, er ist schon fast schwarz-weiss.

`fliege_normal.tscn`, `fliege_schnell.tscn` und `fliege_heuschrecke.tscn` zeigen jetzt auf die neuen Dateien. Die Trefferflaeche bleibt gleich, die Bilder sind gleich gross wie vorher.

### Nachtrag: Fluegelschlag aus deiner Krita-Datei (27.11.2026)

Kein Code, nur `szenen/fliege_normal.tscn` und vier Bilder. Du hast den Schlag in Krita selbst gezeichnet: Bild 1 mit den Fluegeln steil nach oben, Bild 2 flach auf dem Ruecken. Diese Bilder sind jetzt genau so im Spiel:

- `assets/fluegel/schlag/normal-vorn-1.png`, `normal-vorn-2.png`, `normal-hinten-1.png`, `normal-hinten-2.png`. Je Fluegel sind beide Bilder gleich gross ausgeschnitten, damit sie beim Wechsel genau an derselben Stelle liegen.
- `FluegelVorn` und `FluegelHinten` sind jetzt einfache `Sprite2D` ohne Drehung: `scale` 0,2333 wie der Koerper (die Krita-Leinwand hatte die Pixel des Koerperbilds), `position` so, dass sie wie in Krita auf dem Ruecken sitzen.
- Die Animation `flattern` dreht nichts mehr, sie wechselt das Bild: Ihre zwei Spuren setzen `texture` bei 0 Sekunden auf Bild 1 und bei 0,06 Sekunden auf Bild 2. `"update": 1` heisst: Der Wert springt, statt weich ueberzugehen (Bilder kann man nicht halb zeigen). Nach 0,12 Sekunden beginnt sie von vorn.
- Das Anhalten beim Treffer (`nadel.gd`) bleibt, wie es war.

Gemessen in einer Probe: Der Fluegel wechselt 17-mal pro Sekunde das Bild (geplant: alle 0,06 Sekunden, also 16,7-mal).

Frage: Was wuerde passieren, wenn `"update"` 0 waere?

## Hintergrund laeuft nach oben mit, normale Fliege dreht schneller, Fluegel schlagen weiter (27.11.2026)

Deine Wuensche: Die Pappe bewegt sich nicht zur Seite, aber nach oben, damit man sieht, dass man steigt. Die normale Fliege dreht sich doppelt so schnell. Der Fluegelschlag ist so schnell, dass man das Drehen zwischen den zwei Bildern nicht mehr sieht, und er geht weiter, wenn die Fliege gefangen ist.

### Die Pappen (`assets/hintergrund/riffel/`)

Jede Pappe ist jetzt doppelt so hoch: das Bild und darunter dasselbe Bild auf den Kopf gestellt (gespiegelt). So passt die Unterkante genau an die Oberkante der naechsten Kopie, und die Pappe kann sich endlos nach oben wiederholen, ohne dass man eine Naht sieht. Zur Seite wiederholt sie sich nie.

### `szenen/spiel.tscn` - `Hintergrund/Pappe` und `Hintergrund/Naechste`

Vorher waren beide ueber die vier `anchor`-Zeilen genau so gross wie der Bildschirm, das Bild darauf gezogen. Jetzt:
- `offset_right = 592` und `offset_bottom = 2352`: Der Kasten ist so breit wie das Bild und zwei Bilder hoch.
- `scale = (2.4324, 1.8367)`: 592 x 2,4324 = 1440, also genau die Bildschirmbreite. 1,8367 ist dieselbe senkrechte Vergroesserung wie vorher (588 auf 1080), damit die Rillen gleich dick aussehen.
- `stretch_mode = 1` (Kacheln): Das Bild wird untereinander wiederholt statt gezogen.

### `skripte/hintergrund.gd` - geaendert

```gdscript
@export var mitlaufen: float = 0.5
```
Neu. Wie schnell die Pappe mitlaeuft. 0,5 heisst: halb so schnell wie die Welt. Das wirkt, als waere die Pappe weiter weg.

```gdscript
	var kachel: float = $Pappe.texture.get_height() * $Pappe.scale.y
```
Neu, am Ende von `_process`. Wie hoch eine Pappe auf dem Bildschirm ist: Bildhoehe mal Vergroesserung, 1176 x 1,8367 = 2160 Pixel.

```gdscript
	var schieben: float = fposmod(-kanone.position.y * mitlaufen, kachel)
```
Neu. Wie weit die Pappe nach unten geschoben ist. Steigt die Kanone, wird `-kanone.position.y` groesser, also wandert die Pappe nach unten. `fposmod` ist der Rest beim Teilen, immer zwischen 0 und `kachel`: Nach einer ganzen Pappenhoehe faengt die Zahl wieder bei 0 an. Weil die Pappe sich wiederholt, sieht man diesen Sprung nicht.

```gdscript
	$Pappe.position.y = schieben - kachel
	$Naechste.position.y = schieben - kachel
```
Neu. Beide Pappen stehen um eine Pappenhoehe weiter oben und werden dann nach unten geschoben. So ist der Bildschirm immer ganz bedeckt: Der Kasten ist zwei Pappen hoch, oben ragt hoechstens eine ueber den Rand. Beide bekommen denselben Wert, damit das Muster beim Ueberblenden genau aufeinanderliegt.

### `skripte/fliege_normal.gd` - geaendert

```gdscript
@export var drehtempo: float = 25.12
```
Vorher 12,56 (zwei Umdrehungen pro Sekunde), jetzt doppelt so viel: vier Umdrehungen pro Sekunde.

### `szenen/fliege_normal.tscn` - Animation `flattern`

Die Animation ist jetzt 0,034 Sekunden lang statt 0,12, der Wechsel auf Bild 2 kommt bei 0,017 Sekunden statt 0,06. 0,017 Sekunden ist ungefaehr ein Bild bei 60 Bildern pro Sekunde: Die Fluegel wechseln also in jedem Bild. Vorher drehte sich die Fliege waehrend eines Fluegelbilds um etwa 40 Grad, jetzt um etwa 25 (bei doppeltem Drehtempo), und es wechselt so schnell, dass das Auge nur noch ein Flimmern sieht.

### `skripte/nadel.gd` - geaendert

Die zwei Zeilen
```gdscript
	if getroffene.has_node("Flattern"):
		getroffene.get_node("Flattern").pause()
```
sind wieder weg. Eine aufgespiesste Fliege schlaegt jetzt weiter mit den Fluegeln, auch oben an der Hand. Der `AnimationPlayer` laeuft fuer sich weiter, unabhaengig davon, dass die Fliege selbst nicht mehr fliegt.

### So wurde es angeschaut

- Schnellcheck PASS fuer `hintergrund.gd`, `fliege_normal.gd`, `nadel.gd`, Verify PASS.
- Probe: Kanone in 10 Sekunden gleichmaessig von 0 auf 16 Flugkraft hochgefahren, Bilder gespeichert. Zwischen zwei Bildern wandern die Rillen 8 Pixel nach unten (im halb so grossen Bild, also 16 Pixel im Spiel), an vier verschiedenen Stellen gemessen. Gerechnet: 16 Flugkraft in 150 Bildern x 300 Pixel x 0,5 = 16 Pixel. Keine Naht gesehen. Das Video liegt auf dem Desktop (`fliegen-look.mp4`).
- Nicht angeschaut: ob der schnelle Fluegelschlag am Handy und im Browser (oft 60 Bilder pro Sekunde, manchmal weniger) noch wie Flimmern wirkt.

### Drei Fragen zur Selbstkontrolle

1. Warum muessen `Pappe` und `Naechste` immer genau denselben `position.y` haben?
2. Was macht `fposmod`, und warum sieht man nicht, wenn die Zahl wieder bei 0 anfaengt?
3. Warum ist die Pappe jetzt gespiegelt doppelt so hoch?

## Wolken, die an ihrem Ort bleiben (`szenen/spiel.tscn`, 27.11.2026)

Dein Wunsch: Die drei Wolkenbilder kommen ins Spiel. Egal wo man ist, sieht man immer mindestens eine. Die Wolken sind fest: Faehrt man nach rechts, wandern sie im Bild nach links, weil sie bleiben, wo sie sind.

Dafuer ist kein Skript noetig, nur vier neue Knoten in der Szene.

### Die Bilder (`assets/hintergrund/wolken/wolke-1.png` bis `wolke-3.png`)

Deine drei Bilder hatten einen weissen Grund. Das Weiss ist herausgerechnet: Reines Weiss ist ganz durchsichtig, alles, was mindestens 44 Stufen dunkler ist als Weiss (von 255), ist ganz deckend, dazwischen wird es weich durchsichtig. Danach ist der leere Rand abgeschnitten. Deine Originale sind unveraendert, das Rechnen hat ein kleines Hilfsskript gemacht, das nicht im Spielordner liegt.

Wichtig zu wissen: Auch das Weiss mitten in der Wolke ist jetzt durchsichtig. Dort schaut die Pappe durch.

### `Wolken` (Parallax2D) - neu

Derselbe Knotentyp wie `Boden`. Ein `Parallax2D` kann seinen Inhalt endlos wiederholen.

- `repeat_size = (4000, 1080)`: Alles, was in `Wolken` liegt, wiederholt sich alle 4000 Pixel zur Seite und alle 1080 Pixel nach oben und unten. 1080 ist genau die Hoehe des Bildschirms.
- `repeat_times = 5`: So viele Kopien werden nebeneinander und uebereinander gezeichnet. Fuer das normale Bild wuerde weniger reichen, aber in der Totale am Boden ist die Kamera weit weg und zeigt 3349 x 2512 Pixel.
- `scroll_scale` steht nicht da, also gilt der Standard 1: Die Wolken bewegen sich genau so schnell wie die Welt. Das heisst, sie stehen in der Welt fest. Zum Vergleich: Die Pappe laeuft nur halb so schnell mit (`mitlaufen` 0,5).

`Wolken` steht in der Liste zwischen `Hintergrund` und `Boden`. Darum werden die Wolken vor der Pappe gezeichnet, aber hinter der Wiese, den Fliegen und der Kanone.

### `Wolke1`, `Wolke2`, `Wolke3` (Sprite2D) - neu

Je ein Bild, mit `scale = 0.65` etwa 500 bis 580 Pixel breit. Die Orte:

- `Wolke1` bei (200, 250)
- `Wolke2` bei (1500, 800)
- `Wolke3` bei (2800, 520)

Warum sieht man so immer eine? Zur Seite: Von Wolke 1 zu Wolke 2 sind es 1300 Pixel, von 2 zu 3 auch 1300, von 3 zur naechsten Kopie von Wolke 1 (bei 4200) sind es 1400. Der Bildschirm ist 1440 breit, also breiter als jede Luecke: Mindestens eine Wolkenmitte liegt immer in der Breite des Bildes. Nach oben: Jede Wolke kommt alle 1080 Pixel wieder, und das Bild ist 1080 hoch. Also liegt diese Wolke auch in der Hoehe immer im Bild.

### So wurde es angeschaut

- Verify PASS.
- Probe: Kanone an acht Orte gestellt (zur Seite von 0 bis 123456, in der Hoehe bis 28000) und je ein Bild gespeichert, dazu die Totale. In jedem Bild ist mindestens eine Wolke. Auf der weissen Pappe sieht man die Wolken als graue Flecken, auf den dunklen Pappen leuchten sie hell.
- Nicht angeschaut: ob die Wolken beim Spielen von den Fliegen ablenken.

### Drei Fragen zur Selbstkontrolle

1. Warum bleiben die Wolken in der Welt stehen, obwohl sie in einem `Parallax2D` liegen?
2. Was wuerde passieren, wenn `repeat_size` (4000, 2000) waere?
3. Warum liegen die Wolken hinter den Fliegen und nicht davor?

### Nachtrag: die bewegte Wolke aus deinem Video (27.11.2026)

Dein Wunsch: Aus dem Video mit der Wolke vor Blau kommt das Blau heraus, und diese Wolke ist auch immer mindestens einmal am Himmel zu sehen, genauso fest in der Welt.

**Die Bilder (`assets/hintergrund/wolken/bewegt/wolke-001.png` bis `wolke-150.png`).** Godot kann im Browser kein Video mit durchsichtigem Grund zeigen. Darum ist das Video in Einzelbilder zerlegt. Es hat 30 Bilder pro Sekunde und dauert 30 Sekunden, genommen ist jedes sechste Bild: 150 Bilder, 5 pro Sekunde. In jedem Bild ist das Blau herausgerechnet: Die Farbe am Bildrand ist der Hintergrund. Je weiter die Farbe eines Pixels davon entfernt ist, desto deckender ist er. Was dem Blau sehr aehnlich ist, also das Glas der Wolke, bleibt halb durchsichtig. Danach sind alle Bilder auf denselben Ausschnitt geschnitten und auf 320 Pixel Breite verkleinert, damit das Spiel im Browser nicht zu schwer wird. Dein Video ist unveraendert.

**`szenen/wolke_bewegt.tscn` - neu.** Ein einziger Knoten: `WolkeBewegt`, ein `AnimatedSprite2D`, derselbe Typ wie das Feuer und die Drahtrolle der Kanone.
- `sprite_frames`: die Liste der 150 Bilder, in der Animation `default`.
- `"speed": 5.0`: 5 Bilder pro Sekunde. 150 Bilder durch 5 sind 30 Sekunden, so lang wie dein Video.
- `"loop": true`: Nach dem letzten Bild geht es beim ersten weiter. Das letzte und das erste Bild deines Videos passen aneinander, man sieht keinen Sprung.
- `autoplay = "default"`: Die Animation startet von selbst.

Die Wolke hat eine eigene Szene, damit die 150 Zeilen mit den Bildern nicht in `spiel.tscn` stehen.

**`szenen/spiel.tscn` - `WolkenBewegt` (Parallax2D) und darin `WolkeBewegt`.** Gleich gebaut wie `Wolken`:
- `repeat_size = (1440, 900)`: Die bewegte Wolke kommt alle 1440 Pixel zur Seite und alle 900 Pixel nach oben wieder. Der Bildschirm ist 1440 breit und 1080 hoch, also liegt immer mindestens eine Wolkenmitte im Bild. 900 statt 1080, damit sie nicht immer im selben Abstand zu den drei anderen Wolken steht.
- `repeat_times = 5`: wie bei `Wolken`, fuer die Totale.
- `WolkeBewegt` steht bei (900, 450) mit `scale = 1.7`, also 320 x 1,7 = 544 Pixel breit.

Alle Kopien zeigen dasselbe Bild der Animation, weil es derselbe Knoten ist, der mehrmals gezeichnet wird.

**So wurde es angeschaut.** Verify PASS. Probe wie oben, dazu zweimal dasselbe Bild im Abstand von 3 Sekunden: Die Wolke hat sich dazwischen veraendert, in jedem der 11 Bilder ist eine bewegte Wolke zu sehen. Die Naht zwischen letztem und erstem Bild ist kleiner als ein normaler Schritt (4,6 gegen 6,1, mittlerer Farbunterschied). Nicht angeschaut: ob 5 Bilder pro Sekunde ruckelig wirken, und ob die 150 Bilder auf dem Handy im Browser fluessig laufen.

**Fragen.** 1. Warum ist das Video in Einzelbilder zerlegt? 2. Was aendert sich, wenn `"speed"` 10 ist? 3. Warum bleibt das Glas der Wolke halb durchsichtig?

### Nachtrag: nur noch die bewegte Wolke, in vier Fassungen (27.11.2026)

Dein Wunsch: Es bleibt bei der bewegten Wolke. Davon gibt es vier Fassungen: zwei laufen am Anfang der Animation, zwei in der Mitte, und je eine davon steht auf dem Kopf. Steigt man auf oder faehrt zur Seite, kommt erst einmal eine andere. Sie liegen nicht in einer Reihe, sondern versetzt, und trotzdem ist immer mindestens eine im Bild.

**Was weg ist.** Die drei stehenden Wolken `Wolke1` bis `Wolke3`, ihre Bilder `wolke-1.png` bis `wolke-3.png` und der Knoten `WolkenBewegt`. Was oben zu ihnen steht, gilt nicht mehr. Es gibt wieder nur einen `Parallax2D` mit dem Namen `Wolken`.

**`szenen/wolke_bewegt.tscn` - zweite Animation `mitte`.** In `sprite_frames` stehen jetzt zwei Animationen. `default` zeigt die Bilder 1 bis 150. `mitte` zeigt dieselben Bilder, faengt aber bei Bild 76 an: 76 bis 150, dann 1 bis 75. Beide sind gleich lang und gleich schnell. Eine Wolke mit `mitte` ist der anderen also immer genau eine halbe Runde (15 Sekunden) voraus. Dafuer braucht es kein Skript.

**`szenen/spiel.tscn` - `Wolken` (Parallax2D).**
- `repeat_size = (2600, 1600)`: Das Muster aus vier Wolken wiederholt sich alle 2600 Pixel zur Seite und alle 1600 nach oben.
- `repeat_times = 4`: reicht auch fuer die Totale (3349 x 2512 Pixel).

Darin vier Mal die Szene `wolke_bewegt.tscn`, alle mit `scale = 1.7`:

| Knoten | Ort | Animation | auf dem Kopf |
|---|---|---|---|
| `AnfangNormal` | (300, 300) | `default` | nein |
| `MitteKopf` | (1700, 420) | `mitte` | ja |
| `MitteNormal` | (1000, 1180) | `mitte` | nein |
| `AnfangKopf` | (2250, 1040) | `default` | ja |

- `rotation = 3.1415927` bei den zwei Kopf-Wolken: Das ist Pi, eine halbe Drehung. Die Wolke steht auf dem Kopf.
- `animation = &"mitte"` und `autoplay = "mitte"` bei den zwei Mitte-Wolken: Sie zeigen und starten die zweite Animation. Bei den anderen steht nichts, sie nehmen `default` aus der Wolkenszene.

**Das Muster.** Es sind zwei Reihen. Die obere Reihe liegt bei etwa 300 bis 420, die untere bei etwa 1040 bis 1180, und die untere ist zur Seite um etwa eine halbe Luecke verschoben, wie Ziegel in einer Mauer. Neben `AnfangNormal` liegt `MitteKopf`, darueber und darunter liegen `MitteNormal` und `AnfangKopf`: In jede Richtung kommt zuerst eine andere Fassung.

**Warum ist immer eine im Bild?** Zur Seite: In der oberen Reihe sind die Luecken 1400 und 1200 Pixel (300 bis 1700, 1700 bis 2900), in der unteren 1250 und 1350. Alle sind kleiner als die Bildbreite 1440. Nach oben: Von der Oberkante einer Reihe bis zur Unterkante der naechsten sind es hoechstens 980 Pixel (1040 bis 2020), das Bild ist 1080 hoch. Also liegt immer eine ganze Reihe in der Hoehe des Bildes, und in dieser Reihe liegt immer eine Wolkenmitte in der Breite.

**So wurde es angeschaut.** Verify PASS. Probe: Kanone an zehn Orte gestellt, auch je eine Luecke weiter zur Seite und eine Reihe hoeher, dazu die Totale. In allen 13 Bildern ist mindestens eine Wolke, und nebeneinander sieht man verschiedene Formen und Lagen. Nicht angeschaut: wie es sich beim Fliegen anfuehlt.

**Fragen.** 1. Warum laufen `default` und `mitte` nie auseinander? 2. Was passiert, wenn `MitteKopf` bei (2000, 420) steht? 3. Warum reicht fuer "auf dem Kopf" eine Zahl bei `rotation`?

## Geaendert: Die schnelle Fliege dreht sich in der Schleife nicht mehr (`skripte/fliege_schnell.gd`, 27.11.2026)

Dein Wunsch: In der Wende fliegt sie die Schleife ab, aber das Bild dreht sich nicht mit. Erst wenn sie wirklich in die andere Richtung fliegt, wird das Bild umgedreht (gespiegelt).

Weg ist in `fliegen` die Zeile
```gdscript
	rotation = richtung * TAU * gelenkt / WENDE_GANZ
```
Sie hat die ganze Fliege waehrend der Schleife einmal im Kreis gedreht. Ebenso weg: `rotation = 0.0` am Ende der Schleife, weil es nichts mehr zurueckzustellen gibt.

Neu am Ende der Schleife, direkt nach `richtung = -richtung`, und am Ende von `losfliegen`:
```gdscript
		bild_richten()
```
Neu am Ende des Skripts:
```gdscript
func bild_richten() -> void:
	$Bild.flip_h = richtung > 0.0
```
Das Bild der schnellen Fliege schaut nach links (der Kopf mit dem Auge ist links). `flip_h` spiegelt es waagrecht. Fliegt sie nach rechts (`richtung` groesser als 0), wird es gespiegelt und schaut nach rechts. Beim Start (`losfliegen`) und nach jeder Schleife wird das neu eingestellt.

Angeschaut (Probe ohne Bildschirm, eine Fliege mit festem Tempo beobachtet): Drehung bleibt die ganze Zeit 0, auch in der Schleife. Gespiegelt beim Flug nach rechts, nach der Schleife (64 Bilder spaeter) nicht mehr gespiegelt und auf dem Rueckweg nach links. Schnellcheck PASS.

Frage zur Selbstkontrolle: Warum steht `bild_richten()` nach `richtung = -richtung` und nicht davor?

## Fluegel fuer die schnelle Fliege (27.11.2026)

Wie bei der normalen Fliege: zwei Bilder aus deiner Krita-Datei, der `AnimationPlayer` `Flattern` wechselt sie (gleicher Takt wie die normale Fliege: Wechsel nach 0,017 Sekunden, also bei jedem Bild). Neu ist, dass du hier auch den Koerper bewegt hast: Er wippt zwischen den beiden Bildern um gut 8 Pixel. Darum gibt es eine dritte Spur, die das Bild des Koerpers (`Bild:texture`) mitwechselt.

### Die Bilder

- `assets/fluegel/schlag/schnell-vorn-1.png`, `-2.png`, `schnell-hinten-1.png`, `-2.png`: die Fluegel.
- `assets/fliegen/spiel/fliege-skizze-schlag-1.png`, `-2.png`: der Koerper in deinen zwei Stellungen. `fliege-skizze-kraeftig.png` bleibt unveraendert liegen.

### `szenen/fliege_schnell.tscn` - geaendert

Neu: `FluegelHinten` (hinter dem Koerper), `FluegelVorn` (davor) und `Flattern` mit drei Spuren. `Bild` zeigt in Ruhe `fliege-skizze-schlag-1.png`. Alles hat dieselbe Groesse wie der Koerper (`scale` 0,2167), so passt es genau aufeinander wie in Krita.

### `skripte/fliege_schnell.gd` - geaendert

Die schnelle Fliege wird gespiegelt, wenn sie nach rechts fliegt (`bild_richten`). Die Fluegel muessen mit, sonst saessen sie danach am falschen Ende.

```gdscript
var gespiegelt: bool = false
```
Merkt sich, ob Bild und Fluegel gerade gespiegelt sind. In der Szene schaut die Fliege nach links, also am Anfang nicht gespiegelt.

```gdscript
	var nach_rechts: bool = richtung > 0.0
	$Bild.flip_h = nach_rechts
```
Wie vorher, nur mit einem Namen fuer den Vergleich, weil er jetzt zweimal gebraucht wird.

```gdscript
	if nach_rechts != gespiegelt:
		gespiegelt = nach_rechts
		for fluegel in [$FluegelVorn, $FluegelHinten]:
			fluegel.flip_h = nach_rechts
			fluegel.position.x = -fluegel.position.x
```
Nur wenn sich die Richtung wirklich geaendert hat: Jeder Fluegel wird gespiegelt (`flip_h`) und auf die andere Seite der Fliegenmitte gesetzt (aus x 9 wird x -9). Ohne die Abfrage wuerde ein zweiter Aufruf mit derselben Richtung den Fluegel wieder zuruecksetzen. `[$FluegelVorn, $FluegelHinten]` ist eine Liste mit den beiden Knoten, die Schleife macht fuer beide dasselbe.

### So wurde es angeschaut

- Schnellcheck PASS fuer `fliege_schnell.gd`, Verify PASS.
- Probe: die schnelle Fliege nach links und nach rechts, je beide Schlagbilder. Die Fluegel sitzen in beiden Richtungen auf dem Ruecken.

### Drei Fragen zur Selbstkontrolle

1. Warum wird `position.x` umgedreht und nicht nur `flip_h` gesetzt?
2. Was ginge schief, wenn die Abfrage `nach_rechts != gespiegelt` fehlte und `bild_richten` zweimal hintereinander mit derselben Richtung liefe?
3. Warum braucht die schnelle Fliege eine dritte Spur, die normale nicht?

### Nachtrag: zweite Runde normale und schnelle Fliege, neu die scheue Fliege (27.11.2026)

Kein neuer Code. Du hast die normale und die schnelle Fliege in Krita noch einmal ueberarbeitet und die scheue Fliege neu gemacht. Alle drei sind gleich gebaut wie oben beschrieben: zwei Bilder je Fluegel, bei der schnellen und der scheuen auch zwei Koerperbilder, und `Flattern` wechselt sie alle 0,017 Sekunden.

- `szenen/fliege_normal.tscn`, `fliege_schnell.tscn`: neue Bilder, neue Positionen der Fluegel (sie liegen jetzt dort, wo du sie in Krita hingesetzt hast).
- `szenen/fliege_scheu.tscn`: neu `FluegelHinten`, `FluegelVorn`, `Flattern` mit drei Spuren; `Bild` zeigt `fliege-ohne-fluegel-schlag-1.png`. Die Fluegel sind tuerkis (Zone Scheue).
- Neue Bilder: `assets/fluegel/schlag/scheu-*.png`, `assets/fliegen/spiel/fliege-ohne-fluegel-schlag-1.png` und `-2.png`. Dein Original `fliege-ohne-fluegel.png` bleibt unveraendert.

### Nachtrag: Heuschrecke wieder im Original, dritte Runde normale und schnelle Fliege (27.11.2026)

Kein Code.

- `szenen/fliege_heuschrecke.tscn` zeigt wieder `heuschrecke-skizze.png`, dein Original. Die verstaerkte Fassung `heuschrecke-skizze-kraeftig.png` ist geloescht: Beim Verstaerken waren die duennen Linien (Fuehler, Beine) verloren gegangen, man hat die Heuschrecke kaum noch erkannt.
- `fliege_normal.tscn`, `fliege_schnell.tscn`, `fliege_scheu.tscn`: neue Fluegelbilder und Positionen aus deiner letzten Krita-Runde.

## Fluegel fuer die Heuschrecke (27.11.2026)

Wie bei den anderen: zwei Bilder fuer jeden Fluegel und fuer den Koerper aus deiner Krita-Datei, `Flattern` wechselt sie alle 0,017 Sekunden. Die Fluegel sind tuerkis (Zone Scheue).

In Krita war die Heuschrecke gespiegelt, damit sie wie die anderen Fliegen nach links schaut und die Fluegel gleich herum liegen. Beim Einbau wurden alle Bilder wieder zurueckgespiegelt, denn im Spiel schaut die Heuschrecke im Grundzustand nach rechts (so ist dein Original). Neue Bilder: `assets/fluegel/schlag/heuschrecke-*.png`, `assets/fliegen/spiel/heuschrecke-skizze-schlag-1.png` und `-2.png`.

### `skripte/fliege_heuschrecke.gd` - geaendert

In `sprung_beginnen` wurde bisher nur das Bild gespiegelt (`$Bild.flip_h`). Jetzt spiegeln die Fluegel mit, genau wie bei der schnellen Fliege:

```gdscript
var gespiegelt: bool = false
```
Merkt sich, ob gerade gespiegelt ist. Im Grundzustand schaut die Heuschrecke nach rechts, also nicht gespiegelt.

```gdscript
	var nach_links: bool = richtung < 0.0
	$Bild.flip_h = nach_links
	if nach_links != gespiegelt:
		gespiegelt = nach_links
		for fluegel in [$FluegelVorn, $FluegelHinten]:
			fluegel.flip_h = nach_links
			fluegel.position.x = -fluegel.position.x
```
Springt sie nach links, wird gespiegelt. Die Fluegel wechseln nur dann die Seite, wenn sich die Richtung wirklich geaendert hat; jeder Sprung ruft `sprung_beginnen` auf, auch der zweite in dieselbe Richtung.

Angeschaut: Schnellcheck PASS, Verify PASS, Probebild mit vier Heuschrecken (nach rechts und nach links, je beide Schlagbilder): Fluegel sitzen jedes Mal auf dem Ruecken.

Frage: Warum ist hier `richtung < 0.0` der gespiegelte Fall, bei der schnellen Fliege aber `richtung > 0.0`?

### Nachtrag: Fluegel fuer die Koeder-Fliege (27.11.2026)

Kein Code, nur `szenen/fliege_koeder.tscn`: violette Fluegel (Zone Koeder) und wippender Koerper aus deiner Krita-Datei, gebaut wie bei der scheuen Fliege. Neue Bilder: `assets/fluegel/schlag/koeder-*.png`, `assets/fliegen/spiel/fliege-fuehler-gruen-schlag-1.png` und `-2.png`; dein Original bleibt.

### Nachtrag: Fluegel fuer die Teleport-Fliege (27.11.2026)

Kein Code, nur `szenen/fliege_teleport.tscn`: orange Fluegel (Zone Boss) und wippender Koerper aus deiner Krita-Datei. Du hast den Koerper in Krita etwa 1,5-mal so gross gemacht; die neuen Koerperbilder sind darum groesser, und weil `fliege.gd` die Trefferflaeche aus der Bildgroesse rechnet, ist auch die Trefferflaeche groesser. Das Flackern beim Teleport betrifft die ganze Fliege (`modulate` am obersten Knoten), die Fluegel flackern also mit. Neue Bilder: `assets/fluegel/schlag/teleport-*.png`, `assets/fliegen/spiel/fliege-1-schlag-1.png` und `-2.png`; dein Original bleibt.

### Nachtrag: Fluegel fuer den Bockkaefer (27.11.2026)

Kein Code, nur `szenen/fliege_boss.tscn`: orange Fluegel (Zone Boss) und Koerper aus deiner Krita-Datei. Du hast in Krita den hinteren Fluegel ueber den Koerper gelegt. Darum steht `FluegelHinten` hier in der Liste **nach** `Bild` (vor `FluegelVorn`): Was weiter unten in der Liste steht, wird spaeter und damit weiter vorn gemalt, also liegen beide Fluegel vor dem Koerper. Neue Bilder: `assets/fluegel/schlag/boss-*.png`, `assets/fliegen/spiel/bockkaefer-skizze-schlag-1.png` und `-2.png`; dein Original bleibt.

Damit haben alle sieben Fliegen der Zonen Fluegel, die schlagen.

## Die Wiese bleibt unter der Kanone: man landet immer an derselben Stelle (`skripte/spiel.gd`, 27.11.2026)

Dein Wunsch: Wer hochfliegt, zur Seite faehrt und dann ganz abstuerzt, soll nicht irgendwo auf der Wiese landen, sondern immer genau dort, wo er gestartet ist.

Vorher stand die Wiese fest in der Welt. Fuhr die Kanone in der Luft 3000 Pixel nach rechts, lag der Startplatz mit den Pfosten und der Einstellungsfliege 3000 Pixel links von ihr. Jetzt faehrt die Wiese zur Seite einfach mit. Nach oben und unten bleibt sie, wo sie ist.

```gdscript
var fliege_abstand: float = 0.0
```
Neu, oben bei den Variablen. Wie weit die Einstellungsfliege am Anfang rechts von der Kanone steht.

```gdscript
	fliege_abstand = $Einstellungsfliege.position.x - $Kanone.position.x
```
Neu, in `_ready`. Der Abstand wird einmal am Anfang gemessen: 700 - 0 = 700 Pixel. Er steht nicht als feste Zahl im Skript, damit du die Fliege in der Szene verschieben kannst, ohne das Skript zu aendern.

```gdscript
	$Boden.scroll_offset.x = $Kanone.position.x
```
Neu, am Ende von `_process`, also in jedem Bild. `scroll_offset` verschiebt alles, was in `Boden` liegt: Wiese, Pfosten und Nummern. Steht die Kanone bei x = 3000, ist auch der Boden um 3000 nach rechts geschoben. Nur `.x` wird gesetzt, die Hoehe (1212) bleibt.

```gdscript
	$Einstellungsfliege.position.x = $Kanone.position.x + fliege_abstand
```
Neu, direkt darunter. Die Einstellungsfliege liegt nicht in `Boden`, darum bekommt sie ihre eigene Zeile: immer 700 Pixel rechts von der Kanone.

Warum so und nicht die Kanone beim Absturz zurueck zur Mitte schieben? Dann wuerden Fliegen und Wolken im Fallen zur Seite wegrutschen. So bleibt in der Luft alles, wie es war, und nur der Boden kommt mit. Die Wiese wiederholt sich weiter nach links und rechts, aber nur, damit das breite Bild der Totale gefuellt ist. Hinfahren kann man zu den Kopien nicht mehr.

### So wurde es angeschaut

- Schnellcheck PASS fuer `spiel.gd`, Verify PASS.
- Probe: Start aufgenommen, auf 5 Flugkraft gesprungen, die Kanone einmal 3777 Pixel nach rechts und einmal 9123 nach links gestellt, alles verloren, Landung aufgenommen. In beiden Landungen stehen die Pfosten 0 bis 7 und die Einstellungsfliege an derselben Stelle neben der Figur wie beim Start. Gemessen: `Boden.scroll_offset.x` gleich Kanonen-x, Fliege genau 700 daneben.
- Nicht angeschaut: wie es sich im Spiel anfuehlt, wenn man knapp ueber dem Boden zur Seite faehrt.

### Drei Fragen zur Selbstkontrolle

1. Warum wird `fliege_abstand` in `_ready` gemessen und nicht als 700 hingeschrieben?
2. Warum wird nur `scroll_offset.x` gesetzt und nicht der ganze `scroll_offset`?
3. Was wuerde man sehen, wenn die Zeile mit `$Einstellungsfliege` fehlt?

### Nachtrag: nur noch das eine Wiesenbild, ohne Spiegelung und ohne Wiederholung (`szenen/spiel.tscn`, 27.11.2026)

Dein Wunsch: Die Figur stand genau ueber der Stelle, an der die Wiese gedoppelt ist. Du willst nur das eine Wiesenbild sehen, so wie oben im Einstellungsmenue, und es soll sich nie zur Seite bewegen.

Was los war: `wiese.png` ist 1280 Pixel breit und besteht aus zwei Haelften. Links das Wiesenbild, rechts dasselbe Bild gespiegelt. Dazu wiederholte `Boden` das Ganze alle 6694 Pixel. Die Figur stand genau auf einer dieser Naehte.

Geaendert, nur in der Szene:

- `Boden`: `repeat_size` und `repeat_times` sind weg. Die Wiese wird nicht mehr wiederholt, es gibt sie genau einmal.
- `Boden/Wiese`: `region_enabled = true` und `region_rect = Rect2(0, 0, 640, 640)`. Das Sprite zeigt nur noch einen Ausschnitt der Datei: ab der linken oberen Ecke 640 Pixel breit und 640 hoch. Das ist die linke Haelfte, also das eine Bild ohne Spiegelung. Die Datei selbst ist unveraendert.
- `scale = 5.33` statt 5,23: 640 x 5,33 = 3411 Pixel. In der Totale zeigt die Kamera 3349 Pixel Breite. Das Bild ist also 31 Pixel breiter auf jeder Seite. Das reicht fuer das Wackeln beim Aufprall (hoechstens 28 Pixel).
- `position = (-1705.6, -429)`: die halbe Breite nach links, damit das Bild genau mittig unter der Kanone liegt.

Zusammen mit den Zeilen in `spiel.gd` von oben (`$Boden.scroll_offset.x = $Kanone.position.x`) heisst das: Es ist immer dasselbe Bild, immer an derselben Stelle im Bild, egal wie weit man in der Luft zur Seite gefahren ist.

**So wurde es angeschaut.** Verify PASS. Probe wie oben (3777 nach rechts, 9123 nach links, abstuerzen): Der Wiesenstreifen ist beim Start und nach beiden Landungen Pixel fuer Pixel gleich (Unterschied 0,0). Links und rechts im Bild ist keine Spiegelung mehr (Unterschied der Haelften 46,7, bei einer Spiegelung waere es 0), und die Wiese reicht bis an beide Bildraender.

**Fragen.** 1. Was macht `region_rect`? 2. Warum ist das Bild etwas breiter als das, was die Kamera zeigt? 3. Warum steht bei `position` eine negative Zahl?

### Nachtrag: Fluegel fuer die Stechfliege (27.11.2026)

Kein Code, nur `szenen/stechfliege.tscn`: tuerkise Fluegel (sie sticht in der Zone Scheue, `Stecher` haengt an `Zonen/Scheue`) und wippender Koerper aus deiner Krita-Datei, gebaut wie bei den anderen. Wenn sie sich auf der Hand hochkant dreht, drehen die Fluegel mit, weil sie Kinder desselben Knotens sind. Neue Bilder: `assets/fluegel/schlag/stech-*.png`, `assets/fliegen/spiel/fliege-ruessel-orange-schlag-1.png` und `-2.png`; dein Original bleibt. Damit haben alle acht Insekten Fluegel.

## Nagel und Draht als Bild (27.11.2026)

Die Nadel war bisher ein weisser Strich mit einer grauen Linie dahinter. Jetzt ist sie der Nagel aus deinem Bild `nagel_mit_draht.png`, und die Linie ist ein Draht, gemalt mit der Spitze deines Krita-Stifts "Draht gruen".

### Die Bilder

- `assets/nadel/nagel_flug.png`: der ganze Nagel mit der Drahtwicklung am Kopf, aus `nagel_mit_draht.png` bis zur Unterkante des Kopfes ausgeschnitten.
- `assets/nadel/nagel_halb_rund.png`: die hinteren 30 Prozent davon, also Kopf und Wicklung (so viel wie bei `nagel_halb.png`), von dir in Photoshop an der Schnittkante abgerundet.
- `assets/nadel/draht_textur.png`: ein Streifen Draht, 240 mal 44 Pixel, aus vielen Abdruecken der Stiftspitze. Er ist so gebaut, dass sein rechtes Ende genau an sein linkes passt: Hintereinandergelegt sieht man keine Naht.

### `szenen/nadel.tscn` - geaendert

- `Strich` (das weisse Rechteck) ist weg.
- Neu: `Nagel`, ein `Sprite2D` mit `nagel_flug.png`. `scale` 0,1391 macht den Nagel 150 Pixel lang. `centered = false` mit `offset = (-58,5, -2)`: Die Nagelspitze sitzt genau auf dem Nullpunkt der Nadel, denn dort prueft `nadel.gd`, ob eine Fliege getroffen ist. Der Nagel haengt nach unten, weil die Nadel nach oben fliegt.
- Neu: `NagelHalb` mit `nagel_halb_rund.png`, zuerst unsichtbar.
- `Oese` sitzt jetzt dort, wo der Draht den Nagelkopf verlaesst: (7,2 / 150).
- `Faden` ist kein `top_level` mehr (siehe Nachtrag unten) und hat jetzt eine Textur: `texture` ist der Drahtstreifen, `texture_mode = 1` heisst "wiederholen" (der Streifen wird entlang der Linie immer wieder hintereinandergelegt), `texture_repeat = 2` erlaubt Godot, das Bild zu wiederholen. `width` 3: Der Streifen wird auf 3 Pixel Hoehe gedrueckt. `joint_mode = 2` macht die Knicke zwischen den Linienstuecken rund.

### `skripte/nadel.gd` - geaendert

```gdscript
@export var durchhang_flug: float = 0.02
@export var durchhang_haengend: float = 0.06
@export var draht_stuecke: int = 16
@export var oese_halb: Vector2 = Vector2(7.2, 45.6)
@export var steck_tiefe: float = 0.6
```
Fuenf neue Werte fuer den Inspector: wie stark der Draht durchhaengt (2 Prozent seiner Laenge im Flug, 6 Prozent, wenn er an der Hand haengt), aus wie vielen Stuecken die Drahtlinie besteht, wo am halben Nagel der Draht herauskommt, und wie tief der halbe Nagel in der Fliege steckt.

```gdscript
	var bild: Sprite2D = getroffene.get_node("Bild")
	var halbe_hoehe: float = bild.texture.get_size().y * absf(bild.scale.y) / 2.0
	halb_zeigen(halbe_hoehe * steck_tiefe)
```
Neu am Anfang von `aufspiessen`: Wie hoch ist die getroffene Fliege? `texture.get_size().y` ist die Hoehe ihres Bildes in Pixeln, mal ihre Groesse (`scale`), durch 2 ist die halbe Hoehe. `absf` macht eine Zahl positiv, falls das Bild gespiegelt ist. Mit `steck_tiefe` 0 sitzt die Schnittkante des halben Nagels genau in der Fliegenmitte (siehe Nachtrag unten).

```gdscript
	halb_zeigen(0.0)
```
Neu in `stecken_in` (Boss): Dort steckt die Nadel genau an der Trefferstelle.

```gdscript
func halb_zeigen(tiefe: float) -> void:
	$Nagel.visible = false
	$NagelHalb.visible = true
	$NagelHalb.position.y = tiefe
	$Oese.position = Vector2(oese_halb.x, tiefe + oese_halb.y)
```
Der ganze Nagel verschwindet, der halbe erscheint, `tiefe` Pixel unter der Spitze. Die Oese wandert mit, damit der Draht am Kopf des halben Nagels haengt. Bei jedem Treffer wird das neu gesetzt, weil der Nagel dann in der neuen Fliege steckt.

```gdscript
	var oben: Vector2 = $Oese.global_position
	var unten: Vector2 = anker.global_position
	var bogen: Vector2 = durchbiegung(oben, unten)
	var punkte: PackedVector2Array = []
	for nummer in draht_stuecke + 1:
		punkte.append(faden_punkt(oben, unten, bogen, float(nummer) / draht_stuecke))
	$Faden.points = punkte
```
`faden_spannen` zeichnet den Draht jetzt nicht mehr als eine gerade Linie mit zwei Punkten, sondern mit 17 Punkten auf einer Kurve. `float(nummer) / draht_stuecke` geht von 0 bis 1: 0 ist oben an der Nadel, 1 unten am Anker.

```gdscript
		var anteil: float = minf(spiess_abstand * global_scale.x * schritte / laenge, 1.0)
		fliege.global_position = faden_punkt(oben, unten, bogen, anteil)
```
Aeltere aufgespiesste Fliegen sitzen auf derselben Kurve wie der Draht, sonst schwebten sie neben ihm. `anteil` rechnet ihren Abstand in einen Anteil der Drahtlaenge um. `minf(..., 1.0)` verhindert, dass eine Fliege hinter den Anker rutscht.

```gdscript
func durchbiegung(oben: Vector2, unten: Vector2) -> Vector2:
	var richtung: Vector2 = oben.direction_to(unten)
	var quer: Vector2 = Vector2.DOWN - richtung * Vector2.DOWN.dot(richtung)
```
`Vector2.DOWN` ist die Schwerkraft. `dot` misst, wie viel davon in Drahtrichtung zeigt. Zieht man diesen Teil ab, bleibt nur der Teil, der quer zum Draht zieht: Bei einem waagerechten Draht ist das die ganze Schwerkraft, bei einem senkrechten nichts. Darum haengt ein schraeger Draht durch und ein senkrechter bleibt gerade.

```gdscript
	return oben.lerp(unten, anteil) + bogen * 4.0 * anteil * (1.0 - anteil)
```
`faden_punkt`: `lerp` gibt den Punkt auf der geraden Linie. Dazu kommt der Bogen: `anteil * (1 - anteil)` ist an den Enden 0 und in der Mitte 0,25. Mal 4 ergibt in der Mitte genau den vollen Bogen. Das ist eine Parabel, die fuer einen leicht durchhaengenden Draht gut genug aussieht.

### `skripte/uebergabe.gd` - geaendert

```gdscript
@export var fadenpunkt: Node2D
```
Ein Punkt, der das Drahtende von der Muendung zur Hand traegt.

```gdscript
		fadenpunkt.global_position = nadel.anker.global_position
		nadel.anker = fadenpunkt
		...
		zurueck.parallel().tween_property(fadenpunkt, "position", griff.position, dauer)
		await zurueck.finished
		if is_instance_valid(nadel):
			nadel.anker = griff
```
Bisher sprang das Drahtende am Ende der Fahrt von der Muendung zur Hand. Jetzt setzt sich der Fadenpunkt erst auf die Muendung, der Draht haengt an ihm, und waehrend die Kanone zurueckfaehrt, gleitet er in derselben Zeit zum Griff. Erst danach haengt der Draht wirklich am Griff. `is_instance_valid` fragt, ob es die Nadel noch gibt: Ein Hindernis kann sie in der Zwischenzeit abgeschossen haben.

### `szenen/spiel.tscn` - geaendert

Neu: `Kanone/Fadenpunkt`, ein `Marker2D` auf dem Griff. Er ist ein Kind der Kanone wie der Griff, darum kann er mit `position` (statt `global_position`) zum Griff gleiten, auch wenn die Kanone dabei steigt. `Uebergabe` kennt ihn ueber `fadenpunkt`.

### So wurde es angeschaut

- Schnellcheck PASS fuer `nadel.gd` und `uebergabe.gd`, Verify PASS.
- Probe in der Luftansicht: Schuss auf zwei Fliegen uebereinander. Die Nadel spiesst beide auf (nach 6 Bildern steckt die erste), der halbe Nagel schaut unter der oberen heraus, die untere sitzt auf dem Draht. Waehrend der Uebergabe laeuft der Draht von der Muendung zur Nadel, danach haengt er im Bogen von der Hand zur Nadel.
- Nicht angeschaut: ob die Bewegung echt wirkt (dein Blick), die Totale.

### Drei Fragen zur Selbstkontrolle

1. Warum bleibt ein senkrecht gespannter Draht gerade?
2. Was zeigt `faden_punkt` bei `anteil = 0.5`, und warum steht dort `4.0`?
3. Warum wird der halbe Nagel bei jedem Treffer neu gesetzt und nicht nur beim ersten?

### Nachtrag: Blut in Zonenfarbe, Nagel mittig, Draht ohne Luecke (27.11.2026)

**Draht ohne Luecke.** Waehrend die Nadel zum Faecher faehrt, war zwischen Nagelkopf und Draht eine Luecke. Gemessen: Die Zahlen stimmten, der erste Drahtpunkt lag genau auf der Oese. Der Grund ist, dass Godot eine `Line2D` erst im naechsten Bild neu zeichnet, wenn sich ihre Punkte aendern. Der Draht war frei im Raum aufgehaengt (`top_level`) und hing deshalb bei jeder Bewegung ein Bild hinterher. Jetzt ist er ein normales Kind der Nadel:

```gdscript
		punkte.append($Faden.to_local(faden_punkt(oben, unten, bogen, float(nummer) / draht_stuecke)))
```
`to_local` rechnet einen Punkt aus Weltkoordinaten in die Koordinaten des Drahts um. Weil der Draht an der Nadel haengt, bewegt er sich mit ihr mit, und das Ende am Nagel bleibt immer am Nagel. Nur das andere Ende (Muendung oder Hand) kann ein Bild hinterherhaengen, das sieht man dort nicht.

**Nagel mittig.** `steck_tiefe` ist jetzt -0,15: Die Schnittkante des halben Nagels sitzt 15 Prozent der halben Fliegenhoehe ueber der Mitte. Minus heisst nach oben. So deckt der Nagel das dunkle Blutloch, ohne zu weit hinauszuragen. `Nagel` und `NagelHalb` haben `z_index = 3`, sie werden also ueber der Fliege gemalt (die Fliegen haben 1). So sieht es aus, als steckte der Nagel in ihr. In die halbe Hoehe der Fliege rechnet `aufspiessen` jetzt auch die Groesse des obersten Fliegenknotens ein (`getroffene.scale.y`), weil die Fliegen dort inzwischen verkleinert sind.

**Blut statt rotem Kreis.**
- `szenen/blutfleck.tscn` ist jetzt nur noch ein `Sprite2D` mit `assets/blut/blut.png`, ohne Skript. `scale` 0,125 (seit dem 27.11. halb so gross wie zuerst, 0,25). `skripte/blutfleck.gd` (der wachsende, verblassende Kreis) ist geloescht.
- `assets/blut/blut-ausgeschnitten.png` ist dein Ausschnitt, beide Ebenen zusammen, mit der abgedunkelten Mitte. `assets/blut/blut.png` ist daraus gemacht: nur noch hell und dunkel (grau), damit man es einfaerben kann. `modulate` multipliziert jede Farbe des Bildes mit einer Farbe: Weiss wird zur Zonenfarbe, Schwarz bleibt schwarz.
- `skripte/fliege.gd`: neu `@export var blut_farbe: Color`. Jede Fliegenszene hat ihre Zonenfarbe eingetragen: Rosa (normal, schnell), Tuerkis (scheu, Heuschrecke), Violett (Koeder), Orange (Teleport, Boss).

```gdscript
	var fleck: Node2D = blutfleck_szene.instantiate()
	fleck.modulate = getroffene.blut_farbe
	getroffene.add_child(fleck)
```
In `aufspiessen`: Der Fleck wird ein Kind der Fliege. Er sitzt damit an ihrer Mitte, dort wo die Nadel einsticht, wird ueber ihr gemalt, aber unter dem Nagel (der hat `z_index` 3). Bei mehreren aufgespiessten Fliegen hat jede ihren eigenen Fleck. Der rote Platzhalter `Loch` wird nicht mehr eingeschaltet.

In `stecken_in` (Boss) wird der Fleck ein Kind des Bosses, an der Stelle, wo die Nadel steckt.

Angeschaut: Schnellcheck PASS, Verify PASS, Probe in der Luftansicht vergroessert an der Nadel beim Treffer, mitten in der Fahrt und im Faecher: keine Luecke mehr, Nagel mittig, Blut rosa mit dunkler Mitte unter dem Nagel.

Fragen: Warum bleibt der Draht am Nagel, seit er ein Kind der Nadel ist? Was wird aus einem schwarzen Bildpunkt, wenn man `modulate` auf Tuerkis setzt?

## Aufstehen mit deinen Fotos (`szenen/spiel.tscn`, 27.11.2026)

Dein Wunsch: Nach dem Absturz kommt dein Aufprallbild (mit dem Arm hinter dem Koerper), danach das Bild, auf dem du kniest, so wie du es in Krita angeordnet hast.

### Die Bilder (`assets/forscher/aufstehen/aufprall.png` und `kniend.png`)

Beide sind aus deiner Krita-Datei gelesen, mit genau einem gemeinsamen Ausschnitt (1082 x 1079 Pixel). Darum liegen sie im Spiel zueinander genau so wie bei dir in Krita: Der Kniende steht dort, wo du ihn hingeschoben hast. Das dritte Bild (`aufstehend-65`) hattest du aus der Zeitleiste genommen, es ist nicht dabei.

### `SpriteFrames_aufstehen` - geaendert

Vorher drei graue Kaesten (liegt, kniet, steht). Die drei grauen Verlaeufe dafuer sind geloescht, sie wurden nur hier benutzt. Jetzt:

- erstes Bild `aufprall.png` mit `"duration": 2.0`: Es bleibt zwei Bilder lang stehen. In Krita hattest du es auf Bild 0 und 1 der Zeitleiste.
- zweites Bild `kniend.png` mit `"duration": 1.0`.
- `"speed": 6.0`: 6 Bilder pro Sekunde, wie in deiner Krita-Datei. Das Ganze dauert also 3 / 6 = 0,5 Sekunden.

### `Kanone/Aufstehen` - geaendert

- `scale = 0.76`: Das Bild ist 76 Prozent so gross wie das Foto. Der Kniende ist dann etwa 740 Pixel hoch, drei Viertel der grauen Figur (990), weil ein Kniender etwa drei Viertel so hoch ist wie ein Stehender.
- `position = (130, 802)`: x 130 ist die Mitte der Figur. Die Unterkante des Bildes liegt auf dem Boden: 802 + 1079 x 0,76 / 2 = 1212, und 1212 unter der Kanone ist die Wiese.

`spiel.gd` ist unveraendert: `aufstehen()` zeigt den Knoten und spielt `aufstehen`, am Ende startet das Spiel neu.

### So wurde es angeschaut

- Verify PASS.
- Probe: hochgesprungen, alles verloren, beim Aufprall und 0,4 Sekunden spaeter ein Bild aufgenommen. Erst liegt der Forscher an den Pfosten, dann kniet er. Der Kniende schwebt etwa 80 Pixel ueber der Bodenlinie, weil er in deiner Krita-Datei hoeher steht als der Liegende.
- Nicht angeschaut: ob 0,5 Sekunden zu kurz sind, bevor das Spiel neu startet.

### Drei Fragen zur Selbstkontrolle

1. Warum haben beide Bilder denselben Ausschnitt?
2. Was aendert `"duration": 2.0` am ersten Bild?
3. Wie kommt man auf `position.y = 802`?

### Nachtrag: Fallen bis zum Boden, und du ziehst den Forscher selbst hin (`skripte/spiel.gd`, `szenen/spiel.tscn`, 27.11.2026)

Dein Wunsch: Beim Absturz bis auf den Boden faellt der Forscher (mit dem Verlauf nach oben, der staerker und schwaecher wird) und landet genau dort, wo du ihn im Godot-Editor hinziehst.

**Die Bilder (`assets/forscher/aufstehen/`).** Neu sind `fallen-1.png` bis `fallen-6.png`: deine zwei Fallbilder in je drei Staerken, in der Reihenfolge aus Krita (4 mittel, 5 stark, 4 schwach, 5 mittel, 4 stark, 5 schwach). Alle acht Bilder (6 x Fallen, Aufprall, Knien) haben jetzt denselben Ausschnitt (1097 x 1079 Pixel). Darum liegen `aufprall.png` und `kniend.png` neu da, 15 Pixel breiter, sonst gleich. Der gemeinsame Ausschnitt heisst: Fallen, Aufprall und Knien sitzen zueinander so, wie du sie in Krita angeordnet hast. Ziehst du den Knoten, wandert alles zusammen.

**`SpriteFrames_aufstehen` - zweite Animation `fallen`.** Neben `aufstehen` gibt es `fallen`: die sechs Bilder, `"speed": 12.0` (12 Bilder pro Sekunde, wie in der Krita-Datei), `"loop": true`. Weil sie sich wiederholt, meldet sie nie `animation_finished`. Das Spiel startet also nicht mitten im Fallen neu.

**`Kanone/Aufstehen` - geaendert.** Die Zeile `visible = false` ist weg: Im Editor siehst du den Forscher jetzt und kannst ihn ziehen. `position` ist (136, 802), sechs Pixel weiter rechts als vorher, weil der Ausschnitt links breiter geworden ist. So liegt der Liegende an derselben Stelle.

**`skripte/spiel.gd` - geaendert.**

```gdscript
	$Kanone/Aufstehen.visible = false
```
Neu in `_ready`. Weil der Knoten in der Szene sichtbar ist, wird er beim Spielstart versteckt.

```gdscript
		fallen()
```
Neu in `fliege_verlieren`, im Zweig `if flugkraft <= 0:`. Nur wenn man ganz abstuerzt, faellt der Forscher.

```gdscript
func fallen() -> void:
	$Kanone/Arm.visible = false
	$Kanone/Figur.visible = false
	$Kanone/Aufstehen.visible = true
	$Kanone/Aufstehen.play("fallen")
```
Neu. Kanone und graue Figur verschwinden, der Forscher erscheint und spielt `fallen`. Er haengt an der Kanone und faellt mit ihr nach unten. Kommt die Kanone unten an, ruft der Tween wie bisher `aufstehen()`, und das spielt `aufstehen`: Aufprall, dann Knien. Faengt man im Fallen noch eine Fliege, macht `aufstehen_abbrechen()` alles wieder rueckgaengig, wie vorher.

**So ziehst du ihn hin.** In `spiel.tscn` den Knoten `Kanone` > `Aufstehen` auswaehlen und verschieben. Im Editor sieht man das Aufprallbild. Die Wiese liegt 1212 Pixel unter der Kanone.

**So wurde es angeschaut.** Schnellcheck PASS fuer `spiel.gd`, Verify PASS. Probe: hochgesprungen, alles verloren, Bilder aufgenommen. Am Start ist der Forscher unsichtbar. Im Fallen laeuft `fallen`, er kommt beim Herauszoomen von unten ins Bild, dann liegt er und kniet. Nicht angeschaut: wie sich das im Spiel anfuehlt.

**Fragen.** 1. Warum meldet `fallen` nie `animation_finished`? 2. Warum muessen alle acht Bilder denselben Ausschnitt haben? 3. Warum wird der Knoten in `_ready` versteckt und nicht in der Szene?

### Nachtrag: Draht durch die Fliegen, Nadel trifft auch bei Rucklern (27.11.2026)

**Draht durch die Fliegen** (dein Nachtrag zu Abschnitt 10 vom 21.11.: Fliegen in zwei Teile teilen, damit der Faden zwischen ihnen durchlaeuft). Statt jedes Fliegenbild in zwei Dateien zu zerschneiden, macht das die Reihenfolge beim Malen: Der ganze Draht (`Faden`, `z_index` 0) liegt hinter den Fliegen (`z_index` 1). Vor der unteren Haelfte jeder aelteren Fliege liegt ein kurzes Drahtstueck (`z_index` 2), von ihrer Mitte bis zu ihrem unteren Rand. Man sieht also den Draht unten ueber der Fliege, er verschwindet im dunklen Blutloch in der Mitte und kommt oben hinter ihr wieder heraus. Die oberste Fliege braucht das nicht, in ihr steckt der Nagel.

- Neu: `szenen/draht_vorn.tscn`, eine `Line2D` mit derselben Drahttextur und `z_index = 2`. `nadel.tscn` kennt sie ueber `draht_vorn_szene`.
- `nadel.gd`: neue Listen `halbe_groessen` (halbe Breite und halbe Hoehe jeder aufgespiessten Fliege, beim Aufspiessen gemerkt) und `vorn_stuecke` (die kurzen Drahtstuecke).

```gdscript
func vorn_spannen(nummer: int, oben: Vector2, unten: Vector2, bogen: Vector2, anfang: float, stueck_anteil: float) -> void:
	while vorn_stuecke.size() <= nummer:
		var neues: Line2D = draht_vorn_szene.instantiate()
		add_child(neues)
		vorn_stuecke.append(neues)
```
Fuer die Fliege Nummer `nummer` braucht es ein Drahtstueck. Gibt es noch keines, entsteht es aus der Szene. `while` statt `if`, damit auch mehrere fehlende auf einmal entstehen.

```gdscript
	for schritt in 5:
		var anteil: float = minf(anfang + stueck_anteil * schritt / 4.0, 1.0)
		punkte.append(stueck.to_local(faden_punkt(oben, unten, bogen, anteil)))
```
Fuenf Punkte auf derselben Kurve wie der Draht, von der Fliegenmitte (`anfang`) bis knapp ueber ihren Rand hinaus, zum Anker hin. So liegt das Stueck genau auf dem Draht. `faden_loesen` leert auch die Stuecke.

**Nadel trifft auch bei Rucklern.** In der Probe dauerte das erste Bild nach dem Schuss deutlich laenger. Die Nadel sprang in einem Satz von 337 auf 791 Pixel ueber der Muendung und flog ueber zwei Fliegen hinweg, ohne sie zu treffen. Im Browser oder auf dem Handy kann so ein Ruckler auch vorkommen. Darum legt die Nadel ihre Strecke jetzt in Schritten von hoechstens 40 Pixeln zurueck (`schritt_weite`) und prueft nach jedem Schritt:

```gdscript
	var strecke: float = tempo * delta
	var schritte: int = maxi(1, ceili(strecke / schritt_weite))
	for schritt in schritte:
		position += richtung * strecke / schritte
		geflogen += strecke / schritte
		if fliegen_pruefen():
			break
```
`ceili` rundet auf: 100 Pixel in Schritten von 40 sind 3 Schritte. `maxi(1, ...)` sorgt fuer mindestens einen Schritt. Was vorher direkt in `_process` stand (Treffer, stecken bleiben, verschwinden), steht jetzt in `fliegen_pruefen`. Die Funktion gibt `true` zurueck, wenn die Nadel nicht weiterfliegt; dann bricht `break` die Schleife ab.

Angeschaut: Schnellcheck PASS, Verify PASS. Probe mit dem Ruckler dreimal: jedes Mal beide Fliegen aufgespiesst (vorher keine). Bild im Faecher vergroessert: Der Draht laeuft durch die untere Fliege wie beschrieben.

Fragen: Warum braucht die oberste Fliege kein Drahtstueck? Wie viele Schritte macht die Nadel in einem Bild, das 0,14 Sekunden dauert?

**Luecke am Fliegenrand.** Zuerst war das kurze Stueck so lang wie die halbe Fliegenhoehe. Laeuft der Draht schraeg, ist die Fliege in dieser Richtung aber breiter, und zwischen dem Ende des Stuecks und ihrem Rand war der Draht verdeckt (dein Bild). Jetzt rechnet `rand_abstand` den Weg bis zum Rand in Drahtrichtung, die Fliege als Ellipse gedacht:

```gdscript
func rand_abstand(halb: Vector2, richtung: Vector2) -> float:
	var x: float = richtung.x / maxf(halb.x, 1.0)
	var y: float = richtung.y / maxf(halb.y, 1.0)
	return 1.0 / maxf(sqrt(x * x + y * y), 0.001)
```
Das ist die Formel fuer den Abstand von der Mitte einer Ellipse bis zu ihrem Rand in einer Richtung. Senkrecht (richtung (0, 1)) kommt genau die halbe Hoehe heraus, waagerecht die halbe Breite. `maxf` verhindert eine Teilung durch 0. Dazu kommen `rand_zugabe` (6 Pixel), damit das Stueck sicher ueber den Rand reicht. Im Probebild laeuft der Draht jetzt ohne Unterbrechung aus der Fliege heraus.

## Der Arm aus deinem Foto (`szenen/forscher_arm.tscn`, `szenen/spiel.tscn`, 27.11.2026)

Dein Wunsch: Der rechte Arm, den du in Krita auf die richtige Groesse gezogen hast, kommt einzeln ins Spiel und haelt die Kanone.

**Das Bild (`assets/forscher/arm-rechts.png`).** Dein Arm aus der Krita-Datei, genau deine Pixel. Bei dir hing er nach unten (Faust unten). Im Bild ist er um 180 Grad gedreht: Faust oben, Schulter unten, weil der Arm im Spiel nach oben zeigt. Fast durchsichtige Reste neben dem Arm sind weggeschnitten.

**`szenen/forscher_arm.tscn` - neu.** Eine eigene kleine Szene, damit `spiel.tscn` uebersichtlich bleibt.
- `ForscherArm` (Node2D): Sein Nullpunkt ist der Drehpunkt an der Schulter.
- `Foto` (Sprite2D) mit dem Arm. `centered = false` heisst: Die Position meint die linke obere Ecke des Bildes. `scale = 0.935` ist dieselbe Groesse, die du dem Forscher beim Aufstehen gegeben hast (die Fotos kommen aus derselben Kamera). `position = (-63.1, -452.5)`: halbe Bildbreite nach links (135 x 0,935 / 2) und ganze Bildhoehe nach oben (484 x 0,935). So sitzt die Schulter unten mittig auf dem Drehpunkt.

**`szenen/spiel.tscn` - geaendert.**
- In `Kanone/Figur/Schulter/Armbild` steckt neu `ForscherArm`, vor `Bild` (der Kanone). Was in der Liste weiter unten steht, wird spaeter gezeichnet, also liegt die Kanone vor der Faust.
- Die grauen Kaesten `Arm` und `Faust` sind ausgeblendet (`visible = false`), nicht geloescht. Du kannst sie zum Vergleich wieder einblenden.
- Von dir im Editor gesetzt: `Kanone/Aufstehen` steht bei (-130, 1115) mit Groesse 0,935. Dort landet man nach dem Absturz.

**So wurde es angeschaut.** Verify erst FAIL: `forscher_arm.tscn` hatte am Anfang eine unsichtbare Byte-Markierung (BOM), mit der Godot die erste Zeile nicht lesen kann. Entfernt, danach PASS. Probe: Start in der Totale und der Arm um 0,6 gedreht. Der Arm zeigt nach oben, die Kanone sitzt in der Faust, beim Drehen dreht er an der Schulter mit. Nicht angeschaut: ob Drehpunkt und Kanone genau sitzen, das stellst du im Editor nach.

**Fragen.** 1. Warum ist der Arm eine eigene Szene? 2. Wozu `centered = false`? 3. Warum liegt die Kanone vor dem Arm?

## Die Figur steht mit deinen Fotos (`szenen/spiel.tscn`, 27.11.2026)

Dein Wunsch: Die normale Steh-Animation (deine Bilder 0 bis 2 aus Krita) kommt schon ins Spiel, damit man sieht, wie es ungefaehr aussehen wird. Die Warte-Animation (Bild 3 und 4) noch nicht.

### Die Bilder (`assets/forscher/stehen/`)

- `stehen-koerper-1.png` bis `-3.png`: je Bild Hose und Oberkoerper, so wie du sie in Krita gelegt hast, zu einem Bild zusammengesetzt.
- `stehen-kopf-1.png` bis `-3.png`: der Kopf (`kopf-01`) in deiner Kopfgroesse. In jedem Bild steht er dort, wo der Hals in diesem Koerperbild ist.

Alle sechs haben denselben Ausschnitt (651 x 1534 Pixel). Darum passen Kopf und Koerper aufeinander, wenn beide Knoten an derselben Stelle stehen.

### `SpriteFrames_koerper` und `SpriteFrames_kopf` - neu

Je eine Animation `stehen` mit drei Bildern, `"speed": 6.0` (6 Bilder pro Sekunde wie in Krita), `"loop": true`.

### `Kanone/Figur/Gesicht` und `Kanone/Figur/Koerper` - neu (AnimatedSprite2D)

- Beide: `position = (-274.4, -1414.7)`, `scale = 0.935` (die Spiel-Groesse deiner Fotos), `centered = false`, `autoplay = "stehen"`. Weil beide gleichzeitig starten und gleich schnell laufen, zeigen sie immer dasselbe Bild.
- Die Position ist so gerechnet, dass die Mitte zwischen deinen Schuhen auf dem Nullpunkt der Figur steht. Der liegt auf der Wiese.
- `Gesicht` steht in der Liste vor `Koerper`, wird also zuerst gezeichnet und liegt dahinter, wie bei dir in Krita (Kopf hinter allem). Der Arm (`Schulter`) steht danach und liegt vorn.
- Der Kopf ist ein eigener Knoten, damit man spaeter den Ausdruck tauscht, ohne den Koerper anzufassen.

### Sonst geaendert

- `Beine`, `Rumpf`, `Kopf` (die grauen Kaesten) sind ausgeblendet.
- `Schulterpunkt` und `Schulter` stehen bei (-123.9, -847.1): an der Schulter im Foto (auf der Schulterlinie, 40 Pixel vom Rand nach innen). `start_totale.gd` setzt den Arm an den `Schulterpunkt`, darum dreht sich der Arm jetzt an deiner Schulter.

### So wurde es angeschaut

Verify PASS. Probe: drei Bilder je eine Sechstelsekunde auseinander, Koerper und Kopf zeigten jedes Mal dasselbe Bild (0, 1, 2). Die Figur steht mit den Schuhen auf der Wiese, der Arm haelt die Kanone, beim Drehen dreht er an der Schulter. Nicht angeschaut: ob es im Abheben und beim Fang gut aussieht.

### Drei Fragen zur Selbstkontrolle

1. Warum muessen Kopf- und Koerperbilder denselben Ausschnitt haben?
2. Warum liegt der Kopf hinter dem Koerper, obwohl er oben drauf sitzt?
3. Was passiert mit dem Arm, wenn man `Schulterpunkt` verschiebt?

### Nachtrag: nur Koerper 0 und 1 (27.11.2026)

Dein Wunsch: Das dritte Bild (Koerper 2, mit der anderen Hose) kommt raus, das wird spaeter fuers Fliegen ueberarbeitet. Im Spiel stehen nur Koerper 0 und 1.

- `stehen-koerper-3.png` und `stehen-kopf-3.png` sind geloescht, die zwei anderen neu geschnitten. Der Ausschnitt ist jetzt 651 x 1516, unten kuerzer, weil die laengere Hose fehlt. Oben links ist er gleich geblieben, darum stimmt `position` (-274.4, -1414.7) weiter.
- In `SpriteFrames_koerper` und `SpriteFrames_kopf` steht nur noch je zwei Bilder. Die Animation wechselt also zwischen Koerper 0 und 1, drei Mal pro Sekunde je Bild.

So wurde es angeschaut: Verify PASS. Probe: Koerper und Kopf wechseln gemeinsam zwischen Bild 0 und 1.

### Nachtrag: Die Figur steht auf der Hoehe des Knienden (27.11.2026)

Dein Hinweis: Der Stehende haengt in der Luft. Er soll ungefaehr dort stehen, wo die sichtbare Unterkante der Aufsteh-Animation ist.

Die Schuhe des Knienden (das letzte Aufstehbild) liegen 1518,5 Pixel unter der Kanone: Mitte des Aufstehen-Knotens (1115) plus der Weg von der Bildmitte bis zur Schuhkante im Bild (431,5 Pixel im Bild mal 0,935). Die Schuhe des Stehenden lagen bei 1212, also 306,5 hoeher.

Darum stehen `Gesicht`, `Koerper`, `Schulterpunkt` und `Schulter` jetzt je 306,5 Pixel tiefer: Gesicht und Koerper bei y -1108.2, Schulterpunkt und Schulter bei y -540.6. Der Knoten `Figur` selbst bleibt, wo er ist. Er ist auch der Nullpunkt fuer das Abheben, und den wollte ich nicht verschieben.

Dein Aufstehen war richtig gespeichert und wird so verwendet: `Kanone/Aufstehen` steht bei (-130, 1115) mit Groesse 0,935, kein Skript veraendert diese Lage.

So wurde es angeschaut: Verify PASS. Probe: Start und Knien nebeneinander, die Schuhe stehen auf derselben Hoehe im Gras.

### Nachtrag: Teleport-Fliege erholt sich laenger (27.11.2026)

Nur eine Zahl in `skripte/fliege_teleport.gd`: `erholzeit` von 2,5 auf 4 Sekunden (erst 5, dann auf deinen Wunsch 4). So lange springt sie nach ihren drei Spruengen nicht und laesst sich fangen. Die Szene ueberschreibt den Wert nicht, darum gilt die Zahl im Skript.

## Felsen zermatschen sichtbar, Kanone schneller (27.11.2026)

Bisher verschwand eine Fliege einfach, wenn ein Fels sie traf. Den Matsch dazu hatte der Fels aus derselben Szene wie der Blutfleck am Nagel genommen, und seit der zum kleinen, ungefaerbten Punkt geworden war, sah man fast nichts mehr. Jetzt wird die Fliege platt gedrueckt, klebt unten am Fels und faellt mit ihm aus dem Bild, dazu spritzt Blut in ihrer Zonenfarbe auf.

### `szenen/matsch.tscn` und `skripte/matsch.gd` - neu

Ein `Sprite2D` mit dem Blutbild. Das Skript laesst es beim Erscheinen schnell aufspritzen:

```gdscript
func _ready() -> void:
	scale = Vector2.ONE * groesse_anfang
	var spritzen: Tween = create_tween()
	spritzen.tween_property(self, "scale", Vector2.ONE * groesse_ende, dauer)
```
Es beginnt klein (0,15) und waechst in 0,12 Sekunden auf 1,3. Danach bleibt es stehen. Es haengt am Fels, und wenn der Fels unten aus dem Bild ist und geloescht wird, verschwindet es mit ihm. `szenen/hindernis.tscn` benutzt jetzt diese Szene statt `blutfleck.tscn`.

### `skripte/hindernis.gd` - geaendert

```gdscript
@export var platt_breite: float = 1.5
@export var platt_hoehe: float = 0.2
@export var platt_dauer: float = 0.08
```
Drei neue Werte: Die Fliege wird anderthalbmal so breit und auf ein Fuenftel ihrer Hoehe gedrueckt, in 0,08 Sekunden.

```gdscript
	var opfer: Array[Node2D] = []
	if fliege.gefangen:
		...
		opfer.append_array(nadel.aufgespiesste)
		for gefangene in opfer:
			plattmachen(gefangene)
		nadel.queue_free()
	else:
		plattmachen(fliege)
```
`zermatschen`: Trifft der Fels eine gefangene Fliege, gehen alle Fliegen an diesem Draht mit (`append_array` haengt eine ganze Liste an). Erst werden sie plattgemacht und an den Fels gehaengt, dann wird die Nadel geloescht. Andersherum wuerden die Fliegen mit der Nadel verschwinden.

```gdscript
func plattmachen(fliege: Node2D) -> void:
	fliege.remove_from_group("fliegen")
	fliege.gefangen = true
	fliege.set_process(false)
```
Die Fliege zaehlt nicht mehr als Fliege: Sie ist nicht mehr in der Gruppe `fliegen` (sonst traefe der Fels sie im naechsten Bild noch einmal, und Nadeln koennten sie treffen), und nichts bewegt sie mehr. Summen und Fluegelschlag halten an.

```gdscript
	fliege.reparent(self)
	fliege.position.y = 0.0
	fliege.rotation = 0.0
```
Sie wird ein Kind des Felses. `position.y = 0` ist seine Unterkante (das Steinbild sitzt darueber). Seitlich bleibt sie, wo sie war.

```gdscript
	var matsch: Node2D = matsch_szene.instantiate()
	matsch.modulate = fliege.blut_farbe
	add_child(matsch)
	matsch.position = fliege.position
	var platt: Tween = fliege.create_tween()
	platt.tween_property(fliege, "scale", Vector2(fliege.scale.x * platt_breite, fliege.scale.y * platt_hoehe), platt_dauer)
```
Der Spritzer in ihrer Farbe entsteht an derselben Stelle am Fels. Er wird nach dem Stein gemalt (also davor) und vor der Fliege (die hat `z_index` 1). Dann wird die Fliege platt gedrueckt.

### `skripte/kanone.gd` - geaendert

`tempo` 300 -> 360 und `beschleunigung` 600 -> 720: Die Kanone faehrt 20 Prozent schneller hin und her und kommt genauso schnell auf Touren wie vorher.

### So wurde es angeschaut

- Schnellcheck PASS fuer `hindernis.gd`, `matsch.gd`, `kanone.gd`, Verify PASS.
- Probe mit fester Kamera: Fels faellt auf eine normale und eine Koeder-Fliege. Beide werden platt unter den Fels gedrueckt, darunter spritzt Rosa und Violett auf, alles faellt mit dem Fels weiter.
- Nicht angeschaut: der Fall im Faecher im echten Spiel (die Probe dort war wegen der mitfahrenden Kamera unbrauchbar), wie es sich spielt.

### Drei Fragen zur Selbstkontrolle

1. Warum wird die Fliege aus der Gruppe `fliegen` genommen?
2. Warum werden die Fliegen erst an den Fels gehaengt und dann die Nadel geloescht, nicht umgekehrt?
3. Wann wird der Spritzer geloescht?

### Nachtrag: Schatten statt gelber Spalte (27.11.2026)

Nur `szenen/hindernis.tscn`: Die Spalte, in der der Fels faellt, war Gelb mit 15 Prozent Deckkraft und auf den hellen Pappen kaum zu sehen. Jetzt ist sie ein Schatten: `color = Color(0, 0, 0, 0.35)`, also Schwarz mit 35 Prozent Deckkraft. Wie vorher beginnt sie schwaecher (`spalte_anfang` 0,3 mal so kraeftig) und wird bis zum Fallen voll. Auf der fast schwarzen Pappe sieht man den Schatten kaum.

## Punkte, Kombos und Steinschlag-Schild (27.11.2026)

Beim Fang sieht man jetzt, wie viel Flugkraft er bringt ("+4"), bei mehreren Fliegen auf einmal ein Kombo-Wort ("Double Kill"). Zermatscht ein Stein gefangene Fliegen, steht dort, wie viel verloren geht ("-4"). So wird klar, dass der Stein die Fliegen trifft und nicht dich, und dass dich das Hoehe kostet. Das Warnschild ueber der Felsbahn ist jetzt ein Steinschlag-Schild statt des Ausrufezeichens.

### `szenen/zahl.tscn` und `skripte/zahl.gd` - neu

Ein `Label` (ein Textfeld) in deiner Schrift Freckle Face, Groesse 56, mit schwarzem Rand (`outline_size` 14), damit es auf jeder Pappe lesbar ist. `pivot_offset` (200, 40) ist die Mitte des Feldes: Um diesen Punkt wird vergroessert.

```gdscript
func _ready() -> void:
	var ablauf: Tween = create_tween()
	ablauf.set_parallel(true)
	ablauf.tween_property(self, "position:y", position.y - steigen, dauer)
	ablauf.tween_property(self, "modulate:a", 0.0, dauer / 2.0).set_delay(dauer / 2.0)
	ablauf.chain().tween_callback(queue_free)
```
`set_parallel(true)`: Die folgenden Bewegungen laufen gleichzeitig. Der Text steigt in 1,2 Sekunden um 90 Pixel, und in der zweiten Haelfte wird er durchsichtig (`modulate:a` ist die Deckkraft). `chain()` haengt danach etwas hinten an: Wenn alles fertig ist, loescht sich der Text (`queue_free`).

### `skripte/punktanzeige.gd` - neu, Knoten `Punktanzeige` in `szenen/spiel.tscn`

Ein `CanvasLayer` (Ebene 3): Was darin liegt, steht fest auf dem Bildschirm und faehrt nicht mit der Kamera. Zuerst lagen die Zahlen in der Welt; dann blieben sie nach einem Fang zurueck, weil die Kamera mit der Kanone steigt. Der Knoten ist in der Gruppe `punktanzeige`.

```gdscript
func gefangen(nadel: Node2D) -> void:
	zeigen(im_bild(nadel.global_position) + Vector2(70, 0), "+" + str(nadel.flugkraft()), farbe_plus, 1.0)
	var anzahl: int = nadel.aufgespiesste.size()
	if anzahl >= 2:
		var nummer: int = mini(anzahl - 2, kombo_woerter.size() - 1)
		zeigen(kombo_ort, kombo_woerter[nummer], farbe_kombo, kombo_groesse)
```
Gruen "+N" rechts neben der Nadel. `str` macht aus der Zahl Text. Stecken zwei oder mehr Fliegen an der Nadel, kommt das Kombo-Wort dazu, gross und gelb oben in der Mitte. Bei 2 Fliegen ist `nummer` 0 ("Double Kill"), bei 3 ist es 1 ("Triple Kill") und so weiter; `mini` sorgt dafuer, dass ab 5 Fliegen immer das letzte Wort kommt ("Mega Kill"). Die Woerter stehen im Inspector in `kombo_woerter`.

```gdscript
func im_bild(ort: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * ort
```
Rechnet einen Punkt in der Welt in einen Punkt auf dem Bildschirm um. Die `canvas_transform` ist das, was die Kamera mit der Welt macht (verschieben, zoomen); damit multipliziert landet der Punkt dort, wo man ihn gerade sieht.

`verloren(ort, flugkraft)` zeigt rot "-N", `zeigen` baut den Text aus der Szene und setzt Text, Farbe und Groesse.

### Aufrufe

- `skripte/uebergabe.gd`, in `starten`: `get_tree().call_group("punktanzeige", "gefangen", nadel)`. `call_group` ruft die Funktion `gefangen` bei jedem Knoten der Gruppe auf. So muss die Uebergabe den Knoten nicht kennen.
- `skripte/hindernis.gd`, in `zermatschen`, wenn der Stein gefangene Fliegen trifft: `get_tree().call_group("punktanzeige", "verloren", fliege.global_position, nadel.flugkraft())`. Das steht vor dem Plattmachen, solange die Nadel ihre Fliegen noch kennt.

### Steinschlag-Schild

`assets/hintergrund/hindernisse/spiel/steinschlag.png`: das Steinschlag-Schild, auf die Groesse des alten Schilds verkleinert (120 Pixel breit). `szenen/hindernis.tscn` zeigt es statt `warnschild.png`.

### So wurde es angeschaut

- Schnellcheck PASS fuer `zahl.gd`, `punktanzeige.gd`, `uebergabe.gd`, `hindernis.gd`, Verify PASS.
- Probe: ein Schuss spiesst zwei Fliegen auf. "Double Kill" steht gross oben in der Mitte, "+4" gruen neben der Nadel, beides bleibt im Bild, waehrend die Kamera steigt.
- Probe: Ein Stein trifft die beiden gefangenen Fliegen im Faecher. Rot "-4" erscheint oben an der Stelle, danach stuerzt die Figur ab (Flugkraft 0).
- Nicht angeschaut: das Steinschlag-Schild im Spiel.

### Drei Fragen zur Selbstkontrolle

1. Warum liegt die Punktanzeige in einem `CanvasLayer` und nicht in der Welt?
2. Welches Wort erscheint bei 7 Fliegen auf einmal, und warum?
3. Was macht `call_group`, und warum ist das hier praktisch?

### Nachtrag: Treffer auf den Boss, 1/3 bis 3/3 und Wackeln (27.11.2026)

- `skripte/fliege.gd`: neu `var leben_voll`, in `_ready` auf `leben` gesetzt. So weiss man spaeter noch, wie viele Leben die Fliege am Anfang hatte (der Boss hat 3).
- `skripte/nadel.gd`: In `stecken_in` (der Boss lebt noch) und in `aufspiessen` (der letzte Treffer, wenn `leben_voll` groesser als 1 ist) steht jetzt `get_tree().call_group("punktanzeige", "boss_treffer", global_position, nummer, von)`. `nummer` ist der wievielte Treffer: `leben_voll - leben`, beim letzten `leben_voll` selbst.
- `skripte/punktanzeige.gd`: neu `boss_treffer`. Es zeigt `str(nummer) + "/" + str(von)`, also zum Beispiel "2/3", orange und gross ueber der Trefferstelle, und ruft `spiel.wackeln(...)` auf: 12 Pixel fuer 0,3 Sekunden, beim letzten Treffer 24. `wackeln` gab es in `spiel.gd` schon fuer den Absturz. Den Knoten `spiel` bekommt die Punktanzeige im Inspector (`NodePath("..")`, ihr Elternknoten).

Angeschaut: Schnellcheck PASS, Verify PASS, Probe mit Schuessen auf einen stillstehenden Boss: "1/3", "2/3", "3/3" erscheinen, Wackeln 12, 12, 24, beim dritten kommt "+15".

### Nachtrag: Felsschatten je Pappe, auf der fast schwarzen gelb (27.11.2026)

- `skripte/hintergrund.gd`: `nummer` war eine Variable nur in `_process` (`var nummer` innerhalb der Funktion). Jetzt steht `var nummer: int = 0` oben im Skript, und `_process` schreibt nur noch hinein (`nummer = ...`). So koennen andere Knoten lesen, welche Pappe gerade zu sehen ist: 0 ist blau, 7 fast schwarz.
- `skripte/hindernis_erzeuger.gd`: neu `@export var hintergrund: Node` (im Inspector auf den Knoten `Hintergrund` gesetzt) und `hindernis.hintergrund = hintergrund`, wie schon bei `faecher`.
- `skripte/hindernis.gd`: neu `@export var spalte_farben: Array[Color]`, eine Farbe je Pappe. Sieben Mal `Color(0, 0, 0, 0.5)`, Schwarz mit 50 Prozent Deckkraft, und als achte `Color(0.92, 0.73, 0.17, 0.2)`, das Gelb des Steinschlag-Schilds mit 20 Prozent. In `warnen` steht jetzt `$Spalte.color = spalte_farben[hintergrund.nummer]`: Jedes Bild nimmt die Spalte die Farbe der Pappe, die gerade da ist. Das `modulate.a` darunter blendet sie wie bisher am Anfang der Warnung schwaecher ein; beides wird miteinander malgenommen.
- `szenen/hindernis.tscn`: die Startfarbe der Spalte von 35 auf 50 Prozent.

Angeschaut: Schnellcheck PASS fuer alle drei Skripte, Verify PASS. Bogen mit der Spalte auf allen acht Pappen (nicht im laufenden Spiel): auf allen deutlich zu sehen, auf der fast schwarzen als gruenlich-graue Bahn.

### Nachtrag: Matsch nur als Fleck, Steine langsamer, Leuchtringe der Teleport-Fliege (27.11.2026)

**Matsch** (`skripte/hindernis.gd`, `plattmachen`): Die Fliege wird nicht mehr platt gedrueckt, sie verschwindet. Uebrig bleibt nur der Blutfleck in ihrer Farbe, unten am Stein.

```gdscript
	fliege.remove_from_group("fliegen")
	var matsch: Node2D = matsch_szene.instantiate()
	matsch.modulate = fliege.blut_farbe
	add_child(matsch)
	matsch.position = Vector2(to_local(fliege.global_position).x, 0.0)
	fliege.queue_free()
```
`to_local` rechnet die Stelle der Fliege in die Sicht des Steins um. Der Fleck kommt dorthin, aber auf Hoehe 0, an die Unterkante des Steins. `queue_free` loescht die Fliege am Ende des Bilds. Die Werte `platt_breite`, `platt_hoehe` und `platt_dauer` sind weg.

**Steine langsamer** (`skripte/hindernis.gd`): `falltempo` von 3000 auf 1500, halb so schnell. Das gab ein Problem: Stuerzt man ab, faellt die Kanone mit 2400 (`spiel.gd`), also schneller als der Stein, und der Faecher haette den Stein von oben eingeholt. Deshalb merkt sich der Stein in `kanone_vorher`, wo die Kanone im letzten Bild war:

```gdscript
	var kanone_sinkt: float = maxf(kanone.position.y - kanone_vorher, 0.0)
	kanone_vorher = kanone.position.y
	position.y += falltempo * delta + kanone_sinkt
```
Sinkt die Kanone (y wird groesser), faellt der Stein um genau dieses Stueck mehr. Steigt sie, ist der Unterschied negativ, und `maxf` macht daraus 0. In `warnen` wird `kanone_vorher` jedes Bild gesetzt, damit der Wert beim Losfallen stimmt.

**Felsschatten**: In `spalte_farben` sind jetzt die Pappen 6 bis 8 (Indigo, Nachtblau, fast schwarz) gelb, vorher nur die achte.

**Leuchtringe der Teleport-Fliege** (`szenen/fliege_teleport.tscn`, `skripte/fliege_teleport.gd`): Der runde Schimmer (ein Farbverlauf hinter ihr) ist weg. Neu ist ein Knoten `Leuchten` mit drei Bildern, `Ring1` (innen) bis `Ring3` (aussen). Jeder Ring folgt ihrem Umriss. Die Bilder `assets/fliegen/spiel/teleport-leuchten-1.png` bis `-3.png` sind weiss; die Farbe kommt erst im Spiel ueber `modulate` dazu, weiss mal Farbe ergibt die Farbe. Gemacht sind sie ausserhalb des Spielordners mit einem kleinen Python-Programm: Koerper und beide Fluegelbilder uebereinander gelegt, daraus die Umrissflaeche, die dreimal um 7 Pixel geweitet, und jeder Ring ist der Streifen zwischen zwei Weitungen, leicht weichgezeichnet. Weil `Leuchten` die Groesse 0.5 hat, sind die Bilder doppelt so fein gerechnet.

```gdscript
func leuchten_zeigen(ladung: float) -> void:
	var ringe: float = ladung * 3.0
	for nummer in 3:
		var ring: Sprite2D = $Leuchten.get_child(nummer)
		ring.modulate = leucht_farben[nummer]
		ring.modulate.a = clampf(ringe - nummer, 0.0, 1.0)
```
`ladung` kommt aus `ladung_jetzt()`: 1 bei drei Spruengen, 2/3 bei zwei, 1/3 bei einem. Mal 3 ergibt das 3, 2 oder 1. Ring 0 (innen) ist sichtbar, sobald `ringe` mindestens 1 ist; Ring 2 (aussen) erst bei 3. So verschwindet bei jedem Sprung der aeusserste. Waehrend der Erholung waechst `ladung` gleitend von 0 bis 1: Zuerst blendet der innere Ring ein, dann der mittlere, dann der aeussere. Die Farben stehen im Inspector in `leucht_farben`.

Angeschaut: Schnellcheck PASS fuer `hindernis.gd`, `fliege_teleport.gd`, `spiel.gd`, Verify PASS. Probe: Ringe bei 3, 2, 1 Spruengen und bei halber Erholung (innen voll, Mitte halb, aussen aus), Umriss sitzt; ein Stein auf eine freie Fliege: Fliege weg, Fleck da. Nicht angeschaut: ein Absturz mit fallendem Stein im echten Spiel.

### Nachtrag: Flattern langsamer, Teleport-Glitch, duennere Ringe in Fliegenfarben, Forscher faellt mit (28.11.2026)

**Flattern** (alle acht Fliegenszenen, Animation `flattern`): Die Animation ist jetzt 0,06 Sekunden lang statt 0,034, das zweite Fluegelbild kommt bei 0,03 statt 0,017. Jedes Bild bleibt also etwa zwei Bilder lang stehen (bei 60 Bildern pro Sekunde). Bei allen Fliegen gleich.

**Glitch** (`shader/glitch.gdshader`, neu): Ein Shader ist ein kleines Programm, das die Grafikkarte fuer jeden Bildpunkt einer Grafik ausfuehrt. Dieser macht dasselbe wie dein Logo am Ende der Reels: Er schneidet das Bild in waagerechte Streifen, schiebt jeden Streifen ein Stueck zur Seite und laesst einzelne Streifen ganz weg.

```glsl
float zeile = floor(UV.y * streifen);
float verschiebung = (wuerfeln(zeile + zufall) * 2.0 - 1.0) * versatz * staerke;
vec2 stelle = UV + vec2(verschiebung, 0.0);
```
`UV` ist die Stelle im Bild, von 0 (links/oben) bis 1 (rechts/unten). `floor(UV.y * 14)` sagt, in welchem der 14 Streifen der Punkt liegt. `wuerfeln` macht aus der Streifennummer eine Zufallszahl zwischen 0 und 1; mal 2 minus 1 ergibt -1 bis +1, mal `versatz` (15 Prozent der Bildbreite) und mal `staerke`. Gelesen wird die Farbe dann von der verschobenen Stelle, so rutscht der ganze Streifen. Ist `wuerfeln(...)` kleiner als `staerke`, wird der Punkt durchsichtig: Bei staerke 0,5 faellt etwa jeder zweite Streifen weg. `zufall` wechselt jedes Bild, darum flimmert es. `knoten_farbe` merkt sich im `vertex`-Teil das `modulate` des Knotens, damit die Ringe ihre Farbe behalten.

`szenen/fliege_teleport.tscn`: Der Shader steckt als `ShaderMaterial` an der Fliege selbst (`resource_local_to_scene`, damit jede Teleport-Fliege ihren eigenen hat und nicht alle zugleich glitchen). Koerper, Fluegel, `Leuchten` und die drei Ringe haben `use_parent_material = true`: Sie benutzen das Material ihres Elternknotens.

`skripte/fliege_teleport.gd`: Das Blinken (`flacker_takt`, `flacker_blass`) ist weg. Statt dessen `glitchen(staerke)`, das dem Shader die Staerke und eine neue Zufallszahl gibt. Waehrend `flacker_zeit` (0,2 s) vor dem Sprung waechst die Staerke von 0 auf 1 (`1.0 - flackert_noch / flacker_zeit`), sie glitcht weg. Nach dem Sprung taucht sie in `auftauch_zeit` (0,15 s) wieder auf, die Staerke faellt von 1 auf 0 (`taucht_noch / auftauch_zeit`). `skripte/nadel.gd`: Wird sie beim Auftauchen getroffen, setzt `aufspiessen` den Glitch auf 0 (`if getroffene.has_method("glitchen")`: nur die Teleport-Fliege hat diese Funktion).

**Ringe**: duenner (4 statt 7 Pixel je Ring, neu gerechnet), und die Farben in `leucht_farben` sind aus ihrem Bild gemessen: Gruen vom Koerper (0.44, 0.69, 0.27), Blau von den Beinen (0.44, 0.5, 0.78), Violett vom Hinterleib (0.48, 0.28, 0.6).

**Forscher faellt mit** (`skripte/spiel.gd`): Bei einem Absturz, der nicht bis zum Boden geht, ruft `fliege_verlieren` jetzt `zwischenfall(dauer)`. Der Knoten `Aufstehen` (der fallende Forscher) wird sichtbar, spielt `fallen` und faehrt mit einem Tween um `koerper_einflug` (1600 Pixel) nach oben, also von unten ins Bild. Das dauert `koerper_anteil` (30 Prozent) des Absturzes; dann `tween_interval` (Warten), und in den letzten 30 Prozent faehrt er zurueck nach unten und wird versteckt (`koerper.hide`). `koerper_unten` merkt sich in `_ready`, wo er normal steht. `koerper_zuruecksetzen` haelt eine laufende Fahrt an und stellt ihn zurueck; das passiert vor jeder neuen Fahrt, beim Absturz bis zum Boden (`fallen`) und wenn waehrenddessen gefangen wird (`aufstehen_abbrechen`).

Angeschaut: Schnellcheck PASS fuer `spiel.gd`, `fliege_teleport.gd`, `nadel.gd`, Verify PASS. Probe: Teleport-Fliege unter der Kanone, 24 Bilder hintereinander: Streifen verrutschen, fallen weg, Fliege taucht woanders auf. Probe Absturz von 8 auf 4: Forscher kommt unten ins Bild, ist am Ende wieder weg und versteckt. Nicht angeschaut: das Flattern im laufenden Spiel.

## Warten: Nach 3 Sekunden ohne Eingabe geht der Forscher in die Knie (`skripte/warten.gd`, `szenen/spiel.tscn`, 28.11.2026)

Dein Wunsch: Fuers normale Stehen die Koepfe aus deinen Bildern 0 und 1, fuers Warten die aus Bild 10 und 11 (mit den Koerpern 3 und 4). Nach etwa 3 Sekunden ohne Eingabe kommt das Warten, bei einer Mausbewegung sofort wieder das Stehen.

### Die Bilder (`assets/forscher/stehen/`)

Acht Bilder, alle mit demselben Ausschnitt (665 x 1527): `stehen-koerper-1/2`, `stehen-kopf-1/2`, `warten-koerper-1/2`, `warten-kopf-1/2`. Die Koepfe sind genau so, wie du sie in Krita gelegt und vergroessert hast. Die Steh-Bilder von vorher (mit `kopf-01`) sind ersetzt.

### `SpriteFrames_koerper` und `SpriteFrames_kopf` - geaendert

Je zwei Animationen: `stehen` und neu `warten`. Beide mit deinem Takt aus dem Godot-Editor: erstes Bild `"duration": 2.0`, zweites `1.0`, `"speed": 3.0`. Ein Durchlauf dauert also (2 + 1) / 3 = 1 Sekunde. Den Takt hattest du nur beim Koerper eingestellt, der Kopf lief noch mit 6 Bildern pro Sekunde. Jetzt hat der Kopf denselben Takt, sonst liefen Kopf und Koerper auseinander. Dass `warten` denselben Takt hat, ist meine Annahme.

### `skripte/warten.gd` - neu, am neuen Knoten `Kanone/Figur/Warten`

```gdscript
@export var koerper: AnimatedSprite2D
@export var gesicht: AnimatedSprite2D
@export var schulter: Node2D
```
Die drei Teile, die das Skript steuert. In der Szene zeigen sie auf `../Koerper`, `../Gesicht` und `../Schulter`.

```gdscript
@export var wartezeit: float = 3.0
@export var knie_tiefe: float = 231.9
```
Nach 3 Sekunden ohne Eingabe beginnt das Warten. 231,9 ist, wie weit die Schulter in den Knien tiefer liegt: Der Hals rutscht im Foto 248 Pixel nach unten, mal 0,935.

```gdscript
var ruhig: float = 0.0
var schulter_y: float = 0.0
```
`ruhig` zaehlt die Sekunden ohne Eingabe. `schulter_y` merkt sich, wo die Schulter beim Stehen ist.

```gdscript
func _ready() -> void:
	schulter_y = schulter.position.y
	koerper.frame_changed.connect(schulter_setzen)
```
Am Anfang wird die Steh-Hoehe der Schulter gemerkt. `frame_changed` ist ein Signal des Koerpers: Es kommt bei jedem Bildwechsel, und dann wird `schulter_setzen` gerufen.

```gdscript
func _process(delta: float) -> void:
	if not get_parent().aktiv:
		if koerper.animation != "stehen":
			zeigen("stehen")
		return
	ruhig += delta
	if ruhig >= wartezeit and koerper.animation != "warten":
		zeigen("warten")
```
`get_parent()` ist die `Figur`, `aktiv` steht in `start_totale.gd` und wird nach dem ersten Fang `false`. Danach haengt die Figur unter der Kanone, dort soll sie nicht in die Knie gehen. Sonst waechst `ruhig` in jedem Bild um die vergangene Zeit, und ab 3 Sekunden kommt `warten`. Die Bedingung `!= "warten"` sorgt dafuer, dass die Animation nicht in jedem Bild neu startet.

```gdscript
func _input(_ereignis: InputEvent) -> void:
	ruhig = 0.0
	if koerper.animation != "stehen":
		zeigen("stehen")
```
Godot ruft `_input` bei jeder Eingabe: Maus bewegt oder geklickt, Taste, Finger auf dem Bildschirm. Dann faengt das Zaehlen von vorn an, und wartet der Forscher gerade, steht er sofort wieder.

```gdscript
func zeigen(animation: String) -> void:
	koerper.play(animation)
	gesicht.play(animation)
	schulter_setzen()
```
Koerper und Kopf starten dieselbe Animation im selben Moment, darum zeigen sie immer dasselbe Bild.

```gdscript
func schulter_setzen() -> void:
	if koerper.animation == "warten" and koerper.frame == 0:
		schulter.position.y = schulter_y + knie_tiefe
	else:
		schulter.position.y = schulter_y
```
Im ersten Warte-Bild (in den Knien) geht die Schulter mit dem Arm und der Kanone um `knie_tiefe` nach unten, sonst steht sie auf der Steh-Hoehe. Ohne das hingen Arm und Kanone in den Knien oben in der Luft.

### Sonst geaendert in `szenen/spiel.tscn`

- `Gesicht` und `Koerper` bei (-287.5, -1094.2): neu gerechnet fuer den neuen Ausschnitt.
- `Schulterpunkt` und `Schulter` bei y -526.6. Du hast das Aufstehen neu gesetzt (bei (19, 1170), Groesse 0,83 / 0,84), dadurch liegen die Schuhe des Knienden jetzt 1532,5 unter der Kanone. Der Stehende steht wieder auf derselben Hoehe.
- Deine Aenderungen aus dem Editor sind mit drin: Aufstehen neu gesetzt, das erste Aufstehbild 3 statt 2 lang, `ForscherArm` und die Kanone (`Bild`) im Arm verschoben.

### So wurde es angeschaut

Schnellcheck PASS fuer `warten.gd`, Verify PASS. Probe ohne Eingabe: nach 1 Sekunde `stehen`, nach 3,5 Sekunden `warten` (Koerper und Kopf im selben Bild), in den Knien sitzen Arm und Kanone an der Schulter. Dann eine Mausbewegung ins Spiel geschickt: sofort wieder `stehen`. Nicht angeschaut: ob das Warten am Handy ohne Maus zu frueh kommt.

### Drei Fragen zur Selbstkontrolle

1. Warum startet `warten` nicht in jedem Bild neu, obwohl `_process` in jedem Bild laeuft?
2. Was macht `frame_changed.connect(schulter_setzen)`?
3. Warum fragt das Skript `get_parent().aktiv` ab?

### Nachtrag: Warnstreifen-Umriss bei Gefahr, Umrisse je Fluegelbild, Ringe schwaecher (28.11.2026)

**Umrisse je Fluegelbild.** Vorher war der Ring der Teleport-Fliege aus *beiden* Fluegelbildern zusammen gerechnet, darum stand er beim anderen Bild ins Leere. Jetzt gibt es fuer jedes der zwei Bilder der Animation `flattern` eigene Umrissbilder (`assets/fliegen/spiel/umriss/`). Die Animation wechselt sie mit: In jeder Fliegenszene ist eine neue Spur `Gefahr:texture`, bei der Teleport-Fliege dazu `Leuchten/Ring1:texture` bis `Ring3`. Bild 1 bei 0 Sekunden, Bild 2 bei 0,03, genau wie die Fluegel. Gerechnet sind die Bilder ausserhalb des Spielordners mit einem Python-Programm: Es liest aus der Szene, wo Koerper und Fluegel sitzen und wie gross sie sind, legt sie fuer jedes Bild uebereinander und weitet die Umrissflaeche.

**Warnstreifen-Umriss.** Jede Fliege hat einen neuen Knoten `Gefahr` (Sprite2D, unsichtbar), ganz hinten. Sein Bild ist ein weisser, schraeg gestrichelter Streifen 3 bis 8 Pixel um die Fliege herum; die Farbe kommt ueber `modulate`.

`skripte/hindernis.gd`, in `warnen`:
```gdscript
	for fliege in get_tree().get_nodes_in_group("fliegen"):
		if in_spalte(fliege):
			fliege.gefahr_noch = 0.1
			fliege.gefahr_farbe = gefahr_farben[hintergrund.nummer]
```
`in_spalte` ist wie `im_klotz`, nur ohne die Hoehe: seitlich in der Spalte und unter dem Stein. `gefahr_farben` hat eine Farbe je Pappe: das Gelb des Schilds, und ab Indigo, wo der Schatten selbst gelb ist, Schwarz.

`skripte/fliege.gd`: `gefahr_zeigen(delta)` steht in `_process` *vor* `if gefangen: return`, denn auch die gefangenen Fliegen im Faecher sind in Gefahr, gerade die. `gefahr_noch` zaehlt herunter; solange der Stein warnt, setzt er es jedes Bild wieder auf 0,1. Hoert die Warnung auf (der Stein faellt) oder fliegt die Fliege aus der Spalte, ist es nach 0,1 Sekunden vorbei. Sichtbar ist der Umriss, wenn `gefahr_noch > 0.0` und die Blink-Uhr in der ersten Haelfte von `gefahr_takt` (0,3 s) ist.

`skripte/fliege_schnell.gd` und `fliege_heuschrecke.gd`: `$Gefahr.flip_h` wird mitgespiegelt. Das Umrissbild ist um die Mitte der Fliege herum gerechnet, darum reicht Spiegeln, verschieben muss man es nicht.

**Ringe schwaecher.** `skripte/fliege_teleport.gd`: neu `leucht_deckkraft` (0,55); die Deckkraft jedes Rings wird damit malgenommen.

Angeschaut: Schnellcheck PASS (`fliege.gd`, `fliege_schnell.gd`, `fliege_heuschrecke.gd`, `fliege_teleport.gd`, `hindernis.gd`), Verify PASS. Probe: alle sieben Fliegen mit Umriss in beiden Fluegelbildern, gelb auf hell, schwarz auf dunkel; der Umriss folgt jeweils dem Bild. Nicht angeschaut: das Blinken unter einem echten Stein im Spiel.

### Nachtrag: Orange Rand um die schwarzen Warnstriche (28.11.2026)

Auf den dunklen Pappen sind die schwarzen Striche jetzt duenn orange umrandet. Jeder `Gefahr`-Knoten hat ein Kind `Rand` (Sprite2D) mit einem eigenen Bild (`umriss/gefahr-rand-<art>-1.png` und `-2.png`, je Fluegelbild, mit eigener Spur `Gefahr/Rand:texture` in `flattern`). Das Bild ist ein 2 Pixel breiter Saum aussen um jeden Strich, gerechnet aus dem Strichbild (geweitet minus Original).

`skripte/fliege.gd`: `$Gefahr.self_modulate` statt `modulate`. Der Unterschied: `modulate` faerbt den Knoten *und alle Kinder*, `self_modulate` nur den Knoten selbst. Mit `modulate` waere der Rand Schwarz mal Orange, also Schwarz. Neu `gefahr_rand_farbe`, die der Rand als `self_modulate` bekommt.

`skripte/hindernis.gd`: neu `gefahr_rand_farben`, eine Farbe je Pappe. Durchsichtig (`Color(0, 0, 0, 0)`) heisst kein Rand; ab Indigo Orange (1.0, 0.55, 0.1). `fliege_schnell.gd` und `fliege_heuschrecke.gd` spiegeln `Gefahr/Rand` mit.

Angeschaut: Schnellcheck PASS (`fliege.gd`, `hindernis.gd`, `fliege_schnell.gd`, `fliege_heuschrecke.gd`), Verify PASS. Probe auf dunklem Grund, beide Fluegelbilder: Der Rand sitzt um jeden schwarzen Strich, auch bei den gespiegelten Fliegen (beim ersten Versuch hing er bei der schnellen Fliege seitenverkehrt, weil er nicht mitgespiegelt wurde).

### Nachtrag: Abschusspunkt in der Totale haengt am Kanonenbild (28.11.2026)

Du hattest in der Totale das Kanonenbild in der Hand verschoben (`Kanone/Figur/Schulter/Armbild/Bild`, von (-0.3, -403.9) nach (-23.1, -445.4)). Der Abschusspunkt `Spitze` war ein Geschwister des Bilds und blieb stehen, darum kamen Nagel und Draht neben dem Lauf heraus.

Jetzt ist `Spitze` ein **Kind** von `Bild`, auf `Vector2(1.5, -648)`. Das ist die Stelle im Kanonenbild selbst: Das Bild ist 606 x 1300 Pixel gross, seine Mitte ist (0, 0), der Lauf endet oben bei Pixel 304/2, also 1,5 rechts und 648 ueber der Mitte. Weil ein Kind mit seinem Elternknoten mitwandert (und mit ihm skaliert), stimmt der Punkt, egal wohin du das Bild schiebst.

`skripte/start_totale.gd`: Der Pfad heisst jetzt `$Schulter/Armbild/Bild/Spitze` (zweimal, fuer die Startstelle der Nadel und fuer `anker`, an dem der Draht haengt).

Im normalen Spiel (`Kanone/Arm/Muendung`) stimmt die Muendung noch: nachgerechnet gegen `kanone-hinten.png`, Abweichung unter 0,2 Pixel.

Angeschaut: Schnellcheck PASS, Verify PASS, Probe: roter Punkt an `Spitze` in der Totale sitzt genau an der Laufspitze.

## Abheben: Der Forscher haengt am Draht und pendelt (`skripte/haengen.gd`, `skripte/start_totale.gd`, `skripte/spiel.gd`, `szenen/spiel.tscn`, 28.11.2026)

Dein Wunsch: Beim ersten Treffer wird der Forscher zu deinem Abheben-Bild (Bild 7 mit der Hand). Der Kanonenarm schwenkt mit Draht und Fliege nach rechts, der Draht gleitet zwischen Daumen und Finger und bleibt dort. Dann faehrt die Kamera nach oben und zoomt heran: Hand und Unterarm landen oben rechts, die Kanone kommt unten in die Mitte. Ab dem Fang pendelt der ganze Koerper leicht, 3 Grad, erst um die Kanonenspitze, dann um die Hand.

### Die Bilder (`assets/forscher/haengen/`)

Fuenf Ebenen aus deiner Krita-Datei `forscher-abheben-hand.kra`, genau deine Pixel, alle mit demselben Ausschnitt: `haengen-kopf`, `-hose`, `-daumen`, `-arm-links`, `-oberkoerper`. Der Griffpunkt zwischen Daumen und Fingern liegt in deiner Datei bei (768, 712). Von dort aus sind die Bilder um (-211, -42) verschoben, damit der Griff genau auf dem Nullpunkt liegt.

### `szenen/spiel.tscn` - neu: `Kanone/Haenger`

- `Haenger` (Node2D, Skript `haengen.gd`): Er ist der Drehpunkt. In der Totale steht er bei (135.1, 51.5), das ist die Stelle deiner Hand ueber dem stehenden Forscher.
- `Haenger/Inhalt` (Node2D, `scale` 0.935, die Spielgroesse deiner Fotos): Darin die fuenf Bilder, `centered = false`, `position` (-211, -42).
- Die Reihenfolge ist wie in deiner Datei: Kopf, Hose, Daumen hinten, davor Arm links und Oberkoerper. Der Draht ist der Faden der Nadel. Er wird spaeter in der Liste gezeichnet (im Faecher), liegt also vor Kopf, Hose und Daumen. `ArmLinks` und `Oberkoerper` haben `z_index = 1`: Damit liegen sie vor dem Draht. So laeuft der Draht vor dem Daumen und hinter den Fingern.
- `RechteHand` (das graue Kaestchen): Farbe jetzt durchsichtig (`Color(0.6, 0.6, 0.6, 0)`), `z_index = 2`. Die Leiste und die Stichstelle darauf bleiben und liegen vor dem Forscher.
- `Figur/Schulter`: `z_index = 2`, der Kanonenarm liegt ueber allem, wie bei dir in Krita.
- `Figur`: kennt den Haenger (`haenger = NodePath("../Haenger")`).

### `skripte/haengen.gd` - neu

```gdscript
@export var groesster_winkel: float = 3.0
@export var schwingdauer: float = 1.6
@export var daempfung: float = 0.8
@export var mitnahme: float = 0.004
```
Hoechstens 3 Grad zur Seite. Eine ganze Schwingung dauert 1,6 Sekunden. `daempfung` laesst das Schwingen abklingen. `mitnahme` sagt, wie stark eine Bewegung des Drehpunkts den Koerper anstoesst.

```gdscript
var winkel: float = 0.0
var winkeltempo: float = 0.0
var letzter_ort: Vector2 = Vector2.ZERO
var letztes_tempo: float = 0.0
var pendelt: bool = false
```
Der Winkel und wie schnell er sich aendert (im Bogenmass), wo der Drehpunkt im letzten Bild war und wie schnell er da war. `pendelt` ist erst nach dem Treffer `true`.

```gdscript
func _process(delta: float) -> void:
	if not pendelt or delta <= 0.0:
		letzter_ort = global_position
		return
	var tempo: float = (global_position.x - letzter_ort.x) / delta
	var ruck: float = (tempo - letztes_tempo) / delta
	letzter_ort = global_position
	letztes_tempo = tempo
```
In jedem Bild: Wie schnell bewegt sich der Drehpunkt zur Seite (Weg durch Zeit), und wie stark aendert sich dieses Tempo (`ruck`, die Beschleunigung). Faehrt die Kanone los, ist `ruck` gross.

```gdscript
	var eigen: float = TAU / schwingdauer
	var beschleunigung: float = -eigen * eigen * winkel - daempfung * winkeltempo - ruck * mitnahme
	winkeltempo += beschleunigung * delta
	winkel += winkeltempo * delta
```
Das ist ein Pendel. Drei Teile ziehen am Winkel: Er will zur Mitte zurueck (je weiter weg, desto staerker, so entsteht die Schwingung mit 1,6 Sekunden), er klingt ab (`daempfung`), und beschleunigt der Drehpunkt zur Seite, bleibt der Koerper zurueck (`- ruck * mitnahme`). Danach werden Tempo und Winkel um ein Bild weitergerechnet.

```gdscript
	var grenze: float = deg_to_rad(groesster_winkel)
	if absf(winkel) > grenze:
		winkel = clampf(winkel, -grenze, grenze)
		winkeltempo = 0.0
	rotation = winkel
```
Mehr als 3 Grad gibt es nicht: Am Rand bleibt der Winkel stehen und schwingt von dort zurueck. Dann wird der Knoten gedreht, und mit ihm alles darin.

```gdscript
func anstossen() -> void:
	pendelt = true
	letzter_ort = global_position
	letztes_tempo = 0.0
	winkeltempo = deg_to_rad(groesster_winkel) * TAU / schwingdauer
```
Das Pendeln beginnt mit einem Schwung, der gerade bis 3 Grad reicht.

```gdscript
func drehpunkt_setzen(neuer_ort: Vector2) -> void:
	var vorher: Transform2D = $Inhalt.global_transform
	global_position = neuer_ort
	$Inhalt.global_transform = vorher
	letzter_ort = global_position
```
Verlegt den Drehpunkt, ohne dass der Forscher springt: Erst wird gemerkt, wo der Inhalt auf dem Bildschirm ist (`global_transform`: Ort, Drehung, Groesse). Dann wandert der Drehpunkt, und der Inhalt bekommt genau seinen alten Platz zurueck. Ab dann dreht er sich um den neuen Punkt.

### `skripte/start_totale.gd` - geaendert

- Neu: `haenger`, `schwenk_dauer` (0,45 s), `schwenk_extra` (10 Grad), `folgt`, `relativ`, `start_lage`.
- `_ready` merkt sich `start_lage = transform`, wo die Figur am Anfang steht.
- `_process`: Ist `folgt` an, setzt sie sich in jedem Bild auf `haenger.get_node("Inhalt").global_transform * relativ`. Heisst: Die Figur (mit dem Kanonenarm) sitzt immer gleich zum haengenden Forscher und pendelt so mit ihm.
- `erster_treffer`: wie vorher (abheben, gerade stellen), am Ende aber `anhaengen` statt `sequenz_fertig`.
- `anhaengen()`: blendet den stehenden Koerper und Kopf aus und den Haenger ein. `relativ` misst, wo die Figur zum Forscher sitzt. Der Drehpunkt kommt an die Kanonenspitze (dort haengt der Draht), das Pendeln beginnt. Der Draht haengt jetzt am `Fadenpunkt`, der an der Spitze startet. Dann ein Tween: Der Arm dreht in 0,45 Sekunden in Richtung Hand und 10 Grad weiter nach rechts, gleichzeitig wandert der Fadenpunkt in die Hand.
- `in_der_hand()`: Der Drehpunkt kommt in die Hand, der Draht haengt ab jetzt am Haenger selbst (dessen Nullpunkt ist der Griff). Dann `sequenz_fertig`.
- `ausschalten()`: Die Figur folgt nicht mehr und steht wieder an ihrem Anfangsplatz.

### `skripte/spiel.gd` - geaendert

- Neu: `hand_groesse = 0.7`, im Flug ist der Forscher etwas kleiner als in der Totale (0,935).
- `_ready`: Der Haenger ist am Anfang unsichtbar.
- `losgehen()` ruft `hand_in_die_ecke()`: Der Haenger gleitet in `steigdauer` (0,8 Sekunden, so lange wie die Kamerafahrt) an den `Griff` oben rechts, und `Inhalt` wird dabei auf 0,7 verkleinert.
- `erster_fang`: Die Zeile, die den Draht an die Muendung haengte, ist weg. Er steckt schon in der Hand.
- `zwischenfall`: Waehrend der fallende Forscher von unten kommt, ist der Haenger ausgeblendet, danach wieder da. Sonst saehe man ihn zweimal.
- `fallen`: Haenger aus. `aufstehen_abbrechen`: Haenger wieder an, wenn das Spiel schon laeuft.

### So wurde es angeschaut

Schnellcheck PASS fuer alle drei Skripte, Verify PASS. Probe mit einer Nadel, die schon steckt, dann `erster_treffer`: nach 0,4 s haengt der Forscher und pendelt um die Kanonenspitze, der Draht wandert. Nach 0,8 s steckt er in der Hand. Nach 1,7 s ist die Hand oben rechts am Griff (620, -700), der Draht haengt am Griff. Pendeln gemessen: in 4 Sekunden hoechstens 2,2 Grad, 5 Nulldurchgaenge (also etwa 1,6 s je Schwingung). Kanone 400 Pixel zur Seite gefahren: Ausschlag 3,0 Grad. Nicht angeschaut: wie es sich anfuehlt, und am Handy.

### Drei Fragen zur Selbstkontrolle

1. Warum springt der Forscher nicht, wenn `drehpunkt_setzen` den Drehpunkt verlegt?
2. Was bewirkt `- ruck * mitnahme`, wenn die Kanone nach rechts losfaehrt?
3. Warum liegt der Draht hinter den Fingern, aber vor dem Daumen?

### Nachtrag: Abheben nach deiner Rueckmeldung (28.11.2026)

Deine Punkte: keine Luecke im Draht, der Draht bleibt an der Kanone, bis sie bei der Hand ist. Der ganze Koerper bleibt laenger zu sehen, haengend ueber der Wiese mit einem Abstand unter den Fuessen. Dann zoomt es auf den Arm: Am Ende sieht man nur Hand, Unterarm und Aermel, keinen Kopf. Der Kanonenarm schwenkt im Bogen nach links unten aus dem Bild. Erst wenn die Hand sitzt, kommt die Kanone des Spiels von unten in die Mitte.

**Warum es Luecken gab.** Godot ruft in jedem Bild erst alle `_process`-Funktionen und stellt erst danach die Tweens weiter. Die Nadel spannte ihren Draht also zum Arm von vorher, und danach bewegte der Tween den Arm noch ein Stueck. Dazu lief das Drahtende auf einer eigenen geraden Bahn statt an der Kanonenspitze.

**`skripte/start_totale.gd`.**

```gdscript
@export var gleit_dauer: float = 0.2
@export var halte_dauer: float = 0.7
@export var wegschwenk_winkel: float = 160.0
```
Neu: wie lange der Draht von der Spitze in die Hand gleitet, wie lange der Forscher danach noch ganz zu sehen ist, und wie weit der Kanonenarm am Ende wegschwenkt. `schwenk_extra` ist weg.

```gdscript
var haelt_draht: bool = false
var halt: float = 0.0
var ablauf: Tween = null
```
`haelt_draht`: Der Draht haengt noch an der Kanone oder ist auf dem Weg in die Hand. `halt`: 0 heisst an der Spitze, 1 in der Hand. `ablauf` ist der Tween der Sequenz, jetzt als Variable des Skripts, damit `_process` ihn weiterstellen kann.

```gdscript
	if ablauf != null and ablauf.is_valid():
		ablauf.custom_step(delta)
```
Neu, ganz oben in `_process`. Der Ablauf ist angehalten (`ablauf.pause()` beim Anlegen) und wird hier von Hand um die Zeit eines Bildes weitergestellt. So ist der Arm schon gedreht, bevor das Drahtende gesetzt wird.

```gdscript
	if haelt_draht:
		var spitze: Vector2 = $Schulter/Armbild/Bild/Spitze.global_position
		var hand: Vector2 = haenger.get_node("Inhalt").global_position
		var ort: Vector2 = spitze.lerp(hand, halt)
		kanone.get_node("Fadenpunkt").global_position = ort
		haenger.drehpunkt_setzen(ort)
```
In jedem Bild: Das Drahtende sitzt zwischen Spitze und Hand, je nach `halt`. `lerp` mit 0 gibt genau die Spitze, mit 1 genau die Hand. Derselbe Ort ist der Drehpunkt des Pendelns: Der Forscher pendelt immer um die Stelle, an der der Draht gehalten wird, und der Punkt wandert mit dem Arm mit.

`erster_treffer`: Der Koerper steht sofort gerade (`$Schulter.rotation += rotation`, dann `rotation = 0.0`: Der Arm behaelt seine Richtung), dann gleich `anhaengen()`.

`anhaengen()`: Die Richtung zur Hand wird in der Figur gemessen (`to_local`), weil die Figur mitpendelt und die Richtung darin fest bleibt. `wrapf(..., -PI, PI)` nimmt den kuerzeren Drehweg. Der Ablauf: Arm zur Hand (0,45 s), gleichzeitig 132 Pixel abheben und die Nadel gerade stellen. Dann `halt` von 0 auf 1 (0,2 s): Der Draht gleitet in die Hand. Dann `in_der_hand`, dann 0,7 s warten, dann `sequenz_fertig`.

`wegschwenken(dauer)`: neu. Der Kanonenarm dreht 160 Grad nach links (minus heisst gegen den Uhrzeigersinn), waehrend die Kamera heranfaehrt. `ausschalten()` kommt erst danach.

**`skripte/uebergabe.gd`.** Neu `erste(nadel, fahrt, fahrzeit)`: Beim ersten Fang faehrt die Kanone nicht zur Hand, der Draht steckt ja schon darin. Die Nadel gleitet nur an ihren Platz im Faecher. Ihre zwei Bewegungen werden mit `fahrt.parallel()` an die Fahrt der Hand gehaengt. `erste_haengt(nadel)`: Am Ende haengt sie wie alle anderen am Griff. `.bind(nadel)` gibt der Funktion die Nadel mit.

**`skripte/spiel.gd`.**

- `hand_groesse = 1.9` (vorher 0.7): Der Forscher wird beim Heranfahren gross. Die Hand ist 720 Pixel ueber dem unteren Bildrand, der Kopf beginnt in deinem Bild 394 Pixel unter dem Griff: 394 x 1,9 = 749, also knapp unter dem Rand.
- `kanone_dauer`, `kanone_tiefe`, `kanone_da`, `einzug`: neu.
- `_process`: stellt `einzug` (die Fahrt der Hand) von Hand weiter, aus demselben Grund wie oben. `spiel.gd` ist das oberste Skript und darum als erstes dran.
- `losgehen(nadel)`: zeigt die Kanone nicht mehr sofort. Der Kanonenarm schwenkt weg, die Hand gleitet an den Griff und wird gross, die erste Nadel gleitet in den Faecher, dann `kanone_kommt`.
- `kanone_kommt()`: Die Kanone des Spiels startet 450 Pixel tiefer (unter dem Bildrand) und faehrt in 0,4 s hoch. Dann `spielen()`: Erst jetzt faehrt und schiesst sie, und die Hindernisse kommen.
- `aufstehen_abbrechen`: zeigt die Kanone nur, wenn `kanone_da` stimmt.

**`szenen/spiel.tscn`.** `Griff`, `Fadenpunkt` und `RechteHand` liegen 100 Pixel weiter links (Griff bei (520, -700)), sonst ragte die grosse Hand rechts aus dem Bild. Die `Stichstelle` liegt jetzt auf dem nackten Unterarm.

**So wurde es angeschaut.** Schnellcheck PASS fuer `start_totale.gd`, `spiel.gd`, `uebergabe.gd`, Verify PASS. Probe mit einer Nadel, die in einer Fliege steckt, Arm schraeg nach links. Gemessen nach jedem gezeichneten Bild: Abstand zwischen Drahtende und der Stelle, an der es sitzen soll, hoechstens 0,00 Pixel in 3787 Bildern. Bilder: Bis 1,3 s haengt der ganze Forscher ueber der Wiese, die Fuesse in der Luft. Bis 2,35 s Zoom auf den Arm, der Kanonenarm verschwindet links. Am Ende nur Hand, Unterarm und Aermel rechts, die Kanone kommt von unten und laeuft ab 2,75 s. Nicht angeschaut: das Gefuehl beim Spielen.

**Fragen.** 1. Warum wird der Ablauf mit `custom_step` von Hand weitergestellt? 2. Was liefert `spitze.lerp(hand, halt)` bei `halt` 0,5? 3. Warum sieht man bei Groesse 1,9 den Kopf nicht mehr?

### Nachtrag: Der Draht laeuft durch die Hand bis zum Lauf der Kanone (28.11.2026)

Dein Wunsch: Der Draht endet nicht am Daumen, sondern reicht durch die Hand weiter hinunter bis zur Kanone. Er bleibt am Lauf haengen, bis er wirklich fest zwischen Daumen und Fingern sitzt, damit die Fliege nicht entkommen kann. Das gilt beim Abheben und bei jedem spaeteren Fang im Flug.

**`skripte/nadel.gd` und `szenen/nadel.tscn`.**

```gdscript
var ueber: Node2D = null
```
Neu. Der Punkt, ueber den der Draht laeuft, bevor er zum Anker weitergeht: die Hand. `null` heisst: Er geht gerade zum Anker, wie bisher.

```gdscript
	if ueber != null:
		unten = ueber.global_position
		$Rest.points = PackedVector2Array([$Rest.to_local(unten), $Rest.to_local(anker.global_position)])
	elif $Rest.points.size() > 0:
		$Rest.clear_points()
```
Neu in `faden_spannen`. Gibt es einen `ueber`-Punkt, endet das Hauptstueck des Drahts (mit den Fliegen daran) dort. `Rest` ist eine zweite Linie in der Nadel-Szene, gleich eingestellt wie `Faden`: Sie geht von der Hand weiter zum Anker, also zum Lauf der Kanone. Ohne `ueber`-Punkt wird der Rest geloescht. `faden_loesen` raeumt beides ab.

**`skripte/start_totale.gd` (Abheben).** Statt `haelt_draht` gibt es zwei Phasen: `hakt_ein` (mit `halt`) und `laesst_los` (mit `los`). Neu ist `rueck_winkel = 35.0`.

Der Ablauf in `anhaengen()`:
1. Der Anker der Nadel ist die Kanonenspitze selbst (`erste_nadel.anker = $Schulter/Armbild/Bild/Spitze`). Der Arm schwenkt zur Hand.
2. `einhaken()`: `erste_nadel.ueber = Fadenpunkt`. Der Fadenpunkt steht noch an der Spitze und wandert dann in 0,2 s in die Hand (`halt` von 0 auf 1). Der Draht knickt dabei immer weiter zur Hand hin ab, sein Ende bleibt am Lauf.
3. `in_der_hand()`: Der Draht laeuft jetzt fest ueber die Hand (`ueber = haenger`), die Hand ist der Drehpunkt. Der Arm geht in 0,7 s um 35 Grad zurueck: Man sieht den Draht von der Fliege durch die Hand bis hinunter zur Kanone.
4. `loslassen()`: Der Anker wird der Fadenpunkt, der von der Spitze in die Hand wandert (`los` von 0 auf 1): Der Rest rutscht in die Hand.
5. `frei()`: `ueber = null`, `anker = haenger`. Der Draht endet in der Hand. Dann `sequenz_fertig`.

In `_process` setzt die Phase `laesst_los` den Fadenpunkt in jedem Bild auf `von.lerp(bis, los)`, genauso wie beim Einhaken.

**`skripte/uebergabe.gd` (jeder Fang im Flug).**

```gdscript
func _ready() -> void:
	process_priority = -1
```
Dieses Skript ist in jedem Bild vor den Nadeln dran. Knoten mit kleinerer Zahl laufen frueher, der Standard ist 0.

```gdscript
func _process(delta: float) -> void:
	for fahrt in fahrten.duplicate():
		if fahrt.is_valid():
			fahrt.custom_step(delta)
		else:
			fahrten.erase(fahrt)
```
Alle Fahrten der Uebergabe werden hier von Hand weitergestellt, aus demselben Grund wie beim Abheben: Sonst waere die Kanone schon weiter als der Draht. `duplicate()` macht eine Kopie der Liste, weil waehrend der Schleife Eintraege geloescht werden. `fahrt_anlegen()` legt einen angehaltenen Tween an und merkt ihn in `fahrten`.

`uebergeben()`: Die Hinfahrt ist wie vorher. Neu ist die Rueckfahrt:
- Der Anker bleibt die Muendung. Der Fadenpunkt startet an der Muendung, `nadel.ueber = fadenpunkt`, und wandert in den ersten 40 Prozent der Rueckfahrt (`einhak_anteil`) zum Griff: Der Draht hakt in die Hand ein und haengt weiter am Lauf.
- `vom_lauf_loesen(nadel, muendung)`: Jetzt laeuft der Draht fest ueber den Griff (`ueber = griff`). Der Fadenpunkt springt an die Muendung, wird der Anker und wandert in den restlichen 60 Prozent zum Griff: Das Ende loest sich vom Lauf und rutscht in die Hand.
- Am Ende: `ueber = null`, `anker = griff`.

Die Pruefung `is_instance_valid(nadel)` steht jetzt direkt nach der Hinfahrt: Hat ein Hindernis die Nadel inzwischen abgeschossen, geht es mit der naechsten weiter (`continue`).

**So wurde es angeschaut.** Schnellcheck PASS fuer `nadel.gd`, `start_totale.gd`, `uebergabe.gd`, Verify PASS. Probe Abheben: Der Draht geht durch die Hand bis zur Kanonenspitze, waehrend der Arm zurueckgeht. Gemessen nach jedem Bild an allen Enden (Hauptstueck an der Hand, Rest an der Hand, Rest am Lauf): hoechstens 0,00 Pixel Luecke in 3535 Bildern. Probe zweiter Fang im Flug: Der Draht laeuft von der Fliege durch die Hand hinunter zur Muendung, loest sich dann und rutscht in die Hand. Hoechstens 2,25 Pixel in 768 Bildern, und zwar am Griff, wenn die Nadeln im Faecher nachruecken (das Nachruecken stellt `faecher.gd` noch auf die alte Art weiter). Nicht angeschaut: das Gefuehl beim Spielen.

**Fragen.** 1. Was zeichnet die Linie `Rest`, und wann ist sie leer? 2. Warum bleibt beim Einhaken der Anker die Muendung? 3. Was bewirkt `process_priority = -1`?

### Nachtrag: Griffpunkt hoeher, das geloeste Drahtende baumelt (28.11.2026)

Deine Punkte: Der Draht soll hoeher in die Hand gehen, an der oberen Kante des obersten Fingers, zwischen Daumen und Fingern. Und das Stueck, das bis zur Kanone gereicht hat, soll nicht verschwinden, sondern unter der Hand haengen und baumeln, hinter dem Arm. Bei jedem Fang.

**Griffpunkt (`szenen/spiel.tscn`).** Der Griff lag in deinem Bild bei (768, 712), jetzt bei (770, 684): 28 Pixel hoeher, an der Oberkante des obersten Fingers. Die fuenf Bilder in `Haenger/Inhalt` stehen darum bei (-213, -14) statt (-211, -42), und `Haenger` bei (137, 25.3). Der Koerper bleibt dabei, wo er war, nur der Punkt, an dem der Draht haelt und um den er pendelt, ist gewandert. Die `Stichstelle` ist 70 Pixel tiefer, damit sie wieder auf dem Unterarm liegt.

**`skripte/nadel.gd`.**

```gdscript
@export var rest_schwere: float = 40.0
@export var rest_reibung: float = 1.5
@export var rest_hoechstens: float = 600.0
```
Wie stark das baumelnde Ende zur Mitte zurueckgezogen wird, wie schnell es ausschwingt, und wie lang es hoechstens ist.

```gdscript
var rest_laenge: float = 0.0
var rest_winkel: float = 0.0
var rest_tempo: float = 0.0
```
Die Laenge des Endes (0 heisst: keins), sein Winkel (0 heisst: gerade nach unten) und wie schnell sich der Winkel aendert.

```gdscript
		if rest_laenge > 0.0:
			rest_tempo += (-rest_schwere * sin(rest_winkel) - rest_reibung * rest_tempo) * delta
			rest_winkel += rest_tempo * delta
```
Neu in `_process`, nur wenn die Nadel steckt. Wieder ein Pendel: `sin(rest_winkel)` zieht zur Mitte, die Reibung bremst. Nach ein paar Schwingungen haengt das Ende still. Das sind zwei kleine Rechnungen je Nadel und Bild, fuer den Browser ohne Bedeutung.

```gdscript
	elif rest_laenge > 0.0:
		var ende: Vector2 = unten + Vector2.DOWN.rotated(rest_winkel) * rest_laenge
		$Rest.points = PackedVector2Array([$Rest.to_local(unten), $Rest.to_local(ende)])
```
Neu in `faden_spannen`. `unten` ist die Hand. Von dort geht die Linie `Rest` in Richtung des Winkels, so lang wie das Ende ist. `Vector2.DOWN.rotated(...)` ist ein Pfeil nach unten, um den Winkel gedreht.

```gdscript
func rest_abwerfen(hand: Node2D) -> void:
	var von: Vector2 = hand.global_position
	var bis: Vector2 = anker.global_position
	rest_laenge = minf(von.distance_to(bis), rest_hoechstens)
	rest_winkel = (bis - von).angle() - PI / 2.0
	rest_tempo = 0.0
	ueber = null
	anker = hand
```
Wird gerufen, wenn der Draht fest sitzt. Das Ende ist so lang wie der Weg von der Hand zum Lauf in diesem Moment und startet in der Richtung, in der die Kanone war. `angle()` misst ab der Richtung nach rechts, minus ein Viertelkreis (`PI / 2`) ergibt den Winkel ab "gerade nach unten". Danach endet der Draht in der Hand.

**`skripte/start_totale.gd`.** Die Phase `laesst_los` mit `los` ist weg, ebenso `frei()`. `loslassen()` ruft nur noch `erste_nadel.rest_abwerfen(haenger)` und dann `sequenz_fertig()`.

**`skripte/uebergabe.gd`.** `vom_lauf_loesen(nadel)` ruft `nadel.rest_abwerfen(griff)`. Der zweite Teil der Drahtfahrt ist weg.

**Hinter dem Arm.** Die Linie `Rest` gehoert zur Nadel im Faecher. Hand und Kittel haben `z_index = 1`, der Draht 0, also liegt das Ende dahinter. Zwischen den Fingern sieht man es durch.

**So wurde es angeschaut.** Schnellcheck PASS fuer `nadel.gd`, `start_totale.gd`, `uebergabe.gd`, Verify PASS. Probe wie zuvor: Abheben hoechstens 0,00 Pixel Luecke in 3507 Bildern, Fang im Flug 2,25 Pixel (Nachruecken im Faecher, unveraendert). In der Grossaufnahme geht der Draht an der Oberkante des obersten Fingers hinein, das Ende haengt dahinter herunter und ist in den Luecken zwischen den Fingern zu sehen. Nicht angeschaut: wie das Baumeln in Bewegung wirkt.

**Fragen.** 1. Warum haengt das Ende nach einer Weile still? 2. Woher kommt die Laenge des Endes? 3. Warum liegt es hinter der Hand?

### Nachtrag: Der Knick im Draht ist unter dem Finger versteckt (28.11.2026)

Dein Hinweis: Man sah den Knick, an dem der Draht in der Hand nach unten abbiegt. Er soll knapp unter der Kante des obersten Fingers liegen.

Nur zwei Zahlen in `szenen/spiel.tscn`: Der Griff liegt in deinem Bild jetzt bei (776, 693) statt (770, 684), also 9 Pixel tiefer und 6 weiter rechts, im Finger statt auf seiner Kante. Die fuenf Bilder in `Haenger/Inhalt` stehen dafuer bei (-219, -23), `Haenger` bei (142.6, 33.7). Der Finger liegt vor dem Draht (`z_index = 1`), darum verdeckt er den Knick.

So wurde es angeschaut: Verify PASS. Grossaufnahme der Hand waehrend und nach einem Fang: Der Draht verschwindet unter der Kante des obersten Fingers, den Knick sieht man nicht mehr. Das Ende kommt zwischen den Fingern wieder hervor. Luecken wie zuvor (0,00 und 2,25 Pixel).

### Nachtrag: Der Schwung der Kanone drueckt das Seil in die Hand, das Ende faellt als Seil (28.11.2026)

Deine Punkte: Die Kanone soll weiter hinueberfahren, und ihr Schwung soll das Seil in einem Bogen hochdruecken, bis es in der Hand landet, solange es noch an der Kanone haengt. Und das geloeste Ende soll nicht steif und gerade fallen, sondern biegsam wie ein Seil, mit Schwerkraft.

Damit ist der Umweg ueber den `ueber`-Punkt, den Knoten `Fadenpunkt` und das starre Pendel wieder weg. Was in den zwei Nachtraegen davor dazu steht, gilt nicht mehr.

**Der Bogen (`skripte/nadel.gd`).**

```gdscript
var schwung_punkt: Node2D = null
var schwung: float = 0.0
var bogen_extra: Vector2 = Vector2.ZERO
```
`schwung_punkt` ist die Hand, `schwung` sagt, wie weit der Draht schon dort ist (0 bis 1). `bogen_extra` ist ein Bogen, der von selbst verschwindet.

```gdscript
func bogen_jetzt(oben: Vector2, unten: Vector2) -> Vector2:
	var bogen: Vector2 = durchbiegung(oben, unten) + bogen_extra
	if schwung_punkt != null:
		bogen = bogen.lerp(schwung_punkt.global_position - (oben + unten) / 2.0, schwung)
	return bogen
```
Der Draht war schon immer eine Kurve: die gerade Linie plus ein Bogen, der in der Mitte am groessten ist (`faden_punkt`). Bisher war der Bogen nur der Durchhang. Jetzt wandert er mit `schwung` zu dem Wert "Hand minus Mitte der geraden Linie". Mit diesem Bogen liegt die Mitte der Kurve genau in der Hand. Bei `schwung` 1 laeuft der Draht also von der Fliege im Bogen durch die Hand und weiter zur Kanone. `faden_spannen` benutzt `bogen_jetzt` statt `durchbiegung`.

**Das Seilende (`skripte/nadel.gd`).**

```gdscript
@export var rest_schwerkraft: float = 2600.0
@export var rest_daempfung: float = 0.985
@export var rest_glieder: int = 10
@export var rest_takt: float = 0.0166
@export var bogen_tempo: float = 8.0
```
Die Schwerkraft, wie viel Schwung das Seil je Schritt behaelt, die Zahl der Glieder, die Laenge eines Rechenschritts (etwa eine Sechzigstelsekunde) und wie schnell der Draht nach dem Loslassen in den normalen Durchhang zurueckfindet.

```gdscript
var rest_punkte: PackedVector2Array = []
var rest_vorher: PackedVector2Array = []
var rest_laengen: PackedFloat32Array = []
var rest_ruht: bool = true
var rest_uhr: float = 0.0
var rest_stille: float = 0.0
```
Die Punkte der Glieder (gemessen von der Hand aus), dieselben Punkte einen Schritt davor, die Laenge jedes Glieds, ob das Seil still haengt, die noch nicht gerechnete Zeit und wie lange es sich schon kaum bewegt.

`rest_abwerfen(hand)`: Im Moment des Loslassens laeuft der Draht als eine Kurve von der Fliege durch die Hand zur Kanone. Die untere Haelfte wird zum Seilende: Sie wird in 40 kurzen Stuecken abgetastet (`fein`), ihre Laenge wird gemessen, und darauf werden 10 gleich lange Glieder verteilt. Das Seil beginnt also genau dort, wo der Draht eben noch war. `rest_vorher = rest_punkte.duplicate()` macht eine echte Kopie: Ohne `duplicate()` waeren beide Listen dieselbe Liste, und das Seil haette keinen Schwung (das war ein Fehler in meiner ersten Fassung). Die obere Haelfte bleibt der Draht zur Fliege. Damit er nicht springt, bekommt er als `bogen_extra` den Bogen mit, den seine Haelfte gerade hatte. Am Ende `faden_spannen()`, damit alles schon in diesem Bild stimmt.

```gdscript
func rest_fallen(delta: float) -> void:
	rest_uhr += minf(delta, 0.1)
	while rest_uhr >= rest_takt:
		rest_uhr -= rest_takt
		rest_schritt()
```
Das Seil wird in gleich grossen Zeitschritten gerechnet. Dauert ein Bild laenger, gibt es mehrere Schritte, dauert es kuerzer, manchmal keinen. So faellt es auf jedem Geraet gleich schnell. (Meine erste Fassung rechnete einmal je Bild und fiel je nach Bildrate anders.)

`rest_schritt()`:
```gdscript
		var schritt: Vector2 = (punkte[nummer] - vorher[nummer]) * rest_daempfung
		vorher[nummer] = punkte[nummer]
		punkte[nummer] = punkte[nummer] + schritt + Vector2.DOWN * rest_schwerkraft * rest_takt * rest_takt
```
Jedes Glied geht so weiter, wie es im Schritt davor gegangen ist (das ist sein Schwung, etwas gebremst), und die Schwerkraft zieht es nach unten.
```gdscript
			var stueck: Vector2 = punkte[nummer] - punkte[nummer - 1]
			var zu_viel: Vector2 = stueck.normalized() * (stueck.length() - rest_laengen[nummer])
```
Danach wird jedes Glied wieder auf seine Laenge gebracht: Ist es zu lang, ruecken seine zwei Enden je die Haelfte zusammen. Beim obersten Glied bewegt sich nur das untere Ende, das obere haengt an der Hand. Das laeuft achtmal hintereinander, damit sich das Seil nicht dehnt. Bewegt sich eine halbe Sekunde lang fast nichts mehr (`rest_stille`), wird das Seil nicht mehr gerechnet (`rest_ruht`).

In `_process` wird `bogen_extra` in jedem Bild kleiner (`lerp` zu null) und das Seil faellt weiter, solange es nicht ruht.

**Abheben (`skripte/start_totale.gd`).** `am_lauf` ersetzt `hakt_ein` und `halt`, `gleit_dauer` ist weg. In `anhaengen()` bekommt die Nadel `schwung_punkt = hand`, und im Ablauf laeuft `schwung` von 0 auf 1, waehrend der Arm zur Hand schwenkt (die letzten 70 Prozent des Schwenks). Der Pendel-Drehpunkt wandert mit: `spitze.lerp(hand, erste_nadel.schwung)`. `loslassen()` ruft `rest_abwerfen`.

**Jeder Fang (`skripte/uebergabe.gd`).** `ziel_x = 540` statt 480: Die Kanone faehrt bis unter die Hand und ein Stueck weiter. Auf der Hinfahrt laeuft `nadel.schwung` von 0 auf 1: Der Draht schwingt im Bogen hinueber. Auf der Rueckfahrt haengt er noch 40 Prozent der Zeit am Lauf (`halte_anteil`), dann `vom_lauf_loesen`. Der `fadenpunkt` ist weg, auch als Knoten in der Szene.

**So wurde es angeschaut.** Schnellcheck PASS fuer `nadel.gd`, `start_totale.gd`, `uebergabe.gd`, Verify PASS. Probe mit festen 60 Bildern pro Sekunde. Luecken am Drahtende, am Bogen in der Hand und am Seilende: Abheben 0,00 Pixel, Fang im Flug 0,25 Pixel. Die Spitze des Seilendes haengt nach dem Loslassen etwa 470 Pixel unter der Hand und pendelt zwischen etwa 80 Pixel links und rechts aus. Zwei Fehler habe ich dabei gefunden und behoben: Erst fiel das Seil gar nicht (die zwei Listen waren dieselbe), und beim Abheben sass das Drahtende ein Bild lang noch an der Kanone (174 Pixel). Nicht angeschaut: wie Bogen und Seil in Bewegung wirken.

**Fragen.** 1. Warum laeuft der Draht bei `schwung` 1 genau durch die Hand? 2. Wozu braucht das Seil die Punkte vom Schritt davor? 3. Warum wird das Seil in festen Zeitschritten gerechnet?

### Nachtrag: Weniger Schwung, die Rundung haengt unten (28.11.2026)

Dein Hinweis: Das Seil schwang uebermaessig, ohne dass die Kanone sich so bewegt haette. Der Bogen nach oben soll weg. Die Rundung soll unten haengen.

Was falsch war: Ich hatte das ganze Seil als eine Kurve durch die Hand gerechnet. Diese Kurve woelbte sich nach oben und zur Seite, egal wie die Kanone fuhr. Und das geloeste Ende pendelte mehrere Sekunden nach.

**`skripte/nadel.gd`.** `bogen_extra`, `bogen_jetzt` und `bogen_tempo` sind wieder weg. `schwung_punkt` und `schwung` bleiben, bedeuten aber etwas Einfacheres: wie weit die Stelle, an der das Seil gehalten wird, schon von der Kanone zur Hand gewandert ist.

```gdscript
@export var durchhang_rest: float = 0.12
```
Wie weit das Stueck zwischen Hand und Kanone durchhaengt, als Anteil seiner Laenge.

```gdscript
func rest_bogen(von: Vector2, bis: Vector2) -> Vector2:
	var richtung: Vector2 = von.direction_to(bis)
	var quer: Vector2 = Vector2.DOWN - richtung * Vector2.DOWN.dot(richtung)
	return quer * von.distance_to(bis) * durchhang_rest
```
Gerechnet wie `durchbiegung`: Von der Schwerkraft (nach unten) bleibt nur der Teil uebrig, der quer zum Seil zieht. Haengt das Stueck senkrecht, ist das null und es bleibt gerade. Laeuft es schraeg, haengt es nach unten durch. Das ist die Rundung unten.

```gdscript
	if schwung_punkt != null:
		var halt: Vector2 = unten.lerp(schwung_punkt.global_position, schwung)
		var schlaufe: Vector2 = rest_bogen(halt, unten)
		var stuecke: PackedVector2Array = []
		for nummer in 9:
			stuecke.append($Rest.to_local(faden_punkt(halt, unten, schlaufe, nummer / 8.0)))
		$Rest.points = stuecke
		unten = halt
```
In `faden_spannen`. `halt` ist die Stelle, an der das Seil gehalten wird: bei `schwung` 0 die Kanone, bei 1 die Hand. Das Seil zur Fliege endet dort (`unten = halt`) und haengt ganz normal durch. Von `halt` zur Kanone geht die Linie `Rest` in 8 Stuecken, mit der Schlaufe nach unten. Am Anfang ist dieses Stueck null lang, es waechst, waehrend die Kanone das Seil zur Hand hochnimmt.

`rest_abwerfen(hand)`: Das Seilende entsteht jetzt aus genau diesem Stueck zwischen Hand und Kanone (vorher: aus der unteren Haelfte der grossen Kurve). Das Seil zur Fliege aendert sich beim Loslassen gar nicht mehr.

`rest_daempfung = 0.95` statt 0,985: Das Ende verliert je Rechenschritt 5 Prozent seines Schwungs und haengt nach etwa einer Sekunde still.

**`skripte/uebergabe.gd`.** `schwung` laeuft erst in der zweiten Haelfte der Hinfahrt von 0 auf 1 (`dauer / 2.0`, mit `set_delay(dauer / 2.0)`): Die Kanone nimmt das Seil erst mit hoch, wenn sie fast bei der Hand ist. `halte_anteil = 0.25` statt 0,4: Das Seil loest sich frueher, wenn die Kanone noch fast unter der Hand steht. Dann haengt das Ende beim Loslassen schon fast gerade und hat wenig Grund zu schwingen.

**So wurde es angeschaut.** Schnellcheck PASS fuer `nadel.gd` und `uebergabe.gd`, Verify PASS. Probe mit 60 Bildern pro Sekunde: Das Seil geht gerade von der Fliege zur Kanone, wird beim Ankommen in die Hand gelegt und haengt als Schlaufe nach unten zur Kanone. Luecken hoechstens 0,00 Pixel (Abheben) und 0,25 (Fang). Die Spitze des geloesten Endes startet 127 Pixel neben der Hand und haengt nach einer Sekunde gerade darunter, sie schwingt nur noch 11 Pixel ueber die Mitte hinaus (vorher 80 und mehrere Sekunden lang). Nicht angeschaut: wie es in Bewegung wirkt.

**Fragen.** 1. Warum haengt ein senkrechtes Seilstueck nicht durch? 2. Was aendert `rest_daempfung` 0,95 gegenueber 0,985? 3. Warum loest sich das Seil jetzt frueher vom Lauf?

### Nachtrag: Bogen zurueck, die Kanone wirft, der Kanonenarm liegt beim Haengen hinten (28.11.2026)

Deine Punkte: (1) Im Haenge-Bild soll der drehbare Arm mit der Kanone hinter Kopf und Koerper liegen, nur dort. (2) Das Seil soll wieder so schwingen wie in der Fassung mit dem Bogen, aber die Kanone soll in ihrer Bewegung selbst den Schwung machen, der dazu passt.

**Das Seil (`skripte/nadel.gd`).** Die Fassung aus dem vorigen Nachtrag ("Weniger Schwung, die Rundung haengt unten") ist zurueckgenommen: `rest_bogen` und `durchhang_rest` sind wieder weg. Es gilt wieder der Nachtrag davor ("Der Schwung der Kanone drueckt das Seil in die Hand"): `bogen_jetzt`, `bogen_extra`, `bogen_tempo`, das Seil laeuft bei `schwung` 1 als eine Kurve durch die Hand. Einzige Aenderung: `rest_daempfung = 0.97` statt 0,985, das geloeste Ende haengt nach etwa anderthalb Sekunden still.

**Der Wurf der Kanone (`skripte/uebergabe.gd`).**

```gdscript
@export var wurf_hoehe: float = 110.0
@export var wurf_winkel: float = 28.0
```
Wie weit die Kanone am Ende der Hinfahrt anhebt und wie weit sie zur Hand kippt.

```gdscript
		hin.tween_property(arm, "position:x", ziel_x, dauer)
		hin.parallel().tween_property(arm, "position:y", -wurf_hoehe, dauer / 2.0).set_delay(dauer / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		hin.parallel().tween_property(arm, "rotation", deg_to_rad(wurf_winkel), dauer / 2.0).set_delay(dauer / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
```
Die Fahrt zur Seite ist wie vorher, nur noch fuer `position:x`. Neu: In der zweiten Haelfte (`set_delay(dauer / 2.0)`) hebt die Kanone 110 Pixel an (minus ist nach oben) und kippt 28 Grad zur Hand. `TRANS_QUAD` mit `EASE_IN` heisst: erst langsam, dann immer schneller, wie ein Wurf.

```gdscript
		hin.parallel().tween_property(nadel, "schwung", 1.0, dauer).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
```
Der Bogen des Seils waechst mit derselben Kurve wie der Wurf: Das Seil schwingt hinueber, weil die Kanone wirft.

Auf der Rueckfahrt geht `position` zurueck auf null (also auch die Hoehe) und `rotation` zurueck auf 0. `halte_anteil` ist wieder 0,4. Wird die Nadel waehrend der Hinfahrt abgeschossen, stellt das Skript Hoehe und Kippen sofort zurueck.

**Kanonenarm hinter dem Koerper (`skripte/start_totale.gd`, `skripte/haengen.gd`).**

```gdscript
func arm_nach_hinten() -> void:
	kanone.move_child(self, haenger.get_index())
	$Schulter.z_index = 0
```
Godot zeichnet Geschwister in der Reihenfolge der Liste: Was weiter oben steht, liegt hinten. `move_child` rueckt die Figur in der Liste an die Stelle des haengenden Forschers, der rutscht eins weiter. So wird der Arm zuerst gezeichnet und liegt hinter Kopf und Koerper. `z_index = 0` nimmt ihm den Vorrang, den er im Stehen hat (dort bleibt er vorn). Gerufen in `anhaengen()` und, fuer den Testsprung, in `wegschwenken()`.

In `haengen.gd` steht in `_ready` neu `process_priority = -1`: Der haengende Forscher ist in jedem Bild vor der Figur dran, obwohl er jetzt in der Liste hinter ihr steht. Die Figur richtet sich nach ihm, also muss er zuerst gerechnet sein.

**So wurde es angeschaut.** Schnellcheck PASS fuer `nadel.gd`, `uebergabe.gd`, `haengen.gd`, `start_totale.gd`, Verify PASS. Probe mit 60 Bildern pro Sekunde: Beim Haengen laeuft der Aermel des Kanonenarms hinter dem Kopf vorbei. Beim Fang im Flug hebt und kippt die Kanone zur Hand, das Seil schwingt im Bogen hinein. Luecken 0,00 und 0,25 Pixel. Das geloeste Ende startet 143 Pixel neben der Hand und haengt nach 1,5 Sekunden still. Aufgefallen: Die geworfene Kanone steht dabei zum Teil hinter dem Aermel. Nicht angeschaut: wie der Wurf in Bewegung wirkt.

**Fragen.** 1. Was bewirkt `EASE_IN` beim Wurf? 2. Warum liegt der Arm nach `move_child` hinter dem Koerper? 3. Wozu braucht `haengen.gd` jetzt `process_priority = -1`?

## Steine verschwinden erst mit klarem Abstand unter dem Bild (`skripte/hindernis.gd`, 28.11.2026)

Dein Hinweis: Ein fallender Stein darf nicht verschwinden, solange man ihn noch sehen kann oder gleich wieder sehen koennte. Stuerzt man ab, kommt man wieder in sein Blickfeld.

Vorher verschwand der Stein, sobald er 300 Pixel unter der Kanone war. Im Flug liegt der untere Bildrand 20 Pixel unter der Kanone, das reichte. Beim Absturz bis zum Boden zoomt die Kamera aber heraus: Dann reicht das Bild bis 1840 Pixel unter die Kanone, und dort fehlte der Stein.

```gdscript
@export var weg_abstand: float = 1900.0
```
Ersetzt `weg_unter`. So weit muss der Stein unter dem unteren Bildrand sein, bevor er verschwindet. 1900 ist mehr als der Sprung des Bildrands beim Herauszoomen (von 20 auf 1840 unter der Kanone).

```gdscript
	if position.y - hoehe > bildrand_unten() + weg_abstand:
		queue_free()
```
`position.y` ist die Unterkante des Steins, minus `hoehe` ist seine Oberkante. Erst wenn auch die Oberkante weit genug unter dem Bild liegt, wird er geloescht.

```gdscript
func bildrand_unten() -> float:
	var kamera: Camera2D = get_viewport().get_camera_2d()
	return kamera.get_screen_center_position().y + 540.0 / kamera.zoom.y
```
Neu. Gemessen wird am Bild, das die Kamera gerade zeigt, nicht mehr an der Kanone. `get_screen_center_position()` ist die Bildmitte in der Welt, 540 ist die halbe Bildhoehe. Bei Zoom 0,43 zeigt das Bild mehr, darum wird durch den Zoom geteilt: 540 / 0,43 = 1256 Pixel bis zum unteren Rand.

Ein Stein lebt dadurch etwa 1,3 Sekunden laenger (1900 Pixel bei 1500 Pixeln pro Sekunde). Mehr als ein paar Steine gleichzeitig gibt es trotzdem nicht.

### So wurde es angeschaut

- Schnellcheck PASS fuer `hindernis.gd`, Verify PASS.
- Probe mit 60 Bildern pro Sekunde: ein Stein links neben der Kanone, er faellt aus dem Bild. Als seine Oberkante 935 Pixel unter dem Bildrand war (mit der alten Regel waere er schon geloescht), begann der Absturz bis zum Boden. Der Stein war in allen drei Messungen waehrend des Herauszoomens noch da und lag wieder im Bild (1817 bis 2608 Pixel ueber dem unteren Rand). Geloescht wurde er erst 3,6 Sekunden spaeter.
- Nicht angeschaut: Der Stein faellt am Boden durch die Wiese weiter, bis er unter dem Bild ist. Das war vorher auch so, faellt jetzt aber eher auf, weil er laenger lebt.

### Drei Fragen zur Selbstkontrolle

1. Warum wird durch den Zoom geteilt?
2. Warum zaehlt die Oberkante des Steins und nicht die Unterkante?
3. Woher kommt die Zahl 1900?

### Nachtrag: Das Seil antwortet auf die Fahrt der Kanone (`skripte/uebergabe.gd`, 28.11.2026)

Dein Hinweis: Das Seil bog sich schon zur Hand, bevor die Kanone richtig losgefahren war. Es soll am Anfang eher in die andere Richtung schwingen (zurueckbleiben) und erst kurz vor der Ankunft die Kurve zur Hand machen. Welche Staerke es wird, waehlst du aus drei Beispielen. Eingebaut ist vorerst Beispiel 1.

```gdscript
@export var gegen_schwung: float = 0.25
@export var schwung_ab: float = 0.6
```
`gegen_schwung`: wie stark sich das Seil am Anfang von der Hand weg biegt (0 heisst gar nicht). `schwung_ab`: ab welchem Anteil der Hinfahrt es zur Hand hinueberschwingt (0,6 heisst: nach 60 Prozent).

```gdscript
		hin.parallel().tween_method(schwung_setzen.bind(nadel), 0.0, 1.0, dauer)
```
Statt `schwung` direkt von 0 auf 1 laufen zu lassen, ruft der Tween in jedem Bild `schwung_setzen` auf, mit einer Zahl von 0 (Anfang der Hinfahrt) bis 1 (Ende). `.bind(nadel)` gibt die Nadel als zweiten Wert mit.

```gdscript
func schwung_setzen(anteil: float, nadel: Node2D) -> void:
	if not is_instance_valid(nadel):
		return
	if anteil < schwung_ab:
		nadel.schwung = -gegen_schwung * sin(PI * anteil / schwung_ab)
	else:
		var rest: float = (anteil - schwung_ab) / (1.0 - schwung_ab)
		nadel.schwung = rest * rest
```
Vor `schwung_ab` ist `schwung` negativ: Der Bogen des Seils zeigt von der Hand weg, das Seil bleibt hinter der fahrenden Kanone zurueck. `sin` laeuft dabei von 0 ueber 1 zurueck auf 0, das Zurueckbleiben waechst also und geht wieder weg. Danach laeuft `rest` von 0 auf 1, und `rest * rest` macht daraus eine Kurve, die langsam anfaengt und schnell endet: der Schwung zur Hand. Bei 1 laeuft das Seil genau durch die Hand.

**So wurde es angeschaut.** Schnellcheck PASS fuer `uebergabe.gd`, Verify PASS. Derselbe Fang dreimal aufgenommen, mit (0,25 / 0,6), (0 / 0,6) und (0,45 / 0,75). In den Standbildern biegt sich das Seil bei 1 und 3 am Anfang nach links von der Hand weg, bei 2 bleibt es gerade, und bei allen kommt die Kurve zur Hand erst, wenn die Kanone fast dort ist. Welche Fassung sich richtig anfuehlt, entscheidest du.

**Fragen.** 1. Was bedeutet ein negativer `schwung`? 2. Warum `rest * rest` und nicht einfach `rest`? 3. Was macht `tween_method` anders als `tween_property`?

### Nachtrag: Aura um den Boss mit atmenden Loechern, Teleport-Ringe sofort farbig (28.11.2026)

**Aura.** Neuer Knoten `Aura` in `szenen/fliege_boss.tscn`, ganz hinten. Sein Bild (`umriss/aura-boss-1.png` und `-2.png`, je Fluegelbild, mit Spur `Aura:texture` in `flattern`) ist eine weisse Flaeche um den Umriss, die nach aussen gleichmaessig durchsichtig wird: am Rand des Kaefers 92 Prozent deckend, 156 Pixel weiter 0. Gerechnet ausserhalb des Spielordners: fuer jeden Bildpunkt der Abstand zum Umriss (`distance_transform_edt` aus scipy), Deckkraft = 1 - Abstand / 156.

Die Loecher macht `shader/aura.gdshader` (neu), als `ShaderMaterial` an `Aura`. Das Bild wird gedanklich in Felder geteilt, 60 Bildpunkte gross. In jedem Feld sitzt ein Loch an einer zufaelligen Stelle (`wuerfeln(nachbar)`), darum sieht es nicht nach Raster aus. Fuer jeden Bildpunkt wird das eigene Feld und die acht Nachbarfelder angesehen (die zwei `for`-Schleifen), weil ein Loch ueber den Rand seines Felds ragen kann.

```glsl
float atem = 0.5 + 0.5 * sin(TIME * tempo * (0.6 + zufall.x) + zufall.y * 6.28);
float radius = loch_groesse * (0.3 + 0.7 * zufall.y) * atem;
```
`TIME` ist die Zeit seit dem Start. `sin` geht zwischen -1 und 1 hin und her; `0.5 + 0.5 * sin(...)` macht daraus 0 bis 1. Bei 0 ist das Loch ganz weg, bei 1 so gross wie es fuer dieses Loch geht. Jedes Loch hat sein eigenes Tempo (`0.6 + zufall.x`) und seinen eigenen Startpunkt (`zufall.y * 6.28`, 6,28 ist eine ganze Runde), darum atmen sie nicht im Gleichtakt. `smoothstep` macht den Lochrand weich. Ist der Bildpunkt in einem Loch, wird er durchsichtig (`farbe.a * offen`).

Einstellbar im Inspector am Material von `Aura`: `feld` (Abstand der Loecher), `loch_groesse`, `tempo`.

**Weisser Rand an der Teleport-Fliege** (dein Foto): Die Ringe bekamen ihre Farbe nur in `fliegen()`, also wenn die Fliege frei fliegt. Eine Fliege, die gerade ins Bild hereinflieht, kommt dort nicht hin (`fliege.gd` macht vorher `return`). Ihre Ringe blieben weiss und voll deckend; wurde sie so gefangen, blieb es so. Jetzt ruft `losfliegen()` gleich am Anfang `leuchten_zeigen(ladung_jetzt())` auf.

Angeschaut: Schnellcheck PASS (`fliege_teleport.gd`), Verify PASS. Probe: Boss auf dunklem Grund, zwei Zeitpunkte 1,5 s auseinander: die Loecher sind verschieden gross, manche weg; hereinfliehende Teleport-Fliege hat sofort Ring 1 in Gruen (0.44, 0.69, 0.27, Deckkraft 0,55).

### Nachtrag: Die Kanone faehrt zum Mauszeiger (`skripte/kanone.gd`, 28.11.2026)

Dein Wunsch: Im normalen Spiel soll man die Kanone auch lenken koennen, indem der Zeiger links oder rechts von der Mitte liegt. Sie faehrt dann in die Richtung des Zeigers. Tasten und Joystick bleiben wie sie sind.

```gdscript
@export var maus_totzone: float = 40.0
@export var maus_voll: float = 300.0
```
Zwei neue Werte fuer den Inspector. `maus_totzone`: Liegt der Zeiger weniger als 40 Pixel neben der Mitte der Kanone, bleibt sie stehen. Ohne das wuerde sie unter dem Zeiger hin und her zittern. `maus_voll`: Ab 300 Pixeln Abstand faehrt sie mit vollem Tempo. Dazwischen langsamer, so kann man fein lenken.

```gdscript
var maus_lenkt: bool = false
```
Der Schalter: Lenkt gerade die Maus? Am Anfang nein. Sonst wuerde die Kanone bei jedem, der nur mit Tasten spielt, zum Zeiger laufen, der irgendwo im Fenster herumliegt.

```gdscript
func _input(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseMotion:
		maus_lenkt = true
```
Godot ruft `_input` bei jeder Eingabe auf und gibt sie als `ereignis` mit. `is InputEventMouseMotion` fragt: War das eine Mausbewegung? Wenn ja, lenkt ab jetzt die Maus. Ein Finger am Handy zaehlt nicht als Maus (in `project.godot` ist `emulate_mouse_from_touch` aus), dort aendert sich also nichts.

```gdscript
	if richtung != 0.0:
		maus_lenkt = false
	elif maus_lenkt:
		var abstand: float = get_global_mouse_position().x - global_position.x
		if absf(abstand) > maus_totzone:
			richtung = abstand / maus_voll
```
Neu in `fahren`, gleich nach der Zeile mit Tasten und Joystick. Lenken die Tasten oder der Joystick (`richtung` ist nicht 0), gewinnen sie, und die Maus ist abgemeldet, bis man sie wieder bewegt. Sonst, wenn die Maus lenkt: `abstand` ist, wie viele Pixel der Zeiger rechts von der Kanone liegt (negativ heisst links). `get_global_mouse_position()` gibt die Stelle des Zeigers in der Spielwelt, `global_position` die der Kanone. `absf` macht aus einer negativen Zahl eine positive, so gilt die Totzone fuer beide Seiten. `abstand / maus_voll` ergibt bei 300 Pixeln genau 1 (volles Tempo), bei 150 Pixeln 0,5. Die Zeile danach (`clampf`, gab es schon) schneidet alles ueber 1 ab. Der Rest von `fahren` ist unveraendert: Anfahren, Bremsen und das Feuer an den Triebwerken gelten auch fuer die Maus.

Weil die Kamera an der Kanone haengt, steht die Kanone immer in der Bildmitte. "Zeiger rechts von der Kanone" ist also dasselbe wie "Zeiger rechts von der Bildmitte".

**So wurde es angeschaut.** Schnellcheck PASS fuer `kanone.gd`, Verify PASS. Probe im Fenster, je 1,5 Sekunden: Zeiger rechts: 453 Pixel nach rechts, volles Tempo 360. Zeiger links: 453 nach links. Zeiger knapp ueber der Totzone: 79 Pixel, Tempo 54. Taste rechts bei Zeiger links: 453 nach rechts, die Taste gewinnt. Taste los, Maus nicht bewegt: 0 Pixel. Ohne Mausbewegung am Anfang: 0. Gemessen in der Totale (Zoom 0,43), nicht im herangezoomten Spiel. Wie es sich anfuehlt und ob 40 und 300 passen, entscheidest du am Spiel.

**Fragen.** 1. Wozu braucht es `maus_lenkt`, wenn man doch einfach immer den Zeiger nehmen koennte? 2. Was passiert ohne Totzone? 3. Warum wird durch `maus_voll` geteilt?

### Nachtrag: Seil-Variante 2, Kanone vor dem Arm, Kanone beim Absturz weg (28.11.2026)

**Seil (`skripte/uebergabe.gd`).** Du hast Variante 2 gewaehlt: Das Seil bleibt am Anfang gerade und macht die Kurve zur Hand erst im letzten Stueck.

```gdscript
@export var gegen_schwung: float = 0.0
```
Vorher 0.25. Mit 0 ergibt `-gegen_schwung * sin(...)` immer 0, das Seil biegt sich am Anfang also gar nicht mehr weg. Der Regler bleibt, falls du doch etwas Zurueckbleiben willst.

**Kanone vor dem Arm (`szenen/spiel.tscn`).** Zwei Dinge entscheiden, was vorn liegt: `z_index` (groessere Zahl liegt vorn) und bei gleicher Zahl die Reihenfolge in der Liste (was weiter unten steht, liegt vorn). Aermel und Oberkoerper des haengenden Forschers haben `z_index = 1`. Darum:

- Der Knoten `Kanone/Arm` (die Kanone des Spiels) steht in der Liste jetzt **unter** `Haenger` statt darueber.
- Er hat `z_index = 1` bekommen, dieselbe Zahl wie der Aermel. Bei gleicher Zahl gewinnt die Reihenfolge, also die Kanone.

Nicht 2, weil die Steine `z_index = 2` haben und weiter vor der Kanone liegen sollen. In der Totale aendert sich nichts: Dort sieht man diesen Knoten nicht, sondern den Kanonenarm der Figur (`Figur/Schulter`), und der liegt beim Haengen weiter hinter dem Koerper.

**Absturz, der nicht bis zum Boden geht (`skripte/spiel.gd`).**

```gdscript
@export var koerper_start: float = 0.0
@export var koerper_einflug: float = 430.0
```
`koerper_start`: wo der fallende Forscher wartet, gemessen von der Kanone nach unten. Bei 0 liegt seine Oberkante knapp unter dem unteren Bildrand. Vorher startete er am Boden-Platz, 1170 Pixel tiefer, und musste erst 1200 Pixel fahren, bevor man etwas sah. `koerper_einflug`: wie weit er von dort ins Bild kommt (vorher 1600 vom Boden-Platz aus, er landet an derselben Stelle wie vorher).

```gdscript
	koerper.position.y = koerper_start
	...
	$Kanone/Haenger.visible = false
	$Kanone/Arm.visible = false
```
Der Forscher wird an den Startplatz gesetzt. Hand und Kanone werden im selben Moment unsichtbar.

```gdscript
	koerperfahrt.tween_property(koerper, "position:y", koerper_start - koerper_einflug, dauer * koerper_anteil)
	koerperfahrt.tween_interval(dauer * (1.0 - 2.0 * koerper_anteil))
	koerperfahrt.tween_property(koerper, "position:y", koerper_start, dauer * koerper_anteil)
	koerperfahrt.tween_callback(zwischenfall_ende)
```
Hinein, warten, wieder hinaus bis zum Startplatz, dann `zwischenfall_ende`.

```gdscript
func zwischenfall_ende() -> void:
	$Kanone/Aufstehen.visible = false
	$Kanone/Aufstehen.position.y = koerper_unten
	$Kanone/Haenger.visible = true
	$Kanone/Arm.visible = kanone_da
```
Der fallende Forscher verschwindet und steht wieder am Boden-Platz bereit (dort braucht ihn der Aufprall). Die Hand ist wieder da. Die Kanone nur, wenn es sie schon gibt (`kanone_da`).

**So wurde es angeschaut.** Schnellcheck PASS (`spiel.gd`, `uebergabe.gd`), Verify PASS. Probe mit vier Bildern: Kanone in Wurfstellung unter der Hand liegt vor dem Aermel. 0,08 Sekunden nach Beginn eines Absturzes (6 Fliegen verloren) sind Kanone und Hand weg und der Forscher ist schon mit Rumpf und Beinen im Bild (vorher zu diesem Zeitpunkt noch nichts). Nach dem Absturz sind Kanone und Hand wieder da. Nicht angeschaut: wie es in Bewegung wirkt, und ein Absturz, waehrend die Kanone gerade ein Seil zur Hand faehrt (das Seil haengt dann kurz an der unsichtbaren Kanone). Die Flugkraft-Leiste bleibt beim Absturz stehen.

**Fragen.** 1. Warum reicht `z_index = 1`, obwohl der Aermel dieselbe Zahl hat? 2. Warum `kanone_da` und nicht einfach `true`? 3. Was passiert mit `gegen_schwung = 0` in `schwung_setzen`?

### Nachtrag: Jede Fliege schaut in ihre Flugrichtung (28.11.2026)

Vorher spiegelten sich nur die schnelle Fliege und die Heuschrecke, jede mit eigenem Code. Jetzt macht das `skripte/fliege.gd` fuer alle.

Neue Werte: `kopf_rechts` (im Bild schaut der Kopf nach rechts; nur bei der Heuschrecke `true`, in `fliege_heuschrecke.tscn`), `blick_folgt` (aus bei der normalen Fliege, die sich dauernd im Kreis dreht, `fliege_normal.tscn`), `wende_weg` (20 Pixel). Neue Variablen: `gespiegelt` und `blick_x`.

`_process` ruft nach dem Fliegen (oder Fliehen) `blick_richten()` auf:
```gdscript
	var weg: float = position.x - blick_x
	if absf(weg) < wende_weg:
		return
	blick_x = position.x
	blick_setzen(weg > 0.0)
```
`blick_x` ist die Stelle, an der zuletzt gemessen wurde. Erst wenn die Fliege 20 Pixel seitlich weiter ist, wird neu entschieden. Ist `weg` positiv, fliegt sie nach rechts. So dreht sie sich nicht bei jedem kleinen Wackeln um.

`blick_setzen(nach_rechts)`: Gespiegelt werden muss, wenn sie anders schauen soll als im Bild (`nach_rechts != kopf_rechts`). Nur wenn sich das gegenueber jetzt aendert, wird `spiegeln(self)` aufgerufen.

`spiegeln(knoten)` geht durch alle Kinder: `position.x` mal -1 (auf die andere Seite der Mittellinie) und bei Bildern `flip_h` umgedreht. Dann ruft es sich selbst fuer die Kinder des Kindes auf (so werden auch `Gefahr/Rand` und `Leuchten/Ring1` bis `Ring3` mitgespiegelt). Eine Funktion, die sich selbst aufruft, heisst rekursiv. Knoten mit eigenem Skript (eine Nadel, die im Boss steckt) werden uebersprungen.

`_ready`: gleich nach `losfliegen()` schaut die Fliege in die Richtung, in die sie startet (`blick_setzen(richtung > 0.0)`).

`fliege_schnell.gd` und `fliege_heuschrecke.gd`: ihr eigenes Spiegeln (`bild_richten`, `gespiegelt`) ist raus. `fliege_teleport.gd`: Nach einem Sprung wird `blick_x` neu gesetzt, damit der Sprung selbst sie nicht umdreht.

Angeschaut: Schnellcheck PASS (`fliege.gd`, `fliege_schnell.gd`, `fliege_heuschrecke.gd`, `fliege_teleport.gd`), Verify PASS. Probe ueber 600 Bilder mit wandernder Kanone: Die Bilder, in denen eine Fliege falsch herum schaut, sind die ersten 20 Pixel nach einer Wende (schnelle 24 von 573, Heuschrecke 3 von 169, scheue 0 von 182). Standbild aller sechs Arten nach links und nach rechts: Fluegel, Warnumriss, Ringe und Boss-Aura gehen mit.
