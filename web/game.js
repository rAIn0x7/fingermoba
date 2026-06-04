/* FingerMOBA → 幸存者生存(Survivor.io 风)。Phaser,纯形状,秒开。
   单手走位(按住朝手指方向 / WASD)+ 自动开火 + 怪潮 + 升级三选一 + 越活越强。 */
const W = 540, H = 960;

class Game extends Phaser.Scene {
  constructor() { super('game'); }

  create() {
    this.over = false; this.paused = false;
    this.enemies = []; this.projs = []; this.gems = [];
    this.elapsed = 0; this.kills = 0; this.level = 1; this.xp = 0; this.xpNeed = 5;
    this.fireT = 0; this.spawnT = 0.5;
    this.stats = { dmg: 16, fireCd: 0.55, projSpeed: 540, projCount: 1, pierce: 0, moveSpeed: 235, pickup: 78 };

    this.add.rectangle(W/2, H/2, W, H, 0x0b1020).setDepth(-2);
    for (let gx = 60; gx < W; gx += 60) this.add.rectangle(gx, H/2, 1, H, 0x16203a).setDepth(-1);
    for (let gy = 60; gy < H; gy += 60) this.add.rectangle(W/2, gy, W, 1, 0x16203a).setDepth(-1);

    this.player = { x: W/2, y: H/2, r: 15, hp: 100, maxHp: 100 };
    this.player.obj = this.add.circle(this.player.x, this.player.y, 15, 0x3aa0ff).setStrokeStyle(3, 0xffffff).setDepth(5);

    // 输入:按住朝手指方向移动 / WASD
    this.keys = this.input.keyboard.addKeys('W,A,S,D,UP,DOWN,LEFT,RIGHT');

    this.makeHUD();
    const boot = document.getElementById('boot'); if (boot) boot.remove();
  }

  update(_t, dms) {
    if (this.over || this.paused) return;
    const dt = Math.min(dms, 50) / 1000;
    this.elapsed += dt;
    this.moverPlayer(dt);
    this.spawn(dt);
    this.moveEnemies(dt);
    this.fire(dt);
    this.moveProjs(dt);
    this.moveGems(dt);
    this.updateHUD();
  }

  // ---------- 玩家 ----------
  moverPlayer(dt) {
    const p = this.player; let vx = 0, vy = 0, k = this.keys;
    if (k.A.isDown || k.LEFT.isDown) vx -= 1;
    if (k.D.isDown || k.RIGHT.isDown) vx += 1;
    if (k.W.isDown || k.UP.isDown) vy -= 1;
    if (k.S.isDown || k.DOWN.isDown) vy += 1;
    const ptr = this.input.activePointer;
    if (!vx && !vy && ptr.isDown) {
      const a = Phaser.Math.Angle.Between(p.x, p.y, ptr.worldX, ptr.worldY);
      if (Phaser.Math.Distance.Between(p.x, p.y, ptr.worldX, ptr.worldY) > 6) { vx = Math.cos(a); vy = Math.sin(a); }
    }
    if (vx || vy) { const l = Math.hypot(vx, vy); p.x += (vx/l)*this.stats.moveSpeed*dt; p.y += (vy/l)*this.stats.moveSpeed*dt; }
    p.x = Phaser.Math.Clamp(p.x, 16, W-16); p.y = Phaser.Math.Clamp(p.y, 60, H-90);
    p.obj.x = p.x; p.obj.y = p.y;
  }

  // ---------- 敌人 ----------
  spawn(dt) {
    this.spawnT -= dt;
    if (this.spawnT > 0 || this.enemies.length > 140) return;
    this.spawnT = Math.max(0.28, 1.3 - this.elapsed * 0.012);
    const n = 1 + Math.floor(this.elapsed / 25);
    for (let i = 0; i < n; i++) this.spawnEnemy(this.elapsed > 30 && Math.random() < 0.12);
  }
  spawnEnemy(big) {
    const edge = Math.floor(Math.random()*4);
    let x, y;
    if (edge === 0) { x = Math.random()*W; y = -20; }
    else if (edge === 1) { x = Math.random()*W; y = H+20; }
    else if (edge === 2) { x = -20; y = Math.random()*H; }
    else { x = W+20; y = Math.random()*H; }
    const hpBase = 18 + this.elapsed * 1.4;
    const e = big
      ? { x, y, r: 22, hp: hpBase*6, maxHp: hpBase*6, speed: 42 + this.elapsed*0.25, dmg: 22, xp: 5, big: true }
      : { x, y, r: 11, hp: hpBase,  maxHp: hpBase,  speed: 58 + this.elapsed*0.55, dmg: 12, xp: 1 };
    e.speed = Math.min(e.speed, 150);
    e.obj = this.add.circle(x, y, e.r, big ? 0x8a1f1f : 0xff5a5a).setStrokeStyle(2, 0x551111).setDepth(3);
    this.enemies.push(e);
  }
  moveEnemies(dt) {
    const p = this.player;
    for (const e of this.enemies) {
      const a = Phaser.Math.Angle.Between(e.x, e.y, p.x, p.y);
      e.x += Math.cos(a)*e.speed*dt; e.y += Math.sin(a)*e.speed*dt;
      e.obj.x = e.x; e.obj.y = e.y;
      if (Phaser.Math.Distance.Between(e.x, e.y, p.x, p.y) < e.r + p.r) {
        this.player.hp -= e.dmg * dt;
        if (this.player.hp <= 0) return this.end();
      }
    }
  }

  // ---------- 开火(自动瞄最近) ----------
  fire(dt) {
    this.fireT -= dt;
    if (this.fireT > 0 || this.enemies.length === 0) return;
    this.fireT = this.stats.fireCd;
    const tgt = this.nearest(this.player.x, this.player.y);
    if (!tgt) return;
    const base = Phaser.Math.Angle.Between(this.player.x, this.player.y, tgt.x, tgt.y);
    const n = this.stats.projCount, spread = 0.18;
    for (let i = 0; i < n; i++) {
      const a = base + (i - (n-1)/2) * spread;
      const obj = this.add.circle(this.player.x, this.player.y, 5, 0x9fe0ff).setDepth(4);
      this.projs.push({ x: this.player.x, y: this.player.y, vx: Math.cos(a)*this.stats.projSpeed, vy: Math.sin(a)*this.stats.projSpeed, life: 1.2, pierce: this.stats.pierce, obj });
    }
  }
  nearest(x, y) {
    let best = null, bd = 1e9;
    for (const e of this.enemies) { const d = Phaser.Math.Distance.Between(x, y, e.x, e.y); if (d < bd) { bd = d; best = e; } }
    return best;
  }
  moveProjs(dt) {
    for (const pr of this.projs) {
      pr.x += pr.vx*dt; pr.y += pr.vy*dt; pr.life -= dt; pr.obj.x = pr.x; pr.obj.y = pr.y;
      if (pr.life <= 0 || pr.x < -30 || pr.x > W+30 || pr.y < -30 || pr.y > H+30) { pr.dead = true; continue; }
      for (const e of this.enemies) {
        if (e.dead) continue;
        if (Phaser.Math.Distance.Between(pr.x, pr.y, e.x, e.y) < e.r + 5) {
          e.hp -= this.stats.dmg;
          e.obj.setFillStyle(0xffffff); this.time.delayedCall(50, () => { if (e.obj && e.obj.active && !e.dead) e.obj.setFillStyle(e.big?0x8a1f1f:0xff5a5a); });
          if (e.hp <= 0) this.killEnemy(e);
          if (pr.pierce > 0) pr.pierce--; else { pr.dead = true; }
          break;
        }
      }
    }
    this.projs = this.projs.filter(pr => { if (pr.dead) pr.obj.destroy(); return !pr.dead; });
  }
  killEnemy(e) {
    e.dead = true; this.kills++;
    const g = this.add.circle(e.x, e.y, e.big?7:4, 0x8affc0).setDepth(2);
    this.gems.push({ x: e.x, y: e.y, xp: e.xp, obj: g });
    e.obj.destroy();
    this.enemies = this.enemies.filter(en => !en.dead);
  }

  // ---------- 经验 / 升级 ----------
  moveGems(dt) {
    const p = this.player;
    for (const gm of this.gems) {
      const d = Phaser.Math.Distance.Between(gm.x, gm.y, p.x, p.y);
      if (d < this.stats.pickup) {
        const a = Phaser.Math.Angle.Between(gm.x, gm.y, p.x, p.y);
        gm.x += Math.cos(a)*420*dt; gm.y += Math.sin(a)*420*dt; gm.obj.x = gm.x; gm.obj.y = gm.y;
        if (d < p.r + 4) { gm.got = true; this.xp += gm.xp; gm.obj.destroy(); if (this.xp >= this.xpNeed) this.levelUp(); }
      }
    }
    this.gems = this.gems.filter(gm => !gm.got);
  }
  levelUp() {
    this.xp -= this.xpNeed; this.level++; this.xpNeed = Math.floor(this.xpNeed * 1.45 + 3);
    this.player.hp = Math.min(this.player.maxHp, this.player.hp + 15);
    this.paused = true;
    const pool = [
      { t: '⚔ 伤害 +25%', f: () => this.stats.dmg *= 1.25 },
      { t: '🔥 攻速 +20%', f: () => this.stats.fireCd *= 0.82 },
      { t: '➕ 多一发子弹', f: () => this.stats.projCount += 1 },
      { t: '🏃 移速 +12%', f: () => this.stats.moveSpeed *= 1.12 },
      { t: '❤ 上限+25 并回满', f: () => { this.player.maxHp += 25; this.player.hp = this.player.maxHp; } },
      { t: '🧲 拾取范围 +40%', f: () => this.stats.pickup *= 1.4 },
      { t: '🎯 子弹穿透 +1', f: () => this.stats.pierce += 1 },
    ];
    Phaser.Utils.Array.Shuffle(pool);
    const pick = pool.slice(0, 3);
    const layer = [];
    layer.push(this.add.rectangle(W/2, H/2, W, H, 0x000, 0.72).setDepth(20));
    layer.push(this.add.text(W/2, H/2-200, `Lv.${this.level} 升级！三选一`, { fontSize: '24px', color: '#9fe07a', fontStyle: 'bold' }).setOrigin(0.5).setDepth(21));
    pick.forEach((u, i) => {
      const cy = H/2 - 90 + i*110;
      const card = this.add.rectangle(W/2, cy, 380, 90, 0x1c2b4a).setStrokeStyle(2, 0x6fd0ff).setDepth(21).setInteractive();
      const txt = this.add.text(W/2, cy, u.t, { fontSize: '22px', color: '#fff' }).setOrigin(0.5).setDepth(22);
      card.on('pointerdown', () => { u.f(); layer.forEach(o => o.destroy()); card.destroy(); txt.destroy(); this.paused = false; });
      layer.push(card, txt);
    });
  }

  // ---------- HUD / 结算 ----------
  makeHUD() {
    this.add.rectangle(W/2, 18, W-30, 16, 0x222).setDepth(10);
    this.hpFill = this.add.rectangle(16, 18, W-30, 16, 0xff5a5a).setOrigin(0,0.5).setDepth(11);
    this.add.rectangle(W/2, 40, W-30, 10, 0x222).setDepth(10);
    this.xpFill = this.add.rectangle(16, 40, 0, 10, 0x8affc0).setOrigin(0,0.5).setDepth(11);
    this.info = this.add.text(W/2, 58, '', { fontSize: '15px', color: '#cde' }).setOrigin(0.5,0).setDepth(11);
    this.add.text(W/2, H-24, '按住朝手指方向移动 · WASD · 自动开火 · 活得越久越强', { fontSize: '11px', color: '#7a9' }).setOrigin(0.5,0).setDepth(10);
  }
  updateHUD() {
    this.hpFill.width = (W-30) * Math.max(0, this.player.hp / this.player.maxHp);
    this.xpFill.width = (W-30) * Math.max(0, this.xp / this.xpNeed);
    this.info.setText(`Lv.${this.level}   ⏱ ${Math.floor(this.elapsed)}s   💀 ${this.kills}`);
  }
  end() {
    this.over = true;
    this.add.rectangle(W/2, H/2, W, H, 0x000, 0.78).setDepth(30);
    this.add.text(W/2, H/2-70, '你倒下了', { fontSize: '40px', color: '#ff7a7a', fontStyle: 'bold' }).setOrigin(0.5).setDepth(31);
    this.add.text(W/2, H/2-10, `存活 ${Math.floor(this.elapsed)} 秒 · Lv.${this.level} · 击杀 ${this.kills}`, { fontSize: '17px', color: '#cde' }).setOrigin(0.5).setDepth(31);
    const btn = this.add.rectangle(W/2, H/2+70, 200, 60, 0x2f7fd0).setStrokeStyle(2, 0xfff).setDepth(31).setInteractive();
    this.add.text(W/2, H/2+70, '再来一局', { fontSize: '22px', color: '#fff' }).setOrigin(0.5).setDepth(32);
    btn.on('pointerdown', () => this.scene.restart());
  }
}

new Phaser.Game({
  type: Phaser.AUTO, parent: 'game', backgroundColor: '#0b1020',
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH, width: W, height: H },
  scene: [Game]
});
