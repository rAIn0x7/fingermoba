# FingerMOBA → Survivor

A one-thumb, instant-play web survival game. **Click and play, no install:**
👉 **https://rain0x7.github.io/fingermoba/**

> 单手、点开就玩的网页生存小游戏。零安装,链接直接玩。

---

## What it is

A Survivor.io / Vampire-Survivors-style auto-shooter: move with finger/mouse/WASD, **auto-fire at the nearest enemy**, enemies swarm and scale over time, kills drop XP, **level up → pick 1 of 3 upgrades**, survive as long as you can.

- **<1s load, no wasm** — plain JS + Phaser 3 (CDN).
- Runs on mobile and desktop, in any browser.
- Hosted free on GitHub Pages, auto-deploys on push.

## Tech

| | |
|---|---|
| Web build (live) | **Phaser 3 + vanilla JS** — `web/` (~11KB + CDN), instant load |
| Native build (kept) | **Godot 4 + GDScript** — full project + Android workflow, for a future native version |
| Deploy | GitHub Actions → GitHub Pages (static `web/`) |

## The build story (why it looks like this)

This started as a 3v3 MOBA (a tribute to a shut-down game), written first in Unity, then Godot 4. Two pivots made it what it is:

1. **Godot wasm → Phaser** — an ~8MB wasm + compile made first load too slow for a "tap-and-play" web showcase. Rewrote the playable slice in plain JS + Phaser → sub-second load.
2. **MOBA → Survivor** — a MOBA slice is bug-prone (pathing/targeting/balance/AI) and a poor fit for "play a quick round on the subway." Switched to a proven, addictive short-session genre. Same effort, far better retention.

Built solo, with heavy AI pair-programming — part of a "one person + AI shipping real products" experiment.

## Run locally
```bash
cd web && python3 -m http.server   # open http://localhost:8000
```

---

*Made by Zion (rAIn0x7). Part of the [qizh.space](https://qizh.space) ventures.*
