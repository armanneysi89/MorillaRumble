"""Erzeugt die Kampf-Posen Morillas über ComfyUI: Kombo des leichten Angriffs, Block, Dash, Griff und Treffer.

Aufruf: python3 gen_combat.py [name ...]   Bereits vorhandene Dateien werden übersprungen, --force erzeugt neu.

Warum zwei Frames je Angriff: Der Attack-Zustand zeigt Frame 0 im Anlauf (Telegraph) und Frame 1 in der
aktiven Phase (Treffer). Mit nur einem Frame sahen beide Phasen identisch aus – der Gegner konnte den
Schlag nicht lesen. Jede Pose hier liefert deshalb ein klares Vorher und Nachher.
"""
import sys
from pathlib import Path

from comfy import generate
from gen_assets import M, MORILLA, SPRITE

RAW = Path(__file__).parent / "raw"

## (Name, Seed, Pose). _001 = Anlauf/Telegraph, _002 = aktive Phase/Treffer.
POSES = [
    # --- Leichte Kombo: Anlauf und Treffer getrennt ---
    ("morilla_jab_001", 900,
     "Jab wind-up: left fist pulled back slightly at the shoulder, right fist guarding the chin, weight on the back foot, "
     "coiled and ready, upright boxing stance."),
    ("morilla_jab_002", 901,
     "Jab strike: left arm fully extended straight forward with a clenched fist, right fist guarding the chin, front foot "
     "stepping lightly forward, upright boxing stance."),
    ("morilla_cross_001", 902,
     "Cross wind-up: right fist drawn back at the hip, shoulders turned away, left fist guarding the chin, rear foot loaded."),
    ("morilla_cross_002", 903,
     "Cross punch: right arm fully extended straight forward with a clenched fist, hips and shoulders rotated into the "
     "punch, left fist guarding the chin, rear foot pivoting."),
    ("morilla_hook_001", 904,
     "Hook wind-up: right elbow raised out to the side, fist drawn back at head height, torso twisted away, left fist "
     "guarding the chin."),
    ("morilla_hook_002", 905,
     "Wide hook punch: the right arm swings far out forward in a big horizontal arc with the elbow bent and the clenched "
     "fist at head height, shoulders and torso twisted into the swing, left fist guarding the chin, motion pose."),
    ("morilla_lowkick_001", 906,
     "Low kick wind-up: standing on the left leg, right knee lifted and chambered to the side, arms guarding the face, "
     "balanced and ready."),
    ("morilla_lowkick_002", 907,
     "Low kick: right leg swinging forward in a low roundhouse kick at knee height, body leaning slightly away, "
     "arms guarding the face, standing on the left leg."),
    ("morilla_kick_001", 908,
     "High kick wind-up: standing on the left leg, right knee raised high and chambered, torso leaning back, arms guarding, "
     "coiled for the strike."),
    ("morilla_kick_002", 909,
     "High roundhouse kick: right leg swinging up high forward at head height, body leaning back, arms guarding, "
     "standing on the left leg, powerful and dynamic."),

    # --- Verteidigung und Bewegung ---
    ("morilla_block_001", 910,
     "Blocking: both forearms crossed in front of the face and chest, low stable stance, braced."),
    ("morilla_block_002", 911,
     "Blocking under impact: both forearms crossed in front of the face, pushed back by a heavy blow, knees bent, "
     "shoulders hunched, straining against the force."),
    ("morilla_dash_001", 912,
     "Dashing forward at high speed, body leaning far forward almost horizontal, arms and legs stretched back."),
    ("morilla_grab_001", 913,
     "Grab: both arms reaching forward with open hands to seize an opponent, low wide stance."),

    # --- Treffer: Reaktion und Erholung ---
    ("morilla_hurt_001", 914,
     "Getting hit and recoiling backwards, eyes squeezed shut, wincing, torso leaning back, arms flung up."),
    ("morilla_hurt_002", 915,
     "Recovering from a hit: still leaning back but regaining balance, one foot braced behind, arms coming down, "
     "gritting his teeth, determined."),

    # --- Landung: weich und hart ---
    ("morilla_land_001", 916,
     "Landing softly from a small jump: knees slightly bent, arms out for balance, upright and relaxed, feet planted."),
    ("morilla_land_002", 917,
     "Landing hard from a high fall: deep crouch, one knee almost touching the ground, one fist planted on the floor, "
     "dust around the feet, absorbing the impact."),
]

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    force = "--force" in sys.argv
    only = set(args)
    for name, seed, pose in POSES:
        out = RAW / f"{name}.png"
        anim = name.rsplit("_", 1)[0]
        if (out.exists() and not force) or (only and name not in only and anim not in only):
            continue
        print("generating", name, flush=True)
        generate(M + pose + " " + SPRITE, out, 1024, 1024, seed, [MORILLA])
        print("ok", out, flush=True)
    print("done", flush=True)
