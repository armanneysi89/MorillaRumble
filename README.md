# Morilla Rumble

Ein 2D-Jiu-Jitsu-Metroidvania, gebaut mit **Godot 4.7** (GDScript, GL Compatibility).
Du spielst Morilla, einen muskulösen Gorilla im Gi, der als Weißgurt startet und sich bis zum Schwarzgurt hocharbeitet.

![Hauptmenü](docs/screenshots/menu.png)

![Morilla Dojo](docs/screenshots/dojo.png)

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
| Sprechen    | E, Enter            | D-Pad hoch     |
| Pause       | Esc, P              | Start          |
| Musik an/aus| M                   | –              |

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
| `tools/`      | Asset-/Audio-Generierung und Build-Skripte     |
| `concept/`    | Konzeptbilder und Design-Dokument              |

## Screenshots neu erstellen

Screenshots entstehen direkt aus Godot (Viewport-Capture) und liegen in `docs/screenshots/`.
