"""Minimaler ComfyUI-API-Client für die Asset-Generierung (Qwen Image 2.1)."""
import json
import sys
import time
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

SERVER = "http://127.0.0.1:8188"
NEGATIVE = "text, letters, watermark, signature, frame, border, blurry, lowres, deformed, extra limbs, extra fingers, cropped, photo, 3d render"


def _post(path: str, data: bytes, content_type: str) -> dict:
    req = urllib.request.Request(SERVER + path, data=data, headers={"Content-Type": content_type})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())


def upload(path: Path) -> str:
    boundary = uuid.uuid4().hex
    body = (
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"{path.name}\"\r\n"
        "Content-Type: image/png\r\n\r\n"
    ).encode() + path.read_bytes() + f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"overwrite\"\r\n\r\ntrue\r\n--{boundary}--\r\n".encode()
    return _post("/upload/image", body, f"multipart/form-data; boundary={boundary}")["name"]


def build(prompt: str, width: int, height: int, seed: int, refs: list[str], steps: int, negative: str = NEGATIVE) -> dict:
    g = {
        "unet": {"class_type": "UNETLoader", "inputs": {"unet_name": "qwen_image_2.1_int8_convrot.safetensors", "weight_dtype": "default"}},
        "cache": {"class_type": "QwenImage21Cache", "inputs": {"model": ["unet", 0], "device": "auto", "dtype": "default"}},
        "clip": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen3vl_8b_int8_convrot.safetensors", "type": "qwen_image", "device": "default"}},
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_2.1_vae_bf16.safetensors"}},
        "enc": {"class_type": "TextEncodeQwenImage21", "inputs": {
            "clip": ["clip", 0], "prompt": prompt, "negative_prompt": negative, "resolution": 1024, "vae": ["vae", 0]}},
        "latent": {"class_type": "EmptyLatentImage", "inputs": {"width": width, "height": height, "batch_size": 1}},
        "ks": {"class_type": "KSampler", "inputs": {
            "model": ["cache", 0], "positive": ["enc", 0], "negative": ["enc", 1], "latent_image": ["latent", 0],
            "seed": seed, "steps": steps, "cfg": 1.0, "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0}},
        "dec": {"class_type": "VAEDecode", "inputs": {"samples": ["ks", 0], "vae": ["vae", 0]}},
        "save": {"class_type": "SaveImage", "inputs": {"images": ["dec", 0], "filename_prefix": "morilla_rumble/gen"}},
    }
    for i, name in enumerate(refs, 1):
        g[f"ref{i}"] = {"class_type": "LoadImage", "inputs": {"image": name}}
        g["enc"]["inputs"][f"images.image_{i}"] = [f"ref{i}", 0]
    return g


def generate(prompt: str, out: Path, width=1024, height=1024, seed=1, refs: list[Path] | None = None, steps=25, negative: str = NEGATIVE) -> Path:
    names = [upload(p) for p in refs or []]
    pid = _post("/prompt", json.dumps({"prompt": build(prompt, width, height, seed, names, steps, negative)}).encode(), "application/json")["prompt_id"]
    while True:
        with urllib.request.urlopen(f"{SERVER}/history/{pid}") as r:
            hist = json.loads(r.read())
        if pid in hist:
            entry = hist[pid]
            if entry["status"].get("status_str") == "error":
                raise RuntimeError(json.dumps(entry["status"])[:2000])
            img = entry["outputs"]["save"]["images"][0]
            break
        time.sleep(2)
    q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
    out.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(f"{SERVER}/view?{q}") as r:
        out.write_bytes(r.read())
    return out


if __name__ == "__main__":
    generate(sys.argv[1], Path(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]))
