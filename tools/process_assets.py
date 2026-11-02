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

# Figur: (Präfix, Zielordner, Leinwand, anchor_y, Zielhöhe der Referenzpose, Referenzbild, Ordner je Animation)
MORILLA_DIRS = {
    "idle": "idle", "walk": "walk", "run": "run", "jump": "jump", "fall": "jump",
    "light_attack": "attacks", "heavy_attack": "attacks", "dash": "attacks", "block": "attacks",
    "grab": "grappling", "kimura": "grappling", "hurt": "hurt", "death": "hurt",
}
CHARACTERS = {
    "morilla": (OUT / "characters/morilla", (640, 480), 470, 400, "ref/morilla_ref", MORILLA_DIRS),
    "recruit": (OUT / "characters/enemies/white_belt_recruit", (560, 440), 430, 340, "ref/recruit_ref", {}),
    "mo": (OUT / "characters/coaches/mo", (560, 460), 450, 380, "ref/mo_ref", {}),
}

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
}
BACKGROUNDS = {"bg_dojo": "environments/dojo/bg_dojo.png", "bg_garden": "environments/dojo/bg_garden.png",
               "menu_bg": "ui/menu_bg.png"}

TOLERANCE = 26.0


def cut_out(img: Image.Image) -> Image.Image:
    """Macht den randverbundenen Hintergrund transparent und glättet die Kante leicht."""
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    bg = np.median(border, axis=0)
    near = np.linalg.norm(rgb - bg, axis=2) < TOLERANCE
    labels, _ = ndimage.label(near)
    edge_labels = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))) - {0}
    bg_mask = np.isin(labels, list(edge_labels))
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
    if only and name not in only:
        return False
    return force or not dest.exists()


def process_character(key: str, only: set, force: bool) -> None:
    prefix_dir, canvas, anchor_y, target_h, ref_name, dirs = CHARACTERS[key]
    ref_path = RAW / f"{ref_name}.png"
    if not ref_path.exists():
        return
    ref = cut_out(Image.open(ref_path))
    box = bbox(ref)
    factor = target_h / (box[3] - box[1])
    for src in sorted(RAW.glob(f"{key}_*.png")):
        stem = src.stem
        if stem.endswith("_portrait") or not stem[-3:].isdigit():
            continue
        anim = stem[len(key) + 1:-4]
        dest = prefix_dir / dirs.get(anim, "") / f"{stem}.png"
        if not wanted(stem, only, force, dest):
            continue
        img = cut_out(Image.open(src))
        img = img.crop(bbox(img))
        scale = min(factor, (canvas[0] - 20) / img.width, (anchor_y - 10) / img.height)
        img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.LANCZOS)
        alpha = np.asarray(img.getchannel("A")).astype(np.float32)
        cx = (alpha.sum(axis=0) * np.arange(img.width)).sum() / max(alpha.sum(), 1.0)
        x = round(canvas[0] / 2 - cx)
        x = min(max(x, 0), canvas[0] - img.width)
        out = Image.new("RGBA", canvas, (0, 0, 0, 0))
        out.paste(img, (x, anchor_y - img.height), img)
        save(out, dest)


def process_props(only: set, force: bool) -> None:
    for name, (rel, max_side) in PROP_SOURCES.items():
        src, dest = RAW / f"{name}.png", OUT / rel
        if not src.exists() or not wanted(name, only, force, dest):
            continue
        img = cut_out(Image.open(src))
        img = img.crop(bbox(img))
        s = max_side / max(img.size)
        if s < 1:
            img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
        save(img, dest)


def process_backgrounds(only: set, force: bool) -> None:
    for name, rel in BACKGROUNDS.items():
        src, dest = RAW / f"{name}.png", OUT / rel
        if src.exists() and wanted(name, only, force, dest):
            save(Image.open(src).convert("RGB"), dest)


if __name__ == "__main__":
    args = sys.argv[1:]
    force = "--force" in args
    only = {a for a in args if not a.startswith("--")}
    for character in CHARACTERS:
        process_character(character, only, force)
    process_props(only, force)
    process_backgrounds(only, force)
    print("done")
