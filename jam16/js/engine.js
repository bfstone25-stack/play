// Minimal jam engine: fixed-step loop, DPR-correct canvas, unified input,
// WebAudio blips, scene stack, screenshake and particles.
// Theme-independent on purpose — gameplay goes in game.js.

export const TICK = 1 / 60;

export class Engine {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.scenes = [];
    this.time = 0;
    this.accumulator = 0;
    this.shake = 0;
    this.particles = [];
    this.paused = false;
    this.input = new Input(canvas);
    this.audio = new Audio();
    this.view = { w: 360, h: 640, scale: 1 };

    addEventListener('resize', () => this.resize());
    addEventListener('blur', () => { this.paused = true; });
    addEventListener('focus', () => { this.paused = false; this.last = performance.now(); });
    this.resize();
  }

  // Letterboxed portrait-first design space so phones and desktop share code.
  resize() {
    const dpr = Math.min(devicePixelRatio || 1, 2);
    const w = innerWidth, h = innerHeight;
    const scale = Math.min(w / this.view.w, h / this.view.h);
    this.view.scale = scale;
    this.canvas.width = Math.floor(w * dpr);
    this.canvas.height = Math.floor(h * dpr);
    this.canvas.style.width = w + 'px';
    this.canvas.style.height = h + 'px';
    this.offset = { x: (w - this.view.w * scale) / 2, y: (h - this.view.h * scale) / 2 };
    this.dpr = dpr;
    this.input.setTransform(this.offset, scale);
  }

  push(scene) { scene.engine = this; this.scenes.push(scene); scene.enter?.(); }
  pop() { this.scenes.pop()?.exit?.(); }
  replace(scene) { this.pop(); this.push(scene); }
  get scene() { return this.scenes[this.scenes.length - 1]; }

  kick(amount = 6) { this.shake = Math.max(this.shake, amount); }

  burst(x, y, count = 12, color = '#fff') {
    for (let i = 0; i < count; i++) {
      const a = Math.random() * Math.PI * 2;
      const s = 40 + Math.random() * 160;
      this.particles.push({
        x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s,
        life: 0.3 + Math.random() * 0.5, age: 0, color,
      });
    }
  }

  start() {
    this.last = performance.now();
    const frame = (now) => {
      const dt = Math.min((now - this.last) / 1000, 0.25);
      this.last = now;
      if (!this.paused) {
        this.accumulator += dt;
        while (this.accumulator >= TICK) {
          this.step(TICK);
          this.accumulator -= TICK;
        }
      }
      this.draw();
      requestAnimationFrame(frame);
    };
    requestAnimationFrame(frame);
  }

  step(dt) {
    this.time += dt;
    this.shake *= 0.86;
    for (const p of this.particles) {
      p.age += dt; p.x += p.vx * dt; p.y += p.vy * dt; p.vy += 900 * dt;
    }
    this.particles = this.particles.filter((p) => p.age < p.life);
    this.scene?.update?.(dt);
    this.input.endFrame();
  }

  draw() {
    const { ctx, view } = this;
    ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
    ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    const sx = (Math.random() - 0.5) * this.shake;
    const sy = (Math.random() - 0.5) * this.shake;
    ctx.save();
    ctx.translate(this.offset.x + sx, this.offset.y + sy);
    ctx.scale(view.scale, view.scale);
    ctx.beginPath();
    ctx.rect(0, 0, view.w, view.h);
    ctx.clip();
    this.scene?.render?.(ctx);
    for (const p of this.particles) {
      ctx.globalAlpha = Math.max(0, 1 - p.age / p.life);
      ctx.fillStyle = p.color;
      ctx.fillRect(p.x - 2, p.y - 2, 4, 4);
    }
    ctx.globalAlpha = 1;
    ctx.restore();
  }
}

class Input {
  constructor(canvas) {
    this.keys = new Set();
    this.pressed = new Set();
    this.pointer = { x: 0, y: 0, down: false, justDown: false, justUp: false };
    this.offset = { x: 0, y: 0 };
    this.scale = 1;

    addEventListener('keydown', (e) => {
      if (!this.keys.has(e.code)) this.pressed.add(e.code);
      this.keys.add(e.code);
      if (['Space', 'ArrowUp', 'ArrowDown'].includes(e.code)) e.preventDefault();
    });
    addEventListener('keyup', (e) => this.keys.delete(e.code));

    const move = (e) => {
      const t = e.touches ? e.touches[0] : e;
      if (!t) return;
      this.pointer.x = (t.clientX - this.offset.x) / this.scale;
      this.pointer.y = (t.clientY - this.offset.y) / this.scale;
    };
    canvas.addEventListener('pointerdown', (e) => {
      move(e); this.pointer.down = true; this.pointer.justDown = true;
    });
    canvas.addEventListener('pointermove', move);
    addEventListener('pointerup', () => {
      this.pointer.down = false; this.pointer.justUp = true;
    });
    canvas.addEventListener('touchstart', (e) => e.preventDefault(), { passive: false });
  }

  setTransform(offset, scale) { this.offset = offset; this.scale = scale; }
  down(code) { return this.keys.has(code); }
  hit(code) { return this.pressed.has(code); }
  get tap() { return this.pointer.justDown; }
  endFrame() {
    this.pressed.clear();
    this.pointer.justDown = false;
    this.pointer.justUp = false;
  }
}

class Audio {
  constructor() { this.ctx = null; this.muted = false; }

  // Browsers require a gesture before audio; call from first input.
  unlock() {
    if (!this.ctx) this.ctx = new (window.AudioContext || window.webkitAudioContext)();
    if (this.ctx.state === 'suspended') this.ctx.resume();
  }

  blip(freq = 440, dur = 0.08, type = 'square', gain = 0.12) {
    if (this.muted || !this.ctx) return;
    const osc = this.ctx.createOscillator();
    const amp = this.ctx.createGain();
    osc.type = type;
    osc.frequency.value = freq;
    amp.gain.setValueAtTime(gain, this.ctx.currentTime);
    amp.gain.exponentialRampToValueAtTime(0.0001, this.ctx.currentTime + dur);
    osc.connect(amp).connect(this.ctx.destination);
    osc.start();
    osc.stop(this.ctx.currentTime + dur);
  }

  arpeggio(notes, step = 0.07) {
    notes.forEach((n, i) => setTimeout(() => this.blip(n, 0.1, 'triangle'), i * step * 1000));
  }
}

export const save = {
  read(key, fallback = null) {
    try { return JSON.parse(localStorage.getItem(key)) ?? fallback; }
    catch { return fallback; }
  },
  write(key, value) {
    try { localStorage.setItem(key, JSON.stringify(value)); } catch { /* private mode */ }
  },
};
