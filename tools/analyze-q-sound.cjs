// Run from the repository root. Requires FFmpeg and the local captures.
const fs = require('node:fs');
const cp = require('node:child_process');
const crypto = require('node:crypto');

const dir = 'refs/mpt-02-audio/Victory sounds';
const rate = 48000;
const toneHz = 506.44;
const half = rate / (2 * toneHz);
const median = a => [...a].sort((a, b) => a - b)[Math.floor(a.length / 2)];
const hash = path => crypto.createHash('sha256').update(fs.readFileSync(path)).digest('hex');

function decode(file, filter = '') {
    const r = cp.spawnSync('ffmpeg', [
        '-v', 'error', '-i', dir + '/' + file,
        '-af', 'pan=mono|c0=c1' + filter, '-ar', String(rate),
        '-f', 'f32le', 'pipe:1'
    ], {maxBuffer: 15000000});
    if (r.status !== 0) throw Error(String(r.error || r.stderr));
    const b = r.stdout;
    return new Float32Array(b.buffer.slice(b.byteOffset, b.byteOffset + b.byteLength));
}

// Locate bursts on a separate analysis band, not on the waveform being fitted.
function bursts(x) {
    let sum = 0;
    const e = [];
    for (let i = 0; i < x.length; i++) {
        sum += x[i] * x[i];
        if (i >= 240) sum -= x[i - 240] * x[i - 240];
        if (i >= 240 && i % 48 === 0) e.push(Math.sqrt(Math.max(0, sum) / 240));
    }
    const sorted = [...e].sort((a, b) => a - b);
    const threshold = sorted[Math.floor(.95 * e.length)] * .4;
    const runs = [];
    let start = -1;
    for (let i = 0; i <= e.length; i++) {
        const on = i < e.length && e[i] > threshold;
        if (on && start < 0) start = i;
        if (!on && start >= 0) {
            if (i - start >= 5) runs.push([start + 5, i + 5]);
            start = -1;
        }
    }
    return runs;
}

// Remove a fitted offset and linear trend from both data and template.
function detrend(a) {
    const n = a.length, center = (n - 1) / 2;
    let mean = 0, slope = 0, den = 0;
    for (let i = 0; i < n; i++) {
        mean += a[i];
        slope += a[i] * (i - center);
        den += (i - center) ** 2;
    }
    mean /= n;
    slope /= den;
    return a.map((v, i) => v - mean - slope * (i - center));
}

// Residual RMS / detrended data RMS after fitting positive gain.
function residual(y, model) {
    const z = detrend(model);
    let yy = 0, zz = 0, yz = 0;
    for (let i = 0; i < y.length; i++) {
        yy += y[i] * y[i];
        zz += z[i] * z[i];
        yz += y[i] * z[i];
    }
    if (yz <= 0 || yy === 0 || zz === 0) return Infinity;
    return Math.sqrt(Math.max(0, 1 - yz * yz / (yy * zz)));
}

function fit(x, edgeMs, fc, firstRiseMs) {
    const begin = Math.round(edgeMs * 48) - 480;
    const n = 768;
    if (begin < 0 || begin + n > x.length) throw Error('Incomplete fitting window');
    const y = detrend(Array.from(x.subarray(begin, begin + n)));
    const alpha = 1 - Math.exp(-2 * Math.PI * fc / rate);
    const release = firstRiseMs !== undefined;
    let best = {error: Infinity};
    for (let shift = 0; shift <= 576; shift += 2) {
        let level = -1;
        const model = [];
        // Warm the periodic filter state before fitting a release.
        for (let i = release ? -480 : 0; i < n; i++) {
            const phase = release ? (begin + i - firstRiseMs * 48) / half : (i - shift) / half;
            const silent = release ? i >= shift : i < shift;
            const target = silent ? -1 : (((Math.floor(phase) % 2) + 2) % 2 === 0 ? 1 : -1);
            level += alpha * (target - level);
            if (i >= 0) model.push(level);
        }
        const error = residual(y, model);
        if (error < best.error) best = {error, edgeMs: (begin + shift) / 48};
    }
    return best;
}

const results = [];
for (const file of fs.readdirSync(dir).filter(f => /^victory_\d/.test(f)).sort()) {
    const x = decode(file);
    const runs = bursts(decode(file, ',highpass=f=300,lowpass=f=800'));
    if (runs.length < 3) throw Error('Insufficient bursts: ' + file);
    // Skip the first burst; fit up to eight repeated attacks and releases.
    const fits = runs.slice(1, 9).map(r => {
        const onset = fit(x, r[0], 435);
        return {
            onset: onset.error,
            square: fit(x, r[0], 100000).error,
            release: fit(x, r[1], 435, onset.edgeMs).error
        };
    });
    results.push({
        file, sha256: hash(dir + '/' + file), bursts: runs.length,
        medianPeriodMs: median(runs.slice(1).map((v, i) => v[0] - runs[i][0])),
        fittedBursts: fits.length,
        medianOnsetResidual: median(fits.map(v => v.onset)),
        medianSquareOnsetResidual: median(fits.map(v => v.square)),
        medianReleaseResidual: median(fits.map(v => v.release))
    });
}

const traces = process.argv.slice(2).map(path => {
    const edges = [...fs.readFileSync(path, 'utf8').matchAll(/^Q ([01]) frame (\d+).*tick (\d+)/gm)]
        .map(m => ({q: Number(m[1]), frame: Number(m[2]), tick: Number(m[3])}))
        .filter(v => v.frame >= 240);
    const on = [], off = [], period = [];
    for (let i = 1; i < edges.length; i++) {
        (edges[i - 1].q ? on : off).push((edges[i].tick - edges[i - 1].tick) / 1760.229);
    }
    for (let i = 2; i < edges.length; i++) {
        if (edges[i].q) period.push((edges[i].tick - edges[i - 2].tick) / 1760.229);
    }
    if (!period.length) throw Error('Insufficient trace edges: ' + path);
    const range = a => ({min: Math.min(...a), max: Math.max(...a)});
    return {path, sha256: hash(path), onMs: range(on), offMs: range(off), periodMs: range(period)};
});
console.log(JSON.stringify({sampleRate: rate, toneHz, filterHz: 435, results, traces}, null, 2));
