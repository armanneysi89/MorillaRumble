"""Erzeugt die Kombo-Posen des leichten Angriffs (Jab, Cross, Hook, Lowkick, Kick) über ComfyUI.

Aufruf: python3 gen_combat.py [name ...]   Bereits vorhandene Dateien werden übersprungen.
"""
import sys
from pathlib import Path

from comfy import generate
from gen_assets import M, MORILLA, SPRITE

RAW = Path(__file__).parent / "raw"

POSES = [
    ("jab", "Jab: left arm fully extended straight forward with a clenched fist, right fist guarding the chin, front foot "
            "stepping lightly forward, upright boxing stance."),
    ("cross", "Cross punch: right arm fully extended straight forward with a clenched fist, hips and shoulders rotated into the "
              "punch, left fist guarding the chin, rear foot pivoting."),
    ("hook", "Wide hook punch: the right arm swings far out forward in a big horizontal arc with the elbow bent and the clenched "
             "fist at head height, shoulders and torso twisted into the swing, left fist guarding the chin, motion pose."),
    ("lowkick", "Low kick: right leg swinging forward in a low roundhouse kick at knee height, body leaning slightly away, "
                "arms guarding the face, standing on the left leg."),
    ("kick", "High roundhouse kick: right leg swinging up high forward at head height, body leaning back, arms guarding, "
             "standing on the left leg, powerful and dynamic."),
]

if __name__ == "__main__":
    only = set(sys.argv[1:])
    for i, (name, pose) in enumerate(POSES):
        out = RAW / f"morilla_{name}_001.png"
        if out.exists() or (only and name not in only):
            continue
        print("generating", name, flush=True)
        generate(M + pose + " " + SPRITE, out, 1024, 1024, 900 + i + (50 if name == "hook" else 0), [MORILLA])
    print("done", flush=True)
