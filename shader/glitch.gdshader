// Glitch wie beim Logo am Ende der Reels: Das Bild wird in waagerechte Streifen geschnitten.
// Jeder Streifen rutscht ein zufaelliges Stueck zur Seite, und einzelne Streifen fallen ganz weg.
// staerke 0 heisst: ganz normal. staerke 1 heisst: voll verrutscht und fast alles weg.
shader_type canvas_item;

// Wie stark der Glitch gerade ist, von 0 bis 1. Setzt das Skript in jedem Bild.
uniform float staerke = 0.0;
// In wie viele Streifen das Bild geschnitten wird, von oben nach unten.
uniform float streifen = 14.0;
// Wie weit ein Streifen hoechstens zur Seite rutscht, als Anteil der Bildbreite. 0.15 heisst: 15 Prozent.
uniform float versatz = 0.15;
// Eine Zahl, die das Skript in jedem Bild neu auswuerfelt. So sieht jedes Bild anders aus.
uniform float zufall = 0.0;

// Die Farbe, die das Bild von seinem Knoten mitbekommt (modulate). Wird im vertex-Teil gemerkt.
varying vec4 knoten_farbe;

// Macht aus einer Zahl eine scheinbar zufaellige Zahl zwischen 0 und 1. Gleiche Zahl, gleiches Ergebnis.
float wuerfeln(float zahl) {
	return fract(sin(zahl * 12.9898) * 43758.5453);
}

void vertex() {
	knoten_farbe = COLOR;
}

void fragment() {
	// In welchem Streifen dieser Bildpunkt liegt: 0 ganz oben, dann 1, 2 und so weiter.
	float zeile = floor(UV.y * streifen);
	// Wie weit dieser Streifen zur Seite rutscht: zwischen -versatz und +versatz, mal staerke.
	float verschiebung = (wuerfeln(zeile + zufall) * 2.0 - 1.0) * versatz * staerke;
	vec2 stelle = UV + vec2(verschiebung, 0.0);
	vec4 farbe = texture(TEXTURE, stelle);
	// Was ueber den Bildrand hinaus gerutscht ist, ist durchsichtig.
	if (stelle.x < 0.0 || stelle.x > 1.0) {
		farbe.a = 0.0;
	}
	// Je groesser staerke, desto mehr Streifen fallen ganz weg.
	if (wuerfeln(zeile * 3.7 + zufall + 0.5) < staerke) {
		farbe.a = 0.0;
	}
	COLOR = farbe * knoten_farbe;
}
