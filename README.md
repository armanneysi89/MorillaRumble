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
| 2 – Mondbambus-Hain | Sauna-Begegnung mit Coach Arman (Zwischensequenz mit Text, mit Tab überspringbar), danach führt er den Oktopus-Geist vor und lehrt ihn Morilla; Gruppen aus Rekruten und blauen Rivalen, Bambus-Aufstieg zur Schriftrolle, Arena in zwei Wellen |
| 3 – Vitalis Steinbruch | Heller Bergsteinbruch über dem Hain: Begegnung mit dem riesenhaften Baby Mo und dem Gürtelthron von Coach Vitali (Zwischensequenz mit Text), Suplex-Lektion, markierte Bruchplatte, Boss-Arena des Eisenrückens |

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

Beim Wurf fährt ein **sibirischer Bär-Geist** aus Morillas Körper. Er steigt über ihm auf und schlägt genau in dem Moment zu, in dem der geworfene Gegner auf dem Boden aufkommt: Ein bernsteinfarbener Schockwellen-Schlag reißt bis zu fünf weitere Gegner im Umkreis um und betäubt sie. Der geworfene Gegner selbst wird dabei nicht doppelt getroffen; bei statischen Zielen (Bruchplatte) erscheint kein Geist.

## Ton

Alle Soundeffekte entstehen synthetisch in `tools/gen_audio.py` (numpy/scipy, keine Fremdsamples). Jeder Effekt ist
mehrschichtig aufgebaut – Transient, modale Resonanzen als Klangkörper, Sub-Sweep, gefiltertes Rauschen und
Faltungshall – und läuft durch weiche Sättigung. Dadurch klingen Treffer nach Aufprall statt nach Signalgenerator.

Gesprochen ist **nur der Intro-Film** nach „Neues Spiel“ (Erzählerstimme, `tools/gen_intro.py`). Alle
Zwischensequenzen im Level und alle Gespräche mit den Coaches erzählen mit **Text in der Dialogbox**; die Bühne
spielt dort nur Musik und Soundeffekte. Die Dialogzeilen stehen in den Levelskripten (`scripts/levels/*.gd`).
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
| `tools/`      | Asset-/Audio-Generierung und Build-Skripte (`gen_assets.py`, `gen_level2.py`, `gen_sauna.py`, `gen_quarry.py`, `gen_rescue.py`, `gen_music.py`, `process_assets.py`, `gen_audio.py`); `tools/sauna/`, `tools/quarry/` und `tools/rescue/` dokumentieren Workflows, Prompts und Seeds der Zwischensequenzen |
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
XDG_DATA_HOME=/tmp/x godot --path . --resolution 1280x720 --script tools/rescue_test.gd -- play
```

`level_content_test.gd` prüft, dass jede Kletterstufe erreichbar ist, jedes Sammelobjekt an einer Plattform
hängt, jede Pickup-ID weltweit eindeutig ist und die Gegnerdichte spielbar bleibt. `sprite_frames_test.gd`
stellt sicher, dass jede Angriffsanimation Anlauf und Treffer in zwei unterscheidbaren Frames zeigt.

`quarry_test.gd` kennt die Modi `load`, `layout`, `flow`, `skip`, `slab`, `boss` und `old`; Screenshots landen in `/tmp/quarry_shots`.
`rescue_test.gd` kennt die Modi `assets`, `play`, `skip` und `level`; Screenshots landen in `/tmp/rescue_shots`.

## Musik und Ton

Jede Szene hat einen eigenen Musiktitel unter `assets/audio/music/`:

| Titel    | Wo                                        |
|----------|-------------------------------------------|
| `menu`   | Hauptmenü                                 |
| `intro`  | Intro-Film nach „Neues Spiel“             |
| `dojo`   | Level 1 (Dojo)                            |
| `bamboo` | Level 2 (Mondbambus-Hain)                 |
| `quarry` | Level 3 (Bergsteinbruch)                  |
| `sauna`  | Sauna-Zwischensequenz                     |
| `rescue` | Rettungsszene nach der Bambus-Arena       |

`menu` und `dojo` stammen aus `tools/get_music.sh` (CC0, OpenGameArt), die übrigen erzeugt
`tools/gen_music.py` synthetisch (Pad, Bass, Melodie, Perkussion, Faltungshall). Die Stücke sind nahtlos
schleifend: Der Hall hinter dem Schleifenpunkt wird auf den Anfang gefaltet, die Naht wird kurz aus- und
eingefadet.

Zwischensequenzen setzen in `CutsceneSequence.music` ihren Titel; die Levelmusik wird gemerkt und nach der
Szene (auch beim Überspringen) wieder eingesetzt. Jede Einstellung kann zusätzlich einen Soundeffekt aus
`assets/audio/sfx/` auslösen (`SHOTS`-Eintrag `[Datei, loop, sfx]`).

## Screenshots neu erstellen

Screenshots entstehen direkt aus Godot (Viewport-Capture) und liegen in `docs/screenshots/`.
