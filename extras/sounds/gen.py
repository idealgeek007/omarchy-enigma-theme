#!/usr/bin/env python3
"""Synthesize the Enigma theme's UI sounds -- Nothing-phone-style: clean,
soft, quick. Everything here is generated math (sine blips + FFT-filtered
noise), never a sample. Run with `python3 -I gen.py [outdir]`.

Output: 48 kHz, 16-bit mono WAV, peak normalized to -12 dBFS, with fades on
every segment so nothing clicks at its edges.
"""
import math
import os
import sys
import wave

import numpy as np

SR = 48000
PEAK = 10 ** (-12 / 20)  # -12 dBFS in linear amplitude, ~0.251
# Fixed seed: the noise bursts (screenshot shutter, volume tick) are
# reproducible byte-for-byte across runs, same as the pure-tone blips already are.
RNG = np.random.default_rng(20261121)


def ms(n_samples):
    return n_samples / SR * 1000


def fade(n, ms_in, ms_out):
    """Linear in/out envelope, length n samples. Applied on top of whatever
    decay shape a segment already has -- this only kills onset/offset clicks."""
    env = np.ones(n)
    n_in = min(n, max(1, int(SR * ms_in / 1000)))
    n_out = min(n - n_in, max(1, int(SR * ms_out / 1000)))
    env[:n_in] *= np.linspace(0.0, 1.0, n_in, endpoint=False)
    if n_out > 0:
        env[-n_out:] *= np.linspace(1.0, 0.0, n_out, endpoint=True)
    return env


def exp_decay(n, tau_ms):
    t = np.arange(n) / SR
    return np.exp(-t / (tau_ms / 1000))


def silence(dur_ms):
    return np.zeros(int(SR * dur_ms / 1000))


def blip(freq, dur_ms, tau_ms, harmonic_ratio=2.0, harmonic_amp=0.18):
    """A clean glassy tone: fundamental + a soft quiet harmonic, quick attack,
    smooth exponential decay."""
    n = int(SR * dur_ms / 1000)
    t = np.arange(n) / SR
    sig = (np.sin(2 * np.pi * freq * t)
           + harmonic_amp * np.sin(2 * np.pi * freq * harmonic_ratio * t))
    sig *= exp_decay(n, tau_ms)
    sig *= fade(n, 1.5, min(6.0, dur_ms * 0.3))
    return sig


def bandpass_noise(dur_ms, f_lo, f_hi):
    """White noise restricted to [f_lo, f_hi] Hz via a hard FFT-domain mask --
    no scipy needed, just rfft/irfft."""
    n = int(SR * dur_ms / 1000)
    noise = RNG.standard_normal(n)
    spec = np.fft.rfft(noise)
    freqs = np.fft.rfftfreq(n, d=1 / SR)
    spec[(freqs < f_lo) | (freqs > f_hi)] = 0
    return np.fft.irfft(spec, n)


def normalize(sig, peak=PEAK):
    m = np.max(np.abs(sig))
    if m < 1e-9:
        return sig
    return sig / m * peak


def mix(*parts, pad_to=None):
    """Sum same-length-or-shorter signals placed at sample offset 0, or a
    list of (offset_samples, signal) pairs."""
    n = max((off + len(s)) for off, s in parts)
    if pad_to:
        n = max(n, pad_to)
    out = np.zeros(n)
    for off, s in parts:
        out[off:off + len(s)] += s
    return out


# ------------------------------------------------------------------ sounds

def notification():
    # Two quick glassy blips, rising: ~1320 Hz then ~1760 Hz.
    a = blip(1320, 95, 45, harmonic_amp=0.18)
    b = blip(1760, 130, 55, harmonic_amp=0.18)
    sig = np.concatenate([a, silence(20), b])
    return normalize(sig)


def notification_critical():
    # Three slightly lower, firmer blips -- a bigger harmonic and a shorter
    # decay read as firmer than the soft two-note notification chime.
    a = blip(880, 95, 32, harmonic_amp=0.26)
    b = blip(990, 95, 32, harmonic_amp=0.26)
    c = blip(1100, 140, 40, harmonic_amp=0.26)
    sig = np.concatenate([a, silence(26), b, silence(26), c])
    return normalize(sig)


def volume_tick():
    # A tiny dry tick: a very short high pop with almost no ring, plus a
    # trace of filtered noise so it reads as mechanical rather than musical.
    n = int(SR * 40 / 1000)
    tone = blip(2400, 40, 4.0, harmonic_amp=0.08)
    noise = bandpass_noise(40, 3000, 9000) * exp_decay(n, 3.0)
    sig = tone + 0.35 * noise
    sig *= fade(n, 0.5, 6)
    return normalize(sig)


def screenshot():
    # A soft digital "shutter": a short filtered-noise burst (the "click"),
    # overlapped just after it starts by a high blip (the "chirp").
    noise_dur = 70
    n_noise = int(SR * noise_dur / 1000)
    noise = bandpass_noise(noise_dur, 1200, 5000)
    noise *= exp_decay(n_noise, 16)
    noise *= fade(n_noise, 1, 12)

    blip_sig = blip(2200, 140, 42, harmonic_amp=0.15)
    overlap_ms = 22
    overlap_n = int(SR * overlap_ms / 1000)

    sig = mix((0, noise), (overlap_n, blip_sig))
    return normalize(sig)


# ------------------------------------------------------------------ write

def write_wav(path, sig):
    sig = np.clip(sig, -1.0, 1.0)
    pcm = (sig * 32767.0).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    peak = float(np.max(np.abs(sig)))
    peak_dbfs = 20 * math.log10(peak) if peak > 0 else float("-inf")
    print(f"{os.path.basename(path):28s} {SR} Hz 16-bit mono  {ms(len(sig)):6.1f} ms  "
          f"peak {peak_dbfs:6.2f} dBFS  first={int(pcm[0]):6d} last={int(pcm[-1]):6d}")


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "out")
    os.makedirs(out_dir, exist_ok=True)
    sounds = {
        "notification.wav": notification(),
        "notification-critical.wav": notification_critical(),
        "volume.wav": volume_tick(),
        "screenshot.wav": screenshot(),
    }
    for name, sig in sounds.items():
        write_wav(os.path.join(out_dir, name), sig)


if __name__ == "__main__":
    main()
