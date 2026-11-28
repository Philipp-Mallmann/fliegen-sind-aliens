// Die Aura des Bosses: Das Bild ist eine weisse Flaeche, die nach aussen durchsichtig wird.
// Dieser Shader stanzt runde Loecher hinein. Jedes Loch waechst und schrumpft in seinem eigenen Takt,
// bis es ganz verschwindet und wieder auftaucht ("atmen").
shader_type canvas_item;

// Wie weit die Loecher auseinander liegen, in Bildpunkten des Bildes. In jedem Feld dieser Groesse sitzt ein Loch.
uniform float feld = 60.0;
// Wie gross ein Loch hoechstens wird, als Anteil der Feldgroesse. 0.55 heisst: etwas mehr als die halbe Feldbreite als Radius.
uniform float loch_groesse = 0.55;
// Wie schnell die Loecher atmen. 1 heisst: ein Atemzug dauert ungefaehr 6 Sekunden, 2 doppelt so schnell.
uniform float tempo = 1.0;

// Die Farbe des Knotens (modulate), im vertex-Teil gemerkt.
varying vec4 knoten_farbe;

// Macht aus einer Stelle zwei scheinbar zufaellige Zahlen zwischen 0 und 1. Gleiche Stelle, gleiche Zahlen.
vec2 wuerfeln(vec2 stelle) {
	return fract(sin(vec2(dot(stelle, vec2(127.1, 311.7)), dot(stelle, vec2(269.5, 183.3)))) * 43758.5453);
}

void vertex() {
	knoten_farbe = COLOR;
}

void fragment() {
	vec4 farbe = texture(TEXTURE, UV);
	// Die Stelle dieses Bildpunkts, gemessen in Feldern.
	vec2 punkt = UV / TEXTURE_PIXEL_SIZE / feld;
	vec2 eigenes_feld = floor(punkt);
	// 1 heisst: nicht in einem Loch. 0 heisst: mitten im Loch.
	float offen = 1.0;
	// Das eigene Feld und die acht Nachbarn: Ein Loch kann ueber den Rand seines Feldes hinausragen.
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 nachbar = eigenes_feld + vec2(float(x), float(y));
			vec2 zufall = wuerfeln(nachbar);
			// Die Mitte des Lochs liegt irgendwo im Feld, nicht in einem Raster.
			vec2 mitte = nachbar + zufall;
			// Der Atem: von 0 (Loch weg) bis 1 (Loch voll), jedes Loch mit eigenem Tempo und eigenem Startpunkt.
			float atem = 0.5 + 0.5 * sin(TIME * tempo * (0.6 + zufall.x) + zufall.y * 6.28);
			float radius = loch_groesse * (0.3 + 0.7 * zufall.y) * atem;
			float abstand = length(punkt - mitte);
			// smoothstep macht den Lochrand weich: innen 0, aussen 1, dazwischen ein schmaler Uebergang.
			offen = min(offen, smoothstep(radius - 0.04, radius + 0.04, abstand));
		}
	}
	COLOR = vec4(farbe.rgb, farbe.a * offen) * knoten_farbe;
}
