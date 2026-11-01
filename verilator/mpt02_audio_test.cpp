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

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vmpt02_audio top;
    top.reset = 1;
    top.cpu_ce = 1;
    top.tone = 0;
    tick(top);
    top.reset = 0;
    top.tone = 1;

    // One time constant should complete about 63% of a full-scale step.
    int level = 0;
    for (int i = 0; i < 81; i++) level = tick(top);
    if (level < 1500 || level > 1700) return 1;
    top.cpu_ce = 0;
    for (int i = 0; i < 32; i++) if (tick(top) != level) return 1;
    top.cpu_ce = 1;
    top.tone = 0;
    const int release = tick(top);
    if (release >= level || release < level - 100) return 1;

    // Integer-period sampling avoids spectral leakage at the reference note.
    constexpr int period = 580;
    constexpr double pi = 3.14159265358979323846;
    const std::array<int, 5> harmonic = {{1, 3, 5, 7, 9}};
    const std::array<double, 4> reference = {{-16.20, -24.35, -30.54, -35.52}};
    std::array<double, 5> re = {}, im = {};
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
        std::printf("harmonic %d: %.2f dB (capture %.2f dB)\n",
                    harmonic[j], db, reference[j - 1]);
        if (std::abs(db - reference[j - 1]) > 1.2) failures++;
    }
    top.reset = 1;
    if (tick(top) != -6000) failures++;
    std::printf("MPT-02 audio: %s\n", failures ? "FAIL" : "PASS");
    return failures ? 1 : 0;
}
