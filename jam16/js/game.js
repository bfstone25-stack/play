// Placeholder gameplay proving the engine API end to end.
// Replace TitleScene/PlayScene bodies once the jam theme is announced.

import { Engine, save } from './engine.js';

const W = 360, H = 640;
const BEST_KEY = 'jam16.best';

class TitleScene {
  enter() { this.t = 0; }
  update(dt) {
    this.t += dt;
    const { input, audio } = this.engine;
    if (input.tap || input.hit('Space')) {
      audio.unlock();
      audio.arpeggio([440, 554, 659]);
      this.engine.replace(new PlayScene());
    }
  }
  render(ctx) {
    ctx.fillStyle = '#0d0b1a';
    ctx.fillRect(0, 0, W, H);
    ctx.fillStyle = '#e8e3ff';
    ctx.textAlign = 'center';
    ctx.font = 'bold 34px system-ui, sans-serif';
    ctx.fillText('JAM SKELETON', W / 2, H * 0.38);
    ctx.font = '15px system-ui, sans-serif';
    ctx.globalAlpha = 0.6 + 0.4 * Math.sin(this.t * 3);
    ctx.fillText('tap or press space', W / 2, H * 0.52);
    ctx.globalAlpha = 1;
    const best = save.read(BEST_KEY, 0);
    if (best) ctx.fillText(`best ${best}`, W / 2, H * 0.62);
  }
}

class PlayScene {
  enter() {
    this.score = 0;
    this.player = { x: W / 2, y: H - 110, r: 18 };
    this.targets = [];
    this.spawn = 0;
    this.over = false;
  }

  update(dt) {
    if (this.over) {
      if (this.engine.input.tap) this.engine.replace(new TitleScene());
      return;
    }
    const { input, audio } = this.engine;

    const target = input.pointer.down ? input.pointer.x : this.player.x;
    if (input.down('ArrowLeft')) this.player.x -= 420 * dt;
    if (input.down('ArrowRight')) this.player.x += 420 * dt;
    this.player.x += (target - this.player.x) * Math.min(1, dt * 12);
    this.player.x = Math.max(20, Math.min(W - 20, this.player.x));

    this.spawn -= dt;
    if (this.spawn <= 0) {
      this.spawn = Math.max(0.25, 0.9 - this.score * 0.01);
      this.targets.push({
        x: 30 + Math.random() * (W - 60), y: -20,
        v: 150 + Math.random() * 120 + this.score * 3,
      });
    }

    for (const t of this.targets) t.y += t.v * dt;

    for (const t of this.targets) {
      const dx = t.x - this.player.x, dy = t.y - this.player.y;
      if (Math.hypot(dx, dy) < this.player.r + 12) {
        t.dead = true;
        this.score += 1;
        this.engine.kick(5);
        this.engine.burst(t.x, t.y, 14, '#7cf7c4');
        audio.blip(520 + this.score * 8, 0.06);
      } else if (t.y > H + 30) {
        t.dead = true;
        this.fail();
      }
    }
    this.targets = this.targets.filter((t) => !t.dead);
  }

  fail() {
    this.over = true;
    this.engine.kick(14);
    this.engine.audio.blip(120, 0.3, 'sawtooth');
    const best = save.read(BEST_KEY, 0);
    if (this.score > best) save.write(BEST_KEY, this.score);
  }

  render(ctx) {
    ctx.fillStyle = '#11102a';
    ctx.fillRect(0, 0, W, H);

    for (const t of this.targets) {
      ctx.fillStyle = '#7cf7c4';
      ctx.beginPath();
      ctx.arc(t.x, t.y, 12, 0, Math.PI * 2);
      ctx.fill();
    }

    ctx.fillStyle = '#ffd166';
    ctx.beginPath();
    ctx.arc(this.player.x, this.player.y, this.player.r, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = '#fff';
    ctx.textAlign = 'left';
    ctx.font = 'bold 22px system-ui, sans-serif';
    ctx.fillText(String(this.score), 18, 40);

    if (this.over) {
      ctx.fillStyle = 'rgba(6,5,16,0.82)';
      ctx.fillRect(0, 0, W, H);
      ctx.fillStyle = '#fff';
      ctx.textAlign = 'center';
      ctx.font = 'bold 30px system-ui, sans-serif';
      ctx.fillText(`${this.score}`, W / 2, H * 0.44);
      ctx.font = '15px system-ui, sans-serif';
      ctx.fillText('tap to continue', W / 2, H * 0.54);
    }
  }
}

const engine = new Engine(document.getElementById('game'));
engine.view.w = W;
engine.view.h = H;
engine.resize();
engine.push(new TitleScene());
engine.start();
