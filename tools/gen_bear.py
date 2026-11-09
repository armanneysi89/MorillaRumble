"""Erzeugt den sibirischen Bär-Geist für Morillas Suplex über ComfyUI.

Der Geist erscheint beim Wurf aus Morillas Körper und reißt beim Aufprall alle Gegner im Umkreis um.
Bereits vorhandene Dateien werden übersprungen. Aufruf: python3 gen_bear.py [name ...]

Ablauf:
  python3 gen_bear.py            # Referenz + alle Frames
  python3 process_assets.py bear # Freistellen, Leinwand, Skalierung -> assets/characters/summons/bear
  godot --headless --path . --import
"""
import sys
from pathlib import Path

from comfy import generate
from gen_assets import SPRITE

RAW = Path(__file__).parent / "raw"
REF = RAW / "ref"
BEAR_REF = REF / "bear_ref.png"

## Der Geist ist kein Tier, sondern ein Kampfgeist: bernsteinfarben glühende Augen, Rauch an den Rändern.
B = ("Use image 1 as the exact creature reference: the same giant ghostly Siberian brown bear spirit with identical "
     "massive shaggy dark brown fur, broad heavy shoulders, huge clawed paws, a scarred muzzle, glowing amber eyes and "
     "wisps of amber spirit smoke trailing off its fur. Side view facing right. ")

REF_PROMPT = (
    "Full 2D game creature design: a giant ghostly Siberian brown bear spirit summon, standing on all fours but with "
    "the chest raised, side view facing right. Massive shaggy dark brown fur with lighter muzzle and chest, broad heavy "
    "shoulders, huge clawed paws, a scarred muzzle, fierce glowing amber eyes, faint amber spirit smoke and embers "
    "trailing off the fur, slightly translucent at the edges. " + SPRITE
)

FRAMES = [
    ("bear_idle_001", "Standing heavy and calm, chest raised, head low and forward, amber eyes glowing, smoke drifting off the fur."),
    ("bear_idle_002", "Standing heavy, breathing in, chest swelling, shoulders rising slightly, smoke curling upward."),
    ("bear_idle_003", "Standing heavy, breathing out, head lowered a little, embers drifting off the shoulders."),
    ("bear_materialize_001", "Materializing from nothing: only a swirl of translucent amber smoke in the rough shape of a "
                            "huge bear, no solid body yet, two tiny amber sparks where the eyes will be."),
    ("bear_materialize_002", "Materializing: a half-formed translucent bear silhouette made of amber smoke, fur still wispy "
                            "and fading at the edges, glowing amber eyes appearing."),
    ("bear_materialize_003", "Materializing: an almost solid bear spirit, slightly transparent, amber smoke still trailing "
                            "off the fur, eyes blazing."),
    ("bear_slam_001", "Rear up and roar: front paws lifted high off the ground, mouth wide open in a roar, chest out, "
                      "amber energy bursting around the head and shoulders."),
    ("bear_slam_002", "Slamming both front paws down onto the ground: body pitched forward and low, both huge paws "
                      "striking the floor, a shockwave of amber light and dust bursting outward from the impact."),
]


def jobs():
    out = [("ref/bear_ref", REF_PROMPT, 1024, 1024, 12001, [])]
    for i, (name, pose) in enumerate(FRAMES, 1):
        out.append((name, B + pose + " " + SPRITE, 1024, 1024, 12010 + i, [BEAR_REF]))
    return out


def main() -> None:
    only = set(sys.argv[1:])
    for name, prompt, w, h, seed, refs in jobs():
        short = name.split("/")[-1]
        if only and short not in only and not any(short.startswith(o + "_") for o in only):
            continue
        dest = RAW / f"{name}.png"
        if dest.exists():
            continue
        missing = [r for r in refs if not r.exists()]
        if missing:
            sys.exit(f"Referenz fehlt für {name}: {missing}")
        print("generating", name, flush=True)
        generate(prompt, dest, w, h, seed, refs, steps=25)
        print("ok", dest, flush=True)


if __name__ == "__main__":
    main()
