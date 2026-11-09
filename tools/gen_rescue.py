"""Rettungsszene im Mondbambus-Hain: Arman rettet Morilla vor dem Schattenkämpfer.

Die Kampf-Einstellung ist bewusst EIN langer, durchgehender Clip (217 Frames, ~9 s) und wird mit dem
H3-Fight-Flow-LoRA (H3_Fight_Flow_V1.safetensors, Trigger "Unarmed combat interaction.") erzeugt: Das LoRA
lernt Angriff -> Antwort -> Kontakt -> Folge -> Führungswechsel, statt nach jedem Schlag in die neutrale Pose
zurückzufallen. Genau das macht den Kampf flüssig.

Ablauf (jeder Schritt überspringt vorhandene Dateien; --force erzeugt neu):
  refs     Referenz des Schattenkämpfers (Qwen Image 2.1)
  charts   Größenmaßstab-Bild je Panel (nur die Figuren der Szene, verbindliche Körpergrößen)
  panels   sechs Schlüsselframes 1344x768 (Qwen Image 2.1, mit Bildreferenzen)
  clips    je Schlüsselframe ein Clip (MiniMax H3 Bild-zu-Video + Fight-Flow-LoRA)
  export   ffmpeg: Theora-.ogv + JPG-Standbilder nach assets/cutscenes/rescue/ und tools/rescue/manifest.json
Aufruf: python3 gen_rescue.py <schritt> [name ...] [--force]

VERBINDLICHE GRÖSSEN: Morilla 2,2 m, Arman 1,85 m, Schattenkämpfer 2,4 m (der größte der drei).
Morilla trägt in Level 2 noch den weißen Gürtel (die Magenta-Schlüsselfarbe der Referenz wird im Prompt zu Weiß
umgedeutet), Arman den schwarzen Gi mit schwarzem Gürtel.
"""
import json
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

from comfy import NEGATIVE, SERVER, _post, build, generate, upload
from gen_intro import FRAMES, H, W, video_graph

TOOLS = Path(__file__).parent
RAW = TOOLS / "raw"
REF = RAW / "ref"
OUT = RAW / "rescue"
DOC = TOOLS / "rescue"
GAME = TOOLS.parent / "assets" / "cutscenes" / "rescue"

MORILLA_REF = REF / "morilla_ref.png"
ARMAN_REF = REF / "arman_ref.png"
ARMAN_FACE = REF / "arman_face.png"
SHADOW_REF = REF / "shadow_ref.png"
OCTOPUS_REF = REF / "octopus_ref.png"
CHART_DIR = REF / "charts"

## Fight-Flow-LoRA: liegt in ~/ComfyUI/models/loras/ (HuggingFace-Spiegel des Civitai-Modells 2989579).
FIGHT_LORA = "H3_Fight_Flow_V1.safetensors"
## Getesteter Gewichtungswert des Autors für den ersten Durchlauf.
FIGHT_STRENGTH = 0.65
## Trigger des LoRAs: die Interaktionslogik der Szene, nicht die Ausrüstung.
FIGHT_TRIGGER = "Unarmed combat interaction. "

LOOP_FRAMES = 107   # 17k+5 -> ~4,5 s
FIGHT_FRAMES = 217  # 17k+5 -> ~9 s: eine durchgehende Kampf-Einstellung, kein Schnitt
## Lange Clips brauchen mehr VRAM als die Karte hat (217 Frames bei 1344x768 -> OOM, 1120x640 ebenfalls).
## Der Kampf-Clip läuft deshalb in 896x512 (gleiches 1,75-Format); das LoRA bleibt voll wirksam.
CLIP_SIZE = {"3_kampf": (896, 512)}

HEIGHTS = {"morilla": 2.2, "arman": 1.85, "shadow": 2.4}

STYLE = ("Hand-painted 2D anime game cinematic, rich painterly shading, clean dark outlines, moonlit deep blue and "
         "purple night with warm orange lantern glow, 16:9 widescreen, no text, no letters. ")
MORILLA_TXT = ("Use the character reference for Morilla: the muscular anthropomorphic gorilla with black fur, strong "
               "gorilla face, swept-up black hair tuft, sleeveless white Brazilian Jiu-Jitsu gi and a plain WHITE belt "
               "(ignore the magenta color of the belt in the reference), bare feet. ")
ARMAN_TXT = ("Use the character reference for Arman: a lean athletic young man, short dark wavy voluminous hair, thick "
             "dark eyebrows, short well-trimmed dark full beard, olive skin, wearing a black Brazilian Jiu-Jitsu gi with "
             "a black belt, bare feet. ")
SHADOW_TXT = ("Use the character reference for the Shadow Fighter: a tall imposing figure in tattered black robes with a "
              "deep hood that hides the face completely, only two glowing violet eyes visible in the darkness of the "
              "hood, dark grey clawed hands, wisps of purple shadow smoke trailing from the sleeves and the hem, no "
              "visible skin, no face. ")
SCALE_TXT = ("STRICT SIZE RELATION, identical in every shot, measured as a share of the image height: the Shadow Fighter "
             "is the tallest at 2.4 m and fills about 72% of the image height; Morilla is 2.2 m and fills about 66%; "
             "Arman is 1.85 m and fills about 56%. Never change these proportions. The reference image only defines "
             "these heights: it does NOT define who appears in the shot, so draw ONLY the characters named above and "
             "nobody else. ")
GROVE = ("a moonlit bamboo grove at night: tall bamboo stalks, a stone lantern with warm orange light, mossy stone "
         "slabs, drifting purple mist, a huge full moon behind the bamboo. ")

REFS = [
    ("ref/shadow_ref", SHADOW_REF,
     "Full body 2D game enemy design of " + SHADOW_TXT + "Standing in a low predatory fighting stance with clawed hands "
     "raised, side view facing left. Painted game illustration, not a photo. Isolated game asset, centered on a plain "
     "flat light grey background, nothing else, no ground, no shadow, no text.", 1024, 1024, 12001, []),
]

## Einzelreferenzen je Figur (für Panels ohne Größenmaßstab).
REFS_BY_KEY = {"morilla": MORILLA_REF, "arman": ARMAN_REF, "shadow": SHADOW_REF, "octopus": OCTOPUS_REF}


def build_chart(name: str, keys: list[str], force: bool) -> Path:
    """Größenmaßstab aus den Einzelreferenzen: nur die Figuren der Szene, auf ihre verbindliche Körpergröße skaliert."""
    out = CHART_DIR / f"{name}.png"
    if out.exists() and not force:
        return out
    from PIL import Image
    from process_assets import cut_out
    paths = {"morilla": MORILLA_REF, "arman": ARMAN_REF, "shadow": SHADOW_REF}
    imgs = []
    for k in keys:
        path = paths[k]
        if not path.exists():
            sys.exit(f"Referenz fehlt für Maßstab {name}: {path}")
        imgs.append((k, cut_out(Image.open(path).convert("RGB"))))
    px_per_m, pad = 300.0, 40
    heights = [int(HEIGHTS[k] * px_per_m) for k, _ in imgs]
    scaled = []
    for (k, im), h in zip(imgs, heights):
        bb = im.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox() or (0, 0, im.width, im.height)
        im = im.crop(bb)
        s = h / im.height
        scaled.append(im.resize((max(1, round(im.width * s)), h), Image.LANCZOS))
    total_w = sum(im.width for im in scaled) + pad * (len(scaled) + 1)
    total_h = max(heights) + pad * 2
    canvas = Image.new("RGBA", (total_w, total_h), (232, 232, 232, 255))
    x = pad
    for im, h in zip(scaled, heights):
        canvas.alpha_composite(im, (x, total_h - pad - h))
        x += im.width + pad
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out)
    print("chart", out, canvas.size, flush=True)
    return out


## (Name, Referenzen, Seed, Prompt, Bewegung, Frames, LoRA-Gewichtung, Chart?)
## `chart` = True gibt den Größenmaßstab mit (alle Figuren stehend). Bei knienden oder liegenden Posen kopiert das
## Modell die stehende Figur aus dem Maßstab zusätzlich -> dort nur Einzelreferenzen, Größe steht im Prompt.
## Die Bewegungsprompts beschreiben bei den Kampf-Einstellungen bewusst eine Kette
## (Angriff -> Block -> Kontakt -> Konter), damit H3 nicht nach jedem Schlag neu ansetzt.
PANELS = [
    ("1_zu_boden", ["morilla", "shadow"], 12201,
     MORILLA_TXT + SHADOW_TXT + SCALE_TXT + STYLE + "Wide side view in " + GROVE +
     "Morilla is down on one knee on the mossy stone slabs, beaten, one arm braced on the ground, breathing hard, "
     "his white gi torn at the shoulder. The Shadow Fighter stands over him, towering, one clawed hand raised for a "
     "finishing strike, purple smoke curling from the sleeve. Morilla's face is turned up toward the raised claw.",
     "Locked-off wide camera. Morilla stays down on one knee and only breathes, shoulders heaving. The Shadow Fighter "
     "slowly raises the clawed hand higher, purple smoke curls around the arm, mist drifts, the stone lantern flickers. "
     "No camera movement, no cuts.", FRAMES, 0.0, True),
    ("2_arman_einsatz", ["morilla", "arman", "shadow"], 12202,
     MORILLA_TXT + ARMAN_TXT + SHADOW_TXT + SCALE_TXT + STYLE + "Wide side view in " + GROVE +
     "EXACTLY THREE figures in the image and nobody else: one gorilla (Morilla), one man in a black gi (Arman) and "
     "one hooded Shadow Fighter. Arman has just dashed in from the left and stands between the Shadow Fighter and "
     "Morilla, his forearm raised in a hard block, body low and braced, a faint violet octopus-shaped aura flickering "
     "around his shoulders. The Shadow Fighter's clawed strike is caught on Arman's forearm, the impact throwing purple "
     "sparks. Morilla appears only once: he kneels on the ground behind Arman, looking up in shock. Arman wears a "
     "BLACK gi with a black belt, never a white gi.",
     FIGHT_TRIGGER + "Continuous fight interaction: Arman slides in and catches the descending clawed strike on his "
     "forearm, the impact pushes him back half a step and he immediately counters with a low kick that forces the "
     "Shadow Fighter to step back. The Shadow Fighter answers at once with a second claw swipe that Arman slips. "
     "Contact, recoil and the next action flow directly into each other, nobody returns to a neutral stance. "
     "Purple sparks and smoke on every contact, mist drifts, lantern light flickers. No cuts.", FRAMES, FIGHT_STRENGTH, False),
    ("3_kampf", ["arman", "shadow"], 12213,
     ARMAN_TXT + SHADOW_TXT + SCALE_TXT + STYLE + "Wide side view in " + GROVE +
     "EXACTLY TWO figures in the image and nobody else: one man in a black gi (Arman) and one hooded Shadow Fighter. "
     "No gorilla, no third person, no bystander, only one single hooded head. Arman and the Shadow Fighter are locked "
     "in a fast exchange in the center of the frame: Arman has just slipped inside a claw swipe and drives an elbow "
     "toward the hooded head, the Shadow Fighter twists away and its trailing sleeve whips around Arman's arm. Arman "
     "wears a BLACK gi with a black belt, never a white gi. Purple smoke trails every movement.",
     FIGHT_TRIGGER + "One single continuous unarmed exchange, no cuts, no reset: the Shadow Fighter swipes, Arman slips "
     "it and lands an elbow, the Shadow Fighter staggers and immediately whips a smoke-wrapped sleeve that Arman "
     "blocks, Arman answers with a knee and a throw attempt, the Shadow Fighter breaks free and comes back with a "
     "claw. Each action starts from the position and momentum the previous one left behind, initiative keeps "
     "switching, both fighters stay in contact. Fast, fluid, readable choreography, purple smoke and sparks on impact, "
     "mist drifting, lantern light flickering.", FIGHT_FRAMES, FIGHT_STRENGTH, False),
    ("4_oktopus", ["morilla", "arman", "shadow", "octopus"], 12204,
     MORILLA_TXT + ARMAN_TXT + SHADOW_TXT + SCALE_TXT + STYLE + "Wide side view in " + GROVE +
     "Use the last reference image for the octopus spirit: a huge translucent violet ghost octopus with eight long "
     "smoky tentacles, glowing red eyes and a glowing red sigil on its forehead. The spirit is the most important "
     "element of this shot and must be clearly visible and large. Arman stands with both palms pressed together in "
     "front of his chest, eyes closed, the huge octopus spirit rising behind him with its tentacles spread wide. Two "
     "smoky tentacles have wrapped around the Shadow Fighter's arms and chest, lifting it off the ground. Morilla "
     "kneels at the left, staring. Purple light floods the grove.",
     "Slow push-in. The octopus spirit's tentacles tighten around the Shadow Fighter and lift it higher, the Shadow "
     "Fighter struggles and its robes tear into purple smoke, the spirit's red eyes glow brighter, purple light "
     "pulses across the ground. Arman stays still with his palms together, only breathing. The giant violet octopus "
     "spirit stays clearly visible in the frame the whole time. No cuts.", LOOP_FRAMES, 0.0, False),
    ("5_schatten_loest_sich", ["arman", "shadow"], 12205,
     ARMAN_TXT + SHADOW_TXT + SCALE_TXT + STYLE + "Wide side view in " + GROVE +
     "The Shadow Fighter is dissolving: its body breaks apart into streams of purple smoke that are pulled upward and "
     "away, the hood collapsing, only the two glowing violet eyes still visible for a moment. Arman stands in front of "
     "it in a low guard, forearm raised, watching it go. Purple embers drift through the bamboo.",
     "Locked-off camera. The Shadow Fighter's body dissolves from the feet upward into purple smoke that streams away "
     "and fades, the glowing eyes dim last, purple embers drift through the air, Arman lowers his guard slowly and "
     "exhales. Mist drifts, lantern light flickers. No cuts.", FRAMES, 0.0, True),
    ("6_aufhelfen", ["morilla", "arman"], 12206,
     MORILLA_TXT + ARMAN_TXT + SCALE_TXT + STYLE + "Medium shot in " + GROVE +
     "Arman kneels beside Morilla and holds his forearm to pull him up, the other hand on Morilla's shoulder. Morilla "
     "is still on one knee, exhausted, his torn white gi dusty, looking at Arman with relief. The stone lantern glows "
     "warm behind them, purple mist still hangs low over the stones.",
     "Slow subtle push-in. Arman pulls Morilla up by the forearm, Morilla rises heavily and steadies himself, both "
     "breathe hard, Arman says something quietly. Purple mist drifts low, lantern light flickers, bamboo leaves sway. "
     "Faces and clothes never change, no cuts.", LOOP_FRAMES, 0.0, True),
]


def dump(name: str, kind: str, graph: dict, meta: dict) -> None:
    """Speichert den API-Graph samt Prompt, Seed und Referenzen unter tools/rescue/workflows/."""
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


def animate(name: str, image: Path, motion: str, seed: int, out: Path, frames: int, lora: float) -> None:
    w, h = CLIP_SIZE.get(name, (W, H))
    graph = video_graph(upload(image), motion, seed, f"morilla_rumble/rescue_{name}", frames, False,
                        lora=FIGHT_LORA if lora > 0 else None, lora_strength=lora or FIGHT_STRENGTH,
                        width=w, height=h)
    dump(name, "clip", graph, {"motion_prompt": motion, "seed": seed, "frames": frames, "fps": 24, "size": [w, h],
                               "first_frame": rel(image), "output": rel(out),
                               "lora": FIGHT_LORA if lora > 0 else None, "lora_strength": lora or None})
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
    """mp4 -> Theora-.ogv, Standbild als JPG, Manifest für das Spiel."""
    GAME.mkdir(parents=True, exist_ok=True)
    shots = []
    for name, _refs, seed, _prompt, motion, frames, lora, _chart in PANELS:
        mp4, panel = OUT / f"clip_{name}.mp4", OUT / f"panel_{name}.png"
        if not mp4.exists() or not panel.exists():
            print("skip (fehlt)", name)
            continue
        ogv, jpg = GAME / f"{name}.ogv", GAME / f"{name}.jpg"
        if force or not ogv.exists():
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(mp4), "-an",
                            "-c:v", "libtheora", "-q:v", "7", str(ogv)], check=True)
        if force or not jpg.exists():
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(panel), "-q:v", "3", str(jpg)], check=True)
        shots.append({"name": name, "video": f"res://assets/cutscenes/rescue/{name}.ogv",
                      "still": f"res://assets/cutscenes/rescue/{name}.jpg", "loop": frames == LOOP_FRAMES,
                      "frames": frames, "size": list(CLIP_SIZE.get(name, (W, H))), "seed": seed,
                      "refs": _refs, "prompt": _prompt, "motion": motion,
                      "lora": FIGHT_LORA if lora > 0 else None, "lora_strength": lora or None})
    DOC.mkdir(parents=True, exist_ok=True)
    (DOC / "manifest.json").write_text(json.dumps({
        "style": STYLE, "size": [W, H], "fps": 24,
        "frames": {"once": FRAMES, "loop": LOOP_FRAMES, "fight": FIGHT_FRAMES},
        "heights_m": HEIGHTS,
        "image_model": "qwen_image_2.1_int8_convrot.safetensors (comfy.py)",
        "video_model": "minimax_h3_fl2va_pruned_int8_convrot.safetensors (gen_intro.py video_graph)",
        "fight_lora": {"file": FIGHT_LORA, "strength": FIGHT_STRENGTH, "trigger": FIGHT_TRIGGER.strip(),
                       "source": "civitai.com/models/2989579 (H3 Fight Flow V1)"},
        "shots": shots,
    }, indent=1, ensure_ascii=False))
    print("exported", len(shots), "shots")


if __name__ == "__main__":
    mode = sys.argv[1]
    only = set(a for a in sys.argv[2:] if not a.startswith("--"))
    force = "--force" in sys.argv
    OUT.mkdir(parents=True, exist_ok=True)
    if mode == "refs":
        for name, out, prompt, w, h, seed, refs in REFS:
            if not only or name.split("/")[-1] in only:
                make_image(name, out, prompt, w, h, seed, refs, force)
    elif mode == "charts":
        for name, keys, _seed, _prompt, _motion, _frames, _lora, _chart in PANELS:
            if not only or name.split("_")[0] in only:
                build_chart(name, keys, force)
    elif mode == "panels":
        for name, keys, seed, prompt, _motion, _frames, _lora, chart in PANELS:
            if only and name.split("_")[0] not in only:
                continue
            refs = [build_chart(name, keys, force)] if chart else [REFS_BY_KEY[k] for k in keys]
            make_image(name, OUT / f"panel_{name}.png", prompt, W, H, seed, refs, force)
    elif mode == "clips":
        for name, _keys, seed, _prompt, motion, frames, lora, _chart in PANELS:
            out = OUT / f"clip_{name}.mp4"
            if (only and name.split("_")[0] not in only) or (out.exists() and not force):
                continue
            print("animating", name, flush=True)
            animate(name, OUT / f"panel_{name}.png", motion, seed, out, frames, lora)
            print("ok", out, flush=True)
    elif mode == "export":
        export(force)
    else:
        sys.exit(__doc__)
