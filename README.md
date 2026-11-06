# Morilla Rumble

Ein 2D-Jiu-Jitsu-Metroidvania, gebaut mit **Godot 4.7** (GDScript, GL Compatibility).
Du spielst Morilla, einen muskulösen Gorilla im Gi, der als Weißgurt startet und sich bis zum Schwarzgurt hocharbeitet.

![Hauptmenü](docs/screenshots/menu.png)

![Morilla Dojo](docs/screenshots/dojo.png)

![Mondbambus-Hain mit Oktopus-Geist](docs/screenshots/bamboo.png)

## Level

| Level | Inhalt |
|-------|--------|
| 1 – Morilla Dojo | Intro-Film mit Erzähler, Gespräch mit Mo, Bewegungs-Tutorial, Kimura-Lektion, Arena-Kampf |
| 2 – Mondbambus-Hain | Sauna-Begegnung mit Coach Arman (Zwischensequenz mit Erzählerstimme, mit Tab überspringbar), danach führt er den Oktopus-Geist vor und lehrt ihn Morilla; Gruppen aus Rekruten und blauen Rivalen, Bambus-Aufstieg zur Schriftrolle, Arena in zwei Wellen |
| 3 – Vitalis Steinbruch | Heller Bergsteinbruch über dem Hain: Begegnung mit dem riesenhaften Baby Mo und dem Gürtelthron von Coach Vitali (Zwischensequenz mit Erzählerstimme), Suplex-Lektion, markierte Bruchplatte, Boss-Arena des Eisenrückens |

Sammelobjekte: **Schriftrollen** erhöhen dauerhaft das maximale Leben um 1, **Heiltee** heilt sofort 2 Leben. Beides liegt einmalig im Level; im Mondbambus-Hain erreichst du die Schriftrolle über die Bambusstämme, im Steinbruch den Heiltee über den Plankensteg.

### Die Figuren in Level 3

Die Größenverhältnisse sind verbindlich und gelten in Sprites **und** Zwischensequenzen
(`tools/gen_quarry.py`, `HEIGHTS` / `SCALE_TXT`):

| Figur | Größe | Aussehen |
|-------|-------|----------|
| **Morilla** | 2,20 m | Schwarzer Gorilla, weißer Gi, weißer Gürtel |
| **Baby Mo** | 3,00 m | Riese, Vitalis Schüler: schwarzer Gi über schwarz-bordeauxfarbenem Rashguard mit dunkelroten Chevrons, **blauer** Gürtel |
| **Coach Vitali** | 1,90 m | Kräftiger Grappler, offener schwarzer Gi, **Schwarzgurt** mit rotem Rangfeld |

Morilla reicht Baby Mo nur bis zur Brust; Vitali ist der Kleinste. Baby Mo ist trotz seines Namens der größte
Mensch im Spiel – der Spitzname ist geblieben.

Der **Suplex** (Coach Vitalis Technik, Taste **F / G**) beginnt im Klinch und wirft auch große Gegner. Nach einem Fehlschlag (z. B. dem Ansturm des Eisenrückens) ist der Gegner benommen – das ist das Fenster für den Wurf. Mit dem Suplex zerbricht Morilla außerdem die markierte Bruchplatte im Steinbruch und öffnet den Weg zum Boss.

## Ton

Alle Soundeffekte entstehen synthetisch in `tools/gen_audio.py` (numpy/scipy, keine Fremdsamples). Jeder Effekt ist
mehrschichtig aufgebaut – Transient, modale Resonanzen als Klangkörper, Sub-Sweep, gefiltertes Rauschen und
Faltungshall – und läuft durch weiche Sättigung. Dadurch klingen Treffer nach Aufprall statt nach Signalgenerator.

Die Zwischensequenzen in Level 2 und 3 haben denselben **Erzähler** wie das Intro: eine tiefe, ruhige Männerstimme,
die MiniMax H3 zusammen mit dem Bild erzeugt (`tools/gen_narration.py`). Vertont sind nur die Einstellungen ohne
Dialog – läuft eine Dialogbox, schweigt der Erzähler. Die Stimme wird als eigene `.ogg` neben dem Clip abgelegt und
von der Bühne abgespielt; die Sequenz wartet auf ihr Ende, damit kein Satz abgeschnitten wird.

```bash
python3 tools/gen_narration.py clips            # Stimmen erzeugen (ComfyUI muss laufen)
python3 tools/gen_narration.py export sauna     # Tonspur als .ogg nach assets/cutscenes/sauna/
```

Der Oktopus-Geist (Taste **Q / R**, Gamepad: rechter Trigger) erscheint nach kurzer Konzentration, fesselt bis zu sechs Gegner gleichzeitig und setzt sie mit einer Tintenwelle für einige Sekunden außer Gefecht. Danach braucht er neun Sekunden Abklingzeit.

## Steuerung

| Aktion      | Tastatur            | Gamepad        |
|-------------|---------------------|----------------|
| Laufen      | A / D, Pfeiltasten  | D-Pad / Stick  |
| Springen    | Leertaste, W, ↑     | A              |
| Leichter Schlag | J, X            | X              |
| Schwerer Schlag | K, C            | Y              |
| Dash        | Shift, Z            | B              |
| Blocken     | L, V                | LB             |
| Griff       | F, G                | RB             |
| Oktopus-Geist | Q, R              | RT             |
| Sprechen    | E, Enter            | D-Pad hoch     |
| Pause       | Esc, P              | Start          |
| Musik an/aus| M                   | –              |

Der leichte Schlag ist eine Kombo: Wer innerhalb kurzer Zeit weiterdrückt, schlägt Jab, Cross, Hook, Lowkick und zum Abschluss einen Kick (doppelter Schaden, starker Rückstoß).

### Bewegungsgefühl

Die Steuerung ist auf Reaktion ausgelegt, nicht auf Trägheit:

| Mechanik | Verhalten |
|---|---|
| Coyote Time | 0,12 s nach Verlassen des Bodens springt die Figur noch |
| Sprung-Puffer | 0,14 s vor der Landung gedrückt zählt der Sprung |
| Variable Sprunghöhe | Loslassen kappt den Aufstieg, aber nie unter eine Mindesthöhe |
| Apex-Schweben | Am Scheitel ist die Gravitation kurz reduziert |
| Landung | Weiche und harte Landung haben eigene Frames; harte Landungen dämpfen die Steuerung kurz |
| Richtungswechsel | Die Figur dreht sich sichtbar, statt sofort umzuklappen |
| Dash | Unverwundbar nur im Fenster der ersten 0,11 s, nicht im ganzen Schritt |

Jeder Angriff zeigt im Anlauf einen anderen Frame als im Treffer – der Gegner kann den Schlag lesen.

## Starten

1. [Godot 4.7](https://godotengine.org/) installieren.
2. Projektordner öffnen (`project.godot`) und F5 drücken – oder per Kommandozeile:
   ```bash
   godot --path .
   ```

## Release-Builds

Fertige Builds (Linux, Windows, macOS, Web, Android) liegen in `builds/release/`.
Neu erzeugen:

```bash
tools/build_release.sh   # exportiert alle Plattformen
tools/package_release.sh # packt die Releases
```

Der Pfad zur Godot-Binary lässt sich über die Umgebungsvariable `GODOT` setzen.

## Projektstruktur

| Ordner        | Inhalt                                         |
|---------------|------------------------------------------------|
| `assets/`     | Grafiken, Musik und Soundeffekte               |
| `autoload/`   | Globale Systeme (Game, Progression, Sound, Savegame) |
| `scenes/`     | Spieler, Gegner, Trainer, Level, UI            |
| `scripts/`    | GDScript-Logik (u. a. Zustandsmaschine des Spielers) |
| `tools/`      | Asset-/Audio-Generierung und Build-Skripte (`gen_assets.py`, `gen_level2.py`, `gen_sauna.py`, `gen_quarry.py`, `gen_narration.py`, `process_assets.py`, `gen_audio.py`); `tools/sauna/` und `tools/quarry/` dokumentieren Workflows, Prompts und Seeds der Zwischensequenzen |
| `concept/`    | Konzeptbilder und Design-Dokument              |

## Tests

Prüfskripte laufen headless mit eigenem Spielstand (`XDG_DATA_HOME=/tmp/x`), damit der echte Spielstand unberührt bleibt:

```bash
XDG_DATA_HOME=/tmp/x godot --path . --script tools/level_chain_test.gd
XDG_DATA_HOME=/tmp/x godot --path . --script tools/level_content_test.gd
XDG_DATA_HOME=/tmp/x godot --path . --script tools/sprite_frames_test.gd
XDG_DATA_HOME=/tmp/x godot --path . --resolution 1280x720 --script tools/quarry_test.gd -- layout
XDG_DATA_HOME=/tmp/x godot --path . --resolution 1280x720 --script tools/quarry_test.gd -- flow
XDG_DATA_HOME=/tmp/x godot --path . --resolution 1280x720 --script tools/sauna_test.gd -- flow
```

`level_content_test.gd` prüft, dass jede Kletterstufe erreichbar ist, jedes Sammelobjekt an einer Plattform
hängt, jede Pickup-ID weltweit eindeutig ist und die Gegnerdichte spielbar bleibt. `sprite_frames_test.gd`
stellt sicher, dass jede Angriffsanimation Anlauf und Treffer in zwei unterscheidbaren Frames zeigt.

`quarry_test.gd` kennt die Modi `load`, `layout`, `flow`, `skip`, `slab`, `boss` und `old`; Screenshots landen in `/tmp/quarry_shots`.

## Screenshots neu erstellen

Screenshots entstehen direkt aus Godot (Viewport-Capture) und liegen in `docs/screenshots/`.
