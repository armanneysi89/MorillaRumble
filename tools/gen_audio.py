"""Synthetisiert alle Soundeffekte und Musikstücke für Morilla Rumble (numpy/scipy, keine Fremdsamples).

Aufruf: python3 gen_audio.py [name ...]   (ohne Namen wird alles erzeugt)
Ausgabe: assets/audio/sfx/*.wav und assets/audio/music/*.ogg (ffmpeg nötig)
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


# ------------------------------------------------------------------ Musik (Trap)

def bass808(m, sec):
    f = hz(m)
    t = tt(sec)
    freq = f * (1 + 1.2 * np.exp(-t / 0.03))
    x = np.sin(TAU * np.cumsum(freq) / SR) * env(t, sec * 0.5)
    return np.tanh(2.2 * x) * 0.9


def kick808():
    return thump(120, 0.3, 0.1) * 1.1


def snare():
    t = tt(0.25)
    return (bp(noise(0.25), 1200, 9000) * env(t, 0.07) * 0.8 + np.sin(TAU * 190 * t) * env(t, 0.05) * 0.5)


def hat(open_=False):
    sec = 0.18 if open_ else 0.04
    return hp(noise(sec), 7500) * env(tt(sec), 0.09 if open_ else 0.02) * 0.35


def pluck(f, sec, tau=0.35):
    t = tt(sec)
    return sum(a * np.sin(TAU * f * k * t) for k, a in ((1, 1.0), (2, 0.4), (3, 0.25), (4, 0.1))) * env(t, tau)


def dark_pad(freqs, sec):
    t = tt(sec)
    x = sum(np.sin(TAU * f * t) + 0.5 * np.sin(TAU * f * 1.004 * t) for f in freqs)
    a = np.minimum(t / 0.8, 1) * np.minimum((sec - t) / 0.8, 1)
    return lp(x, 700) * a / len(freqs)


def trap(bpm, bars, roots, chords, melody, hard):
    """Halftime-Trap: 808-Bass, Clap auf Schlag 3, 16tel-Hihats mit Rolls. roots/chords: je Takt MIDI-Töne,
    melody: (Takt, 16tel-Schritt, MIDI, Länge in 16teln)."""
    step = 60.0 / bpm / 4
    bar = step * 16
    total = bar * bars
    out = np.zeros(int((total + 3.0) * SR))

    def put(x, start):
        i = int(start * SR)
        out[i:i + len(x)] += x[: len(out) - i]

    kick_pats = [[0, 7, 10], [0, 6, 10, 13], [0, 7, 11], [0, 3, 10, 14]] if hard else [[0, 10], [0, 7, 10], [0, 10], [0, 6, 10]]
    for b in range(bars):
        t0 = b * bar
        put(dark_pad([hz(m) for m in chords[b % len(chords)]], bar + 0.5) * 0.3, t0)
        for s in kick_pats[b % 4]:
            put(kick808() * 0.8, t0 + s * step)
            put(bass808(roots[b % len(roots)], step * 6) * 0.9, t0 + s * step)
        put(snare(), t0 + 8 * step)
        for s in range(0, 16, 2):
            put(hat() * (1.0 if s % 4 == 0 else 0.6), t0 + s * step)
        if hard:
            for s in (13, 15):
                put(hat() * 0.5, t0 + s * step)
            if b % 4 == 3:
                for k in range(6):
                    put(hat() * (0.4 + 0.1 * k), t0 + (12 + k * 2 / 3) * step)
        put(hat(True) * 0.7, t0 + 6 * step)
    for bar_i, s, m, ln in melody:
        put(pluck(hz(m), ln * step + 0.3, 0.3) * 0.35, bar_i * bar + s * step)
    n = int(total * SR)
    out[: len(out) - n] += out[n:]
    out = np.tanh(out[:n] * 1.2)
    return out / max(np.abs(out).max(), 1e-6) * 0.75


def music_menu():
    roots = [33, 29, 36, 31]
    chords = [[57, 60, 64], [53, 57, 60], [60, 64, 67], [55, 59, 62]]
    mel = [(0, 0, 81, 3), (0, 4, 79, 2), (0, 8, 76, 4), (1, 0, 77, 3), (1, 4, 76, 2), (1, 8, 72, 4),
           (2, 0, 79, 3), (2, 4, 76, 2), (2, 8, 72, 4), (3, 0, 74, 3), (3, 4, 71, 2), (3, 8, 67, 6)]
    return trap(128, 16, roots, chords, [(b + o, s, m, ln) for o in (0, 4, 8, 12) for b, s, m, ln in mel], hard=False)


def music_dojo():
    roots = [33, 33, 29, 31]
    chords = [[57, 60, 64], [57, 60, 64], [53, 57, 60], [55, 59, 62]]
    mel = [(0, 0, 76, 2), (0, 3, 76, 1), (0, 6, 79, 2), (0, 10, 76, 2), (0, 13, 72, 2),
           (1, 0, 74, 2), (1, 3, 74, 1), (1, 6, 76, 2), (1, 10, 72, 2), (1, 13, 69, 2),
           (2, 0, 72, 2), (2, 3, 72, 1), (2, 6, 77, 2), (2, 10, 76, 2), (2, 13, 72, 2),
           (3, 0, 74, 2), (3, 3, 71, 1), (3, 6, 74, 2), (3, 10, 79, 4)]
    return trap(140, 16, roots, chords, [(b + o, s, m, ln) for o in (0, 4, 8, 12) for b, s, m, ln in mel], hard=True)


MUSIC = {"menu": music_menu, "dojo": music_dojo}


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
    for name, fn in MUSIC.items():
        if only and name not in only:
            continue
        x = fn()
        with tempfile.TemporaryDirectory() as tmp:
            wav = Path(tmp) / "m.wav"
            write_wav(wav, x)
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "5",
                            str(OUT / "music" / f"{name}.ogg")], check=True)
        print("music", name, f"{len(x) / SR:.1f}s", flush=True)


if __name__ == "__main__":
    main()
