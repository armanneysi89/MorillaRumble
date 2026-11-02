"""Erzeugt die Roh-Assets für Level 1 (Morilla Dojo) über ComfyUI.

Bereits vorhandene Dateien werden übersprungen. Aufruf: python3 gen_assets.py [name ...]
Referenzbilder (ref/) entstehen zuerst; alle Posen verwenden sie als Charakter-Vorlage.
"""
import sys
from pathlib import Path

from comfy import generate

RAW = Path(__file__).parent / "raw"
REF = RAW / "ref"
LOGO = REF / "morilla_logo.png"
MORILLA = REF / "morilla_ref.png"
RECRUIT = REF / "recruit_ref.png"
MO = REF / "mo_ref.png"

STYLE = ("Hand-painted 2D fantasy game art, dark atmospheric painterly style inspired by Hollow Knight, clean bold dark outlines, "
         "rich shading, strong silhouette.")
SPRITE = ("Single character, full body fully visible and not cropped, centered on a plain flat light grey background, nothing else "
          "in the image, no ground, no shadow, no text. " + STYLE)
ISO = ("Isolated game asset, centered on a plain flat light grey background, nothing else, no text. "
       "Hand-painted 2D Japanese-inspired fantasy art, deep blue and purple night palette with warm orange lantern light, "
       "clean dark outlines.")
BG = ("Hand-painted 2D fantasy platformer background art, atmospheric, deep blues and purples, soft moonlight, warm orange "
      "lantern glow, layered depth, highly detailed, no characters, no text.")

# Der Gürtel ist bewusst flach magenta (Schlüsselfarbe): Der Belt-Shader färbt ihn je nach Gürtelstufe um.
M = ("Use image 1 as the exact character reference: the same muscular anthropomorphic gorilla Morilla with identical black fur, "
     "face, white Brazilian Jiu-Jitsu gi jacket and pants, flat bright magenta belt (pure magenta key color) and bare feet. "
     "Side view facing right. ")
R = ("Use image 1 as the exact character reference: the same corrupted spirit trainee with identical pale featureless mask, "
     "glowing orange eyes, tattered white gi and white belt, dark violet smoky skin. Side view facing left. ")
C = ("Use image 1 as the exact character reference: the same old Brazilian Jiu-Jitsu master Coach Mo with identical short gray "
     "hair, gray-white beard, black gi and black belt. Side view facing left. ")

def cycle(prefix, seed0, phases):
    return [(f"{prefix}_{i:03d}", M + p + " " + SPRITE, 1024, 1024, seed0 + i, [MORILLA]) for i, p in enumerate(phases, 1)]


IDLE = cycle("morilla_idle", 200, [
    "Relaxed idle stance, knuckles lightly down, chest at neutral height, shoulders relaxed.",
    "Idle stance, starting to inhale, chest rising very slightly, shoulders lifting a tiny bit.",
    "Idle stance at the top of the breath, chest slightly raised, shoulders slightly raised, head slightly up.",
    "Idle stance, holding the breath, chest raised, a subtle weight shift to the front foot.",
    "Idle stance, exhaling, chest lowering, shoulders dropping slightly.",
    "Idle stance at the bottom of the breath, shoulders slightly lowered, knees slightly bent.",
])
WALK = cycle("morilla_walk", 220, [
    "Walking contact pose: right foot heel planted far forward, left foot behind on its toes, left arm forward, right arm back, body at normal height.",
    "Walking down pose: right foot flat on the ground, knee bending, body at its lowest point, weight shifting onto the right foot.",
    "Walking passing pose: weight on the right leg, left leg lifted and swinging forward under the body, arms passing each other.",
    "Walking up pose: right leg straight pushing up, left leg reaching forward, body at its highest point.",
    "Walking contact pose: left foot heel planted far forward, right foot behind on its toes, right arm forward, left arm back, body at normal height.",
    "Walking down pose: left foot flat on the ground, knee bending, body at its lowest point, weight shifting onto the left foot.",
    "Walking passing pose: weight on the left leg, right leg lifted and swinging forward under the body, arms passing each other.",
    "Walking up pose: left leg straight pushing up, right leg reaching forward, body at its highest point.",
])
RUN = cycle("morilla_run", 240, [
    "Running contact pose: right leg stretched far forward with the foot just landing, left leg pushed back, torso leaning forward, left arm forward, right arm back.",
    "Running down pose: right foot planted under the body, knee deeply bent, torso low and leaning forward, arms pumping.",
    "Running passing pose: right leg pushing off the ground, left knee driving forward, torso leaning forward.",
    "Running flight pose: both feet off the ground, left knee high and forward, right leg extended back, torso leaning forward, arms pumping.",
    "Running contact pose: left leg stretched far forward with the foot just landing, right leg pushed back, torso leaning forward, right arm forward, left arm back.",
    "Running down pose: left foot planted under the body, knee deeply bent, torso low and leaning forward, arms pumping.",
    "Running passing pose: left leg pushing off the ground, right knee driving forward, torso leaning forward.",
    "Running flight pose: both feet off the ground, right knee high and forward, left leg extended back, torso leaning forward, arms pumping.",
])

MENU_BG = (
    "Use image 1 only as the character reference for the gorilla Morilla (black fur, strong gorilla face, swept-up black hair tuft). "
    "Wide cinematic 16:9 video game main menu key art, hand-painted 2D fantasy illustration, dark night palette of deep blue and "
    "purple with red accents, clean bold dark outlines. On the left third of the image: the huge muscular gorilla Morilla seen from a "
    "low heroic angle, standing on dark rocks, body turned three quarters to the right, serious determined look at the viewer, wearing "
    "a white Brazilian Jiu-Jitsu gi with a round gorilla emblem patch on the chest and a plain white belt, fists lowered. Pink cherry "
    "blossom branches and a tattered red banner with a black gorilla emblem frame the left edge. In the background to the right: a "
    "huge full moon, misty dark mountains, a Japanese hilltop dojo temple with glowing warm orange windows, cascading waterfalls, red "
    "torii gates, a stone bridge with glowing lanterns, drifting cherry petals. The center and right-center of the image stays calm, "
    "dark and misty with empty space for a game title and menu. A cobblestone path along the bottom. Only the gorilla appears as a "
    "character, no other people, no text, no logo lettering."
)

JOBS = [
    # name, prompt, w, h, seed, refs
    # --- Referenzen ---
    ("ref/morilla_ref",
     "Use image 1 only as reference for the face and fur of the Morilla Sports gorilla logo. Full body 2D game character design of "
     "Morilla, a muscular athletic anthropomorphic gorilla, black fur with subtle blue-grey highlights, a swept-up tuft of black "
     "hair on the head, strong expressive gorilla face with a determined brow, wearing a white Brazilian Jiu-Jitsu gi (jacket and "
     "pants) with a flat bright magenta belt (pure magenta key color, no other pink or purple anywhere) tied at the waist, bare "
     "gorilla feet, standing in a relaxed ready stance, side view facing right. "
     + SPRITE, 1024, 1024, 7, [LOGO]),
    ("ref/recruit_ref",
     "Full body 2D game enemy design: a corrupted spirit trainee called White Belt Recruit, a lean humanoid fighter with dark violet "
     "smoky skin, a pale smooth featureless mask-face with two glowing orange eyes, wearing a tattered white martial arts gi and a "
     "white belt, wispy shadow tendrils at the wrists and ankles, bare feet, clumsy beginner fighting stance, side view facing "
     "left. " + SPRITE, 1024, 1024, 11, []),
    ("ref/mo_ref",
     "Full body 2D game character design of Coach Mo, an older Brazilian Jiu-Jitsu master, calm and authoritative, short gray hair, "
     "gray-white beard, solid athletic build, wearing a black Brazilian Jiu-Jitsu gi and a black belt, bare feet, standing upright "
     "with arms crossed, side view facing left. " + SPRITE, 1024, 1024, 13, []),

    # --- Morilla ---
    *IDLE,
    *WALK,
    *RUN,
    ("morilla_jump_001", M + "Jumping upwards, legs tucked under the body, both fists raised, powerful and agile. " + SPRITE, 1024, 1024, 29, [MORILLA]),
    ("morilla_fall_001", M + "Falling downwards through the air, arms spread out for balance, legs dangling, intense focused face. " + SPRITE, 1024, 1024, 30, [MORILLA]),
    ("morilla_light_attack_001", M + "Light attack wind-up: weight shifted back, right fist pulled back at the hip, left hand guarding the face. " + SPRITE, 1024, 1024, 31, [MORILLA]),
    ("morilla_light_attack_002", M + "Fast straight punch: right arm fully extended forward with a clenched fist, left hand guarding, leaning into the punch. " + SPRITE, 1024, 1024, 32, [MORILLA]),
    ("morilla_heavy_attack_001", M + "Heavy attack wind-up: deep crouch, entire body coiled, right arm cocked far back, powerful stance. " + SPRITE, 1024, 1024, 33, [MORILLA]),
    ("morilla_heavy_attack_002", M + "Powerful hook strike: wide step forward, right arm swinging forward at full extension, whole body rotated into the blow. " + SPRITE, 1024, 1024, 34, [MORILLA]),
    ("morilla_dash_001", M + "Dashing forward at high speed, body leaning far forward almost horizontal, arms and legs stretched back. " + SPRITE, 1024, 1024, 35, [MORILLA]),
    ("morilla_block_001", M + "Blocking: both forearms crossed in front of the face and chest, low stable stance, braced. " + SPRITE, 1024, 1024, 36, [MORILLA]),
    ("morilla_grab_001", M + "Grab: both arms reaching forward with open hands to seize an opponent, low wide stance. " + SPRITE, 1024, 1024, 37, [MORILLA]),
    ("morilla_kimura_001", M + "Jiu-Jitsu clinch: both hands gripping forward at wrist height as if holding an opponent's arm, crouched, focused. " + SPRITE, 1024, 1024, 38, [MORILLA]),
    ("morilla_kimura_002", M + "Kimura armlock: kneeling low, both hands clamped together twisting an unseen opponent's arm behind it, leaning forward with full strength. " + SPRITE, 1024, 1024, 39, [MORILLA]),
    ("morilla_kimura_003", M + "Releasing a hold: standing up from a kneeling position, hands opening, calm victorious posture. " + SPRITE, 1024, 1024, 40, [MORILLA]),
    ("morilla_hurt_001", M + "Getting hit and recoiling backwards, eyes squeezed shut, wincing, torso leaning back, arms flung up. " + SPRITE, 1024, 1024, 41, [MORILLA]),
    ("morilla_death_001", M + "Knocked out: falling backwards, losing balance, eyes closed, body arched, arms limp. " + SPRITE, 1024, 1024, 42, [MORILLA]),
    ("morilla_death_002", M + "Knocked out and lying flat on his back on the ground, completely limp, side view, full body visible. " + SPRITE, 1280, 768, 43, [MORILLA]),
    ("morilla_portrait",
     "Use image 1 as the exact character reference. Close-up portrait of the head and shoulders of the gorilla Morilla, facing the "
     "viewer, determined expression, black fur, white gi collar. " + SPRITE, 1024, 1024, 44, [MORILLA]),

    # --- White Belt Recruit ---
    ("recruit_idle_001", R + "Idle fighting stance, hunched, arms hanging forward. " + SPRITE, 1024, 1024, 51, [RECRUIT]),
    ("recruit_walk_001", R + "Walking forward, right foot stepping, arms swinging stiffly. " + SPRITE, 1024, 1024, 52, [RECRUIT]),
    ("recruit_walk_002", R + "Walking forward, left foot stepping, arms swinging stiffly. " + SPRITE, 1024, 1024, 53, [RECRUIT]),
    ("recruit_attack_001", R + "Attack wind-up: right arm pulled far back, leaning back, clearly telegraphing a strike. " + SPRITE, 1024, 1024, 54, [RECRUIT]),
    ("recruit_attack_002", R + "Clumsy lunging punch: right arm fully extended forward, body stretched forward. " + SPRITE, 1024, 1024, 55, [RECRUIT]),
    ("recruit_hurt_001", R + "Getting hit and recoiling backwards, staggering, arms flung up. " + SPRITE, 1024, 1024, 56, [RECRUIT]),
    ("recruit_grabbed_001", R + "Trapped in an armlock: bent forward in pain, one arm twisted behind and held tight, other hand tapping, grimacing mask. " + SPRITE, 1024, 1024, 57, [RECRUIT]),
    ("recruit_death_001", R + "Defeated: lying flat on the ground, dissolving into wisps of violet smoke, side view, full body visible. " + SPRITE, 1280, 768, 58, [RECRUIT]),

    # --- Coach Mo ---
    ("mo_idle_001", C + "Standing calmly, arms crossed over the chest, wise composed expression. " + SPRITE, 1024, 1024, 61, [MO]),
    ("mo_talk_001", C + "Standing, one hand raised explaining, mouth slightly open, friendly but authoritative. " + SPRITE, 1024, 1024, 62, [MO]),
    ("mo_portrait",
     "Use image 1 as the exact character reference. Close-up portrait of the head and shoulders of Coach Mo, facing the viewer, "
     "calm authoritative expression, short gray hair, gray-white beard, black gi collar. " + SPRITE, 1024, 1024, 63, [MO]),

    # --- Hauptmenü ---
    *[(f"menu_bg_{v}", MENU_BG, 1664, 928, seed, [MORILLA]) for v, seed in (("a", 301), ("b", 302), ("c", 303))],

    # --- Umgebung: Dojo ---
    ("bg_dojo",
     BG + " Wide panorama of the interior of a large Japanese-inspired dojo training hall at night: huge dark wooden beams and "
     "pillars, paper shoji screens glowing softly, moonlight falling through tall windows, hanging red paper lanterns, a hint of "
     "cherry blossoms visible through the open doors in the back, far depth, calm empty floor area at the bottom.",
     2048, 1024, 71, []),
    ("bg_garden",
     BG + " Wide panorama of a moonlit Japanese garden seen from a dojo veranda: a huge full moon, drifting cherry blossom petals, "
     "layered pine and cherry trees, a distant pagoda and misty mountains, deep blue and purple sky with soft pink blossoms.",
     2048, 1024, 72, []),
    ("pillar",
     "A tall dark lacquered wooden dojo pillar with a red cloth banner tied around it, front view, tall. " + ISO, 768, 1280, 73, []),
    ("lantern",
     "A hanging red Japanese paper lantern with warm glowing orange light and a black top and bottom cap, hanging from a short rope. " + ISO, 1024, 1024, 74, []),
    ("banner",
     "A tall hanging dark red cloth dojo banner with a stylized black gorilla silhouette emblem and no text, hanging from a wooden "
     "rod. " + ISO, 768, 1280, 75, []),
    ("cherry_tree",
     "A beautiful cherry blossom tree with a twisted dark trunk and a lush canopy of pink blossoms, side view. " + ISO, 1280, 1280, 76, []),
    ("weapon_rack",
     "A wooden martial arts training rack with wooden bokken swords and staffs standing in it, front view. " + ISO, 1024, 1024, 77, []),
    ("dummy",
     "A wooden martial arts training dummy: a thick wooden post with three short wooden arms and a lower leg peg, on a heavy wooden "
     "base, front view. " + ISO, 768, 1280, 78, []),
    ("gong",
     "A large bronze temple gong hanging in a dark wooden frame with a red rope, glowing softly, front view, checkpoint shrine. " + ISO, 1024, 1024, 79, []),
    ("gate",
     "A tall Japanese torii-style wooden gate in dark red and black, with a soft glowing white-blue light between the pillars, "
     "front view. " + ISO, 1280, 1280, 80, []),
    ("scroll",
     "A rolled ancient martial arts technique scroll with a red ribbon and gold ends, glowing softly, small collectible item. " + ISO, 1024, 1024, 81, []),
    ("ground_wood",
     "Side view cross-section of a chunk of terrain for a 2D platformer: a flat level top of dark polished wooden dojo floor planks "
     "with a thin red edge trim, below it a tall dark stone and timber foundation. " + ISO, 1024, 1280, 82, []),
    ("ground_stone",
     "Side view cross-section of a chunk of terrain for a 2D platformer: a flat level top of mossy grey stone slabs with small pink "
     "cherry petals, below it a tall dark rocky foundation. " + ISO, 1024, 1280, 83, []),
    ("platform_wood",
     "Side view of a floating-looking wooden dojo platform: a horizontal thick dark wooden beam shelf with red trim, supported by "
     "two short carved brackets, straight and level, wide. " + ISO, 2048, 768, 84, []),
]

if __name__ == "__main__":
    only = set(sys.argv[1:])
    for name, prompt, w, h, seed, refs in JOBS:
        out = RAW / f"{name}.png"
        if out.exists() or (only and name not in only):
            continue
        if any(not r.exists() for r in refs):
            print("skip (reference missing)", name, flush=True)
            continue
        print("generating", name, flush=True)
        generate(prompt, out, w, h, seed, refs)
    print("done", flush=True)
