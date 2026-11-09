"""Verarbeitet die Roh-Assets aus tools/raw zu spielfertigen Dateien unter assets/.

Hintergrund (flaches Hellgrau) wird per Flood-Fill vom Bildrand freigestellt. Figuren erhalten eine feste Leinwand mit
Fußpunkt unten mittig (siehe scripts/systems/character_specs.gd) und einen gemeinsamen Skalierungsfaktor pro Figur.
Aufruf: python3 process_assets.py [--force] [name ...]
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
RAW = Path(__file__).parent / "raw"
OUT = ROOT / "assets"
## Unterordner von tools/raw, in denen Rohdateien zusätzlich gesucht werden (z. B. quarry/).
RAW_SUBDIRS = ["quarry"]


def raw_path(name: str) -> Path:
	"""Rohdatei: zuerst tools/raw/<name>.png, dann die Unterordner (quarry/ ...)."""
	direct = RAW / f"{name}.png"
	if direct.exists():
		return direct
	for sub in RAW_SUBDIRS:
		candidate = RAW / sub / f"{name}.png"
		if candidate.exists():
			return candidate
	return direct

# Figur: (Präfix, Zielordner, Leinwand, anchor_y, Zielhöhe der Referenzpose, Referenzbild, Ordner je Animation)
MORILLA_DIRS = {
    "idle": "idle", "walk": "walk", "run": "run", "jump": "jump", "fall": "jump", "land": "jump",
    "light_attack": "attacks", "heavy_attack": "attacks", "dash": "attacks", "block": "attacks",
    "jab": "attacks", "cross": "attacks", "hook": "attacks", "lowkick": "attacks", "kick": "attacks",
    "grab": "grappling", "kimura": "grappling", "suplex": "grappling", "summon": "grappling",
    "hurt": "hurt", "death": "hurt",
}
CHARACTERS = {
    "morilla": (OUT / "characters/morilla", (640, 480), 470, 400, "ref/morilla_ref", MORILLA_DIRS),
    "recruit": (OUT / "characters/enemies/white_belt_recruit", (560, 440), 430, 340, "ref/recruit_ref", {}),
    "mo": (OUT / "characters/coaches/mo", (560, 460), 450, 380, "ref/mo_ref", {}),
    "rival": (OUT / "characters/enemies/blue_belt_rival", (560, 440), 430, 340, "ref/rival_ref", {}),
    "arman": (OUT / "characters/coaches/arman", (560, 460), 450, 380, "ref/arman_ref", {}),
    "octopus": (OUT / "characters/summons/octopus", (640, 640), 320, 520, "ref/octopus_ref", {}),
    "bear": (OUT / "characters/summons/bear", (760, 760), 380, 620, "ref/bear_ref", {}),
    # Level 2, Steinbruch-Abschnitt: Baby Mo (drei Meter groß), Vitali (Schwarzgurt) und Boss Eisenrücken.
    "baby_mo": (OUT / "characters/coaches/baby_mo", (760, 640), 620, 560, "ref/baby_mo_ref", {}),
    "vitali": (OUT / "characters/coaches/vitali", (640, 560), 540, 450, "ref/vitali_ref", {}),
    "ironback": (OUT / "characters/enemies/ironback", (760, 620), 600, 540, "ref/ironback_ref", {}),
}
# Schwebende Figuren werden am Schwerpunkt statt am Fußpunkt ausgerichtet.
CENTERED = {"octopus", "bear"}
# Der Hintergrund wird auch zwischen den Tentakeln entfernt (Insel-Hintergründe).
ENCLOSED = {"octopus", "bear", "bamboo_cluster", "bamboo_stalks", "tea_jar", "bonsai", "stone_pagoda",
            "quarry_arch", "quarry_crane", "quarry_rope", "quarry_waterfall", "quarry_rock", "quarry_pillar",
            "belt_throne", "belt_throne_base", "belt_throne_cascade", "break_slab"}

# Roh-Name -> (Zieldatei, Maximalgröße längste Seite oder None)
PROPS = "environments/dojo/props"
PROP_SOURCES = {
    "pillar": (f"{PROPS}/pillar.png", 1280), "lantern": (f"{PROPS}/lantern.png", 512),
    "banner": (f"{PROPS}/banner.png", 1024), "cherry_tree": (f"{PROPS}/cherry_tree.png", 1280),
    "weapon_rack": (f"{PROPS}/weapon_rack.png", 768), "dummy": (f"{PROPS}/dummy.png", 1024),
    "gong": (f"{PROPS}/gong.png", 768), "gate": (f"{PROPS}/gate.png", 1280),
    "scroll": (f"{PROPS}/scroll.png", 256),
    "ground_wood": ("environments/dojo/terrain/ground_wood.png", 1024),
    "ground_stone": ("environments/dojo/terrain/ground_stone.png", 1024),
    "platform_wood": ("environments/dojo/terrain/platform_wood.png", 1536),
    "mo_portrait": ("ui/mo_portrait.png", 512), "morilla_portrait": ("ui/morilla_portrait.png", 512),
    "arman_portrait": ("ui/arman_portrait.png", 512), "andre_portrait": ("ui/andre_portrait.png", 512),
    "matthias_portrait": ("ui/matthias_portrait.png", 512), "vitali_portrait": ("ui/vitali_portrait.png", 512),
    "kevin_portrait": ("ui/kevin_portrait.png", 512),
    "brush_black": ("ui/brush_black.png", 1024), "brush_red": ("ui/brush_red.png", 1024),
    # Level 2: Mondbambus-Hain
    "bamboo_stalks": ("environments/bamboo/props/bamboo_stalks.png", 1280),
    "bamboo_cluster": ("environments/bamboo/props/bamboo_cluster.png", 1280),
    "stone_lantern": ("environments/bamboo/props/stone_lantern.png", 768),
    "shrine": ("environments/bamboo/props/shrine.png", 1024),
    "sauna_house": ("environments/bamboo/props/sauna_house.png", 1280),
    "tea_jar": ("environments/bamboo/props/tea_jar.png", 256),
    "bonsai": ("environments/bamboo/props/bonsai.png", 512),
    "stone_pagoda": ("environments/bamboo/props/stone_pagoda.png", 1024),
    "ground_moss": ("environments/bamboo/terrain/ground_moss.png", 1024),
    "platform_bamboo": ("environments/bamboo/terrain/platform_bamboo.png", 1536),
    # Level 2, Steinbruch-Abschnitt
    "ground_rock": ("environments/quarry/terrain/ground_rock.png", 1024),
    "platform_plank": ("environments/quarry/terrain/platform_plank.png", 1536),
    "stairs_stone": ("environments/quarry/terrain/stairs_stone.png", 1536),
    "quarry_arch": ("environments/quarry/props/quarry_arch.png", 1280),
    "quarry_crane": ("environments/quarry/props/quarry_crane.png", 1280),
    "quarry_lantern": ("environments/quarry/props/quarry_lantern.png", 768),
    "quarry_banner": ("environments/quarry/props/quarry_banner.png", 1024),
    "quarry_rope": ("environments/quarry/props/quarry_rope.png", 1024),
    "quarry_waterfall": ("environments/quarry/props/quarry_waterfall.png", 1280),
    "quarry_rock": ("environments/quarry/props/quarry_rock.png", 768),
    "quarry_pillar": ("environments/quarry/props/quarry_pillar.png", 1280),
    "belt_throne": ("environments/quarry/props/belt_throne.png", 1280),
    "belt_throne_base": ("environments/quarry/props/belt_throne_base.png", 1280),
    "belt_throne_cascade": ("environments/quarry/props/belt_throne_cascade.png", 1536),
    "break_slab": ("environments/quarry/props/break_slab.png", 1024),
    "baby_mo_portrait": ("ui/baby_mo_portrait.png", 512),
}
BACKGROUNDS = {"bg_dojo": "environments/dojo/bg_dojo.png", "bg_garden": "environments/dojo/bg_garden.png",
               "bg_bamboo": "environments/bamboo/bg_bamboo.png", "menu2_b": "ui/menu_bg.png",
               "bg_quarry": "environments/quarry/bg_quarry.png"}

TOLERANCE = 26.0


def cut_out(img: Image.Image, enclosed: bool = False) -> Image.Image:
    """Macht den randverbundenen Hintergrund transparent (enclosed: auch eingeschlossene Hintergrundinseln) und glättet die Kante."""
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    bg = np.median(border, axis=0)
    near = np.linalg.norm(rgb - bg, axis=2) < TOLERANCE
    labels, _ = ndimage.label(near)
    edge_labels = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))) - {0}
    bg_mask = near if enclosed else np.isin(labels, list(edge_labels))
    bg_mask = ndimage.binary_dilation(bg_mask, iterations=1)
    alpha = Image.fromarray(((~bg_mask) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    out = img.convert("RGBA")
    out.putalpha(alpha)
    return out


def bbox(img: Image.Image) -> tuple[int, int, int, int]:
    box = img.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox()
    return box if box else (0, 0, img.width, img.height)


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print("wrote", path.relative_to(ROOT), img.size, flush=True)


def wanted(name: str, only: set, force: bool, dest: Path) -> bool:
    if only and name not in only and not any(name.startswith(o + "_") for o in only):
        return False
    return force or not dest.exists()


def process_character(key: str, only: set, force: bool) -> None:
    prefix_dir, canvas, anchor_y, target_h, ref_name, dirs = CHARACTERS[key]
    ref_path = raw_path(ref_name)
    if not ref_path.exists():
        return
    ref = cut_out(Image.open(ref_path), key in ENCLOSED)
    box = bbox(ref)
    factor = target_h / (box[3] - box[1])
    for src in sorted(RAW.glob(f"{key}_*.png")) + sorted((RAW / "quarry").glob(f"{key}_*.png")):
        stem = src.stem
        if stem.endswith("_portrait") or not stem[-3:].isdigit():
            continue
        anim = stem[len(key) + 1:-4]
        dest = prefix_dir / dirs.get(anim, "") / f"{stem}.png"
        if not wanted(stem, only, force, dest):
            continue
        img = cut_out(Image.open(src), key in ENCLOSED)
        img = img.crop(bbox(img))
        scale = min(factor, (canvas[0] - 20) / img.width, ((canvas[1] if key in CENTERED else anchor_y) - 10) / img.height)
        img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.LANCZOS)
        alpha = np.asarray(img.getchannel("A")).astype(np.float32)
        cx = (alpha.sum(axis=0) * np.arange(img.width)).sum() / max(alpha.sum(), 1.0)
        x = round(canvas[0] / 2 - cx)
        x = min(max(x, 0), canvas[0] - img.width)
        if key in CENTERED:
            cy = (alpha.sum(axis=1) * np.arange(img.height)).sum() / max(alpha.sum(), 1.0)
            y = min(max(round(canvas[1] / 2 - cy), 0), canvas[1] - img.height)
        else:
            y = anchor_y - img.height
        out = Image.new("RGBA", canvas, (0, 0, 0, 0))
        out.paste(img, (x, y), img)
        save(out, dest)


def process_props(only: set, force: bool) -> None:
    for name, (rel, max_side) in PROP_SOURCES.items():
        src, dest = raw_path(name), OUT / rel
        if not src.exists() or not wanted(name, only, force, dest):
            continue
        img = cut_out(Image.open(src), name in ENCLOSED)
        img = img.crop(bbox(img))
        s = max_side / max(img.size)
        if s < 1:
            img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
        save(img, dest)


def process_backgrounds(only: set, force: bool) -> None:
    for name, rel in BACKGROUNDS.items():
        src, dest = raw_path(name), OUT / rel
        if src.exists() and wanted(name, only, force, dest):
            save(Image.open(src).convert("RGB"), dest)


def process_title(only: set, force: bool) -> None:
    """Logo auf Schwarz: Die Helligkeit wird zum Alphakanal, die Farbe entpremultipliziert."""
    src, dest = RAW / "title_logo.png", OUT / "ui/title_logo.png"
    if not src.exists() or not wanted("title_logo", only, force, dest):
        return
    rgb = np.asarray(Image.open(src).convert("RGB")).astype(np.float32)
    peak = rgb.max(axis=2)
    alpha = np.clip((peak - 12.0) * 2.2, 0.0, 255.0)
    color = np.clip(rgb * 255.0 / np.maximum(peak, 1.0)[..., None], 0.0, 255.0)
    out = Image.fromarray(np.dstack([color, alpha]).astype(np.uint8), "RGBA")
    out = out.crop(bbox(out))
    save(out, dest)


if __name__ == "__main__":
    args = sys.argv[1:]
    force = "--force" in args
    only = {a for a in args if not a.startswith("--")}
    for character in CHARACTERS:
        process_character(character, only, force)
    process_props(only, force)
    process_backgrounds(only, force)
    process_title(only, force)
    print("done")
