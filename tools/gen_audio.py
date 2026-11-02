"""Synthetisiert alle Soundeffekte für Morilla Rumble (numpy/scipy, keine Fremdsamples). Musik: tools/get_music.sh.

Aufruf: python3 gen_audio.py [name ...]   (ohne Namen wird alles erzeugt)
Ausgabe: assets/audio/sfx/*.wav
"""
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

SR = 44100
TAU = 2 * np.pi
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"
rng = np.random.default_rng(11)


def tt(sec):
    return np.arange(int(sec * SR)) / SR


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def noise(sec):
    return rng.uniform(-1, 1, int(sec * SR))


def env(t, tau):
    return np.exp(-t / tau)


def lp(x, fc):
    return sosfilt(butter(2, fc, "low", fs=SR, output="sos"), x)


def hp(x, fc):
    return sosfilt(butter(2, fc, "high", fs=SR, output="sos"), x)


def bp(x, lo, hi):
    return sosfilt(butter(2, [lo, hi], "band", fs=SR, output="sos"), x)


def glide(f0, f1, sec):
    t = tt(sec)
    f = f0 * (f1 / f0) ** (t / sec)
    return np.sin(TAU * np.cumsum(f) / SR)


def fade(x, a=0.003, r=0.015):
    x = x.copy()
    na, nr = int(a * SR), int(r * SR)
    x[:na] *= np.linspace(0, 1, na)
    x[-nr:] *= np.linspace(1, 0, nr)
    return x


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def at(x, delay):
    return np.concatenate([np.zeros(int(delay * SR)), x])


def tone(f, sec, tau=0.2, harm=(1.0, 0.4, 0.2)):
    t = tt(sec)
    return sum(a * np.sin(TAU * f * (k + 1) * t) for k, a in enumerate(harm)) * env(t, tau)


def bell(f, sec, tau=0.7):
    t = tt(sec)
    return (np.sin(TAU * f * t) + 0.5 * np.sin(TAU * f * 2.76 * t) + 0.3 * np.sin(TAU * f * 5.4 * t)) * env(t, tau)


def thump(f0=110, sec=0.25, tau=0.09):
    return glide(f0, f0 * 0.4, sec) * env(tt(sec), tau)


def whoosh(sec, f0, f1, vol=0.6):
    t = tt(sec)
    x = noise(sec)
    parts = []
    n = 12
    for i in range(n):
        c = f0 * (f1 / f0) ** (i / (n - 1))
        seg = bp(x, c * 0.7, c * 1.4) * np.exp(-((t - sec * i / (n - 1)) / (sec * 0.2)) ** 2)
        parts.append(seg)
    return vol * np.sum(parts, axis=0)


# ------------------------------------------------------------------ SFX

def sfx_jump():
    return fade(glide(260, 620, 0.16) * env(tt(0.16), 0.12) * 0.7)


def sfx_land():
    return fade(mix(thump(90, 0.22, 0.07), lp(noise(0.12), 700) * env(tt(0.12), 0.04) * 0.6))


def sfx_step():
    return fade(mix(thump(150, 0.08, 0.025) * 0.8, lp(noise(0.07), 1200) * env(tt(0.07), 0.02) * 0.4))


def sfx_whoosh():
    return fade(whoosh(0.22, 700, 3200, 0.7))


def sfx_heavy_whoosh():
    return fade(mix(whoosh(0.35, 300, 2200, 0.9), thump(80, 0.3, 0.12) * 0.3))


def sfx_dash():
    return fade(mix(whoosh(0.28, 500, 4500, 0.8), glide(300, 900, 0.2) * env(tt(0.2), 0.08) * 0.25))


def sfx_hit():
    return fade(mix(thump(160, 0.2, 0.06), bp(noise(0.12), 800, 5000) * env(tt(0.12), 0.03) * 0.8))


def sfx_heavy_hit():
    return fade(mix(thump(100, 0.4, 0.14) * 1.2, lp(noise(0.25), 2500) * env(tt(0.25), 0.07) * 0.9,
                    bell(180, 0.4, 0.15) * 0.3))


def sfx_block():
    return fade(mix(bp(noise(0.2), 1500, 6000) * env(tt(0.2), 0.04), bell(520, 0.25, 0.06) * 0.5, thump(120, 0.15, 0.05) * 0.5))


def sfx_block_up():
    return fade(lp(noise(0.12), 1500) * env(tt(0.12), 0.05) * 0.5)


def sfx_parry():
    return fade(mix(bell(1320, 0.5, 0.18) * 0.7, bell(1980, 0.4, 0.12) * 0.4, bp(noise(0.08), 3000, 9000) * env(tt(0.08), 0.02)))


def sfx_hurt():
    return fade(mix(glide(420, 140, 0.28) * env(tt(0.28), 0.14) * 0.8, thump(120, 0.2, 0.06) * 0.7,
                    lp(noise(0.15), 1800) * env(tt(0.15), 0.05) * 0.4))


def sfx_death():
    return fade(mix(glide(320, 55, 0.9) * env(tt(0.9), 0.4) * 0.9, thump(70, 0.7, 0.25), at(thump(60, 0.6, 0.2) * 0.6, 0.35)), r=0.1)


def sfx_enemy_swing():
    return fade(whoosh(0.2, 400, 1600, 0.45))


def sfx_enemy_down():
    return fade(mix(glide(500, 90, 0.5) * env(tt(0.5), 0.2) * 0.5, lp(noise(0.5), 1200) * env(tt(0.5), 0.15) * 0.5))


def sfx_grab():
    return fade(mix(lp(noise(0.15), 900) * env(tt(0.15), 0.05) * 0.7, thump(130, 0.18, 0.06) * 0.7))


def sfx_strain():
    t = tt(0.55)
    wob = 1 + 0.04 * np.sin(TAU * 9 * t)
    x = np.sin(TAU * np.cumsum(140 * wob * (1 + 0.5 * t)) / SR) * 0.5 + lp(noise(0.55), 900) * 0.25
    return fade(x * np.minimum(t / 0.08, 1) * env(t, 0.45), r=0.08)


def sfx_submit():
    return fade(mix(bell(880, 0.5, 0.15) * 0.5, thump(100, 0.25, 0.08) * 0.8, at(bell(1320, 0.5, 0.2) * 0.5, 0.1)))


def sfx_gong():
    t = tt(2.5)
    x = sum(a * np.sin(TAU * f * t + p) * env(t, tau) for f, a, p, tau in
            [(110, 1.0, 0, 1.6), (165.3, 0.6, 1, 1.2), (221, 0.5, 2, 1.0), (304, 0.35, 3, 0.7), (447, 0.2, 4, 0.5)])
    return fade(mix(x * 0.8, lp(noise(0.15), 3000) * env(tt(0.15), 0.03) * 0.5), r=0.2)


def sfx_scroll():
    return fade(mix(bp(noise(0.25), 2500, 8000) * env(tt(0.25), 0.08) * 0.5, at(bell(1568, 0.5, 0.2) * 0.4, 0.06)))


def sfx_learn():
    notes = [67, 71, 74, 79]
    return fade(mix(*[at(bell(hz(m), 0.9, 0.35) * 0.5, 0.09 * i) for i, m in enumerate(notes)]), r=0.1)


def sfx_arena_start():
    return fade(mix(thump(70, 0.7, 0.3) * 1.2, at(thump(70, 0.7, 0.3), 0.3), sfx_gong()[: int(1.4 * SR)] * 0.5), r=0.1)


def sfx_arena_clear():
    notes = [60, 64, 67, 72]
    return fade(mix(*[at(tone(hz(m), 0.7, 0.3, (1, 0.5, 0.25)) * 0.5, 0.11 * i) for i, m in enumerate(notes)]), r=0.1)


def sfx_fanfare():
    seq = [(67, 0.0, 0.18), (67, 0.2, 0.18), (67, 0.4, 0.18), (72, 0.6, 0.5), (71, 1.15, 0.18), (74, 1.35, 0.9)]
    parts = [at(tone(hz(m), d + 0.3, 0.5, (1, 0.5, 0.35, 0.2)) * 0.4, s) for m, s, d in seq]
    parts += [at(tone(hz(m - 12), 1.0, 0.8, (1, 0.3)) * 0.3, 1.35) for m in (74,)]
    return fade(mix(*parts), r=0.15)


def sfx_ui():
    return fade(mix(bell(1046, 0.18, 0.05) * 0.6, bell(1568, 0.14, 0.04) * 0.3))


SFX = {
    "jump": sfx_jump, "land": sfx_land, "step": sfx_step, "whoosh": sfx_whoosh, "heavy_whoosh": sfx_heavy_whoosh,
    "dash": sfx_dash, "hit": sfx_hit, "heavy_hit": sfx_heavy_hit, "block": sfx_block, "block_up": sfx_block_up,
    "parry": sfx_parry, "hurt": sfx_hurt, "death": sfx_death, "enemy_swing": sfx_enemy_swing, "enemy_down": sfx_enemy_down,
    "grab": sfx_grab, "strain": sfx_strain, "submit": sfx_submit, "gong": sfx_gong, "scroll": sfx_scroll,
    "learn": sfx_learn, "arena_start": sfx_arena_start, "arena_clear": sfx_arena_clear, "fanfare": sfx_fanfare,
    "ui": sfx_ui,
}



def write_wav(path, x):
    x16 = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(x16.tobytes())


def main() -> None:
    only = set(sys.argv[1:])
    (OUT / "sfx").mkdir(parents=True, exist_ok=True)
    (OUT / "music").mkdir(parents=True, exist_ok=True)
    for name, fn in SFX.items():
        if only and name not in only:
            continue
        x = fn()
        write_wav(OUT / "sfx" / f"{name}.wav", x / max(np.abs(x).max(), 1e-6) * 0.8)
        print("sfx", name, flush=True)

if __name__ == "__main__":
    main()
