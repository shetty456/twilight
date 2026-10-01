"""Create the two small, original MVP cues using only Python's standard library."""

from math import exp, pi, sin
from pathlib import Path
from random import Random
from struct import pack
import wave


RATE = 44_100
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)


def save(name: str, samples: list[float]) -> None:
    peak = max(max(abs(s) for s in samples), 1.0)
    with wave.open(str(OUT / name), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(b"".join(pack("<h", int(s / peak * 26000)) for s in samples))


def lamp() -> list[float]:
    result = []
    for i in range(int(RATE * 1.45)):
        t = i / RATE
        attack = min(1.0, t * 90)
        bell = (
            0.65 * sin(2 * pi * 587.3 * t) * exp(-3.2 * t)
            + 0.28 * sin(2 * pi * 880.0 * t) * exp(-5.3 * t)
            + 0.16 * sin(2 * pi * 1174.7 * t) * exp(-7.0 * t)
        )
        second = max(0.0, t - 0.19)
        echo = 0.32 * sin(2 * pi * 783.99 * second) * exp(-4.1 * second) if t > 0.19 else 0
        result.append((bell + echo) * attack)
    return result


def hit() -> list[float]:
    rng = Random(9)
    result = []
    phase = 0.0
    for i in range(int(RATE * 0.42)):
        t = i / RATE
        frequency = 145 * exp(-5 * t) + 55
        phase += 2 * pi * frequency / RATE
        body = sin(phase) * exp(-15 * t)
        grit = (rng.random() * 2 - 1) * exp(-36 * t)
        result.append(0.85 * body + 0.18 * grit)
    return result


save("lamp.wav", lamp())
save("hit.wav", hit())
