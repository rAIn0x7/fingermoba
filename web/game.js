/* FingerMOBA — Phaser 垂直切片(指尖刀塔风)。纯形状渲染,秒开。 */
const W = 540, H = 960;
const COL = {
  allyHero: 0x3aa0ff, enemyHero: 0xff5a5a,
  allyMin: 0x7fd0ff, enemyMin: 0xffa0a0,
  allyStruct: 0x2f7fd0, enemyStruct: 0xd04a4a,
  lane: 0x12351a, bg: 0x0a160c, hpFill: 0x66e06a, hpBack: 0x222
};

class Game extends Phaser.Scene {
  constructor() { super('game'); }

  create() {
    this.over = false;
    this.units = [];
    this.skillCd = 0; this.skillMax = 5;

    // 背景 + 中路
    this.add.rectangle(W/2, H/2, W, H, COL.bg).setDepth(-2);
    this.add.rectangle(W/2, H/2, 150, H, COL.lane).setDepth(-1);
    for (let y = 90; y < H; y += 90) this.add.rectangle(W/2, y, 150, 2, 0x1c4a26).setDepth(-1);

    // 建筑:水晶(胜负目标)+ 塔
    this.enemyCrystal = this.mkStruct('enemy', W/2, 64, 'crystal', 2600, '敌方水晶');
    this.allyCrystal  = this.mkStruct('ally',  W/2, H-64, 'crystal', 2600, '你的水晶');
    this.mkStruct('enemy', W/2, 250, 'tower', 1600, '塔');
    this.mkStruct('ally',  W/2, H-250, 'tower', 1600, '塔');

    // 英雄
    this.hero = this.mkHero('ally', W/2, H-150);
    this.enemyHero = this.mkHero('enemy', W/2, 150);
    this.moveTarget = null;

    // 输入:点击/拖动移动 + 技能键
    this.input.on('pointerdown', (p) => {
      if (this.over) return;
      if (this.skillHit(p.x, p.y)) { this.castSkill(); return; }
      this.moveTarget = { x: p.worldX, y: p.worldY };
    });
    this.input.on('pointermove', (p) => {
      if (!this.over && p.isDown && !this.skillHit(p.x, p.y)) this.moveTarget = { x: p.worldX, y: p.worldY };
    });
    this.keys = this.input.keyboard.addKeys('W,A,S,D,UP,DOWN,LEFT,RIGHT');
    this.input.keyboard.on('keydown-Q', () => this.castSkill());
    this.input.keyboard.on('keydown-SPACE', () => this.castSkill());

    // 小兵波次
    this.time.addEvent({ delay: 7000, loop: true, callback: () => this.spawnWave() });
    this.spawnWave();

    this.makeHUD();
    const boot = document.getElementById('boot'); if (boot) boot.remove();
  }

  // ---------- 工厂 ----------
  mkUnit(o) {
    o.dead = false; o.cd = 0; o.hp = o.maxHp;
    o.hpBg = this.add.rectangle(o.x, o.y - o.r - 8, o.r * 2, 5, COL.hpBack).setDepth(5);
    o.hpFill = this.add.rectangle(o.x - o.r, o.y - o.r - 8, o.r * 2, 5, COL.hpFill).setOrigin(0, 0.5).setDepth(6);
    this.units.push(o);
    return o;
  }
  mkHero(team, x, y) {
    const c = team === 'ally' ? COL.allyHero : COL.enemyHero;
    const obj = this.add.circle(x, y, 18, c).setStrokeStyle(3, 0xffffff).setDepth(4);
    return this.mkUnit({ kind: 'hero', team, x, y, r: 18, obj, maxHp: 900, atk: 60, range: 95, speed: 175, cdMax: 0.9, spawn: { x, y } });
  }
  mkMinion(team, x, y) {
    const c = team === 'ally' ? COL.allyMin : COL.enemyMin;
    const obj = this.add.circle(x, y, 9, c).setDepth(3);
    return this.mkUnit({ kind: 'minion', team, x, y, r: 9, obj, maxHp: 120, atk: 14, range: 60, speed: 95, cdMax: 1.0 });
  }
  mkStruct(team, x, y, kind, hp, label) {
    const c = team === 'ally' ? COL.allyStruct : COL.enemyStruct;
    const big = kind === 'crystal';
    const size = big ? 64 : 46;
    let obj;
    if (big) { obj = this.add.star(x, y, 6, size*0.4, size*0.62, c).setStrokeStyle(3, 0xffffff).setDepth(2); }
    else { obj = this.add.rectangle(x, y, size, size, c).setStrokeStyle(2, 0x000000).setDepth(2); }
    const u = this.mkUnit({ kind, team, x, y, r: size/2, obj, maxHp: hp, atk: 45, range: 130, speed: 0, cdMax: 1.1, structure: true });
    if (label) this.add.text(x, y + (big?44:30), label, { fontSize: '11px', color: '#cfe' }).setOrigin(0.5).setDepth(5);
    return u;
  }
  spawnWave() {
    if (this.over) return;
    for (let i = 0; i < 3; i++) {
      this.mkMinion('ally',  W/2 + (i-1)*26, H-200 + i*14);
      this.mkMinion('enemy', W/2 + (i-1)*26, 200 - i*14);
    }
  }

  // ---------- 主循环 ----------
  update(_t, dms) {
    if (this.over) return;
    const dt = Math.min(dms, 50) / 1000;
    this.skillCd = Math.max(0, this.skillCd - dt);
    this.updateHUD();
    this.controlHero(dt);
    for (const u of this.units) if (!u.dead && u.kind !== 'hero' || (u.kind === 'hero' && u.team === 'enemy')) {
      // 玩家英雄单独处理移动;其余(含敌方英雄)走 AI
      if (!(u === this.hero)) this.aiUnit(u, dt);
    }
    for (const u of this.units) if (!u.dead) this.syncBars(u);
    this.cleanup();
  }

  controlHero(dt) {
    const h = this.hero; if (h.dead) return;
    let vx = 0, vy = 0;
    const k = this.keys;
    if (k.A.isDown || k.LEFT.isDown) vx -= 1;
    if (k.D.isDown || k.RIGHT.isDown) vx += 1;
    if (k.W.isDown || k.UP.isDown) vy -= 1;
    if (k.S.isDown || k.DOWN.isDown) vy += 1;
    if (vx || vy) {
      const len = Math.hypot(vx, vy); h.x += (vx/len)*h.speed*dt; h.y += (vy/len)*h.speed*dt; this.moveTarget = null;
    } else if (this.moveTarget) {
      const d = Phaser.Math.Distance.Between(h.x, h.y, this.moveTarget.x, this.moveTarget.y);
      if (d > 6) { const a = Phaser.Math.Angle.Between(h.x, h.y, this.moveTarget.x, this.moveTarget.y);
        h.x += Math.cos(a)*h.speed*dt; h.y += Math.sin(a)*h.speed*dt; } else this.moveTarget = null;
    }
    h.x = Phaser.Math.Clamp(h.x, 20, W-20); h.y = Phaser.Math.Clamp(h.y, 20, H-20);
    h.obj.x = h.x; h.obj.y = h.y;
    // 自动攻击最近敌人
    this.tryAttack(h, dt);
  }

  aiUnit(u, dt) {
    const tgt = this.nearestEnemy(u, u.structure ? u.range : 220);
    if (u.structure) { this.tryAttack(u, dt); return; }
    // 有近敌则打,否则朝敌方水晶推进
    if (tgt && Phaser.Math.Distance.Between(u.x, u.y, tgt.x, tgt.y) <= u.range) { this.tryAttack(u, dt); }
    else {
      const goal = tgt || (u.team === 'ally' ? this.enemyCrystal : this.allyCrystal);
      if (goal && !goal.dead) { const a = Phaser.Math.Angle.Between(u.x, u.y, goal.x, goal.y);
        u.x += Math.cos(a)*u.speed*dt; u.y += Math.sin(a)*u.speed*dt; u.obj.x = u.x; u.obj.y = u.y;
        if (Phaser.Math.Distance.Between(u.x, u.y, goal.x, goal.y) <= u.range) this.tryAttack(u, dt); }
    }
  }

  tryAttack(u, dt) {
    u.cd = Math.max(0, u.cd - dt);
    const tgt = this.nearestEnemy(u, u.range);
    if (!tgt || u.cd > 0) return;
    this.damage(tgt, u.atk, u);
    u.cd = u.cdMax;
    this.zap(u, tgt);
  }

  nearestEnemy(u, range) {
    let best = null, bd = range;
    for (const e of this.units) {
      if (e.dead || e.team === u.team) continue;
      const d = Phaser.Math.Distance.Between(u.x, u.y, e.x, e.y) - e.r;
      if (d <= bd) { bd = d; best = e; }
    }
    return best;
  }

  damage(t, amt, src) {
    if (t.dead) return;
    t.hp -= amt;
    t.obj.setScale(1.12); this.time.delayedCall(70, () => { if (t.obj && t.obj.active) t.obj.setScale(1); });
    if (t.hp <= 0) this.die(t);
  }

  die(t) {
    t.dead = true;
    if (t.obj) t.obj.destroy(); if (t.hpBg) t.hpBg.destroy(); if (t.hpFill) t.hpFill.destroy();
    if (t === this.enemyCrystal) return this.end(true);
    if (t === this.allyCrystal) return this.end(false);
    if (t.kind === 'hero') {  // 英雄复活
      t.dead = false; t.hp = t.maxHp;
      this.time.delayedCall(5000, () => {
        t.x = t.spawn.x; t.y = t.spawn.y; t.hp = t.maxHp;
        const c = t.team === 'ally' ? COL.allyHero : COL.enemyHero;
        t.obj = this.add.circle(t.x, t.y, t.r, c).setStrokeStyle(3, 0xffffff).setDepth(4);
        t.hpBg = this.add.rectangle(t.x, t.y - t.r - 8, t.r*2, 5, COL.hpBack).setDepth(5);
        t.hpFill = this.add.rectangle(t.x - t.r, t.y - t.r - 8, t.r*2, 5, COL.hpFill).setOrigin(0,0.5).setDepth(6);
      });
    }
  }

  zap(u, t) {
    const g = this.add.line(0, 0, u.x, u.y, t.x, t.y, u.team === 'ally' ? 0x9fe0ff : 0xffc0c0).setOrigin(0).setLineWidth(u.kind==='hero'?2.5:1).setDepth(3).setAlpha(0.8);
    this.time.delayedCall(90, () => g.destroy());
  }

  castSkill() {
    if (this.over || this.skillCd > 0 || this.hero.dead) return;
    this.skillCd = this.skillMax;
    const radius = 130;
    const ring = this.add.circle(this.hero.x, this.hero.y, radius, 0x6fd0ff, 0.28).setDepth(3);
    this.tweens.add({ targets: ring, scale: 1.2, alpha: 0, duration: 320, onComplete: () => ring.destroy() });
    for (const e of this.units) {
      if (e.dead || e.team === 'ally') continue;
      if (Phaser.Math.Distance.Between(this.hero.x, this.hero.y, e.x, e.y) <= radius + e.r) this.damage(e, 160, this.hero);
    }
  }

  // ---------- HUD ----------
  makeHUD() {
    this.add.text(W/2, 14, 'FINGERMOBA', { fontSize: '15px', color: '#9fe07a', fontStyle: 'bold' }).setOrigin(0.5,0).setDepth(10);
    this.add.text(W/2, H-26, '点击/拖动移动 · WASD · Q 放大招 · 推掉敌方水晶获胜', { fontSize: '11px', color: '#7a9' }).setOrigin(0.5,0).setDepth(10);
    this.skillBtn = this.add.circle(W-70, H-110, 40, 0x244, 0.9).setStrokeStyle(3, 0x6fd0ff).setDepth(10);
    this.skillTxt = this.add.text(W-70, H-110, 'Q', { fontSize: '22px', color: '#cfe' }).setOrigin(0.5).setDepth(11);
    this.skillCover = this.add.rectangle(W-70, H-110, 80, 80, 0x000, 0.55).setDepth(10);
  }
  skillHit(x, y) { return Phaser.Math.Distance.Between(x, y, W-70, H-110) <= 46; }
  updateHUD() {
    const r = this.skillCd / this.skillMax;
    this.skillCover.setScale(1, r); this.skillCover.y = (H-110) - 40 + (80*r)/2;
    this.skillTxt.setText(this.skillCd > 0 ? Math.ceil(this.skillCd) : 'Q');
  }
  syncBars(u) {
    if (!u.hpBg) return;
    u.hpBg.x = u.x; u.hpBg.y = u.y - u.r - 8;
    u.hpFill.x = u.x - u.r; u.hpFill.y = u.y - u.r - 8;
    u.hpFill.width = (u.r*2) * Math.max(0, u.hp / u.maxHp);
  }
  cleanup() { this.units = this.units.filter(u => !u.dead || u.kind === 'hero'); }

  end(win) {
    this.over = true;
    this.add.rectangle(W/2, H/2, W, H, 0x000, 0.72).setDepth(20);
    this.add.text(W/2, H/2-40, win ? '胜利 🏆' : '失败', { fontSize: '46px', color: win ? '#9fe07a' : '#ff7a7a', fontStyle: 'bold' }).setOrigin(0.5).setDepth(21);
    this.add.text(W/2, H/2+18, win ? '你推掉了敌方水晶' : '水晶被摧毁了', { fontSize: '15px', color: '#cde' }).setOrigin(0.5).setDepth(21);
    const btn = this.add.rectangle(W/2, H/2+90, 180, 56, 0x2f7fd0).setStrokeStyle(2, 0xfff).setDepth(21).setInteractive();
    this.add.text(W/2, H/2+90, '再来一局', { fontSize: '20px', color: '#fff' }).setOrigin(0.5).setDepth(22);
    btn.on('pointerdown', () => this.scene.restart());
  }
}

new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game',
  backgroundColor: '#070d07',
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH, width: W, height: H },
  scene: [Game]
});
