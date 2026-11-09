"""Synthetisiert die Musik der Zwischensequenzen (numpy/scipy, keine Fremdsamples).

Vorher lief in jeder Szene dieselbe Levelmusik weiter (und im Intro gar keine). Jetzt bekommt jede Szene
ein eigenes, nahtlos schleifendes Stück:

  intro    dunkel, langsam, Taiko-Herzschlag und Bordun – Morillas Heimkehr ins verwüstete Dojo
  sauna    warm und ruhig, weiche Flächen, keine Trommeln – das Gespräch mit Arman
  bamboo   nächtlich, flirrend, leichte Perkussion – der Mondbambus-Hain
  quarry   kalt und weit, Stein und Metall – der Bergsteinbruch
  rescue   treibend und angespannt, schnelles Ostinato – Armans Kampf gegen den Schattenkämpfer

Aufbau wie in gen_audio.py: Pad (tiefpassgefilterter Sägezahn-Akkord), Bass, Melodie (Glocke/Pluck),
Perkussion (Taiko, Shaker) und Faltungshall. Jedes Stück wird länger gerendert als seine Schleife; der
Ausklang hinter dem Schleifenpunkt wird auf den Anfang gefaltet, damit der Übergang ohne Klick umläuft.

Aufruf: python3 gen_music.py [name ...]
Ausgabe: assets/audio/music/<name>.ogg
"""
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

from gen_audio import SR, TAU, hp, hz, lp, modal, noise, reverb, sub, tt

OUT = Path(__file__).resolve().parent.parent / "assets" / "audio" / "music"
rng = np.random.default_rng(23)

## Moll-Pentatonik: passt zu allen Szenen und klingt auch ohne Auflösung stimmig.
PENTA = [0, 3, 5, 7, 10]


def deg(root: int, d: int, octave: int = 0) -> float:
    """Frequenz des d-ten Tons der Pentatonik über dem Grundton (MIDI-Nummer)."""
    return hz(root + PENTA[d % 5] + 12 * (d // 5 + octave))


# ------------------------------------------------------------------ Klangerzeuger

def _saw(f: float, sec: float, bright: float = 0.4) -> np.ndarray:
    """Additiver Sägezahn ohne Hüllkurve (die kommt von außen)."""
    t = tt(sec)
    out = np.zeros(len(t))
    k = 1
    while f * k < SR / 2.2:
        out += np.sin(TAU * f * k * t) / k
        k += 1
    return out * bright


def _env(sec: float, attack: float, release: float, hold: float = 1.0) -> np.ndarray:
    """Halte-Hüllkurve mit weichem Ein- und Ausschwingen."""
    e = np.full(int(sec * SR), hold)
    na, nr = int(attack * SR), int(release * SR)
    if na > 0:
        e[:na] *= np.linspace(0.0, 1.0, na)
    if nr > 0:
        e[-nr:] *= np.linspace(1.0, 0.0, nr)
    return e


def _pad(freqs, sec: float, attack: float = 1.4, release: float = 1.8, bright: float = 0.3,
         detune: float = 0.7, damp: float = 2200.0) -> np.ndarray:
    """Weiche Fläche: mehrere leicht verstimmte Sägezähne, tiefpassgedämpft."""
    out = np.zeros(int(sec * SR))
    for f in freqs:
        for d in (-detune, 0.0, detune):
            out += _saw(f + d, sec, bright)
    out /= max(len(freqs) * 3, 1)
    return lp(out, damp) * _env(sec, attack, release)


def _pluck(f: float, sec: float, tau: float = 0.35, bright: float = 0.5) -> np.ndarray:
    """Gezupfter Ton (Bass, Ostinato)."""
    t = tt(sec)
    x = _saw(f, sec, bright) + 0.5 * np.sin(TAU * f * 2 * t)
    return x * np.exp(-t / tau) * np.minimum(t / 0.004, 1.0)


def _bell(f: float, sec: float, tau: float = 0.9) -> np.ndarray:
    """Glocke für die Melodie (inharmonische Teilöne wie bei einer Tempelglocke)."""
    t = tt(sec)
    return (np.sin(TAU * f * t) + 0.45 * np.sin(TAU * f * 2.76 * t) + 0.22 * np.sin(TAU * f * 5.4 * t)) \
        * np.exp(-t / tau)


def _taiko(f0: float = 72.0, sec: float = 0.5) -> np.ndarray:
    """Trommel: Druck-Sweep plus Fell-Resonanzen."""
    return sub(f0, f0 * 0.55, sec, 0.16, 1.6) + modal([f0 * 1.6, f0 * 2.4], sec, [0.12, 0.08], [0.5, 0.3]) * 0.5


def _shaker(sec: float = 0.09) -> np.ndarray:
    return hp(noise(sec), 6000) * np.exp(-tt(sec) / 0.02) * 0.5


def _metal(f: float = 900.0, sec: float = 1.2) -> np.ndarray:
    """Angeschlagener Stein/Metall für den Steinbruch."""
    return modal([f, f * 1.51, f * 2.32, f * 3.11], sec, [0.5, 0.35, 0.22, 0.14], [1.0, 0.6, 0.4, 0.25])


# ------------------------------------------------------------------ Schleifen-Renderer

class Track:
    """Sammelt Klänge auf einer Zeitachse und faltet den Ausklang in den Schleifenanfang."""

    def __init__(self, sec: float, tail: float = 3.0):
        self.sec = sec
        self.tail = tail
        self.buf = np.zeros(int((sec + tail) * SR))

    def add(self, x: np.ndarray, at_sec: float, gain: float = 1.0) -> None:
        i = int(at_sec * SR)
        if i >= len(self.buf):
            return
        n = min(len(x), len(self.buf) - i)
        self.buf[i:i + n] += x[:n] * gain

    def render(self, wet: float = 0.3, damp: float = 3200.0) -> np.ndarray:
        n = int(self.sec * SR)
        ext = reverb(self.buf, self.tail, wet, damp)
        out = ext[:n].copy()
        # Ausklang hinter dem Schleifenpunkt auf den Anfang falten: der Hall läuft weiter, statt abzureißen.
        out[: len(ext) - n] += ext[n:]
        # Naht: 25 ms aus-/einfaden. Ohne das knackt es, wenn das letzte Sample nicht auf Null liegt.
        seam = int(0.025 * SR)
        out[:seam] *= np.linspace(0.0, 1.0, seam)
        out[-seam:] *= np.linspace(1.0, 0.0, seam)
        return out / max(np.abs(out).max(), 1e-6) * 0.85


# ------------------------------------------------------------------ Stücke

def music_intro() -> np.ndarray:
    """Dunkel und langsam: Bordun, Taiko-Herzschlag, vereinzelte Glocken. 40 s."""
    sec, root = 40.0, 45  # A2
    tr = Track(sec)
    tr.add(_pad([hz(root), hz(root + 7), hz(root + 12)], sec, 3.0, 4.0, 0.22), 0.0, 0.55)
    # Herzschlag: zwei Schläge, dann Pause – wie ein Puls unter der Musik.
    t = 0.0
    while t < sec:
        tr.add(_taiko(64, 0.7), t, 0.5)
        tr.add(_taiko(58, 0.7), t + 0.42, 0.3)
        t += 2.4
    # Glockenmelodie: absteigende Figur, die sich wiederholt und leicht verschiebt.
    figure = [4, 3, 2, 0, 2, 3]
    for bar in range(5):
        for i, d in enumerate(figure):
            at = bar * 8.0 + i * 1.15
            if at < sec:
                tr.add(_bell(deg(root, d, 2), 2.4, 1.1), at, 0.3 if i % 2 else 0.42)
    # Tiefe Einzeltöne als Akzente.
    for at in (6.0, 14.0, 22.0, 30.0):
        tr.add(_pluck(deg(root, 0, 0), 2.0, 0.9, 0.35), at, 0.4)
    return tr.render(0.42, 2600)


def music_sauna() -> np.ndarray:
    """Warm und ruhig: weiche Flächen, sanfte Bassnoten, keine Trommeln. 32 s."""
    sec, root = 32.0, 48  # C3
    tr = Track(sec)
    chords = [[0, 2, 4], [0, 2, 4], [1, 3, 5], [0, 2, 4]]
    for i, ch in enumerate(chords):
        at = i * 8.0
        tr.add(_pad([deg(root, d, 1) for d in ch], 8.4, 1.6, 2.2, 0.26, 0.5, 1800), at, 0.5)
        tr.add(_pluck(deg(root, ch[0], 0), 3.0, 1.2, 0.3), at, 0.35)
    # Ruhige Melodie über den Flächen.
    melody = [(0, 2.0), (2, 3.4), (3, 4.8), (2, 6.2), (1, 9.0), (0, 10.4), (2, 12.0), (3, 13.6)]
    for d, at in melody:
        tr.add(_bell(deg(root, d, 2), 3.0, 1.4), at, 0.26)
        tr.add(_bell(deg(root, d, 2), 3.0, 1.4), at + 16.0, 0.22)
    return tr.render(0.38, 2400)


def music_bamboo() -> np.ndarray:
    """Nächtlich und flirrend: gezupfte Figur, Shaker, tiefe Fläche. 32 s."""
    sec, root = 32.0, 50  # D3
    tr = Track(sec)
    tr.add(_pad([hz(root), hz(root + 7), hz(root + 10)], sec, 2.5, 3.0, 0.2, 0.6, 1600), 0.0, 0.4)
    # Gezupfte Achtelfigur, die leicht wandert.
    pattern = [0, 2, 4, 2, 3, 2, 4, 1]
    step = 0.5
    for i in range(int(sec / step)):
        d = pattern[i % len(pattern)]
        tr.add(_pluck(deg(root, d, 1), 0.9, 0.28, 0.45), i * step, 0.22 if i % 2 else 0.3)
    # Shaker auf den Achteln, Betonung auf der Zählzeit.
    for i in range(int(sec / step)):
        tr.add(_shaker(), i * step, 0.16 if i % 2 else 0.26)
    # Bass alle zwei Takte.
    for i in range(int(sec / 4.0)):
        tr.add(_pluck(deg(root, 0, 0), 2.2, 0.8, 0.3), i * 4.0, 0.4)
    # Vereinzelte Glocken als Fernwirkung.
    for at in (5.0, 13.0, 21.0, 27.0):
        tr.add(_bell(deg(root, 4, 2), 3.0, 1.3), at, 0.2)
    return tr.render(0.34, 3000)


def music_quarry() -> np.ndarray:
    """Kalt und weit: tiefer Bordun, angeschlagener Stein, sparsame Melodie. 36 s."""
    sec, root = 36.0, 43  # G2
    tr = Track(sec)
    tr.add(_pad([hz(root), hz(root + 7), hz(root + 12), hz(root + 19)], sec, 4.0, 5.0, 0.18, 0.9, 1400), 0.0, 0.5)
    # Steinschläge in unregelmäßigem Abstand.
    for at in (2.0, 7.5, 11.0, 16.5, 21.0, 26.0, 31.5):
        tr.add(_metal(760 + rng.uniform(-90, 90), 1.6), at, 0.3)
        tr.add(_taiko(52, 0.9), at, 0.35)
    # Sehr tiefe Bassnoten als Schritte.
    for i in range(int(sec / 6.0)):
        tr.add(_pluck(deg(root, 0, 0), 3.0, 1.4, 0.28), i * 6.0, 0.42)
    # Sparsame Melodie, hohe Glocke.
    for d, at in [(4, 4.0), (3, 9.0), (2, 14.0), (4, 19.0), (3, 24.0), (1, 29.0)]:
        tr.add(_bell(deg(root, d, 2), 3.4, 1.6), at, 0.22)
    return tr.render(0.45, 2200)


def music_rescue() -> np.ndarray:
    """Treibend und angespannt: schnelles Ostinato, Taiko, aufsteigende Bläserlinie. 24 s."""
    sec, root = 24.0, 45  # A2
    tr = Track(sec)
    # Ostinato in Sechzehnteln: gibt der Szene Vorwärtsdruck.
    step = 0.125
    ost = [0, 0, 2, 0, 0, 3, 2, 0]
    for i in range(int(sec / step)):
        d = ost[i % len(ost)]
        tr.add(_pluck(deg(root, d, 0), 0.28, 0.11, 0.55), i * step, 0.3 if i % 4 else 0.42)
    # Taiko auf den Vierteln, Betonung auf 1 und 3.
    for i in range(int(sec / 0.5)):
        tr.add(_taiko(70, 0.45), i * 0.5, 0.42 if i % 4 == 0 else 0.2)
    # Fläche darüber, die Spannung hält.
    tr.add(_pad([hz(root + 12), hz(root + 19), hz(root + 24)], sec, 2.0, 2.5, 0.22, 0.8, 2000), 0.0, 0.34)
    # Aufsteigende Linie alle vier Sekunden – wie ein Countdown.
    for bar in range(int(sec / 4.0)):
        for i, d in enumerate([2, 3, 4, 5]):
            tr.add(_bell(deg(root, d, 2), 1.6, 0.7), bar * 4.0 + i * 0.5, 0.24)
    # Becken-artiger Akzent am Anfang jedes Achttakters.
    for at in (0.0, 8.0, 16.0):
        tr.add(_metal(1200, 2.0), at, 0.22)
    return tr.render(0.3, 3400)


MUSIC = {
    "intro": music_intro,
    "sauna": music_sauna,
    "bamboo": music_bamboo,
    "quarry": music_quarry,
    "rescue": music_rescue,
}


def write_ogg(path: Path, x: np.ndarray) -> None:
    """WAV zwischenspeichern und als Vorbis kodieren (Godot lädt .ogg direkt)."""
    import wave
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav = Path(tmp.name)
    x16 = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(wav), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(x16.tobytes())
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "5",
                    str(path)], check=True)
    wav.unlink(missing_ok=True)


def main() -> None:
    only = set(sys.argv[1:])
    for name, fn in MUSIC.items():
        if only and name not in only:
            continue
        x = fn()
        out = OUT / f"{name}.ogg"
        write_ogg(out, x)
        print("music", name, "%.1fs" % (len(x) / SR), out, flush=True)


if __name__ == "__main__":
    main()
