#!/usr/bin/env python3
"""Focused checks for the Studio II pitch, release, and retrigger model."""

from pathlib import Path
import math
import re


PIXEL_CLOCK = 1_760_229
RTL = Path(__file__).resolve().parents[1] / "rtl" / "rcastudioii.sv"
TEXT = RTL.read_text(encoding="utf-8")


def parameter(name: str) -> int:
    match = re.search(rf"{name}\s*=\s*16'd(\d+)", TEXT)
    assert match, f"could not find {name} in {RTL}"
    return int(match.group(1))


TOP = parameter("SND_HALF_TOP")
BOTTOM = parameter("SND_HALF_BOTTOM")
HOLD_TICKS = parameter("SND_HOLD_TICKS")
RETRIGGER_TOP = parameter("SND_RETRIGGER_TOP")
RECOVER_STEP = parameter("SND_RECOVER_STEP")
ATTACK_STEP = parameter("SND_ATTACK_STEP")

bands = [
    (int(limit), int(interval))
    for limit, interval in re.findall(
        r"half_period < 16'd(\d+)\) snd_decay_interval = 13'd(\d+)", TEXT
    )
]
last_interval = re.search(
    r"else\s+snd_decay_interval = 13'd(\d+)", TEXT
)
assert len(bands) >= 7 and last_interval, "could not parse decay bands"
intervals = [interval for _, interval in bands] + [int(last_interval.group(1))]


def decay_interval(half_period: int) -> int:
    for limit, interval in bands:
        if half_period < limit:
            return interval
    return intervals[-1]


def release_interval(amplitude: int) -> int:
    if amplitude >= 192:
        return 170
    if amplitude >= 128:
        return 240
    if amplitude >= 64:
        return 400
    if amplitude >= 32:
        return 800
    if amplitude >= 16:
        return 1600
    if amplitude >= 8:
        return 3200
    return 5700


class Beeper:
    def __init__(self) -> None:
        self.half = TOP
        self.drive_half = TOP
        self.curve = 0
        self.recover_count = 0
        self.hold = 0
        self.amp_count = 0
        self.amp = 0
        self.state = "recover"
        self.q_prev = False

    def tick(self, q: bool) -> None:
        previous_q = self.q_prev
        self.q_prev = q
        if not q:
            self.recover_count = 0
            self.hold = 0
            if previous_q:
                self.state = "release"
                self.amp_count = 0
            elif self.amp == 0:
                self.state = "recover"
            if self.half > TOP:
                if self.curve >= RECOVER_STEP - 1:
                    self.curve = 0
                    self.half -= 1
                else:
                    self.curve += 1
            else:
                self.curve = 0
            if self.amp:
                if not previous_q and self.amp_count >= release_interval(self.amp) - 1:
                    self.amp_count = 0
                    self.amp -= 1
                elif not previous_q:
                    self.amp_count += 1
            else:
                self.amp_count = 0
            return

        if not previous_q:
            self.recover_count = self.curve
            self.curve = 0
            self.hold = 0
            self.amp_count = 0
            self.drive_half = TOP
            self.state = "hold"
        elif self.state == "hold":
            if self.half > RETRIGGER_TOP and self.half > self.drive_half:
                if self.recover_count >= RECOVER_STEP - 1:
                    self.recover_count = 0
                    self.half -= 1
                else:
                    self.recover_count += 1
            else:
                self.recover_count = 0
            self.curve = 0
            if self.hold >= HOLD_TICKS - 1:
                self.hold = 0
                self.state = "decay"
            else:
                self.hold += 1
        elif self.state == "decay":
            if self.half > RETRIGGER_TOP and self.half > self.drive_half:
                if self.recover_count >= RECOVER_STEP - 1:
                    self.recover_count = 0
                    self.half -= 1
                else:
                    self.recover_count += 1
            else:
                self.recover_count = 0
            if self.drive_half < BOTTOM:
                if self.curve >= decay_interval(self.drive_half) - 1:
                    self.curve = 0
                    self.drive_half += 1
                    if self.drive_half - 1 >= self.half:
                        self.half = self.drive_half
                        self.recover_count = 0
                else:
                    self.curve += 1
            else:
                self.drive_half = BOTTOM
                if self.half < BOTTOM:
                    self.half = BOTTOM
                self.curve = 0

        if self.amp < 255:
            if self.amp_count >= ATTACK_STEP - 1:
                self.amp_count = 0
                self.amp += 1
            else:
                self.amp_count += 1
        else:
            self.amp_count = 0

    def run_ms(self, milliseconds: float, q: bool) -> None:
        for _ in range(round(milliseconds * PIXEL_CLOCK / 1000)):
            self.tick(q)

    @property
    def hz(self) -> float:
        if self.half == TOP:
            # The plateau alternates 1400/1401-tick half-cycles, 574/1024 long.
            return PIXEL_CLOCK / (2 * (TOP + 574 / 1024))
        # Other divider values are terminal counts, hence half+1 ticks.
        return PIXEL_CLOCK / (2 * (self.half + 1))


def check(label: str, condition: bool, detail: str) -> None:
    if not condition:
        raise AssertionError(f"{label}: {detail}")
    print(f"ok  {label}: {detail}")


check(
    "monotonic slowdown",
    all(a < b for a, b in zip(intervals, intervals[1:])),
    f"step intervals {intervals}",
)

pip = Beeper()
pip.run_ms(19.5, True)
check("19.5 ms pip", pip.half == TOP, f"{pip.hz:.2f} Hz at the principal divider")

early_descent = Beeper()
early_descent.run_ms(48, True)
check("48 ms early descent", 560 <= early_descent.hz <= 567, f"{early_descent.hz:.2f} Hz")

emphasis_100 = Beeper()
emphasis_100.run_ms(100, True)
check("100 ms emphasis", 524 <= emphasis_100.hz <= 527, f"{emphasis_100.hz:.2f} Hz")

emphasis_120 = Beeper()
emphasis_120.run_ms(120, True)
check("120 ms emphasis", 515 <= emphasis_120.hz <= 519, f"{emphasis_120.hz:.2f} Hz")

sustained = Beeper()
sustained.run_ms(211, True)
check(
    "sustained floor",
    sustained.half == BOTTOM and 505.1 <= sustained.hz <= 505.3,
    f"{sustained.hz:.2f} Hz after 211 ms",
)
check("driven amplitude", sustained.amp == 255, f"full envelope level {sustained.amp}")

soft_landing = Beeper()
soft_landing.run_ms(200, True)
check(
    "soft floor approach",
    BOTTOM - 4 <= soft_landing.half < BOTTOM and 505.7 <= soft_landing.hz <= 506.4,
    f"{soft_landing.hz:.2f} Hz with {BOTTOM - soft_landing.half} divider steps remaining at 200 ms",
)

release = Beeper()
release.run_ms(211, True)
release.tick(False)
check(
    "release entry",
    release.state == "release" and release.amp == 255,
    f"entered at {release.hz:.2f} Hz and level {release.amp}",
)
release.run_ms(40, False)
check(
    "audible upward release",
    540 <= release.hz <= 544 and 36 <= release.amp <= 42,
    f"{release.hz:.2f} Hz at level {release.amp} after 40 ms",
)
check(
    "RC-like release level",
    -17.0 <= 20 * math.log10(release.amp / 255) <= -15.5,
    f"{20 * math.log10(release.amp / 255):.1f} dB after 40 ms",
)
release.run_ms(38, False)
check(
    "quiet residual tail",
    release.amp <= 7 and 20 * math.log10(release.amp / 255) <= -30,
    f"level {release.amp} ({20 * math.log10(release.amp / 255):.1f} dB) after 78 ms",
)
release.run_ms(19, False)
check(
    "silent recovery",
    release.amp == 0 and release.state == "recover",
    f"level {release.amp}, continuing at {release.hz:.2f} Hz",
)

retrigger = Beeper()
retrigger.run_ms(120, True)
retrigger.run_ms(5, False)
instantaneous = retrigger.half
instantaneous_amp = retrigger.amp
retrigger.tick(True)
check(
    "retrigger continuity",
    retrigger.half == instantaneous
    and retrigger.amp == instantaneous_amp
    and retrigger.state == "hold",
    f"resumed at divider {retrigger.half}, level {retrigger.amp}",
)
retrigger.run_ms(2, True)
check(
    "retrigger settling",
    retrigger.half < instantaneous and retrigger.amp > instantaneous_amp,
    f"pitch recovery continued at {retrigger.hz:.2f} Hz while level rose "
    f"{instantaneous_amp}->{retrigger.amp}",
)

retrigger.run_ms(98, True)
fresh_100 = Beeper()
fresh_100.run_ms(100, True)
check(
    "non-additive retrigger",
    retrigger.half == fresh_100.half,
    f"divider {retrigger.half} rejoined fresh contour {fresh_100.half} "
    f"without stacking below live {instantaneous}",
)

concentration = Beeper()
concentration.run_ms(120, True)
first_trough_hz = concentration.hz
concentration.run_ms(12, False)
second_pulse_hz = []
for _ in range(50):
    concentration.run_ms(1, True)
    second_pulse_hz.append(concentration.hz)
second_crest_hz = max(second_pulse_hz)
principal_interval = 1200 * math.log2(second_crest_hz / 628.4)
trough_interval = 1200 * math.log2(second_crest_hz / first_trough_hz)
check(
    "Concentration second-pulse crest",
    558 <= second_crest_hz <= 562,
    f"{second_crest_hz:.2f} Hz after a representative 120/12ms retrigger",
)
check(
    "Concentration pitch windows",
    -205 <= principal_interval <= -195 and 130 <= trough_interval <= 140,
    f"{principal_interval:.1f} cents from principal, "
    f"+{trough_interval:.1f} cents from first trough",
)

rapid = Beeper()
for _ in range(4):
    rapid.run_ms(15, True)
    rapid.run_ms(35, False)
check(
    "20 Hz short pulses",
    rapid.half == TOP,
    f"remained at the {rapid.hz:.2f} Hz principal pitch",
)

cactus_spam = Beeper()
cactus_troughs = []
for _ in range(6):
    cactus_spam.run_ms(120, True)
    cactus_troughs.append(cactus_spam.half)
    cactus_spam.run_ms(40, False)
check(
    "repeated-note bound",
    all(half <= cactus_troughs[0] for half in cactus_troughs[1:]),
    f"no cumulative lowering across dividers {cactus_troughs}",
)
