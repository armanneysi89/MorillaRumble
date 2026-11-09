"""Vitali-Abschnitt in Level 3 (Bergsteinbruch, Baby Mo, Gürtelthron, Suplex, Eisenrücken) über ComfyUI.

Ablauf (jeder Schritt überspringt vorhandene Dateien; --force erzeugt neu):
  refs     Charakter-Referenzen (aus dem freigegebenen Szenenblatt) und die Größenmaßstäbe je Panel
  assets   Umgebung (Hintergrund, Böden, Plattformen, Treppen, Dekor) und der Gürtelthron
  chars    Baby Mo, Vitali, Eisenrücken und Morillas Suplex-Frames
  panels   sechs Schlüsselframes 1344x768 (Qwen Image 2.1, mit Bildreferenzen)
  clips    je Schlüsselframe ein Clip (MiniMax H3 Bild-zu-Video), einzeln animiert, kein Storyboard-Morphing
  export   ffmpeg: Theora-.ogv + JPG-Standbilder nach assets/cutscenes/vitali/ und tools/quarry/manifest.json
Aufruf: python3 gen_quarry.py <schritt> [name ...]

Modelle, Knoten und Server stammen unverändert aus comfy.py (Qwen Image 2.1) und gen_intro.py (MiniMax H3).
Jeder erzeugte API-Graph landet samt Prompt, Seed und Referenzen unter tools/quarry/workflows/, damit sich alles
reproduzieren lässt (Graph per ComfyUI-API /prompt abschicken oder diese Datei erneut ausführen).

VERBINDLICHE GRÖSSEN (HEIGHTS): Morilla 2,2 m, Baby Mo 3,0 m (der Riese, Morilla reicht ihm nur bis zur Brust),
Vitali 1,9 m (der kleinste). Diese Relation steht in jedem Panel-Prompt (SCALE_TXT) und wird zusätzlich als
Größenmaßstab-Bild mitgegeben (build_chart), damit sie in keiner Einstellung springt.

Vitali (verbindliche Referenz, aus dem Szenenblatt): kurze dunkle Haare, voller getrimmter dunkler Bart, kräftige
natürliche Gesichtszüge, kräftiger Grappler-Körperbau (kein übertriebener Bodybuilder), offener schwarzer Gi über
schwarzem Rashguard mit dunkelroten Chevrons, SCHWARZER Gürtel mit rotem Rangfeld. Sein grauer Saunahut liegt neben
dem Thron.
Baby Mo (verbindliche Referenz, aus dem Szenenblatt): Vitalis erwachsener Schüler und ein Riese (3,0 m), kurze dunkle
Locken, kurzer dunkler Bart, schwarzer Gi über schwarz-bordeauxfarbenem Rashguard mit dunkelroten Chevrons,
deutlich sichtbarer BLAUER Gürtel.
Morilla trägt in Level 3 noch den weißen Gürtel (Gürtelstufe des Spielstands); die Magenta-Schlüsselfarbe der Referenz
wird im Prompt zu Weiß umgedeutet.
"""
import json
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

from comfy import NEGATIVE, SERVER, _post, build, generate, upload
from gen_assets import ISO, MORILLA, SPRITE
from gen_intro import FRAMES, H, W, video_graph

TOOLS = Path(__file__).parent
RAW = TOOLS / "raw"
REF = RAW / "ref"
OUT = RAW / "quarry"
DOC = TOOLS / "quarry"
GAME = TOOLS.parent / "assets" / "cutscenes" / "vitali"

VITALI_PORTRAIT = RAW / "vitali_portrait.png"
VITALI_REF = REF / "vitali_ref.png"
BABY_MO_REF = REF / "baby_mo_ref.png"
IRONBACK_REF = REF / "ironback_ref.png"
## Größenmaßstab je Panel: aus den Einzelreferenzen zusammengesetzt, nur mit den Figuren, die in der Szene
## vorkommen. Ein gemeinsames Lineup-Bild würde fremde Figuren in jede Szene "schmuggeln".
CHART_DIR = REF / "charts"
## Körpergrößen in Metern – die einzige Quelle der Wahrheit für alle Prompts und Sprites.
HEIGHTS = {"morilla": 2.2, "baby_mo": 3.0, "vitali": 1.9}
## Vom Nutzer übergebenes Szenenblatt, in sechs Panels zerlegt (nur als Kompositions-Referenz).
SHEET_SRC = DOC / "refs" / "sheet.png"
SHEET = REF / "sheet"
THRONE = OUT / "belt_throne.png"
BG = OUT / "bg_quarry.png"

LOOP_FRAMES = 107  # 17k+5 -> ~4,5 s; pro Loop-Clip wird per ffmpeg ein Ping-Pong (vor/zurück) daraus

STYLE = ("Hand-painted 2D anime game cinematic, rich painterly shading, clean dark outlines, cold morning light in pale "
         "blue and grey with warm copper lantern accents, 16:9 widescreen, no text, no letters. ")
MORILLA_TXT = ("Use image 1 as the exact character reference: the muscular anthropomorphic gorilla Morilla with black fur, "
               "strong gorilla face, swept-up black hair tuft, sleeveless white Brazilian Jiu-Jitsu gi and a plain WHITE belt "
               "(ignore the magenta color of the belt in the reference), bare feet. ")
## Baby Mo ist ein RIESE: 3,0 m, also rund 1,4x so groß wie Morilla (2,2 m) und deutlich größer als Vitali (1,9 m).
## Diese Relation steht in JEDEM Prompt, damit er in keiner Einstellung schrumpft.
BABY_MO_TXT = ("Baby Mo: a very tall, huge adult student of Vitali, 3.0 metres tall, about 1.4 times the height of Morilla and "
               "clearly the tallest person in the scene, broad heavy shoulders, calm and friendly, short dark curly hair, short "
               "dark beard, wearing a black Brazilian Jiu-Jitsu gi over a black-and-bordeaux rashguard with dark red chevron "
               "stripes, a clearly visible BLUE belt, bare feet. ")
VITALI_TXT = ("Vitali: a strong broad-shouldered Brazilian Jiu-Jitsu coach, 1.9 metres tall, clearly shorter than Baby Mo and "
              "about the same height as Morilla, powerful grappler build (muscular but not an exaggerated bodybuilder), short "
              "dark hair with short sides and a slightly longer top, a full well-trimmed dark beard, strong natural facial "
              "features, wearing an open black Brazilian Jiu-Jitsu gi over a black rashguard with dark red chevron stripes, a "
              "BLACK belt with a red rank patch, bare feet. ")
IRONBACK_TXT = ("Ironback: a massive hulking boss fighter made of dark grey stone and iron bands, carrying a heavy stone "
                "training frame on his back, glowing orange cracks across his body, heavy slow movements. ")
## Größenverhältnis als eigene Zeile – wird an jeden Panel-Prompt gehängt.
## Größenrelation als konkrete Bildanteile: Qwen Image hält verbale Größenangaben schlecht ein, Prozentwerte der
## Bildhöhe sind eindeutig. Baby Mo 3,0 m, Morilla 2,2 m, Vitali 1,9 m.
SCALE_TXT = ("STRICT SIZE RELATION, identical in every shot, measured as a share of the image height: Baby Mo is the "
             "tallest figure at 3.0 m and fills about 78% of the image height; Morilla is 2.2 m and fills about 57%; "
             "Vitali is 1.9 m and fills about 50%. Morilla's head reaches only to Baby Mo's chest, Vitali is the shortest. "
             "Never change these proportions, never make Baby Mo small or the same size as Morilla. The reference image "
             "only defines these heights: it does NOT define who appears in the shot, so draw ONLY the characters named "
             "above and nobody else. ")
QUARRY = ("a vast abandoned mountain quarry with a Japanese-inspired training sanctuary: monumental stone arches, misty "
          "gorges, waterfalls, old wooden cranes with ropes, hanging training bags, wooden walkways and warm lanterns. ")

# (Name, Prompt, Referenzen, Breite, Höhe, Seed) – Referenzen werden bei der Ausführung geprüft.
# Die Gesichter stammen aus dem vom Nutzer übergebenen Szenenblatt (tools/quarry/refs/), damit Spiel und
# Zwischensequenzen dieselben Personen zeigen.
VITALI_FACE = SHEET / "vitali_face.png"
BABY_MO_FACE = SHEET / "baby_mo_face.png"

REFS = [
    ("ref/vitali_ref", VITALI_REF,
     "Use image 1 as the exact reference for the face and the outfit of Vitali. Full body 2D game character design of "
     + VITALI_TXT + "Standing upright and calm with hands relaxed in front of him, side view facing left. Painted game "
     "illustration, not a photo. " + SPRITE, 1024, 1024, 11001, [VITALI_FACE]),
    ("ref/baby_mo_ref", BABY_MO_REF,
     "Use image 1 as the exact reference for the face and the outfit of Baby Mo. Full body 2D game character design of "
     + BABY_MO_TXT + "Standing upright and calm with hands relaxed in front of him, side view facing left. Painted game "
     "illustration, not a photo. " + SPRITE, 1024, 1024, 11002, [BABY_MO_FACE]),
    ("ref/ironback_ref", IRONBACK_REF,
     "Full body 2D game boss design of " + IRONBACK_TXT + "Standing in a heavy fighting stance, side view facing left. "
     "Painted game illustration, not a photo. " + SPRITE, 1024, 1024, 11003, []),
]

## Morillas Referenz trägt einen magenta Schlüsselgürtel (im Spiel per Shader umgefärbt). In den Cutscene-Bildern
## muss er weiß sein, sonst zeigt das Modell einen magenta Gürtel.
def whiten_belt(img):
    import numpy as np
    from PIL import Image
    a = np.asarray(img.convert("RGBA")).astype(np.int16)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    # Magenta/Pink: Rot und Blau deutlich über Grün, und Rot nicht zu dunkel.
    magenta = (r > 90) & (b > 70) & (g < 0.78 * np.minimum(r, b))
    if not magenta.any():
        return img
    a[..., 0][magenta] = 238
    a[..., 1][magenta] = 238
    a[..., 2][magenta] = 232
    return Image.fromarray(a.astype(np.uint8), "RGBA")


## Größenmaßstab: setzt die Einzelreferenzen auf eine gemeinsame Standlinie und skaliert sie auf ihre
## verbindliche Körpergröße. Nur so bleibt Baby Mo in jeder Einstellung der Riese und Vitali der kleinste.
def build_chart(name: str, keys: list[str], force: bool) -> Path:
    """Baut aus den Einzelreferenzen ein Größenbild (nur die genannten Figuren) und gibt den Pfad zurück."""
    out = CHART_DIR / f"{name}.png"
    if out.exists() and not force:
        return out
    from PIL import Image
    from process_assets import cut_out
    imgs = []
    for k in keys:
        path = {"morilla": MORILLA, "baby_mo": BABY_MO_REF, "vitali": VITALI_REF}[k]
        if not path.exists():
            sys.exit(f"Referenz fehlt für Maßstab {name}: {path}")
        # Hintergrund freistellen, sonst stehen die Figuren in grauen Kästen.
        im = cut_out(Image.open(path).convert("RGB"))
        if k == "morilla":
            im = whiten_belt(im)
        imgs.append((k, im))
    # Gemeinsame Standlinie: alle Figuren gleich hoch skaliert auf ihre Sollgröße in Pixeln.
    px_per_m = 300.0
    pad = 40
    heights = [int(HEIGHTS[k] * px_per_m) for k, _ in imgs]
    widths = []
    scaled = []
    for (k, im), h in zip(imgs, heights):
        bb = im.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox() or (0, 0, im.width, im.height)
        im = im.crop(bb)
        s = h / im.height
        im = im.resize((max(1, round(im.width * s)), h), Image.LANCZOS)
        scaled.append(im)
        widths.append(im.width)
    total_w = sum(widths) + pad * (len(scaled) + 1)
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


ASSETS = [
    ("bg_quarry", BG,
     "Hand-painted 2D fantasy platformer background art, atmospheric, cold pale morning light in blue and grey with warm "
     "copper lantern accents, layered depth, highly detailed, no characters, no text. Wide panorama of " + QUARRY +
     "Distant snow-capped mountains, a giant carved stone guardian statue in the rock face, terraced waterfalls, a calm empty "
     "quarry floor at the bottom.", 2048, 1024, 11101, []),
    ("ground_rock", OUT / "ground_rock.png",
     "Side view cross-section of a chunk of terrain for a 2D platformer: a flat level top of grey quarry rock with cracks, "
     "moss and small stones on the surface, below it a tall dark rock foundation. The surface is only rock, gravel and moss: "
     "no lantern, no objects, no buildings. " + ISO, 1024, 1280, 11102, []),
    ("platform_plank", OUT / "platform_plank.png",
     "Side view of a wooden quarry walkway platform: a horizontal row of thick weathered wooden planks lashed together with "
     "rope, supported by two short wooden brackets, straight and level, wide. " + ISO, 2048, 768, 11103, []),
    ("stairs_stone", OUT / "stairs_stone.png",
     "Side view of a short flight of weathered stone quarry steps, three broad steps rising to the right, moss in the cracks, "
     "straight and level, wide. " + ISO, 1536, 768, 11104, []),
    ("quarry_arch", OUT / "quarry_arch.png",
     "A monumental ruined stone arch of an ancient mountain quarry temple, tall and weathered with carved patterns and moss, "
     "front view. " + ISO, 1024, 1280, 11105, []),
    ("quarry_crane", OUT / "quarry_crane.png",
     "An old wooden quarry crane: a tall timber mast with a long jib arm, a large wooden wheel, thick ropes and a hanging "
     "stone block, side view. " + ISO, 1280, 1280, 11106, []),
    ("quarry_lantern", OUT / "quarry_lantern.png",
     "A weathered iron and wood quarry lantern hanging from a short bracket, glowing warm copper light inside, front view. "
     + ISO, 768, 1024, 11107, []),
    ("quarry_banner", OUT / "quarry_banner.png",
     "A long tattered dark red training banner with a pale mountain emblem, hanging from a wooden crossbar, weathered and "
     "frayed at the bottom, front view. " + ISO, 768, 1280, 11108, []),
    ("quarry_rope", OUT / "quarry_rope.png",
     "A vertical bundle of thick old ropes and a wooden pulley block hanging down, frayed ends, side view. " + ISO,
     768, 1280, 11109, []),
    ("quarry_waterfall", OUT / "quarry_waterfall.png",
     "A tall narrow waterfall cascading down a dark rock face into mist, seen from the side, with wet stone and moss. " + ISO,
     768, 1280, 11110, []),
    ("quarry_rock", OUT / "quarry_rock.png",
     "A cluster of large grey quarry boulders with moss and cracks, side view. " + ISO, 768, 768, 11111, []),
    ("quarry_pillar", OUT / "quarry_pillar.png",
     "A tall weathered stone pillar of an ancient mountain temple, carved with simple patterns and covered with moss, front "
     "view. " + ISO, 768, 1280, 11112, []),
    ("belt_throne", THRONE,
     "A gigantic throne built entirely from thousands of woven, knotted and layered Brazilian Jiu-Jitsu belts: the backrest, "
     "the seat, the armrests and the base are visibly made of densely braided and stacked fabric belts in white, blue, purple, "
     "brown and black with visible stitching, rank patches and frayed ends. Huge amounts of belts hang over the base and the "
     "steps. Front view, symmetrical, empty (nobody sitting on it), the throne must clearly read as a collection of real "
     "fighting belts. " + ISO, 1280, 1280, 11113, []),
    ("belt_throne_base", OUT / "belt_throne_base.png",
     "The stone base and steps of a giant throne, a broad stepped stone pedestal with a few frayed Jiu-Jitsu belts draped over "
     "the steps, front view, symmetrical, empty. " + ISO, 1280, 768, 11114, []),
    ("belt_throne_cascade", OUT / "belt_throne_cascade.png",
     "A dense cascade of many woven and knotted Brazilian Jiu-Jitsu belts in white, blue, purple, brown and black hanging down "
     "over the front of a throne, frayed ends and rank patches, front view, wide. " + ISO, 1536, 768, 11115, []),
    ("break_slab", OUT / "break_slab.png",
     "A marked cracked stone slab blocking a passage in a quarry: a large grey stone plate with a bright glowing crack pattern "
     "and a painted warning mark, front view. " + ISO, 768, 1024, 11116, []),
]


def _cycle(prefix, seed0, phases, ref, txt):
    return [(f"{prefix}_{i:03d}", txt + p + " " + SPRITE, 1024, 1024, seed0 + i, [ref]) for i, p in enumerate(phases, 1)]


## Greift für alle Einzelposen: exakt eine Figur, kein zweiter Kämpfer im Bild.
SOLO = ("EXACTLY ONE character in the image: only this single fighter, alone. No opponent, no second person, no "
        "training partner, no arms or legs of another fighter, no silhouette of another body. ") + SPRITE


CHARS = [
    # --- Baby Mo ---
    *_cycle("baby_mo_idle", 11201, [
        "Standing calm and relaxed, hands resting in front of the belt, friendly expression.",
        "Standing calm, breathing, shoulders slightly raised.",
        "Standing calm, breathing out, shoulders slightly lowered.",
    ], BABY_MO_REF, "Use image 1 as the exact character reference: the same giant student Baby Mo with identical "
       "short dark curly hair, short dark beard, black Brazilian Jiu-Jitsu gi over a black-and-bordeaux rashguard with "
       "dark red chevron stripes and a clearly visible BLUE belt, bare feet. Side view facing left. "),
    *_cycle("baby_mo_talk", 11211, [
        "Speaking calmly, one open hand raised in a friendly explaining gesture, mouth slightly open.",
        "Speaking, both hands open in front of the chest, friendly expression.",
    ], BABY_MO_REF, "Use image 1 as the exact character reference: the same giant student Baby Mo with identical "
       "short dark curly hair, short dark beard, black Brazilian Jiu-Jitsu gi over a black-and-bordeaux rashguard with "
       "dark red chevron stripes and a clearly visible BLUE belt, bare feet. Side view facing left. "),
    ("baby_mo_point_001", "Use image 1 as the exact character reference: the same giant student Baby Mo with identical "
     "short dark curly hair, short dark beard, black Brazilian Jiu-Jitsu gi over a black-and-bordeaux rashguard with dark "
     "red chevron stripes and a clearly visible BLUE belt, bare feet. Side view facing left. Pointing forward and slightly "
     "up with one outstretched arm, calm friendly expression. " + SPRITE, 1024, 1024, 11221, [BABY_MO_REF]),
    *_cycle("baby_mo_walk", 11231, [
        "Walking forward, right foot stepping, arms relaxed.",
        "Walking forward, left foot stepping, arms relaxed.",
    ], BABY_MO_REF, "Use image 1 as the exact character reference: the same giant student Baby Mo with identical "
       "short dark curly hair, short dark beard, black Brazilian Jiu-Jitsu gi over a black-and-bordeaux rashguard with "
       "dark red chevron stripes and a clearly visible BLUE belt, bare feet. Side view facing left. "),

    # --- Vitali ---
    *_cycle("vitali_idle", 11301, [
        "Standing calm and grounded, hands relaxed in front of the belt, direct calm expression.",
        "Standing calm, breathing, chest slightly raised.",
        "Standing calm, breathing out, weight shifting slightly.",
    ], VITALI_REF, "Use image 1 as the exact character reference: the same coach Vitali with identical short dark hair, full "
       "well-trimmed dark beard, strong natural features, open black Brazilian Jiu-Jitsu gi over a black rashguard with dark "
       "red chevron stripes, BLACK belt with a red rank patch, bare feet. Side view facing left. "),
    *_cycle("vitali_talk", 11311, [
        "Speaking with one open hand raised in a calm explaining gesture, mouth slightly open.",
        "Speaking, both hands open in front of the chest, calm direct expression.",
    ], VITALI_REF, "Use image 1 as the exact character reference: the same coach Vitali with identical short dark hair, full "
       "well-trimmed dark beard, strong natural features, open black Brazilian Jiu-Jitsu gi over a black rashguard with dark "
       "red chevron stripes, BLACK belt with a red rank patch, bare feet. Side view facing left. "),
    ("vitali_sit_001", "Use image 1 as the exact character reference: the same coach Vitali with identical short dark hair, full "
     "well-trimmed dark beard, strong natural features, open black Brazilian Jiu-Jitsu gi over a black rashguard with dark red "
     "chevron stripes, BLACK belt with a red rank patch, bare feet. Side view facing left. Sitting upright and calm on an "
     "INVISIBLE seat: thighs horizontal, knees bent, both feet flat on the ground, hands resting relaxed on his own thighs. "
     "NO chair, NO throne, NO seat, NO armrests, NO furniture of any kind in the image, only the man on a plain flat light grey "
     "background. " + SPRITE, 1024, 1024, 11321, [VITALI_REF]),
    ("vitali_stand_001", "Use image 1 as the exact character reference: the same coach Vitali with identical short dark hair, full "
     "well-trimmed dark beard, strong natural features, open black Brazilian Jiu-Jitsu gi over a black rashguard with dark "
     "red chevron stripes, BLACK belt with a red rank patch, bare feet. Side view facing left. Rising from a seated "
     "position to standing, one hand pushing off his own knee, mid motion. "
     + SPRITE, 1024, 1024, 11322, [VITALI_REF]),
    *_cycle("vitali_suplex", 11331, [
        "Suplex demonstration, clinch: low wide stance, both arms wrapped forward around an empty space at chest height "
        "as if gripping an opponent's torso, elbows tight, shoulders hunched.",
        "Suplex demonstration, lift: back arched, both arms raised high over his own shoulder as if hoisting a heavy "
        "opponent up, knees bent, straining with full strength.",
        "Suplex demonstration, throw: body bent far backwards in a deep arch, both arms sweeping down and behind over "
        "his own shoulder as if hurling a heavy opponent to the floor behind him, one leg braced forward, head thrown "
        "back, powerful follow-through.",
        "Suplex demonstration, impact: standing up out of the throw, arms opening, calm recovered posture.",
    ], VITALI_REF, "Use image 1 as the exact character reference: the same coach Vitali with identical short dark hair, full "
       "well-trimmed dark beard, strong natural features, open black Brazilian Jiu-Jitsu gi over a black rashguard with dark "
       "red chevron stripes, BLACK belt with a red rank patch, bare feet. Side view facing left. " + SOLO),

    # --- Eisenrücken ---
    *_cycle("ironback_idle", 11401, [
        "Standing heavy and still, the stone training frame on his back, glowing orange cracks, menacing.",
        "Standing heavy, breathing, the stone frame shifting slightly.",
    ], IRONBACK_REF, "Use image 1 as the exact creature reference: the same massive stone-and-iron boss Ironback with identical "
       "dark grey stone body, iron bands, heavy stone training frame on his back and glowing orange cracks. Side view facing "
       "left. "),
    *_cycle("ironback_walk", 11411, [
        "Walking forward heavily, right foot planted, the stone frame swaying.",
        "Walking forward heavily, left foot planted, the stone frame swaying.",
    ], IRONBACK_REF, "Use image 1 as the exact creature reference: the same massive stone-and-iron boss Ironback with identical "
       "dark grey stone body, iron bands, heavy stone training frame on his back and glowing orange cracks. Side view facing "
       "left. "),
    ("ironback_windup_001", "Use image 1 as the exact creature reference: the same massive stone-and-iron boss Ironback with "
     "identical dark grey stone body, iron bands, heavy stone training frame on his back and glowing orange cracks. Side view "
     "facing left. Heavy attack wind-up: coiled low, one huge stone fist cocked far back, glowing cracks flaring bright orange. "
     + SPRITE, 1024, 1024, 11421, [IRONBACK_REF]),
    ("ironback_attack_001", "Use image 1 as the exact creature reference: the same massive stone-and-iron boss Ironback with "
     "identical dark grey stone body, iron bands, heavy stone training frame on his back and glowing orange cracks. Side view "
     "facing left. Heavy attack: swinging the huge stone fist forward at full extension, body rotated into the blow. "
     + SPRITE, 1024, 1024, 11422, [IRONBACK_REF]),
    ("ironback_charge_001", "Use image 1 as the exact creature reference: the same massive stone-and-iron boss Ironback with "
     "identical dark grey stone body, iron bands, heavy stone training frame on his back and glowing orange cracks. Side view "
     "facing left. Charging forward at full speed, body leaning far forward, stone frame lowered like a battering ram, dust "
     "kicked up. " + SPRITE, 1024, 1024, 11423, [IRONBACK_REF]),
    ("ironback_stagger_001", "Use image 1 as the exact creature reference: the same massive stone-and-iron boss Ironback with "
     "identical dark grey stone body, iron bands, heavy stone training frame on his back and glowing orange cracks. Side view "
     "facing left. Staggering and off balance after a failed charge, head lowered, arms hanging, clearly dazed and open. "
     + SPRITE, 1024, 1024, 11424, [IRONBACK_REF]),
    ("ironback_thrown_001", "Use image 1 as the exact creature reference: the same massive stone-and-iron boss Ironback with "
     "identical dark grey stone body, iron bands, heavy stone training frame on his back and glowing orange cracks. Side view "
     "facing left. Being thrown backwards through the air, body arched, limbs flailing, the stone frame slipping. "
     + SPRITE, 1024, 1024, 11425, [IRONBACK_REF]),
    ("ironback_hurt_001", "Use image 1 as the exact creature reference: the same massive stone-and-iron boss Ironback with "
     "identical dark grey stone body, iron bands, heavy stone training frame on his back and glowing orange cracks. Side view "
     "facing left. Getting hit and recoiling backwards, staggering, cracks flickering. " + SPRITE, 1024, 1024, 11426, [IRONBACK_REF]),
    ("ironback_death_001", "Use image 1 as the exact creature reference: the same massive stone-and-iron boss Ironback with "
     "identical dark grey stone body, iron bands, heavy stone training frame on his back and glowing orange cracks. Side view "
     "facing left. Defeated: collapsing forward onto one knee, the stone frame breaking apart, cracks fading to dark. "
     + SPRITE, 1280, 768, 11427, [IRONBACK_REF]),

    # --- Morilla: Suplex-Frames ---
    # Der Gegner ist im Spiel eine eigene Figur und darf NICHT mitgezeichnet werden. Deshalb wird die Pose rein
    # körperlich beschrieben (Arme über der Schulter, Hohlkreuz, Stemmschritt) und eine zweite Person ausdrücklich
    # verboten: sonst malt das Modell einen Gegner mit, der im Spiel doppelt erscheint.
    *_cycle("morilla_suplex", 11501, [
        "Suplex clinch: low wide stance, both arms wrapped forward around an empty space at chest height as if gripping "
        "an opponent's torso, elbows tight, shoulders hunched, straining.",
        "Suplex lift: back arched, both arms raised high over his own shoulder as if hoisting a heavy opponent up, knees "
        "bent, chest open, straining with full strength, mouth closed in effort.",
        "Suplex throw: body bent far backwards in a deep arch, both arms sweeping down and behind over his own shoulder "
        "as if hurling a heavy opponent to the floor behind him, one leg braced forward, head thrown back, powerful "
        "follow-through.",
        "Suplex impact: standing up out of the throw, arms opening wide, chest out, calm recovered posture.",
    ], MORILLA, MORILLA_TXT + "Side view facing right. " + SOLO),

    # --- Porträts ---
    ("baby_mo_portrait",
     "Use image 1 as the exact reference for the face of Baby Mo. Close-up portrait of the head and shoulders of Baby Mo, "
     "facing the viewer, short dark curly hair, short dark beard, calm friendly expression, black Brazilian Jiu-Jitsu gi "
     "collar over a black-and-bordeaux rashguard. Hand-painted 2D game character portrait, clean bold dark outlines, rich "
     "shading, not a photo, centered on a plain flat light grey background, nothing else, no text. ", 1024, 1024, 11601, [BABY_MO_REF]),
    ("vitali_portrait",
     "Use image 1 as the exact reference for the face of Vitali. Close-up portrait of the head and shoulders of Vitali, facing "
     "the viewer, short dark hair with short sides and a slightly longer top, a full well-trimmed dark beard, strong natural "
     "facial features, direct calm eyes, black Brazilian Jiu-Jitsu gi collar. Hand-painted 2D game character portrait, clean "
     "bold dark outlines, rich shading, not a photo, centered on a plain flat light grey background, nothing else, no text. ",
     1024, 1024, 11602, [VITALI_REF]),
]

## Panels, bei denen das Storyboard-Bild zusätzliche Figuren beisteuert und deshalb nicht als Referenz dient.
## Das freigegebene Szenenblatt zeigt inzwischen in jedem Panel genau die richtige Besetzung, deshalb dient es
## überall als Kompositionsvorgabe.
NO_BOARD = set()

## Maßstab je Panel: nur die Figuren, die in der Szene vorkommen.
CHARTS = {
    "1_vorhof": ["morilla", "baby_mo"],
    "2_baby_mo": ["morilla", "baby_mo"],
    "3_thron_zeigen": ["morilla", "baby_mo"],
    "4_thron_enthuellung": ["morilla", "baby_mo", "vitali"],
    "5_vitali_hut": ["vitali"],
    "6_vor_dem_thron": ["morilla", "baby_mo", "vitali"],
}

## Besetzung je Panel: verhindert, dass der Maßstab Figuren in Szenen "schmuggelt", in denen sie nicht vorkommen.
CAST = {
    "1_vorhof": "ONLY Morilla and Baby Mo appear in this shot. Vitali is NOT in this shot.",
    "2_baby_mo": "ONLY Morilla and Baby Mo appear in this shot. Vitali is NOT in this shot.",
    "3_thron_zeigen": "ONLY Morilla and Baby Mo appear in this shot. The throne is empty. Vitali is NOT in this shot.",
    "4_thron_enthuellung": "Morilla, Baby Mo and Vitali appear in this shot, Vitali sitting on the throne.",
    "5_vitali_hut": "ONLY Vitali appears in this shot, sitting on the throne. Morilla and Baby Mo are NOT in this shot.",
    "6_vor_dem_thron": "Morilla, Baby Mo and Vitali appear in this shot, Vitali sitting on the throne.",
}

## Kompositionsvorgabe aus dem Szenenblatt: wird als letztes Referenzbild mitgegeben.
## Das Blatt ist die verbindliche Vorlage für Kamera, Bildausschnitt, Standlinie, Blickrichtungen und Posen.
COMPOSE = ("Image {n} is the approved storyboard panel for this exact shot. Reproduce its camera angle, framing, "
           "horizon, ground line, background composition and the body poses of the figures as closely as possible. "
           "The figures in it are rough placeholders: take their POSES and PLACEMENT from it, but take their faces, "
           "clothes, belt colours and exact sizes exclusively from image 1. Do not add anyone who is not named above. ")


## Jedes Panel bekommt genau drei Referenzen: den Größenmaßstab der Szene (enthält die Figuren bereits in der
## richtigen Relation), den Ort und das freigegebene Szenenblatt-Panel. Mehr Referenzbilder widersprechen sich und
## lassen das Modell Figuren verdoppeln.
## Die Anzahl der Figuren wird explizit genannt: sonst zeichnet das Modell eine Figur doppelt, wenn der Maßstab
## zwei Figuren zeigt und der Text beide beschreibt.
## Ohne klare Zuordnung "wer ist wer" verwechselt das Modell die Figuren (Gorilla als Baby Mo, Mensch als Morilla).
CHART_TXT = ("Image 1 is the exact character reference for this shot: it shows exactly {n} characters at their correct "
             "relative sizes on one ground line. WHO IS WHO, never swap them: Morilla is the black-furred GORILLA in the "
             "white gi; Baby Mo is the tall HUMAN man with short dark curly hair and the BLUE belt; Vitali is the HUMAN "
             "man with the dark beard and the BLACK belt with a red rank patch. Copy their faces, hair, gis, belt colours "
             "and body proportions exactly, and keep the size relation exactly as shown. The finished shot contains "
             "exactly {n} characters and nobody else: draw each of them EXACTLY ONCE, no duplicates, no extra fighters, "
             "no second gorilla, no background people. ")
LOC_TXT = "Image 2 is the exact reference for the location and props. "

PANELS = [
    ("1_vorhof", [BG], 11701,
     CHART_TXT + LOC_TXT + STYLE + "Wide side view of the quarry courtyard, both figures full-body on the same ground line: "
     "Morilla stands at the left, facing right, seen from the side; Baby Mo stands at the center-right, facing left, both "
     "arms open wide in a calm welcoming gesture. Baby Mo is a giant: Morilla's head reaches only to his chest. Behind them "
     "monumental stone arches, a waterfall, a hanging training bag on a wooden frame at the left, a wooden crane, a dark red "
     "banner with a pale emblem at the right and stone stairs rising to the right. " + SCALE_TXT,
     "Slow static camera with a tiny drift. Baby Mo holds his open welcoming gesture and breathes calmly, Morilla stands and "
     "breathes, lantern light flickers, mist drifts. Both characters keep their exact size relation, no cuts.", False),
    ("2_baby_mo", [BG], 11702,
     CHART_TXT + LOC_TXT + STYLE + "Medium shot from a slightly low angle: Baby Mo fills the right half of the frame, huge and "
     "towering, facing left, one open hand raised in a friendly explaining gesture, his clearly visible BLUE belt in frame; "
     "Morilla stands at the lower left, seen from behind and from the side, much smaller, his head at Baby Mo's chest height, "
     "looking up at him. Stone arches and a misty gorge behind them. " + SCALE_TXT,
     "Slow subtle push-in. Baby Mo speaks with a calm open-hand gesture, Morilla listens and breathes, lantern light flickers, "
     "mist drifts. Faces, clothes, belt colors and the size relation never change.", True),
    ("3_thron_zeigen", [THRONE], 11703,
     CHART_TXT + LOC_TXT + STYLE + "Wide shot: Baby Mo stands at the left, huge, seen from behind and from the side, pointing "
     "forward and up with one outstretched arm toward a gigantic throne built entirely from thousands of woven Jiu-Jitsu belts "
     "in white, blue, purple, brown and black, which rises in the center-right of the quarry courtyard. Morilla stands at the "
     "far left, seen from behind, much smaller than Baby Mo, looking up at the throne. " + SCALE_TXT,
     "Slow push-in toward the throne. Baby Mo holds his pointing arm steady, Morilla looks up, lantern light flickers, mist "
     "drifts around the base of the throne. The throne stays identical, the size relation stays identical, no cuts.", True),
    ("4_thron_enthuellung", [THRONE], 11704,
     CHART_TXT + LOC_TXT + STYLE + "Wide reveal shot of the whole throne: the gigantic throne of thousands of woven Jiu-Jitsu "
     "belts fills the center, and on it sits Vitali in his open black gi with a BLACK belt and red rank patch, calm and "
     "upright, hands on the armrests. Baby Mo stands at the left, huge, seen from behind, pointing at him; Morilla stands at "
     "the far left, seen from behind, much smaller than Baby Mo. Warm sunbeams fall through the arches onto the throne, "
     "quarry courtyard, lanterns, mist. " + SCALE_TXT,
     "Slow dramatic push-in toward the throne. Vitali sits perfectly still and only breathes, Baby Mo lowers his pointing arm, "
     "Morilla looks up, lantern light flickers, mist drifts. Faces, clothes, the throne and the size relation never change.",
     False),
    ("5_vitali_hut", [THRONE], 11705,
     CHART_TXT + LOC_TXT + STYLE + "Close shot of Vitali sitting on the belt throne: he is calm and upright in his open black "
     "gi with a BLACK belt and red rank patch, both hands resting on the armrests, looking straight at the viewer. Beside him "
     "on the belts at the right lies a grey felt sauna hat. The woven belts of the throne fill the whole background.",
     "Slow subtle push-in. Vitali sits still and only breathes, his eyes calm and direct, lantern light flickers, mist drifts. "
     "The grey sauna hat stays in place. Faces and clothes never change.", True),
    ("6_vor_dem_thron", [THRONE], 11706,
     CHART_TXT + LOC_TXT + STYLE + "Wide side view: Morilla stands in the foreground at the left, full-body, facing right "
     "toward the throne; Baby Mo stands just behind him at the center-left, huge, seen from behind, facing right; Vitali sits "
     "on the gigantic belt throne at the right, calm and upright in his open black gi with a BLACK belt and red rank patch, "
     "one open hand raised in a calm explaining gesture. Quarry courtyard, stone arches, waterfall, lanterns, mist. "
     + SCALE_TXT,
     "Slow static camera with a tiny drift. Morilla stands and breathes, Baby Mo stands still, Vitali speaks with a calm open "
     "hand, lantern light flickers, mist drifts. Consistent characters and sizes, no cuts.", False),
]


## Szenenblatt: 2 Spalten x 3 Reihen, randlos. Die Zellen sind 768x341 (2,25:1) – genau das Format der Panels.
SHEET_COLS = 2
SHEET_ROWS = 3
## Reihenfolge der Zellen im Szenenblatt (links oben nach rechts unten).
SHEET_ORDER = ["1_vorhof", "2_baby_mo", "3_thron_zeigen", "4_thron_enthuellung", "5_vitali_hut", "6_vor_dem_thron"]


def split_sheet(force: bool) -> None:
    """Zerlegt das freigegebene Szenenblatt (tools/quarry/refs/sheet.png) in die sechs Kompositions-Panels.

    Das Blatt ist eine randlose 2x3-Collage; jede Zelle ist ein Panel. Die Ausschnitte landen unter
    tools/raw/ref/sheet/<name>.png und dienen `panels` als Kompositionsvorgabe (COMPOSE).
    """
    from PIL import Image
    if not SHEET_SRC.exists():
        sys.exit(f"Szenenblatt fehlt: {SHEET_SRC}")
    sheet = Image.open(SHEET_SRC).convert("RGB")
    cw, ch = sheet.width // SHEET_COLS, sheet.height // SHEET_ROWS
    SHEET.mkdir(parents=True, exist_ok=True)
    for i, name in enumerate(SHEET_ORDER):
        out = SHEET / f"{name}.png"
        if out.exists() and not force:
            continue
        col, row = i % SHEET_COLS, i // SHEET_COLS
        cell = sheet.crop((col * cw, row * ch, (col + 1) * cw, (row + 1) * ch))
        cell.save(out)
        print("sheet", out, cell.size, flush=True)


def dump(name: str, kind: str, graph: dict, meta: dict) -> None:
    """Speichert den API-Graph samt Prompt, Seed und Referenzpfaden unter tools/quarry/workflows/."""
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
    graph = video_graph(upload(image), motion, seed, f"morilla_rumble/vitali_{name}", frames, False)
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
        shots.append({"name": name, "video": f"res://assets/cutscenes/vitali/{name}.ogv",
                      "still": f"res://assets/cutscenes/vitali/{name}.jpg", "loop": loop, "seed": seed,
                      "cast": CHARTS[name], "chart": rel(CHART_DIR / f"{name}.png"),
                      "refs": [rel(r) for r in _refs], "prompt": _prompt, "motion": motion})
    DOC.mkdir(parents=True, exist_ok=True)
    (DOC / "manifest.json").write_text(json.dumps({
        "style": STYLE, "size": [W, H], "fps": 24, "frames": {"once": FRAMES, "loop": LOOP_FRAMES},
        "heights_m": HEIGHTS,
        "size_rule": SCALE_TXT,
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
    if mode == "refs":
        # Szenenblatt zuerst zerlegen: die Ausschnitte sind die Kompositionsvorgabe der Panels.
        split_sheet(force)
        for name, out, prompt, w, h, seed, refs in REFS:
            if not only or name.split("/")[-1] in only:
                make_image(name, out, prompt, w, h, seed, refs, force)
        # Größenmaßstäbe: aus den fertigen Einzelreferenzen zusammengesetzt, je Panel nur die eigene Besetzung.
        for chart, keys in CHARTS.items():
            if not only or chart in only:
                build_chart(chart, keys, force)
    elif mode == "assets":
        for name, out, prompt, w, h, seed, refs in ASSETS:
            if not only or name in only:
                make_image(name, out, prompt, w, h, seed, refs, force)
    elif mode == "chars":
        for name, prompt, w, h, seed, refs in CHARS:
            # Filter akzeptiert Figuren-Präfix ("morilla"), Animationspräfix ("morilla_suplex") und vollen Namen.
            if only and not (name.split("_")[0] in only or name in only
                             or any(name.startswith(o + "_") for o in only)):
                continue
            make_image(name, OUT / f"{name}.png", prompt, w, h, seed, refs, force)
    elif mode == "panels":
        for name, refs, seed, prompt, _motion, _loop in PANELS:
            if not only or name.split("_")[0] in only:
                # Größenmaßstab der Szene + freigegebenes Szenenblatt-Panel als Kompositionsvorgabe.
                chart = build_chart(name, CHARTS[name], force)
                # Panels mit mehreren Figuren: das Storyboard liefert dort zusätzliche Figuren, also weglassen.
                board = SHEET / f"{name}.png" if name not in NO_BOARD else Path("/nonexistent")
                all_refs = [chart] + list(refs) + ([board] if board.exists() else [])
                full = (prompt.format(n=len(CHARTS[name])) + CAST[name] + " "
                        + (COMPOSE.format(n=len(all_refs)) if board.exists() else ""))
                make_image(name, OUT / f"panel_{name}.png", full, W, H, seed, all_refs, force)
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
