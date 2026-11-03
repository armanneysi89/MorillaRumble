"""Erzeugt die Roh-Assets für Level 2 (Mondbambus-Hain, Coach Arman, Oktopus-Geist) und das neue Hauptmenü über ComfyUI.

Bereits vorhandene Dateien werden übersprungen. Aufruf: python3 gen_level2.py [name ...]
Coach Armans Gesicht stammt aus ref/arman_face.png (Ausschnitt aus dem Charakter-Sheet); alle Posen hängen an ref/arman_ref.
"""
import sys
from pathlib import Path

from comfy import NEGATIVE, generate
from gen_assets import BG, ISO, MORILLA, SPRITE

RAW = Path(__file__).parent / "raw"
REF = RAW / "ref"
ARMAN_FACE = REF / "arman_face.png"
ARMAN_FACE34 = REF / "arman_face34.png"
ARMAN = REF / "arman_ref.png"
OCTOPUS = REF / "octopus_ref.png"
RIVAL = REF / "rival_ref.png"
MO_PORTRAIT = RAW / "mo_portrait.png"

NEGATIVE_LOGO = "blurry, lowres, deformed, extra letters, misspelled, photo, 3d render, background scenery"

FACE = ("short dark wavy voluminous hair, thick dark eyebrows, a short well-trimmed dark full beard, olive skin, strong jaw and "
        "calm, focused, analytical eyes")
A = ("Use image 1 as the exact character reference and image 2 as the reference for the face: the same young Brazilian Jiu-Jitsu "
     "coach Arman with identical " + FACE + ", black Brazilian Jiu-Jitsu gi jacket and pants, black belt, bare feet, athletic "
     "lean build. Painted game illustration, not a photo. Side view facing left. ")
O = ("Use image 1 as the exact creature reference: the same giant ghostly octopus spirit with identical dark violet and indigo "
     "translucent body wreathed in purple smoke, glowing red eyes, glowing red circular sigil on its forehead, pale lavender "
     "tentacle suckers. Front view, floating. ")
RV = ("Use image 1 as the exact character reference: the same corrupted spirit rival with identical pale featureless mask, "
      "glowing orange eyes, dark teal-blue smoky skin, tattered white gi and bright blue belt. Side view facing left. ")

PORTRAIT_STYLE = ("Use image 1 only as a painting style reference (not for the face). Close-up portrait of the head and shoulders "
                  "of {who}, facing the viewer, {look}, black Brazilian Jiu-Jitsu gi collar, calm friendly expression. "
                  "Hand-painted 2D game character portrait, clean bold dark outlines, rich shading, centered on a plain flat "
                  "light grey background, nothing else, no text. ")

MENU = (
    "Use image 1 only as the character reference for the gorilla Morilla (black fur, strong gorilla face, swept-up black hair tuft). "
    "Wide cinematic 16:9 video game main menu key art, hand-painted 2D fantasy illustration with clean bold dark outlines, dark "
    "night palette of deep blue and purple with red accents. On the left third: the huge muscular gorilla Morilla in a low heroic "
    "angle, standing proudly on dark rocks, body turned three quarters to the right, serious determined look, wearing a white "
    "Brazilian Jiu-Jitsu gi with a round gorilla emblem patch on the chest and a plain white belt. A pink cherry blossom branch "
    "and a tattered red banner with a black gorilla emblem frame the left edge. Behind and to the right: a huge glowing full moon, "
    "misty dark mountains, a Japanese hilltop dojo temple with glowing warm orange windows and a round gorilla emblem on its "
    "facade, cascading waterfalls, red torii gates, a stone bridge with glowing lanterns, another red banner on the far right, "
    "drifting cherry petals. The center and lower center stay calm, dark and misty with empty space for a game title and menu. A "
    "cobblestone path along the bottom edge. Only the gorilla appears as a character, no other people, no text, no lettering."
)

OCTO_REF_PROMPT = (
    "Full 2D game creature design: a giant ghostly octopus spirit summon, floating, front view, symmetrical. Dark violet and indigo "
    "translucent body streaked with pale lavender veins, wreathed in swirling purple smoke wisps, fierce glowing red eyes, a "
    "glowing red circular sigil on its forehead, eight thick curling tentacles spread wide below it with pale lavender suckers and "
    "a few red glowing tentacle tips. " + SPRITE
)


def octo(prefix, seed0, phases):
    return [(f"octopus_{prefix}_{i:03d}", O + p + " " + SPRITE, 1024, 1024, seed0 + i, [OCTOPUS]) for i, p in enumerate(phases, 1)]


def rival(name, seed, pose, w=1024, h=1024):
    return (f"rival_{name}", RV + pose + " " + SPRITE, w, h, seed, [RIVAL])


def arman(name, seed, pose, w=1024, h=1024):
    return (f"arman_{name}", A + pose + " " + SPRITE, w, h, seed, [ARMAN, ARMAN_FACE])


JOBS = [
    # --- Coach Arman ---
    ("ref/arman_ref",
     "Use image 1 as the exact reference for the face of Coach Arman: " + FACE + ". Full body 2D game character design of Coach "
     "Arman, a young Brazilian Jiu-Jitsu coach, technical and analytical, athletic lean build, wearing a black Brazilian "
     "Jiu-Jitsu gi jacket and pants with a black belt, bare feet, standing upright and calm with hands relaxed in front of him, "
     "side view facing left. Painted game illustration, not a photo. " + SPRITE, 1024, 1024, 401, [ARMAN_FACE]),
    arman("idle_001", 411, "Standing calmly in a balanced stance, hands relaxed in front of the belt, composed focused expression."),
    arman("talk_001", 412, "Standing, one hand raised with an index finger up explaining a technique, mouth slightly open, focused."),
    arman("demo_001", 413, "Both hands held together in front of the chest forming a ritual hand seal, eyes closed in deep concentration, "
                           "faint purple spirit energy wisps swirling around his hands."),
    arman("demo_002", 414, "Both arms thrust forward and upward with open palms casting a spell, intense eyes, purple spirit energy "
                           "swirling around his arms and a few purple smoke wisps rising above him."),
    ("arman_portrait",
     "Use image 1 and image 2 as the exact reference for the face of Coach Arman. Close-up portrait of the head and shoulders of "
     "Coach Arman, facing the viewer, " + FACE + ", black Brazilian Jiu-Jitsu gi collar. Hand-painted 2D game character portrait, "
     "clean bold dark outlines, rich shading, not a photo, centered on a plain flat light grey background, nothing else, no text. ",
     1024, 1024, 415, [ARMAN_FACE, ARMAN_FACE34]),

    # --- Morilla beschwört ---
    ("morilla_summon_001", "Use image 1 as the exact character reference: the same muscular anthropomorphic gorilla Morilla with identical "
     "black fur, face, white Brazilian Jiu-Jitsu gi, flat bright magenta belt (pure magenta key color) and bare feet. Side view facing "
     "right. Summoning pose: standing wide, both hands pressed together in front of the chest, eyes closed, deep concentration, "
     "faint purple energy wisps around his hands. " + SPRITE, 1024, 1024, 421, [MORILLA]),
    ("morilla_summon_002", "Use image 1 as the exact character reference: the same muscular anthropomorphic gorilla Morilla with identical "
     "black fur, face, white Brazilian Jiu-Jitsu gi, flat bright magenta belt (pure magenta key color) and bare feet. Side view facing "
     "right. Casting pose: both arms thrust forward and upward with open palms, mouth open in a roar, purple energy swirling around "
     "his arms. " + SPRITE, 1024, 1024, 422, [MORILLA]),

    # --- Oktopus-Geist (Arman-Technik) ---
    ("ref/octopus_ref", OCTO_REF_PROMPT, 1024, 1024, 431, []),
    *octo("idle", 440, [
        "Hovering idle: body slightly raised, tentacles spread wide and relaxed, calm menacing glow.",
        "Hovering idle: body slightly lowered, tentacles curling gently inward, purple smoke drifting.",
        "Hovering idle: body centered, tentacles swaying outward, soft purple glow.",
    ]),
    *octo("materialize", 450, [
        "Materializing from nothing: only a faint swirl of translucent violet smoke wisps in the rough shape of curling tentacles, "
        "no solid body yet, two tiny red sparks where the eyes will be.",
        "Materializing: translucent half-formed octopus silhouette made of purple smoke, head and tentacles still wispy and fading "
        "at the edges, red glowing eyes appearing.",
        "Materializing: nearly solid octopus, slightly transparent, smoke still trailing off the tentacles, red sigil flickering.",
    ]),
    *octo("charge", 460, [
        "Charging an attack: tentacles pulled in tight and coiled back, body swelling, a red glow gathering around the head.",
        "Charging an attack at full power: tentacles coiled, crackling red energy lightning around the whole body, eyes blazing red.",
    ]),
    *octo("strike", 470, [
        "Tentacle strike: several tentacles whip violently outward to both sides, stretched long, with red speed trails and "
        "motion blur streaks.",
        "Tentacle strike: two huge tentacles lashing far out sideways with bright red slash trails, body leaning forward, "
        "other tentacles flared.",
    ]),
    *octo("blast", 480, [
        "Mystic ink blast: bright white-violet energy bursting from the center of the body, tentacles flung wide open, "
        "glowing shock rays.",
        "Spirit burst: a huge dark purple ink cloud exploding outward all around the octopus with red glints and violet "
        "smoke, tentacles flared.",
    ]),

    # --- Blauer Rivale (Gegner Level 2) ---
    ("ref/rival_ref",
     "Full body 2D game enemy design: a corrupted spirit fighter called Blue Belt Rival, a lean agile humanoid fighter with dark "
     "teal-blue smoky skin, a pale smooth featureless mask-face with two glowing orange eyes, wearing a tattered white martial "
     "arts gi and a bright blue belt, wispy blue shadow tendrils at wrists and ankles, bare feet, confident fast fighting "
     "stance, side view facing left. " + SPRITE, 1024, 1024, 491, []),
    rival("idle_001", 501, "Idle fighting stance, light on the feet, guard hands raised, slightly bouncing."),
    rival("walk_001", 502, "Walking forward fast, right foot stepping, guard hands up."),
    rival("walk_002", 503, "Walking forward fast, left foot stepping, guard hands up."),
    rival("attack_001", 504, "Attack wind-up: body coiled, right arm cocked far back, leaning back, clearly telegraphing a strike."),
    rival("attack_002", 505, "Fast lunging straight punch: right arm fully extended forward, body stretched forward."),
    rival("hurt_001", 506, "Getting hit and recoiling backwards, staggering, arms flung up."),
    rival("grabbed_001", 507, "Trapped in an armlock: bent forward in pain, one arm twisted behind and held tight, grimacing mask."),
    rival("death_001", 508, "Defeated: lying flat on the ground, dissolving into wisps of blue smoke, side view, full body "
                            "visible.", 1280, 768),

    # --- Umgebung: Mondbambus-Hain ---
    ("bg_bamboo",
     BG + " Wide panorama of a moonlit bamboo forest at night: dense tall bamboo stalks in layers, a huge pale full moon "
     "behind soft blue-purple mist, a far-away small mountain shrine, glowing stone lanterns, drifting fireflies, deep blue and "
     "teal-green palette with warm orange lantern accents, calm empty forest floor at the bottom.", 2048, 1024, 601, []),
    ("bamboo_stalks",
     "A tall dense cluster of dark teal-green bamboo stalks with leaf tufts, front view, very tall, fading in moonlit mist. "
     + ISO, 768, 1280, 602, []),
    ("bamboo_cluster",
     "A beautiful bamboo grove cluster: several thick tall bamboo stalks of different heights with lush leaves, ferns at the "
     "base, side view. " + ISO, 1280, 1280, 603, []),
    ("stone_lantern",
     "A traditional Japanese stone toro lantern with a glowing warm orange light inside and moss on the stone, front view. "
     + ISO, 768, 1024, 604, []),
    ("shrine",
     "A small mountain shrine for martial arts training: a dark red torii gate in front of a small wooden hall with a curved "
     "roof and glowing orange windows, stone steps, a round gorilla emblem on the roof, front view. " + ISO, 1280, 1280, 605, []),
    ("ground_moss",
     "Side view cross-section of a chunk of terrain for a 2D platformer: a flat level top of dark mossy forest earth with "
     "bamboo leaves and small ferns on the surface, below it a tall dark earth and roots foundation. The surface is only moss, grass, "
     "ferns and fallen leaves: no lantern, no objects, no buildings, no stones on top. " + ISO, 1024, 1280, 616, []),
    ("platform_bamboo",
     "Side view of a floating-looking bamboo platform: a horizontal row of thick bamboo logs lashed together with red rope, "
     "supported by two short bamboo brackets, straight and level, wide. " + ISO, 2048, 768, 607, []),

    # --- Hauptmenü ---
    *[(f"menu2_{v}", MENU, 1664, 928, seed, [MORILLA]) for v, seed in (("a", 701), ("b", 702), ("c", 703))],
    ("title_logo",
     "Video game title logo lettering on a pure solid black background: the two words MORILLA RUMBLE. The word MORILLA on the "
     "first line in huge white rough dry-brush italic letters with a thin dark outline, the word RUMBLE on the second line, "
     "slightly bigger, in bright blood-red rough brush-stroke italic letters with a white edge highlight, a red brush swoosh "
     "underline below, ink splatters, dynamic, aggressive, martial arts game logo. Nothing else in the image.",
     1536, 768, 711, [], NEGATIVE_LOGO),
    ("brush_black",
     "A single wide horizontal rough dry-brush ink stroke, solid pure black with jagged torn bristle ends, plain flat light grey "
     "background, nothing else, no text.", 1536, 384, 721, []),
    ("brush_red",
     "A single wide horizontal rough dry-brush paint stroke, solid bright blood red with jagged torn bristle ends, plain flat "
     "light grey background, nothing else, no text.", 1536, 384, 722, []),

    # --- Coach-Karten im Hauptmenü ---
    *[(f"{name}_portrait", PORTRAIT_STYLE.format(who=who, look=look), 1024, 1024, seed, [MO_PORTRAIT])
      for name, who, look, seed in (
          ("andre", "Coach Andre", "short dark hair, a short neatly groomed dark beard, dark eyes, strong athletic neck", 801),
          ("matthias", "Coach Matthias", "short light-brown hair, light short stubble, lean athletic face, friendly eyes", 802),
          ("vitali", "Coach Vitali", "short dark hair, a full dark beard, strong broad neck and jaw, direct calm eyes", 803),
          ("kevin", "Coach Kevin", "short blond tidy hair, clean-shaven with light stubble, youthful friendly face, a faint smile", 804),
      )],
]


if __name__ == "__main__":
    only = set(sys.argv[1:])
    for job in JOBS:
        name, prompt, w, h, seed, refs = job[:6]
        negative = job[6] if len(job) > 6 else NEGATIVE
        out = RAW / f"{name}.png"
        if out.exists() or (only and name not in only):
            continue
        if any(not r.exists() for r in refs):
            print("skip (reference missing)", name, flush=True)
            continue
        print("generating", name, flush=True)
        generate(prompt, out, w, h, seed, refs, negative=negative)
    print("done", flush=True)
