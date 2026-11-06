"""Erzählerstimme für die Zwischensequenzen (Sauna, Steinbruch) über MiniMax H3.

Wie im Intro (tools/gen_intro.py, Modus `voiced`) erzeugt H3 Bild und Ton gemeinsam: Ein Erzähler mit ruhiger,
tiefer Männerstimme spricht langsam auf Deutsch über die Einstellung, darunter leise Nachtatmosphäre, keine Musik.
Damit klingt die Stimme in allen Zwischensequenzen gleich.

Nur die Einstellungen OHNE Dialog bekommen eine Stimme. Läuft eine Dialogbox über der Einstellung, bleibt der
Erzähler still – sonst sprechen zwei Stimmen gleichzeitig.

Ablauf (vorhandene Dateien werden übersprungen, --force erzeugt neu):
  clips    voiced Clip je Einstellung -> tools/raw/<szene>/clip_<name>_voiced.mp4
  export   ffmpeg: Tonspur als Vorbis-.ogg -> assets/cutscenes/<szene>/<name>.ogg + tools/<szene>/narration.json
Aufruf: python3 gen_narration.py clips|export [sauna|vitali] [name ...]

Die Standbilder (panel_<name>.png) stammen aus gen_sauna.py bzw. gen_quarry.py; die Einstellungsnamen sind dort
identisch, damit Bild, Clip und Stimme zusammengehören.
"""
import json
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

from comfy import SERVER, _post, upload
from gen_intro import VOICED_FRAMES, video_graph

TOOLS = Path(__file__).parent
RAW = TOOLS / "raw"
GAME = TOOLS.parent / "assets" / "cutscenes"

## Erzähler wie im Intro: tiefe, ruhige, warme männliche Erzählstimme, langsam, deutsch.
VOICE = ("Audio: an off-screen narrator with a deep, calm, warm male storytelling voice speaks slowly in German: \"{text}\" "
         "Soft ambient night sounds in the background, no music.")

## Je Szene: (Einstellung, Seed, Erzählertext, Bewegung). Die Bewegung stammt aus gen_sauna.py / gen_quarry.py,
## damit der Clip weiterhin animiert ist und nicht nur aus einem Standbild mit Ton besteht.
SCENES = {
    "sauna": {
        "dir": RAW / "sauna",
        "prefix": "morilla_rumble/sauna_voice",
        "lines": [
            ("1_anreise", 9301,
             "Der Pfad führt Morilla tief in den Mondbambus-Hain. Vor ihm liegt die Sauna.",
             "Slow tracking camera follows Morilla as he walks calmly toward the sauna house with heavy relaxed steps. "
             "Bamboo leaves sway slightly, steam rises from the chimney, lantern light flickers softly, water ripples "
             "gently. Peaceful atmosphere. Consistent character, no cuts."),
            ("4_trainingsplatz", 9304,
             "Im Hof wartet Morilla. Der Coach hat ihn hierher bestellt.",
             "Slow static camera with a tiny drift. Morilla waits and breathes calmly, shifting his weight a little. "
             "Bamboo leaves sway, fireflies drift, lantern light flickers, steam from the sauna. Consistent character, "
             "no cuts."),
            ("6_oktopus", 9306,
             "Arman kniet nieder und ruft den Geist des Oktopus.",
             "Slow push-in toward Arman. The octopus spirit slowly rises and its smoky tentacles curl, purple smoke "
             "swirls, its red eyes glow brighter. Arman stays kneeling with his palms together, only breathing; Morilla "
             "watches. Characters stay consistent, no cuts."),
        ],
    },
    "vitali": {
        "dir": RAW / "quarry",
        "prefix": "morilla_rumble_vitali_voice",
        "lines": [
            ("1_vorhof", 9401,
             "Der Steinbruch. Zwischen den Bögen wartet ein Riese namens Baby Mo.",
             "Slow tracking camera follows Morilla as he walks in and stops in front of Baby Mo. Baby Mo breathes calmly "
             "and turns his head slightly toward Morilla. Lantern light flickers, mist drifts. Both characters keep their "
             "exact size relation, no cuts."),
            ("4_thron_enthuellung", 9404,
             "Auf dem Thron aus tausend Gürteln sitzt Coach Vitali.",
             "Slow dramatic push-in toward the throne. Vitali sits perfectly still and only breathes, Baby Mo lowers his "
             "pointing arm, Morilla looks up, lantern light flickers, mist drifts. Faces, clothes, the throne and the size "
             "relation never change."),
            ("6_vor_dem_thron", 9406,
             "Vitali erhebt sich. Die Lektion beginnt.",
             "Slow static camera with a tiny drift. Morilla stands and breathes, Vitali sits still and only breathes, "
             "lantern light flickers, mist drifts. Consistent characters and sizes, no cuts."),
        ],
    },
}


def clip_path(scene: str, name: str) -> Path:
    return SCENES[scene]["dir"] / f"clip_{name}_voiced.mp4"


def panel_path(scene: str, name: str) -> Path:
    return SCENES[scene]["dir"] / f"panel_{name}.png"


def animate(scene: str, name: str, seed: int, text: str, motion: str) -> Path:
    """Erzeugt den voiced Clip: Standbild als erstes Bild, Bewegung + Erzählertext als Prompt, H3 liefert Bild und Ton."""
    image = upload(panel_path(scene, name))
    prompt = motion + " " + VOICE.format(text=text)
    graph = video_graph(image, prompt, seed, f"{SCENES[scene]['prefix']}_{name}", VOICED_FRAMES, True)
    pid = _post("/prompt", json.dumps({"prompt": graph}).encode(), "application/json")["prompt_id"]
    while True:
        with urllib.request.urlopen(f"{SERVER}/history/{pid}") as r:
            hist = json.loads(r.read())
        if pid in hist:
            entry = hist[pid]
            if entry["status"].get("status_str") == "error":
                raise RuntimeError(json.dumps(entry["status"])[:3000])
            f = entry["outputs"]["save"]["gifs"][0]
            break
        time.sleep(5)
    q = urllib.parse.urlencode({"filename": f["filename"], "subfolder": f["subfolder"], "type": f["type"]})
    out = clip_path(scene, name)
    with urllib.request.urlopen(f"{SERVER}/view?{q}") as r:
        out.write_bytes(r.read())
    return out


def export(scene: str, force: bool) -> None:
    """Tonspur des voiced Clips als Vorbis-.ogg ablegen; das Spiel spielt sie über die Bühne ab."""
    target = GAME / scene
    target.mkdir(parents=True, exist_ok=True)
    entries = []
    for name, seed, text, _motion in SCENES[scene]["lines"]:
        mp4 = clip_path(scene, name)
        if not mp4.exists():
            print("skip (fehlt)", name)
            continue
        ogg = target / f"{name}.ogg"
        if force or not ogg.exists():
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(mp4), "-vn", "-ac", "1", "-ar", "44100",
                            "-c:a", "libvorbis", "-q:a", "5", str(ogg)], check=True)
        entries.append({"shot": name, "voice": f"res://assets/cutscenes/{scene}/{name}.ogg",
                        "text": text, "seed": seed, "source": str(mp4.relative_to(TOOLS.parent))})
        print("ok", ogg, flush=True)
    doc = TOOLS / scene
    doc.mkdir(parents=True, exist_ok=True)
    (doc / "narration.json").write_text(json.dumps({
        "voice_prompt": VOICE,
        "model": "minimax_h3_fl2va_pruned_int8_convrot.safetensors + minimax_h3_audio_vae_fp32.safetensors",
        "frames": VOICED_FRAMES, "fps": 24,
        "shots": entries,
    }, indent=1, ensure_ascii=False))
    print("exported", len(entries), "voices")


if __name__ == "__main__":
    mode = sys.argv[1]
    args = [a for a in sys.argv[2:] if not a.startswith("--")]
    force = "--force" in sys.argv
    scenes = [args[0]] if args and args[0] in SCENES else list(SCENES)
    only = set(args[1:]) if args and args[0] in SCENES else set(args)
    for scene in scenes:
        if mode == "clips":
            for name, seed, text, motion in SCENES[scene]["lines"]:
                if only and name.split("_")[0] not in only and name not in only:
                    continue
                out = clip_path(scene, name)
                if out.exists() and not force:
                    continue
                print("speaking", scene, name, flush=True)
                animate(scene, name, seed, text, motion)
                print("ok", out, flush=True)
        else:
            export(scene, force)
