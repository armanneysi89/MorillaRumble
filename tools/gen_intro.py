"""Intro-Animation: 6 Panels (Qwen Image) -> je ein Clip (MiniMax H3 Bild-zu-Video) -> tools/raw/intro.

Aufruf: gen_intro.py panels|clips|voiced [1..6]
Die Clips werden bewusst einzeln animiert und später hart geschnitten (keine Perspektiv-Morphs).
"""
import json
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

from comfy import NEGATIVE, SERVER, _post, generate, upload

RAW = Path(__file__).parent / "raw"
OUT = RAW / "intro"
REF = RAW / "ref"
MORILLA = REF / "morilla_ref.png"
MO = REF / "mo_ref.png"

W, H = 1344, 768
FRAMES = 73  # 17k+5 -> ~3 s bei 24 fps
VOICED_FRAMES = 107  # ~4,5 s Platz für den Sprecher

STYLE = ("Hand-painted 2D anime game cinematic, rich painterly shading, dramatic dusk lighting in purple and deep blue with warm "
         "orange lantern glow, 16:9 widescreen. ")
MORILLA_TXT = ("Use image 1 as the exact character reference: the muscular anthropomorphic gorilla Morilla with black fur, strong "
               "gorilla face, swept-up black hair tuft, white Brazilian Jiu-Jitsu gi and white belt, bare feet. ")
MO_TXT = ("Use image 2 as the exact reference for Head Coach Mo: older man, short gray hair, gray-white beard, black gi, black belt, "
          "bare feet. ")
DOJO = ("a traditional Japanese dojo, its wooden door and walls splintered with dark purple claw-like scorch marks, "
        "wrecked training dummies, torn mats, a toppled gong, broken beams, red ribbons on the pillars, dusty air in lantern light")

# (Name, Prompt, Referenzen, Seed, Bewegungs-Prompt für den Clip)
SHOTS = [
    ("1_heimkehr",
     MORILLA_TXT + STYLE + "Morilla walks on a stone path through a cherry blossom garden at dusk, seen from the side and slightly "
     "behind, carrying a bundle of firewood tied with rope under his arm. In the distance his dojo with a blue tiled roof and "
     "red banners, glowing lanterns, a stone lantern, pink blossoms.",
     [MORILLA], 5101,
     "Slow tracking camera behind and beside Morilla as he walks calmly forward with heavy relaxed steps, carrying the firewood. "
     "Cherry blossom petals and leaves drift in the wind, lantern light flickers softly. Peaceful atmosphere."),
    ("2_etwas_stimmt_nicht",
     MORILLA_TXT + STYLE + "Close-up over Morilla's shoulder, he stands still and stares with worry at the entrance of his dojo: "
     "a broken door with splintered wood and dark purple scorch marks, a lantern hanging beside it. The firewood bundle is on his "
     "back.",
     [MORILLA], 5102,
     "The camera slowly pushes in towards Morilla's shoulder. Morilla stops and stays still, only breathing, fur moving slightly. "
     "Violet smoke slowly drifts out of the broken entrance, lantern light flickers."),
    ("3_schock",
     MORILLA_TXT + STYLE + "Extreme close-up of Morilla's open hand and bare foot at the wooden floor of the dojo entrance, the bundle "
     "of firewood tied with rope just slipped from his hand and lies on the floor, small splinters and dust, a splintered pillar "
     "with purple scorch marks in the background.",
     [MORILLA], 5103,
     "Static close-up camera. Morilla's hand slowly opens, the bundle of firewood falls to the ground with a thud and kicks up "
     "a puff of dust and small splinters. The hand stays open, trembling slightly."),
    ("4_zerstoertes_dojo",
     MORILLA_TXT + STYLE + "Wide side view into the wrecked interior of the dojo: " + DOJO + ". Morilla stands at the left in the "
     "entrance, small in frame, looking into the room, a purple glowing moon-lit window in the background.",
     [MORILLA], 5104,
     "Slow dolly through the entrance into the dojo. Morilla walks carefully and slowly into the wrecked room, looking around. "
     "Dust floats in the lantern light, lanterns flicker, faint violet mist hangs near the floor."),
    ("5_mo_lebt",
     MORILLA_TXT + MO_TXT + STYLE + "Morilla kneels worriedly on the floor next to Head Coach Mo, who sits exhausted and leaning "
     "against a pillar with a red cloth tied around it, in the wrecked dojo. A lantern glows on the right, broken wood on the floor.",
     [MORILLA, MO], 5105,
     "Gentle slow push-in. Mo weakly lifts his head and looks at Morilla, breathing heavily. Morilla leans forward with concern. "
     "Lantern light flickers softly."),
    ("6_uebergang",
     MORILLA_TXT + MO_TXT + STYLE + "Wide static side view of the wrecked dojo interior: " + DOJO + ". Morilla stands on the left, "
     "Head Coach Mo stands on the right, both full-body facing each other on the wooden floor, small in frame.",
     [MORILLA, MO], 5106,
     "Locked-off static side camera. Only subtle breathing movement of both characters, flickering lanterns, drifting dust. "
     "No camera movement."),
]


# Erzähler-Zeilen (kurz: ein Clip dauert ~3-4 s). H3 erzeugt Bild und Ton gemeinsam.
NARRATION = {
    "1": "Morilla kehrt vom Holzsammeln heim. Vor ihm liegt sein Dojo.",
    "2": "Doch etwas stimmt nicht. Die Tür ist zerbrochen.",
    "3": "Das Holz fällt ihm aus der Hand.",
    "4": "Sein Dojo ist verwüstet.",
    "5": "Doch Mo lebt.",
    "6": "Der Schattenmeister war hier.",
}
VOICE = ("Audio: an off-screen narrator with a deep, calm, warm male storytelling voice speaks slowly in German: \"{text}\" "
         "Soft ambient night sounds in the background, no music.")


def panel_path(name: str) -> Path:
    return OUT / f"panel_{name}.png"


def clip_path(name: str) -> Path:
    return OUT / f"clip_{name}.mp4"


def video_graph(image: str, prompt: str, seed: int, prefix: str, frames: int = FRAMES, voiced: bool = False) -> dict:
    g = {
        "clip": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors", "type": "minimax", "device": "default"}},
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": "minimax_h3_video_vae_int8_convrot.safetensors"}},
        "unet": {"class_type": "UNETLoader", "inputs": {"unet_name": "minimax_h3_fl2va_pruned_int8_convrot.safetensors", "weight_dtype": "default"}},
        "img": {"class_type": "LoadImage", "inputs": {"image": image}},
        "cond": {"class_type": "MiniMaxH3ImageToVideo", "inputs": {
            "clip": ["clip", 0], "vae": ["vae", 0], "prompt": prompt, "width": W, "height": H, "length": frames, "first_frame": ["img", 0]}},
        "neg": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["cond", 0]}},
        "shift": {"class_type": "MiniMaxH3SigmaShift", "inputs": {"model": ["unet", 0], "shift_video": 10, "shift_audio": 3}},
        "attn": {"class_type": "ModelAttentionBackend", "inputs": {"model": ["shift", 0], "attention": "comfy kitchen attention"}},
        "sparse": {"class_type": "BlockSparseAttention", "inputs": {
            "model": ["attn", 0], "selection": "vsa", "selection.keep_percent": 10, "start_percent": 0.2, "end_percent": 1.0,
            "dense_blocks": "", "min_tokens": 12288, "extra_tokens": 256, "sink_conditioning": "exact_kv_and_rows", "verbose": False}},
        "ks": {"class_type": "KSampler", "inputs": {
            "model": ["sparse", 0], "positive": ["cond", 0], "negative": ["neg", 0], "latent_image": ["cond", 1],
            "seed": seed, "steps": 8, "cfg": 1.0, "sampler_name": "res_multistep", "scheduler": "simple", "denoise": 1.0}},
        "dec": {"class_type": "VAEDecode", "inputs": {"samples": ["ks", 0], "vae": ["vae", 0]}},
        "save": {"class_type": "VHS_VideoCombine", "inputs": {
            "images": ["dec", 0], "frame_rate": 24, "loop_count": 0, "filename_prefix": prefix, "format": "video/h264-mp4",
            "pix_fmt": "yuv420p", "crf": 17, "save_metadata": False, "trim_to_audio": False, "pingpong": False, "save_output": True}},
    }
    if voiced:
        g["avae"] = {"class_type": "VAELoader", "inputs": {"vae_name": "minimax_h3_audio_vae_fp32.safetensors"}}
        g["adec"] = {"class_type": "VAEDecodeAudio", "inputs": {"samples": ["ks", 0], "vae": ["avae", 0]}}
        g["save"]["inputs"]["audio"] = ["adec", 0]
    return g


def animate(name: str, prompt: str, seed: int, out: Path, frames: int = FRAMES, voiced: bool = False) -> Path:
    image = upload(panel_path(name))
    graph = video_graph(image, prompt, seed, f"morilla_rumble/intro_{name}", frames, voiced)
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
    return out


if __name__ == "__main__":
    mode = sys.argv[1]
    only = set(sys.argv[2:])
    OUT.mkdir(parents=True, exist_ok=True)
    for name, prompt, refs, seed, motion in SHOTS:
        if only and name.split("_")[0] not in only:
            continue
        if mode == "panels":
            out = panel_path(name)
            if out.exists():
                continue
            generate(prompt, out, W, H, seed, refs, negative=NEGATIVE)
        elif mode == "voiced":
            out = OUT / f"clip_{name}_voiced.mp4"
            if out.exists():
                continue
            text = NARRATION[name.split("_")[0]]
            animate(name, motion + " " + VOICE.format(text=text), seed, out, VOICED_FRAMES, True)
        else:
            out = clip_path(name)
            if out.exists():
                continue
            animate(name, motion, seed, out)
        print("ok", out, flush=True)
