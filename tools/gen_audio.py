"""Synthetisiert alle Soundeffekte für Morilla Rumble (numpy/scipy, keine Fremdsamples). Musik: tools/get_music.sh.

Klangaufbau: Jeder Effekt besteht aus mehreren Schichten statt aus einem einzelnen Sinus:
  transient  kurzer Klick (Anschlag, Schärfe)
  body       modale Resonanzen (Klangkörper, Material, Gewicht)
  sub        tiefer Sinus-Sweep (Druck)
  air        gefiltertes Rauschen (Bewegung, Staub, Wind)
  tail       Faltungshall (Raum)
Dazu weiche Sättigung (tanh) für Punch. Das klingt nach Aufprall statt nach Signalgenerator.

Aufruf: python3 gen_audio.py [name ...]   (ohne Namen wird alles erzeugt)
Ausgabe: assets/audio/sfx/*.wav
"""
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np
from scipy.signal import butter, fftconvolve, sosfilt

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
    na, nr = min(int(a * SR), len(x) // 2), min(int(r * SR), len(x) // 2)
    if na > 0:
        x[:na] *= np.linspace(0, 1, na)
    if nr > 0:
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


# ------------------------------------------------------------------ Bausteine

def saturate(x, drive=1.8):
    """Weiche Sättigung: gibt Punch und Obertöne, ohne hart zu clippen."""
    return np.tanh(x * drive) / np.tanh(drive)


def _ir(sec=0.5, damp=3500):
    """Synthetische Impulsantwort: kurzes Rausch-Abklingen, tiefpassgedämpft."""
    n = max(int(sec * SR), 8)
    t = np.arange(n) / SR
    x = rng.uniform(-1, 1, n) * np.exp(-t / (sec * 0.35))
    x = lp(x, damp)
    x[: int(0.004 * SR)] = 0.0
    return x / max(np.sqrt(np.sum(x ** 2)), 1e-9)


def reverb(x, sec=0.5, mix=0.25, damp=3500):
    """Faltungshall – gibt dem Klang einen Raum, statt trocken zu stehen."""
    wet = fftconvolve(x, _ir(sec, damp))[: len(x)]
    wet *= np.sqrt(np.mean(x ** 2)) / max(np.sqrt(np.mean(wet ** 2)), 1e-9)
    return (1.0 - mix) * x + mix * wet


def modal(freqs, sec, decays, amps=None, detune=0.7):
    """Modale Resonanzen: gedämpfte Sinus-Paare = Klangkörper aus Holz, Fleisch, Metall."""
    t = tt(sec)
    if np.isscalar(decays):
        decays = [decays] * len(freqs)
    if amps is None:
        amps = [1.0 / (i + 1) for i in range(len(freqs))]
    out = np.zeros(len(t))
    for f, d, a in zip(freqs, decays, amps):
        out += a * (np.sin(TAU * f * t) + 0.7 * np.sin(TAU * (f + detune) * t)) * np.exp(-t / d)
    return out


def click(sec=0.006, fc=5000, tau=0.0015):
    """Transient: der Anschlag, der einen Aufprall erst scharf macht."""
    return hp(noise(sec), fc) * np.exp(-tt(sec) / tau)


def sub(f0, f1, sec, tau=0.12, drive=1.8):
    """Tiefer Druck-Sweep mit Sättigung."""
    return saturate(glide(f0, f1, sec), drive) * env(tt(sec), tau)


def air(sec, lo, hi, tau=0.1, attack=0.008):
    """Gefiltertes Rauschen: Luft, Staub, Stoff, Wind."""
    t = tt(sec)
    return bp(noise(sec), lo, hi) * np.exp(-t / tau) * np.minimum(t / max(attack, 1e-4), 1.0)


def sweep(sec, f0, f1, vol=1.0, q=1.5, attack=0.15, release=0.5):
    """Bewegtes Bandrauschen: ein Schwung, der durch die Frequenzen wandert."""
    t = tt(sec)
    x = noise(sec)
    n = 16
    centres = f0 * (f1 / f0) ** (np.arange(n) / (n - 1))
    out = np.zeros(len(t))
    for i, c in enumerate(centres):
        w = np.exp(-((t / sec - i / (n - 1)) / 0.22) ** 2)
        out += bp(x, c / q, c * q) * w
    e = np.minimum(t / max(attack * sec, 1e-4), 1.0) * np.exp(-np.maximum(t - attack * sec, 0.0) / (release * sec))
    return vol * out * e


def saw(f, sec, tau=0.3, bright=0.5):
    """Sägezahnartiger Ton (additiv) für Bläser und Fanfaren."""
    t = tt(sec)
    out = np.zeros(len(t))
    k = 1
    while f * k < SR / 2.2:
        out += np.sin(TAU * f * k * t) / k
        k += 1
    return out * env(t, tau) * bright


def formant(sec, f0, f1, formants=(700, 1220, 2600), tau=0.18):
    """Stimmartiger Klang: Rauschen und Gleitton durch Formantfilter."""
    t = tt(sec)
    src = noise(sec) * 0.6 + glide(f0, f1, sec) * 0.4
    out = np.zeros(len(t))
    for i, f in enumerate(formants):
        out += bp(src, f * 0.8, f * 1.25) / (i + 1)
    return out * env(t, tau) * np.minimum(t / 0.02, 1.0)


# ------------------------------------------------------------------ SFX

def sfx_jump():
    return fade(mix(sweep(0.20, 500, 2600, 0.5, attack=0.1, release=0.6),
                    sub(200, 120, 0.14, 0.06) * 0.5,
                    air(0.10, 900, 4000, 0.05) * 0.3), r=0.03)


def sfx_land():
    x = mix(sub(110, 42, 0.30, 0.10),
            modal([78, 132, 205], 0.30, [0.10, 0.07, 0.05], [1.0, 0.6, 0.35]) * 0.7,
            air(0.16, 200, 1400, 0.05) * 0.5,
            click(0.008, 2500, 0.002) * 0.4)
    return fade(reverb(saturate(x, 1.4), 0.35, 0.18, 2200), r=0.05)


def sfx_step():
    x = mix(sub(150, 80, 0.10, 0.03) * 0.7,
            modal([210, 340], 0.10, [0.03, 0.02], [1.0, 0.5]) * 0.4,
            air(0.07, 400, 2200, 0.02) * 0.35)
    return fade(x, r=0.02)


def sfx_whoosh():
    return fade(mix(sweep(0.26, 600, 3400, 0.9, attack=0.2, release=0.55),
                    air(0.26, 300, 900, 0.12) * 0.25), r=0.04)


def sfx_heavy_whoosh():
    return fade(mix(sweep(0.40, 220, 2000, 1.0, attack=0.18, release=0.6),
                    sub(90, 55, 0.35, 0.14) * 0.5,
                    air(0.40, 120, 600, 0.18) * 0.35), r=0.06)


def sfx_dash():
    return fade(mix(sweep(0.30, 400, 5200, 0.9, attack=0.08, release=0.5),
                    sub(160, 90, 0.18, 0.07) * 0.4,
                    click(0.006, 4000, 0.0015) * 0.3), r=0.04)


def sfx_hit():
    x = mix(click(0.010, 1800, 0.002) * 0.45,
            modal([118, 205, 330, 520], 0.24, [0.060, 0.045, 0.030, 0.020], [1.0, 0.75, 0.5, 0.28]) * 1.0,
            sub(140, 58, 0.22, 0.060) * 0.9,
            air(0.13, 400, 3200, 0.035) * 0.45)
    return fade(reverb(saturate(x, 1.7), 0.28, 0.16, 2200), r=0.03)


def sfx_heavy_hit():
    x = mix(click(0.014, 1400, 0.003) * 0.4,
            modal([72, 118, 190, 305], 0.48, [0.15, 0.11, 0.075, 0.05], [1.0, 0.85, 0.6, 0.32]),
            sub(98, 34, 0.45, 0.14) * 1.15,
            air(0.28, 180, 1800, 0.07) * 0.55)
    return fade(reverb(saturate(x, 1.9), 0.45, 0.22, 1800), r=0.06)


def sfx_block():
    x = mix(click(0.008, 2600, 0.0018) * 0.5,
            modal([420, 720, 1120, 1680], 0.28, [0.07, 0.05, 0.035, 0.022], [1.0, 0.65, 0.42, 0.22]) * 0.75,
            sub(120, 62, 0.16, 0.045) * 0.55,
            air(0.16, 900, 4800, 0.04) * 0.4)
    return fade(reverb(x, 0.25, 0.15, 3200), r=0.03)


def sfx_block_up():
    x = mix(air(0.14, 300, 1800, 0.05) * 0.6,
            modal([180, 300], 0.14, [0.04, 0.03], [1.0, 0.5]) * 0.4,
            click(0.006, 2000, 0.0015) * 0.3)
    return fade(x, r=0.03)


def sfx_parry():
    x = mix(click(0.008, 6000, 0.0015) * 0.7,
            modal([1320, 1980, 2640, 3960], 0.55, [0.20, 0.14, 0.09, 0.06], [1.0, 0.7, 0.45, 0.25]) * 0.8,
            air(0.10, 3000, 9000, 0.02) * 0.4)
    return fade(reverb(x, 0.6, 0.3, 6000), r=0.05)


def sfx_hurt():
    x = mix(formant(0.30, 420, 150, (720, 1180, 2500), 0.13) * 0.9,
            sub(130, 70, 0.22, 0.06) * 0.6,
            air(0.16, 500, 2600, 0.05) * 0.4)
    return fade(reverb(saturate(x, 1.5), 0.3, 0.15, 3000), r=0.04)


def sfx_death():
    x = mix(formant(0.95, 330, 60, (600, 1000, 2200), 0.42) * 0.9,
            sub(80, 34, 0.85, 0.30) * 0.9,
            at(sub(62, 30, 0.6, 0.22) * 0.6, 0.35),
            air(0.9, 150, 1200, 0.3) * 0.4)
    return fade(reverb(saturate(x, 1.4), 0.9, 0.3, 2000), r=0.12)


def sfx_enemy_swing():
    return fade(mix(sweep(0.22, 350, 1800, 0.6, attack=0.2, release=0.5),
                    air(0.22, 200, 800, 0.1) * 0.25), r=0.04)


def sfx_enemy_down():
    x = mix(sub(120, 45, 0.55, 0.18) * 0.9,
            modal([95, 160, 250], 0.55, [0.16, 0.11, 0.07], [1.0, 0.6, 0.35]) * 0.7,
            air(0.5, 200, 1500, 0.14) * 0.5)
    return fade(reverb(saturate(x, 1.5), 0.5, 0.2, 2200), r=0.08)


def sfx_grab():
    x = mix(air(0.16, 250, 1600, 0.05) * 0.7,
            modal([140, 230], 0.18, [0.05, 0.035], [1.0, 0.5]) * 0.6,
            click(0.007, 2200, 0.0018) * 0.4)
    return fade(x, r=0.03)


def sfx_strain():
    t = tt(0.6)
    wob = 1.0 + 0.05 * np.sin(TAU * 8.5 * t)
    src = glide(150, 210, 0.6) * wob * 0.5 + noise(0.6) * 0.5
    out = np.zeros(len(t))
    for i, f in enumerate((620, 1050, 2400)):
        out += bp(src, f * 0.8, f * 1.3) / (i + 1)
    out *= np.minimum(t / 0.08, 1.0) * env(t, 0.42)
    return fade(reverb(saturate(out, 1.4), 0.3, 0.12, 3000), r=0.08)


def sfx_submit():
    x = mix(modal([880, 1320, 1760], 0.6, [0.18, 0.13, 0.09], [1.0, 0.6, 0.35]) * 0.6,
            sub(110, 55, 0.28, 0.09) * 0.8,
            at(modal([1320, 1980], 0.5, [0.16, 0.1], [1.0, 0.5]) * 0.4, 0.1))
    return fade(reverb(x, 0.6, 0.28, 5000), r=0.06)


def sfx_gong():
    x = mix(click(0.012, 2500, 0.003) * 0.6,
            modal([110, 165.3, 221, 304, 447, 592], 2.6,
                  [1.7, 1.3, 1.05, 0.75, 0.5, 0.35],
                  [1.0, 0.65, 0.5, 0.35, 0.22, 0.14], detune=1.4) * 0.8,
            air(0.18, 400, 4000, 0.04) * 0.4)
    return fade(reverb(x, 1.6, 0.3, 3000), r=0.25)


def sfx_scroll():
    x = mix(air(0.28, 2200, 8000, 0.09) * 0.6,
            at(modal([1568, 2340], 0.5, [0.18, 0.1], [1.0, 0.4]) * 0.35, 0.06))
    return fade(reverb(x, 0.4, 0.2, 6000), r=0.05)


def sfx_learn():
    notes = [67, 71, 74, 79]
    parts = [at(modal([hz(m), hz(m) * 2.76, hz(m) * 5.4], 0.9, [0.35, 0.2, 0.12], [1.0, 0.4, 0.2]) * 0.45, 0.09 * i)
             for i, m in enumerate(notes)]
    return fade(reverb(mix(*parts), 0.8, 0.3, 5000), r=0.1)


def sfx_arena_start():
    x = mix(sub(75, 32, 0.8, 0.32) * 1.1,
            at(sub(70, 30, 0.7, 0.28) * 0.8, 0.3),
            sfx_gong()[: int(1.6 * SR)] * 0.5)
    return fade(reverb(x, 0.8, 0.25, 2500), r=0.12)


def sfx_arena_clear():
    notes = [60, 64, 67, 72]
    parts = [at(saw(hz(m), 0.8, 0.35, 0.35) * 0.4, 0.11 * i) for i, m in enumerate(notes)]
    return fade(reverb(mix(*parts), 0.7, 0.28, 4000), r=0.1)


def sfx_fanfare():
    seq = [(67, 0.0, 0.18), (67, 0.2, 0.18), (67, 0.4, 0.18), (72, 0.6, 0.5), (71, 1.15, 0.18), (74, 1.35, 0.9)]
    parts = [at(saw(hz(m), d + 0.35, 0.5, 0.4) * 0.4, s) for m, s, d in seq]
    parts += [at(saw(hz(74 - 12), 1.1, 0.8, 0.3) * 0.3, 1.35)]
    return fade(reverb(mix(*parts), 0.9, 0.3, 4000), r=0.15)


def sfx_ui():
    x = mix(modal([1046, 1568], 0.20, [0.05, 0.035], [1.0, 0.4]) * 0.6,
            click(0.004, 6000, 0.001) * 0.25)
    return fade(x, r=0.02)


def sfx_summon_charge():
    t = tt(0.65)
    swell = saturate(glide(170, 620, 0.65), 1.5) * (t / 0.65) ** 1.6 * 0.55
    shimmer = bp(noise(0.65), 2500, 7500) * (t / 0.65) ** 2 * 0.3
    return fade(reverb(mix(swell, shimmer), 0.5, 0.2, 6000), a=0.02, r=0.06)


def sfx_summon():
    x = mix(sub(150, 40, 0.95, 0.34),
            sweep(0.75, 260, 3200, 0.7, attack=0.15, release=0.6),
            at(modal([55, 82, 110], 1.0, [0.5, 0.35, 0.25], [1.0, 0.5, 0.3]) * 0.35, 0.05),
            air(0.9, 200, 2000, 0.3) * 0.3)
    return fade(reverb(saturate(x, 1.5), 0.9, 0.28, 3000), r=0.14)


def sfx_tentacle():
    t = tt(0.32)
    crack = hp(noise(0.05), 2600) * np.exp(-tt(0.05) / 0.010)
    slither = lp(noise(0.32), 1500) * np.exp(-t / 0.09) * (1.0 + 0.6 * np.sin(TAU * 38 * t))
    x = mix(sweep(0.24, 450, 4200, 0.8, attack=0.1, release=0.5),
            at(crack * 0.9, 0.12),
            at(slither * 0.35, 0.1))
    return fade(reverb(x, 0.3, 0.15, 4000), r=0.04)


def sfx_ink_blast():
    x = mix(sub(72, 30, 0.85, 0.30) * 1.2,
            modal([46, 78, 118], 0.9, [0.35, 0.25, 0.18], [1.0, 0.5, 0.3]) * 0.5,
            air(0.9, 250, 2200, 0.22) * 0.7,
            at(sweep(0.5, 600, 3200, 0.4, attack=0.1, release=0.5), 0.05))
    return fade(reverb(saturate(x, 1.6), 0.8, 0.26, 2500), r=0.12)


def sfx_spirit_vanish():
    x = mix(sweep(0.75, 3600, 380, 0.6, attack=0.1, release=0.6),
            glide(700, 130, 0.75) * env(tt(0.75), 0.3) * 0.35)
    return fade(reverb(x, 0.7, 0.3, 5000), r=0.1)


def sfx_bear_roar():
    """Tiefes, kehliges Brüllen des Bär-Geists: Formanten weit unten, viel Rauschen, langer Hall."""
    t = tt(1.1)
    growl = glide(96, 62, 1.1) * (1.0 + 0.35 * np.sin(TAU * 23.0 * t))
    src = growl * 0.55 + noise(1.1) * 0.45
    out = np.zeros(len(t))
    for i, f in enumerate((320, 640, 1180, 2300)):
        out += bp(src, f * 0.75, f * 1.35) / (i + 1)
    out *= np.minimum(t / 0.09, 1.0) * np.exp(-np.maximum(t - 0.35, 0.0) / 0.45)
    x = mix(saturate(out, 2.0) * 0.9,
            sub(78, 40, 0.9, 0.30) * 0.7,
            air(0.9, 180, 1600, 0.28) * 0.35)
    return fade(reverb(x, 1.0, 0.3, 2200), r=0.16)


def sfx_bear_slam():
    """Doppelter Prankenhieb auf den Boden: sehr tiefer Druck, breite Moden, viel Staub."""
    x = mix(click(0.016, 1200, 0.003) * 0.4,
            modal([48, 82, 132, 214], 0.7, [0.22, 0.16, 0.11, 0.07], [1.0, 0.8, 0.55, 0.3]),
            sub(86, 28, 0.7, 0.22) * 1.25,
            air(0.5, 140, 1500, 0.16) * 0.6)
    return fade(reverb(saturate(x, 2.0), 0.7, 0.26, 1600), r=0.1)


def sfx_menu_start():
    x = mix(sub(85, 40, 0.55, 0.22),
            modal([hz(60), hz(67), hz(72)], 0.9, [0.4, 0.35, 0.3], [1.0, 0.6, 0.4]) * 0.4,
            sweep(0.45, 400, 2600, 0.6, attack=0.15, release=0.5))
    return fade(reverb(x, 0.7, 0.25, 3500), r=0.1)


SFX = {
    "jump": sfx_jump, "land": sfx_land, "step": sfx_step, "whoosh": sfx_whoosh, "heavy_whoosh": sfx_heavy_whoosh,
    "dash": sfx_dash, "hit": sfx_hit, "heavy_hit": sfx_heavy_hit, "block": sfx_block, "block_up": sfx_block_up,
    "parry": sfx_parry, "hurt": sfx_hurt, "death": sfx_death, "enemy_swing": sfx_enemy_swing, "enemy_down": sfx_enemy_down,
    "grab": sfx_grab, "strain": sfx_strain, "submit": sfx_submit, "gong": sfx_gong, "scroll": sfx_scroll,
    "learn": sfx_learn, "arena_start": sfx_arena_start, "arena_clear": sfx_arena_clear, "fanfare": sfx_fanfare,
    "ui": sfx_ui, "summon_charge": sfx_summon_charge, "summon": sfx_summon, "tentacle": sfx_tentacle,
    "ink_blast": sfx_ink_blast, "spirit_vanish": sfx_spirit_vanish, "menu_start": sfx_menu_start,
    "bear_roar": sfx_bear_roar, "bear_slam": sfx_bear_slam,
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
