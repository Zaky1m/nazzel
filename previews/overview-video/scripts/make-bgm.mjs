// Synthesizes the background bed: a warm minor-key pad, a plucked arpeggio
// and a soft beat at 104 BPM, shaped to the film's sections from src/timing.json.
// Everything is seeded, so the same timing always yields the same file.
//
//   node scripts/make-bgm.mjs   ->  public/bgm/bed.wav (then encoded to mp3)
// Copied from previews/requests-video; only the timing source and output folder differ.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const T = JSON.parse(readFileSync(join(ROOT, "src", "timing.json"), "utf8"));

const RATE = 44100;
const LEN = T.duration;
const N = Math.ceil(LEN * RATE);
const L = new Float32Array(N);
const R = new Float32Array(N);

const BPM = 104;
const BEAT = 60 / BPM;
const BAR = BEAT * 4;

let seed = 1234567;
function rand() {
  seed = (seed * 1664525 + 1013904223) >>> 0;
  return seed / 4294967296;
}

const midi = (m) => 440 * Math.pow(2, (m - 69) / 12);
// Am9 - Fmaj7 - Cadd9 - G6, two bars each.
const CHORDS = [
  [57, 60, 64, 67, 71],
  [53, 57, 60, 64, 69],
  [48, 55, 60, 62, 64],
  [55, 59, 62, 64, 67],
];
const chordAt = (t) => CHORDS[Math.floor(t / (BAR * 2)) % CHORDS.length];

// Section energy: pad alone for the intro and the logo, the groove in between.
function groove(t) {
  const a = T.introOut - 0.4, b = T.outLogo - 0.2;
  if (t < a || t > b + 2) return 0;
  const inn = Math.min(1, (t - a) / 1.2);
  const out = t > b ? Math.max(0, 1 - (t - b) / 2) : 1;
  return inn * out;
}
function master(t) {
  const fadeIn = Math.min(1, t / 1.5);
  const fadeOut = Math.min(1, (LEN - t) / 2.6);
  return fadeIn * Math.max(0, fadeOut);
}

// Kick sidechain: pad and plucks dip right after each kick.
function duck(t) {
  if (groove(t) === 0) return 1;
  const ph = t % (BEAT * 2);
  return 1 - 0.45 * groove(t) * Math.exp(-ph * 9);
}

// ---- pad: detuned additive voices through a smoothed crossfade per chord ----
for (let i = 0; i < N; i++) {
  const t = i / RATE;
  const pos = t / (BAR * 2);
  const idx = Math.floor(pos);
  const frac = pos - idx;
  const cur = CHORDS[idx % CHORDS.length];
  const prev = CHORDS[(idx + CHORDS.length - 1) % CHORDS.length];
  const xf = Math.min(1, frac * (BAR * 2) / 0.6);
  let l = 0, r = 0;
  for (const [notes, w] of [[cur, xf], [prev, 1 - xf]]) {
    if (w <= 0) continue;
    notes.forEach((m, k) => {
      const f = midi(m);
      const det = 1 + (k % 2 ? 0.0025 : -0.0025);
      const v =
        Math.sin(2 * Math.PI * f * t) +
        0.35 * Math.sin(2 * Math.PI * f * det * 2 * t + k) +
        0.12 * Math.sin(2 * Math.PI * f * 3 * t + 2 * k);
      const pan = (k / (notes.length - 1)) * 0.6 - 0.3;
      l += v * w * (0.5 - pan);
      r += v * w * (0.5 + pan);
    });
  }
  const lfo = 0.85 + 0.15 * Math.sin(2 * Math.PI * 0.11 * t);
  const g = 0.05 * lfo * duck(t);
  L[i] += l * g;
  R[i] += r * g;
}

// ---- plucks: Karplus-Strong 8th-note arpeggio ----
function pluck(start, freq, amp, pan) {
  const period = Math.max(2, Math.round(RATE / freq));
  const buf = new Float32Array(period);
  for (let k = 0; k < period; k++) buf[k] = rand() * 2 - 1;
  const len = Math.floor(RATE * 1.4);
  const s0 = Math.floor(start * RATE);
  let p = 0;
  for (let k = 0; k < len && s0 + k < N; k++) {
    const nxt = (p + 1) % period;
    const v = buf[p];
    buf[p] = 0.4985 * (buf[p] + buf[nxt]);
    p = nxt;
    const env = Math.min(1, k / 40);
    const out = v * amp * env * duck((s0 + k) / RATE);
    L[s0 + k] += out * (0.5 - pan);
    R[s0 + k] += out * (0.5 + pan);
  }
}
const ARP = [0, 2, 4, 3, 1, 3, 4, 2];
for (let t = 0, n = 0; t < LEN; t += BEAT / 2, n++) {
  const g = groove(t);
  const g2 = Math.max(g, t > T.introIn && t < T.introOut ? 0.35 : 0);
  if (g2 <= 0) continue;
  const chord = chordAt(t);
  const m = chord[ARP[n % ARP.length]] + 12;
  const accent = n % 4 === 0 ? 1 : 0.7;
  pluck(t, midi(m), 0.16 * g2 * accent, n % 2 ? 0.25 : -0.25);
}

// ---- drums ----
function kick(start, amp) {
  const s0 = Math.floor(start * RATE);
  for (let k = 0; k < RATE * 0.45 && s0 + k < N; k++) {
    const t = k / RATE;
    const f = 45 + 80 * Math.exp(-t * 28);
    const ph = 2 * Math.PI * (45 * t + (80 / 28) * (1 - Math.exp(-t * 28)));
    const v = Math.sin(ph) * Math.exp(-t * 7) * amp;
    L[s0 + k] += v;
    R[s0 + k] += v;
    void f;
  }
}
function hat(start, amp, decay) {
  const s0 = Math.floor(start * RATE);
  let prev = 0;
  for (let k = 0; k < RATE * 0.2 && s0 + k < N; k++) {
    const n = rand() * 2 - 1;
    const hp = n - prev;
    prev = n;
    const v = hp * Math.exp(-(k / RATE) * decay) * amp;
    L[s0 + k] += v * 0.8;
    R[s0 + k] += v;
  }
}
function snap(start, amp) {
  const s0 = Math.floor(start * RATE);
  let lp = 0;
  for (let k = 0; k < RATE * 0.25 && s0 + k < N; k++) {
    const t = k / RATE;
    lp += 0.35 * (rand() * 2 - 1 - lp);
    const body = Math.sin(2 * Math.PI * 185 * t) * Math.exp(-t * 30);
    const v = (lp * Math.exp(-t * 18) * 0.9 + body * 0.5) * amp;
    L[s0 + k] += v;
    R[s0 + k] += v;
  }
}
for (let b = 0; b * BEAT < LEN; b++) {
  const t = b * BEAT;
  const g = groove(t);
  if (g <= 0) continue;
  if (b % 2 === 0) kick(t, 0.55 * g);
  if (b % 2 === 1) snap(t, 0.16 * g);
  hat(t + BEAT / 2, 0.05 * g, 60);
  if (b % 4 === 3) hat(t + BEAT * 0.75, 0.03 * g, 70);
}

// ---- sub bass on chord roots ----
for (let i = 0; i < N; i++) {
  const t = i / RATE;
  const g = groove(t);
  if (g <= 0) continue;
  const root = chordAt(t)[0] - 12;
  const ph = (t % BEAT) / BEAT;
  const env = Math.min(1, ph * 20) * Math.exp(-ph * 1.6);
  const v = Math.sin(2 * Math.PI * midi(root) * t) * 0.16 * g * env * duck(t);
  L[i] += v;
  R[i] += v;
}

// ---- master: gentle saturation, fades, normalize to -3 dBFS ----
let peak = 0;
for (let i = 0; i < N; i++) {
  const m = master(i / RATE);
  L[i] = Math.tanh(L[i] * 1.2) * m;
  R[i] = Math.tanh(R[i] * 1.2) * m;
  peak = Math.max(peak, Math.abs(L[i]), Math.abs(R[i]));
}
const norm = 0.708 / peak;
const data = Buffer.alloc(N * 4);
for (let i = 0; i < N; i++) {
  data.writeInt16LE(Math.round(Math.max(-1, Math.min(1, L[i] * norm)) * 32767), i * 4);
  data.writeInt16LE(Math.round(Math.max(-1, Math.min(1, R[i] * norm)) * 32767), i * 4 + 2);
}
const head = Buffer.alloc(44);
head.write("RIFF", 0);
head.writeUInt32LE(36 + data.length, 4);
head.write("WAVE", 8);
head.write("fmt ", 12);
head.writeUInt32LE(16, 16);
head.writeUInt16LE(1, 20);
head.writeUInt16LE(2, 22);
head.writeUInt32LE(RATE, 24);
head.writeUInt32LE(RATE * 4, 28);
head.writeUInt16LE(4, 32);
head.writeUInt16LE(16, 34);
head.write("data", 36);
head.writeUInt32LE(data.length, 40);
mkdirSync(join(ROOT, "public", "bgm"), { recursive: true });
const out = join(ROOT, "public", "bgm", "bed.wav");
writeFileSync(out, Buffer.concat([head, data]));
console.log(`wrote ${out} (${LEN}s)`);
