/* FingerMOBA — 幸存者生存(Survivor 风)。Phaser + SVG 贴图,秒开。
   虚拟摇杆 / WASD 走位 + 自动开火 + 怪潮(基础/快怪/坦克) + 升级三选一 + 越活越强。 */
const W = 540, H = 960;
const DPR = Math.min(window.devicePixelRatio || 1, 2); // 高清:按设备像素渲染,封顶 2x 保帧率
const RASTER = 256;                                    // SVG 栅格化分辨率(远大于显示尺寸 → 缩小不糊)
const SPRITES = ['hero', 'enemy_basic', 'enemy_fast', 'enemy_tank', 'gem', 'projectile'];

/* ── 浮动虚拟摇杆:按哪出哪、拖动给方向+模拟量速度、松手隐藏、触屏/鼠标通用、与 WASD 共存 ── */
class VirtualJoystick {
  constructor(scene, opts = {}) {
    this.scene = scene;
    this.radius = opts.radius ?? 70;
    this.deadZone = opts.deadZone ?? 0.12;
    this.depth = opts.depth ?? 12;
    this.followBase = !opts.staticBase;
    this.active = false; this.pointerId = -1;
    this.baseX = 0; this.baseY = 0; this.curX = 0; this.curY = 0;
    this._vec = { x: 0, y: 0 };
    this.base = scene.add.circle(0, 0, this.radius, 0xffffff, 0.10)
      .setStrokeStyle(3, 0xffffff, 0.35).setDepth(this.depth).setVisible(false).setScrollFactor(0);
    this.thumb = scene.add.circle(0, 0, this.radius * 0.42, 0xffffff, 0.28)
      .setStrokeStyle(2, 0xffffff, 0.7).setDepth(this.depth + 1).setVisible(false).setScrollFactor(0);
    if (scene.input.addPointer) scene.input.addPointer(2);
    scene.input.on('pointerdown', (p) => this._down(p));
    scene.input.on('pointermove', (p) => this._move(p));
    scene.input.on('pointerup', (p) => this._up(p));
    scene.input.on('pointerupoutside', (p) => this._up(p));
    scene.input.on('gameout', () => this._release());
  }
  canStart() { return !(this.scene.paused || this.scene.over); }
  _down(p) {
    if (this.active || !this.canStart()) return;
    this.active = true; this.pointerId = p.id;
    this.baseX = this.curX = p.worldX; this.baseY = this.curY = p.worldY;
    this.base.setPosition(this.baseX, this.baseY).setVisible(true);
    this.thumb.setPosition(this.baseX, this.baseY).setVisible(true);
    this._recompute();
  }
  _move(p) { if (this.active && p.id === this.pointerId) { this.curX = p.worldX; this.curY = p.worldY; this._recompute(); } }
  _up(p) { if (this.active && p.id === this.pointerId) this._release(); }
  _release() { this.active = false; this.pointerId = -1; this._vec.x = 0; this._vec.y = 0; this.base.setVisible(false); this.thumb.setVisible(false); }
  _recompute() {
    let dx = this.curX - this.baseX, dy = this.curY - this.baseY, dist = Math.hypot(dx, dy);
    const R = this.radius;
    if (dist > R) {
      if (this.followBase) {
        const over = dist - R;
        this.baseX += (dx / dist) * over; this.baseY += (dy / dist) * over;
        this.base.setPosition(this.baseX, this.baseY);
        dx = this.curX - this.baseX; dy = this.curY - this.baseY; dist = R;
      } else { dx = (dx / dist) * R; dy = (dy / dist) * R; dist = R; }
    }
    this.thumb.setPosition(this.baseX + dx, this.baseY + dy);
    let mag = dist / R;
    if (mag < this.deadZone || dist === 0) { this._vec.x = 0; this._vec.y = 0; return; }
    mag = (mag - this.deadZone) / (1 - this.deadZone);
    this._vec.x = (dx / dist) * mag; this._vec.y = (dy / dist) * mag;
  }
  get vector() { return this._vec; }
}

class Game extends Phaser.Scene {
  constructor() { super('game'); }

  preload() {
    // SVG 贴图按高分辨率栅格化(显示时缩小 → 任何屏幕都清晰,无马赛克)
    for (const k of SPRITES) this.load.svg(k, `sprites/${k}.svg`, { width: RASTER, height: RASTER });
  }

  create() {
    this.over = false; this.paused = false;
    this.enemies = []; this.projs = []; this.gems = [];
    this.elapsed = 0; this.kills = 0; this.level = 1; this.xp = 0; this.xpNeed = 5;
    this.fireT = 0; this.spawnT = 0.5;
    this.stats = { dmg: 16, fireCd: 0.55, projSpeed: 540, projCount: 1, pierce: 0, moveSpeed: 235, pickup: 78 };

    this.add.rectangle(W/2, H/2, W, H, 0x0b1020).setDepth(-2);
    for (let gx = 60; gx < W; gx += 60) this.add.rectangle(gx, H/2, 1, H, 0x16203a).setDepth(-1);
    for (let gy = 60; gy < H; gy += 60) this.add.rectangle(W/2, gy, W, 1, 0x16203a).setDepth(-1);

    this.player = { x: W/2, y: H/2, r: 17, hp: 100, maxHp: 100 };
    this.player.obj = this.add.image(this.player.x, this.player.y, 'hero').setDepth(5);
    this.player.obj.setDisplaySize(48, 48);

    this.keys = this.input.keyboard.addKeys('W,A,S,D,UP,DOWN,LEFT,RIGHT');
    this.stick = new VirtualJoystick(this, { radius: 70, deadZone: 0.12, depth: 12 });

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
    if (!vx && !vy) { const jv = this.stick.vector; vx = jv.x; vy = jv.y; } // WASD 优先,否则用摇杆(模拟量)
    if (vx || vy) {
      const l = Math.hypot(vx, vy);
      const speed = Math.min(l, 1) * this.stats.moveSpeed; // 摇杆给模拟速度,WASD 恒为满速
      p.x += (vx/l)*speed*dt; p.y += (vy/l)*speed*dt;
      p.obj.setFlipX(vx < 0); // 朝移动方向翻面,有点生气
    }
    p.x = Phaser.Math.Clamp(p.x, 16, W-16); p.y = Phaser.Math.Clamp(p.y, 60, H-90);
    p.obj.x = p.x; p.obj.y = p.y;
  }

  // ---------- 敌人 ----------
  spawn(dt) {
    this.spawnT -= dt;
    if (this.spawnT > 0 || this.enemies.length > 140) return;
    this.spawnT = Math.max(0.28, 1.3 - this.elapsed * 0.012);
    const n = 1 + Math.floor(this.elapsed / 25);
    for (let i = 0; i < n; i++) {
      const r = Math.random();
      let type = 'basic';
      if (this.elapsed > 30 && r < 0.12) type = 'tank';
      else if (this.elapsed > 15 && r < 0.34) type = 'fast';
      this.spawnEnemy(type);
    }
  }
  spawnEnemy(type) {
    const edge = Math.floor(Math.random()*4);
    let x, y;
    if (edge === 0) { x = Math.random()*W; y = -20; }
    else if (edge === 1) { x = Math.random()*W; y = H+20; }
    else if (edge === 2) { x = -20; y = Math.random()*H; }
    else { x = W+20; y = Math.random()*H; }
    const hp0 = 18 + this.elapsed * 1.4;
    let e;
    if (type === 'tank') e = { type, r: 24, hp: hp0*6, maxHp: hp0*6, speed: 42 + this.elapsed*0.25, dmg: 22, xp: 5, sprite: 'enemy_tank' };
    else if (type === 'fast') e = { type, r: 11, hp: hp0*0.55, maxHp: hp0*0.55, speed: 95 + this.elapsed*0.5, dmg: 9, xp: 1, sprite: 'enemy_fast' };
    else e = { type, r: 14, hp: hp0, maxHp: hp0, speed: 56 + this.elapsed*0.5, dmg: 12, xp: 1, sprite: 'enemy_basic' };
    e.x = x; e.y = y;
    e.speed = Math.min(e.speed, type === 'fast' ? 185 : 150);
    e.obj = this.add.image(x, y, e.sprite).setDepth(3);
    e.obj.setDisplaySize(e.r*2.8, e.r*2.8);
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
      const obj = this.add.image(this.player.x, this.player.y, 'projectile').setDepth(4);
      obj.setDisplaySize(20, 20); obj.rotation = a;
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
        if (Phaser.Math.Distance.Between(pr.x, pr.y, e.x, e.y) < e.r + 6) {
          e.hp -= this.stats.dmg;
          e.obj.setTintFill(0xffffff); // 受击白闪
          this.time.delayedCall(60, () => { if (e.obj && e.obj.active && !e.dead) e.obj.clearTint(); });
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
    const g = this.add.image(e.x, e.y, 'gem').setDepth(2);
    g.setDisplaySize(e.type === 'tank' ? 28 : 18, e.type === 'tank' ? 28 : 18);
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
        if (d < p.r + 6) { gm.got = true; this.xp += gm.xp; gm.obj.destroy(); if (this.xp >= this.xpNeed) this.levelUp(); }
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
    layer.push(this.add.text(W/2, H/2-200, `Lv.${this.level} 升级！三选一`, { fontSize: '24px', color: '#9fe07a', fontStyle: 'bold', resolution: DPR }).setOrigin(0.5).setDepth(21));
    pick.forEach((u, i) => {
      const cy = H/2 - 90 + i*110;
      const card = this.add.rectangle(W/2, cy, 380, 90, 0x1c2b4a).setStrokeStyle(2, 0x6fd0ff).setDepth(21).setInteractive();
      const txt = this.add.text(W/2, cy, u.t, { fontSize: '22px', color: '#fff', resolution: DPR }).setOrigin(0.5).setDepth(22);
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
    this.info = this.add.text(W/2, 58, '', { fontSize: '15px', color: '#cde', resolution: DPR }).setOrigin(0.5,0).setDepth(11);
    this.add.text(W/2, H-24, '拖动摇杆 / WASD 移动 · 自动开火 · 活得越久越强', { fontSize: '11px', color: '#7a9', resolution: DPR }).setOrigin(0.5,0).setDepth(10);
  }
  updateHUD() {
    this.hpFill.width = (W-30) * Math.max(0, this.player.hp / this.player.maxHp);
    this.xpFill.width = (W-30) * Math.max(0, this.xp / this.xpNeed);
    this.info.setText(`Lv.${this.level}   ⏱ ${Math.floor(this.elapsed)}s   💀 ${this.kills}`);
  }
  end() {
    this.over = true;
    this.add.rectangle(W/2, H/2, W, H, 0x000, 0.78).setDepth(30);
    this.add.text(W/2, H/2-70, '你倒下了', { fontSize: '40px', color: '#ff7a7a', fontStyle: 'bold', resolution: DPR }).setOrigin(0.5).setDepth(31);
    this.add.text(W/2, H/2-10, `存活 ${Math.floor(this.elapsed)} 秒 · Lv.${this.level} · 击杀 ${this.kills}`, { fontSize: '17px', color: '#cde', resolution: DPR }).setOrigin(0.5).setDepth(31);
    const btn = this.add.rectangle(W/2, H/2+70, 200, 60, 0x2f7fd0).setStrokeStyle(2, 0xfff).setDepth(31).setInteractive();
    this.add.text(W/2, H/2+70, '再来一局', { fontSize: '22px', color: '#fff', resolution: DPR }).setOrigin(0.5).setDepth(32);
    btn.on('pointerdown', () => this.scene.restart());
  }
}

new Phaser.Game({
  type: Phaser.AUTO, parent: 'game', backgroundColor: '#0b1020',
  scale: {
    mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH,
    width: W * DPR, height: H * DPR, // 高清:绘制缓冲区 = 逻辑尺寸 × 设备像素比
    zoom: 1 / DPR, autoRound: true,  // 缩回逻辑尺寸,所有 W/H 坐标不变
  },
  render: { antialias: true, antialiasGL: true, roundPixels: false, pixelArt: false, mipmapFilter: 'LINEAR_MIPMAP_LINEAR', powerPreference: 'high-performance' },
  scene: [Game],
});
