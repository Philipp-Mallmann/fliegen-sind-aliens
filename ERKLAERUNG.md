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
