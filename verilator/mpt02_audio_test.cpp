#include "Vmpt02_audio.h"
#include "verilated.h"

#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>

static int tick(Vmpt02_audio& top) {
    top.clk = 0;
    top.eval();
    top.clk = 1;
    top.eval();
    return static_cast<int16_t>(top.audio);
}

static void restart(Vmpt02_audio& top, int filter) {
    top.filter = filter;
    top.reset = 1;
    top.cpu_ce = 1;
    top.tone = 0;
    tick(top);
    top.reset = 0;
}

// One time constant should complete about 63% of a full-scale step.
static int check_step(Vmpt02_audio& top, int filter, int cycles, int lo, int hi) {
    restart(top, filter);
    top.tone = 1;
    int level = 0;
    for (int i = 0; i < cycles; i++) level = tick(top);
    if (level < lo || level > hi) {
        std::printf("filter %d: step %d after %d cycles\n", filter, level, cycles);
        return 1;
    }
    top.cpu_ce = 0;
    for (int i = 0; i < 32; i++) if (tick(top) != level) return 1;
    top.cpu_ce = 1;
    top.tone = 0;
    const int release = tick(top);
    if (release >= level || release < level - 1000) return 1;
    return 0;
}

// Integer-period sampling avoids spectral leakage at the reference note.
static int check_harmonics(Vmpt02_audio& top, int filter, int period,
                           const std::array<double, 4>& reference, const char* source) {
    constexpr double pi = 3.14159265358979323846;
    const std::array<int, 5> harmonic = {{1, 3, 5, 7, 9}};
    std::array<double, 5> re = {}, im = {};
    restart(top, filter);
    for (int i = 0; i < period * 66; i++) {
        top.tone = (i % period) < period / 2;
        const int sample = tick(top);
        if (i < period * 2) continue;
        if (sample < -6001 || sample > 6000) return 1;
        for (unsigned j = 0; j < harmonic.size(); j++) {
            const double phase = 2 * pi * harmonic[j] * (i % period) / period;
            re[j] += sample * std::cos(phase);
            im[j] += sample * std::sin(phase);
        }
    }
    int failures = 0;
    const double fundamental = std::hypot(re[0], im[0]);
    for (unsigned j = 1; j < harmonic.size(); j++) {
        const double db = 20 * std::log10(std::hypot(re[j], im[j]) / fundamental);
        std::printf("filter %d harmonic %d: %.2f dB (%s %.2f dB)\n",
                    filter, harmonic[j], db, source, reference[j - 1]);
        if (std::abs(db - reference[j - 1]) > 1.2) failures++;
    }
    return failures;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vmpt02_audio top;
    int failures = 0;

    // Filter 0, MPT-02: 434.4 Hz pole, tau about 81 machine cycles.
    failures += check_step(top, 0, 81, 1500, 1700);
    // Filter 1, Apollo 80: 2576 Hz pole, tau about 14 machine cycles.
    failures += check_step(top, 1, 14, 1600, 1800);

    // MPT-02 reference: FliP's captures near 379.3 Hz (580 cycles at 220029 Hz).
    failures += check_harmonics(top, 0, 580, {{-16.20, -24.35, -30.54, -35.52}}, "MPT-02 capture");
    // Apollo 80 reference: TLD1985 default tone, 506.3 Hz (432 cycles is 509.3 Hz).
    failures += check_harmonics(top, 1, 432, {{-10.7, -17.0, -21.2, -24.5}}, "Apollo 80 capture");
    // Off: the unfiltered square wave.
    failures += check_harmonics(top, 2, 432, {{-9.54, -13.98, -16.90, -19.08}}, "square");

    // Off follows the tone on the next clock, even without a machine-cycle enable.
    restart(top, 2);
    top.cpu_ce = 0;
    top.tone = 1;
    if (tick(top) != 6000) failures++;
    top.tone = 0;
    if (tick(top) != -6000) failures++;

    top.reset = 1;
    if (tick(top) != -6000) failures++;
    std::printf("MPT-02 audio: %s\n", failures ? "FAIL" : "PASS");
    return failures ? 1 : 0;
}
