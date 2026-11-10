"""Erzeugt die Roh-Assets für die Level-Erweiterung: neue Spielfiguren-Posen und neue Spielelemente.

Bereits vorhandene Dateien werden übersprungen. Aufruf: python3 gen_extras.py [name ...]
Die Figuren-Posen hängen an ref/morilla_ref.png, die Elemente sind eigenständige Objekte.
"""
import sys
from pathlib import Path

from comfy import generate
from gen_assets import ISO, M, SPRITE

RAW = Path(__file__).parent / "raw"
MORILLA = RAW / "ref" / "morilla_ref.png"

# Neue Posen: Luftangriff, Ausweichrolle und Sieg. Sie schließen Lücken im Bewegungsbild,
# die bisher mit Frames aus anderen Animationen überbrückt wurden.
POSES = [
    ("morilla_air_attack_001",
     "Aerial attack wind-up in mid-air: knees tucked up under the body, right fist cocked far back and high, torso coiled, "
     "looking down at the target below, both feet off the ground.", 1024, 1024, 1101),
    ("morilla_air_attack_002",
     "Aerial downward punch: body diving forward and down, right fist thrust down and forward at full extension, left arm "
     "pulled back for balance, legs trailing behind, both feet off the ground.", 1024, 1024, 1102),
    ("morilla_roll_001",
     "Dodge roll start: crouched very low, body tucked into a ball, arms wrapped around the knees, head down, beginning to "
     "roll forward.", 1024, 1024, 1103),
    ("morilla_roll_002",
     "Dodge roll mid-roll: fully tucked and rolling forward, back rounded, head tucked down, arms hugging the shins, "
     "momentum forward.", 1024, 1024, 1104),
    ("morilla_victory_001",
     "Victory pose: standing tall, both fists raised high above the head, chest out, head up, roaring triumphantly.", 1024, 1024, 1105),
    ("morilla_victory_002",
     "Victory pose: one fist raised high, the other hand resting on the hip, calm proud stance, looking forward.", 1024, 1024, 1106),
]

# Neue Spielelemente. Jedes Objekt ist eine eigene Mechanik, keine reine Dekoration.
PROPS = [
    ("crate",
     "A sturdy wooden training crate with dark iron corner brackets and a stamped red gorilla emblem on the front, slightly "
     "weathered planks, front view, a breakable destructible object. " + ISO, 768, 768, 1201),
    ("spring_pad",
     "A bamboo and iron spring launch pad: a low round platform with a thick coiled metal spring and a taut red cloth top, "
     "front view, a bounce pad that launches a fighter upward. " + ISO, 768, 768, 1202),
    ("spike_trap",
     "A row of sharp dark iron spikes rising from a low cracked stone base, front view, a floor hazard trap. " + ISO, 1024, 512, 1203),
    ("gem",
     "A floating faceted crystal gem glowing warm gold with a soft inner light and tiny sparkles around it, front view, a "
     "small valuable collectible item. " + ISO, 512, 512, 1204),
    ("wind_vent",
     "A stone vent in the ground blowing a visible upward column of pale blue-white air with dust and small leaves swirling "
     "in it, front view, an updraft hazard. " + ISO, 768, 1024, 1205),
]


def jobs():
    for name, pose, w, h, seed in POSES:
        yield (name, M + pose + " " + SPRITE, w, h, seed, [MORILLA])
    for name, prompt, w, h, seed in PROPS:
        yield (name, prompt, w, h, seed, [])


if __name__ == "__main__":
    only = set(sys.argv[1:])
    for name, prompt, w, h, seed, refs in jobs():
        out = RAW / f"{name}.png"
        if out.exists() or (only and name not in only):
            continue
        if any(not r.exists() for r in refs):
            print("skip (reference missing)", name, flush=True)
            continue
        print("generating", name, flush=True)
        generate(prompt, out, w, h, seed, refs)
    print("done", flush=True)
