"""Sauna-Begegnung in Level 2 (Mondbambus-Hain): Assets und Zwischensequenz über ComfyUI.

Ablauf (jeder Schritt überspringt vorhandene Dateien; --force erzeugt neu):
  assets   Sauna-Haus (Spielprop, später freigestellt), Saunaraum (Umgebungsreferenz), Raum mit Arman + Vitali
  panels   sechs Schlüsselframes 1344x768 (Qwen Image 2.1, mit Bildreferenzen)
  clips    je Schlüsselframe ein Clip (MiniMax H3 Bild-zu-Video), einzeln animiert, kein Storyboard-Morphing
  export   ffmpeg: Theora-.ogv + JPG-Standbilder nach assets/cutscenes/sauna/ und tools/sauna/manifest.json
Aufruf: python3 gen_sauna.py <schritt> [name ...]

Modelle, Knoten und Server stammen unverändert aus comfy.py (Qwen Image 2.1) und gen_intro.py (MiniMax H3).
Jeder erzeugte API-Graph landet samt Prompt, Seed und Referenzen unter tools/sauna/workflows/, damit sich alles
reproduzieren lässt (Graph per ComfyUI-API /prompt abschicken oder diese Datei erneut ausführen).
Vitali bleibt anonym: Es gibt kein Gesichts-Referenzbild von ihm, sein Gesicht liegt immer unter dem grauen Filzhut.
Morilla trägt in Level 2 noch den weißen Gürtel (Gürtelstufe des Spielstands); die Magenta-Schlüsselfarbe der
Referenz wird im Prompt zu Weiß umgedeutet.
"""
import json
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

from comfy import NEGATIVE, SERVER, _post, build, generate, upload
from gen_assets import ISO, MORILLA
from gen_intro import FRAMES, H, W, video_graph

TOOLS = Path(__file__).parent
RAW = TOOLS / "raw"
REF = RAW / "ref"
OUT = RAW / "sauna"
DOC = TOOLS / "sauna"
GAME = TOOLS.parent / "assets" / "cutscenes" / "sauna"

ARMAN_SHEET = REF / "arman_ref.png"
ARMAN_FACE = REF / "arman_face.png"
OCTOPUS = REF / "octopus_ref.png"
DUMMY = RAW / "dummy.png"
HOUSE = RAW / "sauna_house.png"
INTERIOR = OUT / "sauna_interior.png"
DUO = OUT / "sauna_duo.png"

LOOP_FRAMES = 107  # 17k+5 -> ~4,5 s; pro Loop-Clip wird per ffmpeg ein Ping-Pong (vor/zurück) daraus

STYLE = ("Hand-painted 2D anime game cinematic, rich painterly shading, clean dark outlines, moonlit deep blue and "
         "purple night with warm orange lantern glow, 16:9 widescreen, no text, no letters. ")
MORILLA_TXT = ("Use image 1 as the exact character reference: the muscular anthropomorphic gorilla Morilla with black fur, "
               "strong gorilla face, swept-up black hair tuft, sleeveless white Brazilian Jiu-Jitsu gi and a plain WHITE belt "
               "(ignore the magenta color of the belt in the reference), bare feet. ")
ARMAN_HAT = ("Arman: a lean athletic young man, short dark wavy voluminous hair under a brown felt sauna hat, thick dark "
             "eyebrows, short well-trimmed dark full beard, olive skin, bare chest, a white towel around his waist. ")
VITALI = ("Vitali: a broader, stronger man (muscular but not an exaggerated bodybuilder), bare chest, white towel around "
          "his waist, sitting cross-legged and perfectly still on the highest bench, wearing a large grey felt sauna hat "
          "that is pulled down over his whole head and completely covers his face: no eyes, no nose, no mouth, no beard "
          "visible, only the grey hat, his identity is secret. ")
ROOM = ("a traditional Japanese wooden sauna room: three clearly separated wooden bench tiers rising like steps, the "
        "lowest bench at the front, the second bench tier in the middle, the highest third tier at the back, a stone "
        "sauna heater full of dark stones on the right with a wooden bucket and ladle beside it, warm hanging lanterns, "
        "a lattice window with a purple night sky, soft white steam, warm orange light. ")

# (Name, Prompt, Referenzen, Breite, Höhe, Seed) – Referenzen werden bei der Ausführung geprüft.
ASSETS = [
    ("house", RAW / "sauna_house.png",
     "A traditional Japanese wooden sauna bathhouse, small and cozy, front view: dark timber walls, a gently curved "
     "tiled roof covered with moss, a wooden porch with two steps, a sliding shoji door in the exact center with warm "
     "orange light glowing through it, two glowing paper lattice windows, a paper lantern hanging on each side of the "
     "door, a wooden bucket beside the entrance, a small chimney pipe with soft white steam rising from the roof. " + ISO,
     1536, 1024, 9101, []),
    ("interior", INTERIOR, STYLE + "Empty " + ROOM + "Wide static side view into the room from the entrance, an open "
     "sliding door with a moonlit bamboo garden outside on the far left, nobody in the room, no people.",
     W, H, 9102, []),
    ("duo", DUO, STYLE + "Use image 1 as the exact reference for the room, its three bench tiers, stove, lamps and "
     "lighting; keep the room unchanged. Use image 2 as the exact reference for Arman's face. Add exactly two men: on the "
     "middle bench (second tier) sits " + ARMAN_HAT + "He faces left toward the door, one arm stretched out in a "
     "welcoming gesture, a friendly relaxed smile. Directly behind him and higher, on the third tier, sits " + VITALI +
     "The lowest bench and the door area on the left stay empty. Both men are full-bodied and only slightly smaller "
     "than the room.", W, H, 9103, [INTERIOR, ARMAN_FACE]),
]

PANELS = [
    ("1_anreise", [MORILLA, HOUSE], 9201,
     MORILLA_TXT + "Use image 2 as the exact reference for the sauna building. " + STYLE + "Side view: Morilla walks along "
     "a stone path through a moonlit bamboo grove toward the Japanese wooden sauna house, which stands at the right with "
     "warm lantern light glowing through its windows and steam from its chimney. A full moon in the dark blue sky, "
     "purple flowers, a stone lantern, a small pond reflecting the lights. Morilla is full-body on the left, mid stride.",
     "Slow tracking camera follows Morilla as he walks calmly toward the sauna house with heavy relaxed steps. Bamboo "
     "leaves sway slightly, steam rises from the chimney, lantern light flickers softly, water ripples gently. "
     "Peaceful atmosphere. Consistent character, no cuts.", False),
    ("2_sauna_innen", [MORILLA, DUO], 9212,
     MORILLA_TXT + "Use image 2 as the exact reference for the room and for the two men on the benches (their faces, "
     "hats, bodies and bench tiers must stay identical). " + STYLE + "Static wide side view into the sauna room: Morilla "
     "stands in the open doorway on the left, full-body, looking into the room. Arman on the middle bench tier gestures "
     "toward him with an open hand and a friendly smile; behind him on the highest tier sits the man in the grey felt hat "
     "that completely covers his face, resting directly on the top bench against the back wall, not floating.", 
     "Locked-off camera with only a very slow push-in. Steam drifts softly, lantern light flickers, Arman's open hand "
     "makes a small welcoming gesture, everyone breathes slowly. The man in the grey hat stays motionless. "
     "Faces, hats, hat colors and body proportions never change.", True),
    ("3_sauna_nahaufnahme", [MORILLA, DUO], 9203,
     MORILLA_TXT + "Use image 2 as the exact reference for the room and for the two men on the benches (faces, brown and "
     "grey hats, bodies stay identical). " + STYLE + "Over-the-shoulder shot: in the left foreground, large and slightly "
     "out of focus, the back of Morilla's head and shoulder; beyond him Arman sits on the middle bench tier with a brown "
     "felt hat, speaking with an open palm toward Morilla, and behind him on the highest tier the man with the grey felt "
     "hat covering his whole face sits cross-legged. Warm wooden sauna wall, steam.",
     "Slow subtle push-in. Arman's hand makes a calm explaining gesture, steam drifts, lantern light flickers, chests "
     "move with slow breathing. The man in the grey hat stays still. Faces, hats and clothes never change.", True),
    ("4_trainingsplatz", [MORILLA, DUMMY, HOUSE], 9204,
     MORILLA_TXT + "Use image 2 as the exact reference for the wooden training dummy and image 3 for the sauna building. "
     + STYLE + "Wide side view of a small moonlit training yard in the bamboo grove: a raised wooden training deck with "
     "the wooden Wing Chun training dummy, a stone lantern, a wooden fence, a pond with moon reflection, the glowing "
     "sauna house at the right edge. Morilla stands full-body on the stone path in the center-left, arms hanging, "
     "waiting and looking toward the sauna door.",
     "Slow static camera with a tiny drift. Morilla waits and breathes calmly, shifting his weight a little. Bamboo "
     "leaves sway, fireflies drift, lantern light flickers, steam from the sauna. Consistent character, no cuts.", False),
    ("5_arman_gespraech", [MORILLA, ARMAN_SHEET, ARMAN_FACE, OUT / "panel_4_trainingsplatz.png"], 9205,
     MORILLA_TXT + "Use image 2 and image 3 as the exact references for Arman: " + ARMAN_HAT.replace(
         "under a brown felt sauna hat", "uncovered, no hat").replace("bare chest, a white towel around his waist",
         "wearing his black Brazilian Jiu-Jitsu gi and black belt, bare feet") + "Use image 4 as the exact reference for the "
     "location. " + STYLE + "Medium shot at the training yard: Morilla at the left, large, listening seriously; Arman at "
     "the right in his black gi (no hat) speaks to him with open hands, calm and analytical. Wooden training dummy and "
     "stone lantern behind them, bamboo and full moon.",
     "Slow subtle push-in. Arman gestures calmly with his open hands while he talks, Morilla listens and breathes, "
     "bamboo leaves sway, lantern light flickers. Faces and clothes never change.", True),
    ("6_oktopus", [MORILLA, ARMAN_SHEET, OCTOPUS, OUT / "panel_4_trainingsplatz.png"], 9206,
     MORILLA_TXT + "Use image 2 as the exact reference for Arman in his black gi without a hat, image 3 for the giant "
     "ghostly octopus spirit (dark violet translucent body, purple smoke, glowing red eyes, glowing red sigil on its "
     "forehead) and image 4 for the location. " + STYLE + "Arman kneels in the center of the training yard in his black "
     "gi, eyes closed, both palms pressed together in front of his chest in a ritual seal; behind him the huge purple "
     "octopus spirit rises with its tentacles spread wide, red eyes glowing. Morilla stands at the left, watching "
     "amazed. Wooden training dummy, lantern and moon.",
     "Slow push-in toward Arman. The octopus spirit slowly rises and its smoky tentacles curl, purple smoke swirls, its "
     "red eyes glow brighter. Arman stays kneeling with his palms together, only breathing; Morilla watches. "
     "Characters stay consistent, no cuts.", False),
]


def dump(name: str, kind: str, graph: dict, meta: dict) -> None:
    """Speichert den API-Graph samt Prompt, Seed und Referenzpfaden unter tools/sauna/workflows/."""
    path = DOC / "workflows" / f"{name}.{kind}.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"server": SERVER, "meta": meta, "api_graph": graph}, indent=1, ensure_ascii=False))


def rel(p: Path) -> str:
    return str(p.relative_to(TOOLS.parent)) if p.is_relative_to(TOOLS.parent) else str(p)


def make_image(name: str, out: Path, prompt: str, w: int, h: int, seed: int, refs: list[Path], force: bool) -> None:
    if out.exists() and not force:
        return
    missing = [r for r in refs if not r.exists()]
    if missing:
        sys.exit(f"Referenz fehlt für {name}: {missing}")
    print("generating", name, flush=True)
    graph = build(prompt, w, h, seed, [r.name for r in refs], 25, NEGATIVE)
    dump(name, "image", graph, {"prompt": prompt, "seed": seed, "size": [w, h], "steps": 25,
                                 "refs": [rel(r) for r in refs], "output": rel(out)})
    generate(prompt, out, w, h, seed, refs, steps=25)
    print("ok", out, flush=True)


def animate(name: str, image: Path, motion: str, seed: int, out: Path, frames: int) -> None:
    graph = video_graph(upload(image), motion, seed, f"morilla_rumble/sauna_{name}", frames, False)
    dump(name, "clip", graph, {"motion_prompt": motion, "seed": seed, "frames": frames, "fps": 24, "size": [W, H],
                                "first_frame": rel(image), "output": rel(out)})
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
    with urllib.request.urlopen(f"{SERVER}/view?{q}") as r:
        out.write_bytes(r.read())


def export(force: bool) -> None:
    """mp4 -> Theora-.ogv (Loop-Clips als Ping-Pong), Standbild als JPG, Manifest für das Spiel."""
    GAME.mkdir(parents=True, exist_ok=True)
    shots = []
    for name, _refs, seed, _prompt, motion, loop in PANELS:
        mp4, panel = OUT / f"clip_{name}.mp4", OUT / f"panel_{name}.png"
        if not mp4.exists() or not panel.exists():
            print("skip (fehlt)", name)
            continue
        ogv, jpg = GAME / f"{name}.ogv", GAME / f"{name}.jpg"
        if force or not ogv.exists():
            vf = "[0:v]split[a][b];[b]reverse[r];[a][r]concat=n=2:v=1:a=0[v]" if loop else "[0:v]null[v]"
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(mp4), "-filter_complex", vf, "-map", "[v]",
                            "-an", "-c:v", "libtheora", "-q:v", "7", str(ogv)], check=True)
        if force or not jpg.exists():
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(panel), "-q:v", "3", str(jpg)], check=True)
        shots.append({"name": name, "video": f"res://assets/cutscenes/sauna/{name}.ogv",
                      "still": f"res://assets/cutscenes/sauna/{name}.jpg", "loop": loop, "seed": seed,
                      "refs": [rel(r) for r in _refs], "prompt": _prompt, "motion": motion})
    DOC.mkdir(parents=True, exist_ok=True)
    (DOC / "manifest.json").write_text(json.dumps({
        "style": STYLE, "size": [W, H], "fps": 24, "frames": {"once": FRAMES, "loop": LOOP_FRAMES},
        "image_model": "qwen_image_2.1_int8_convrot.safetensors (comfy.py)",
        "video_model": "minimax_h3_fl2va_pruned_int8_convrot.safetensors (gen_intro.py video_graph)",
        "shots": shots,
    }, indent=1, ensure_ascii=False))
    print("exported", len(shots), "shots")


if __name__ == "__main__":
    mode = sys.argv[1]
    only = set(a for a in sys.argv[2:] if not a.startswith("--"))
    force = "--force" in sys.argv
    OUT.mkdir(parents=True, exist_ok=True)
    if mode == "assets":
        for name, out, prompt, w, h, seed, refs in ASSETS:
            if not only or name in only:
                make_image(name, out, prompt, w, h, seed, refs, force)
    elif mode == "panels":
        for name, refs, seed, prompt, _motion, _loop in PANELS:
            if not only or name.split("_")[0] in only:
                make_image(name, OUT / f"panel_{name}.png", prompt, W, H, seed, refs, force)
    elif mode == "clips":
        for name, _refs, seed, _prompt, motion, loop in PANELS:
            out = OUT / f"clip_{name}.mp4"
            if (only and name.split("_")[0] not in only) or (out.exists() and not force):
                continue
            print("animating", name, flush=True)
            animate(name, OUT / f"panel_{name}.png", motion, seed, out, LOOP_FRAMES if loop else FRAMES)
            print("ok", out, flush=True)
    elif mode == "export":
        export(force)
    else:
        sys.exit(__doc__)
