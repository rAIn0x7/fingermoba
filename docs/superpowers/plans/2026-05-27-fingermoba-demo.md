# FingerMOBA Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable single-player Android demo of FingerMOBA — a vertical-screen 3v3 MOBA inspired by 指尖刀塔, with AI opponents, 3 heroes, three-lane map, gold/item system, and hero leveling.

**Architecture:** Unity 2D project with MonoBehaviour-based game objects. Pure-logic classes (GoldManagerLogic, BehaviorTree) are decoupled from MonoBehaviour for unit testability. Systems communicate via a static EventBus (string-keyed events) to avoid direct dependencies between unrelated components.

**Tech Stack:** Unity 2022.3 LTS (2D URP), C#, Unity Test Framework (NUnit EditMode), Android build target, legacy Input (touch), Physics2D for range/collision detection.

---

## File Map

```
Assets/
├── Scripts/
│   ├── Core/
│   │   ├── EventBus.cs          # Static event system, string-keyed
│   │   ├── GameState.cs         # Enums: Team, GamePhase + event data classes
│   │   └── GameManager.cs       # Singleton, spawns heroes, listens for game-over
│   ├── Hero/
│   │   ├── HeroStats.cs         # ScriptableObject: base stats + per-level growth
│   │   ├── HeroBase.cs          # MonoBehaviour: HP, XP, level, death, respawn
│   │   ├── HeroController.cs    # Player input → movement + basic attack
│   │   ├── SkillBase.cs         # Abstract MonoBehaviour: cooldown, cast
│   │   └── Skills/
│   │       ├── GuardianCharge.cs
│   │       ├── GuardianShield.cs
│   │       ├── AssassinBlink.cs
│   │       ├── AssassinCombo.cs
│   │       ├── MageLightning.cs
│   │       └── MageStorm.cs
│   ├── Map/
│   │   ├── LaneData.cs          # ScriptableObject: ordered waypoints for one lane
│   │   ├── MinionSpawner.cs     # Timed wave spawner per lane
│   │   ├── MinionController.cs  # Minion: follow lane, attack enemies
│   │   ├── TowerController.cs   # Auto-attack nearest enemy hero/minion in range
│   │   └── Crystal.cs           # Base crystal — takes damage, fires CRYSTAL_DESTROYED
│   ├── AI/
│   │   ├── BehaviorNode.cs      # Enum + pure-logic behavior tree node
│   │   └── BotController.cs     # MonoBehaviour: drives HeroBase using BehaviorTree
│   ├── Economy/
│   │   ├── GoldManagerLogic.cs  # Pure C# gold ledger (no Unity dep, unit-testable)
│   │   ├── GoldManager.cs       # MonoBehaviour wrapper — fires EventBus on changes
│   │   ├── ItemData.cs          # ScriptableObject: item stats
│   │   └── ShopController.cs    # Buy items, apply stat bonuses
│   ├── Camera/
│   │   └── CameraFollow.cs      # Smooth follow of player hero, portrait lock
│   └── UI/
│       ├── VirtualJoystick.cs   # Floating touch joystick
│       ├── SkillButton.cs       # Tap/drag-release skill button with CD ring
│       ├── HeroHUD.cs           # HP bar, mana bar, level, gold display
│       ├── MiniMap.cs           # Top-corner minimap render texture
│       └── ResultScreen.cs      # Win/lose overlay, restart button
├── Tests/
│   ├── EditMode/
│   │   ├── GoldManagerTests.cs
│   │   ├── HeroStatsTests.cs
│   │   └── BehaviorNodeTests.cs
│   ├── EditMode.asmdef
│   └── PlayMode/
│       └── GameFlowTests.cs
├── ScriptableObjects/
│   ├── Heroes/
│   │   ├── Guardian.asset
│   │   ├── Assassin.asset
│   │   └── Mage.asset
│   └── Items/
│       ├── Sword.asset
│       ├── IronArmor.asset
│       ├── MageStaff.asset
│       └── SpeedBoots.asset
├── Prefabs/
│   ├── Heroes/
│   ├── Minions/
│   ├── Towers/
│   └── UI/
└── Scenes/
    ├── MainMenu.unity
    └── GameScene.unity
```

---

## Task 1: Unity Project Setup + Android Config + .gitignore

**Files:**
- Create: Unity project at `/home/test/code/fingermoba/` (via Unity Hub)
- Create: `.gitignore`
- Create: `README.md`

- [ ] **Step 1: Install Unity Hub and Unity 2022.3 LTS**

  Download Unity Hub from https://unity.com/download. In Unity Hub → Installs → Install Editor → select **Unity 2022.3 LTS**. During install, check the **Android Build Support** module (includes Android SDK and NDK).

- [ ] **Step 2: Create project via Unity Hub**

  Unity Hub → Projects → New Project → Template: **2D (URP)** → Name: `fingermoba` → Location: `/home/test/code/` → Create.

  Unity will create `/home/test/code/fingermoba/` with `Assets/`, `Packages/`, `ProjectSettings/`. The `docs/` folder already in that directory will be preserved.

- [ ] **Step 3: Configure Portrait + Android build target**

  In Unity: File → Build Settings → select **Android** → Switch Platform.

  Then Edit → Project Settings → Player → **Other Settings**:
  - Default Orientation: **Portrait**
  - Minimum API Level: Android 8.0 (API 26)
  - Target API Level: Automatic (highest installed)
  - Package Name: `ai.worldengine.fingermoba`

- [ ] **Step 4: Create folder structure inside Assets/**

  In Unity Project window, create these folders under `Assets/`:
  `Scripts/Core`, `Scripts/Hero`, `Scripts/Hero/Skills`, `Scripts/Map`, `Scripts/AI`, `Scripts/Economy`, `Scripts/Camera`, `Scripts/UI`, `Tests/EditMode`, `Tests/PlayMode`, `ScriptableObjects/Heroes`, `ScriptableObjects/Items`, `Prefabs/Heroes`, `Prefabs/Minions`, `Prefabs/Towers`, `Prefabs/UI`, `Sprites/Placeholders`

- [ ] **Step 5: Add .gitignore for Unity**

  Create `/home/test/code/fingermoba/.gitignore`:

  ```
  # Unity generated
  [Ll]ibrary/
  [Tt]emp/
  [Oo]bj/
  [Bb]uild/
  [Bb]uilds/
  [Ll]ogs/
  [Uu]ser[Ss]ettings/
  MemoryCaptures/
  .vs/
  *.pidb
  *.suo
  *.user
  *.userprefs
  *.unityproj
  *.booproj
  *.svd
  *.pdb
  *.mdb
  *.opendb
  *.VC.db
  *.apk
  *.aab
  *.unitypackage
  crashlytics-build.properties
  ```

- [ ] **Step 6: Create EditMode assembly definition**

  Create `Assets/Tests/EditMode.asmdef` with content:

  ```json
  {
      "name": "FingerMOBA.Tests.EditMode",
      "references": [
          "UnityEngine.TestRunner",
          "UnityEditor.TestRunner",
          "FingerMOBA.Runtime"
      ],
      "optionalUnityReferences": [
          "TestAssemblies"
      ],
      "includePlatforms": ["Editor"],
      "excludePlatforms": [],
      "allowUnsafeCode": false,
      "overrideReferences": true,
      "precompiledReferences": [
          "nunit.framework.dll"
      ]
  }
  ```

  Also create `Assets/Scripts/FingerMOBA.Runtime.asmdef`:
  ```json
  {
      "name": "FingerMOBA.Runtime",
      "references": [],
      "includePlatforms": [],
      "excludePlatforms": [],
      "allowUnsafeCode": false
  }
  ```

- [ ] **Step 7: Commit**

  ```bash
  cd /home/test/code/fingermoba
  git add .gitignore Assets/Scripts/FingerMOBA.Runtime.asmdef Assets/Tests/EditMode.asmdef
  git commit -m "feat: Unity project setup, Android portrait config, test assembly defs"
  ```

---

## Task 2: Core — EventBus + GameState + GameManager

**Files:**
- Create: `Assets/Scripts/Core/EventBus.cs`
- Create: `Assets/Scripts/Core/GameState.cs`
- Create: `Assets/Scripts/Core/GameManager.cs`

- [ ] **Step 1: Create EventBus.cs**

  ```csharp
  // Assets/Scripts/Core/EventBus.cs
  using System;
  using System.Collections.Generic;

  public static class EventBus
  {
      public const string HERO_DIED       = "hero.died";
      public const string HERO_LEVEL_UP   = "hero.levelup";
      public const string TOWER_DESTROYED = "tower.destroyed";
      public const string CRYSTAL_DESTROYED = "crystal.destroyed";
      public const string GOLD_CHANGED    = "gold.changed";
      public const string MINION_DIED     = "minion.died";
      public const string GAME_OVER       = "game.over";

      private static readonly Dictionary<string, List<Action<object>>> _listeners = new();

      public static void On(string evt, Action<object> handler)
      {
          if (!_listeners.ContainsKey(evt)) _listeners[evt] = new List<Action<object>>();
          _listeners[evt].Add(handler);
      }

      public static void Off(string evt, Action<object> handler)
      {
          if (_listeners.TryGetValue(evt, out var list)) list.Remove(handler);
      }

      public static void Emit(string evt, object data = null)
      {
          if (!_listeners.TryGetValue(evt, out var list)) return;
          foreach (var h in new List<Action<object>>(list)) h(data);
      }

      public static void Clear() => _listeners.Clear();
  }
  ```

- [ ] **Step 2: Create GameState.cs**

  ```csharp
  // Assets/Scripts/Core/GameState.cs
  public enum Team { Radiant, Dire }
  public enum GamePhase { Playing, GameOver }

  public class HeroDiedData
  {
      public HeroBase Hero;
      public HeroBase Killer; // null = killed by tower or minion
  }

  public class GameOverData
  {
      public Team Winner;
  }
  ```

- [ ] **Step 3: Create GameManager.cs**

  ```csharp
  // Assets/Scripts/Core/GameManager.cs
  using UnityEngine;

  public class GameManager : MonoBehaviour
  {
      public static GameManager Instance { get; private set; }
      public GamePhase Phase { get; private set; } = GamePhase.Playing;
      public Team? Winner { get; private set; }

      [SerializeField] private HeroStats playerHeroStats;
      [SerializeField] private HeroStats[] radiantBotStats;  // 2 entries
      [SerializeField] private HeroStats[] direBotStats;     // 3 entries
      [SerializeField] private Transform[] radiantSpawns;    // 3 points
      [SerializeField] private Transform[] direSpawns;       // 3 points

      private void Awake()
      {
          if (Instance != null) { Destroy(gameObject); return; }
          Instance = this;
      }

      private void Start()
      {
          EventBus.On(EventBus.CRYSTAL_DESTROYED, OnCrystalDestroyed);
          SpawnHeroes();
      }

      private void OnDestroy() => EventBus.Clear();

      private void SpawnHeroes()
      {
          // Player hero (Radiant, index 0)
          SpawnHero(playerHeroStats, Team.Radiant, 0, radiantSpawns[0], isPlayer: true);
          // Radiant bots
          for (int i = 0; i < radiantBotStats.Length; i++)
              SpawnHero(radiantBotStats[i], Team.Radiant, i + 1, radiantSpawns[i + 1], isPlayer: false);
          // Dire bots
          for (int i = 0; i < direBotStats.Length; i++)
              SpawnHero(direBotStats[i], Team.Dire, i + 10, direSpawns[i], isPlayer: false);
      }

      private void SpawnHero(HeroStats stats, Team team, int id, Transform spawn, bool isPlayer)
      {
          GameObject go = Instantiate(stats.prefab, spawn.position, Quaternion.identity);
          var hero = go.GetComponent<HeroBase>();
          hero.Init(stats, team, id, spawn);
          if (isPlayer)
          {
              go.AddComponent<HeroController>();
              Camera.main.GetComponent<CameraFollow>().SetTarget(go.transform);
          }
          else
          {
              var bot = go.AddComponent<BotController>();
              bot.Init(hero);
          }
      }

      private void OnCrystalDestroyed(object data)
      {
          if (Phase != GamePhase.Playing) return;
          Phase = GamePhase.GameOver;
          Team destroyed = (Team)data;
          Winner = destroyed == Team.Radiant ? Team.Dire : Team.Radiant;
          EventBus.Emit(EventBus.GAME_OVER, new GameOverData { Winner = Winner.Value });
      }
  }
  ```

- [ ] **Step 4: Verify compile in Unity**

  Open Unity. The console should show no errors after Unity auto-compiles. Fix any red errors before proceeding.

- [ ] **Step 5: Commit**

  ```bash
  git add Assets/Scripts/Core/
  git commit -m "feat: add EventBus, GameState enums, GameManager skeleton"
  ```

---

## Task 3: HeroStats ScriptableObject + Tests

**Files:**
- Create: `Assets/Scripts/Hero/HeroStats.cs`
- Create: `Assets/Tests/EditMode/HeroStatsTests.cs`

- [ ] **Step 1: Write failing test**

  ```csharp
  // Assets/Tests/EditMode/HeroStatsTests.cs
  using NUnit.Framework;
  using UnityEngine;

  public class HeroStatsTests
  {
      [Test]
      public void HeroStats_DefaultValues_AreReasonable()
      {
          var stats = ScriptableObject.CreateInstance<HeroStats>();
          stats.maxHp = 1000f;
          stats.hpPerLevel = 80f;
          Assert.AreEqual(1000f, stats.maxHp);
          Assert.AreEqual(80f, stats.hpPerLevel);
      }
  }
  ```

  In Unity: Window → General → Test Runner → EditMode → Run All. Expect: **FAIL** (HeroStats not defined).

- [ ] **Step 2: Create HeroStats.cs**

  ```csharp
  // Assets/Scripts/Hero/HeroStats.cs
  using UnityEngine;

  [CreateAssetMenu(fileName = "NewHeroStats", menuName = "FingerMOBA/HeroStats")]
  public class HeroStats : ScriptableObject
  {
      public string heroName;

      [Header("Base Stats")]
      public float maxHp       = 1000f;
      public float attack      = 60f;
      public float moveSpeed   = 3.3f;   // Unity units/sec
      public float attackSpeed = 1.0f;   // attacks/sec
      public float attackRange = 1.5f;   // Unity units
      public float physicalArmor = 0f;   // flat % reduction (0–1)
      public float magicResist   = 0f;

      [Header("Per Level Growth")]
      public float hpPerLevel     = 80f;
      public float attackPerLevel = 4f;

      [Header("Visuals")]
      public GameObject prefab;
      public Sprite portrait;
  }
  ```

- [ ] **Step 3: Run tests — expect PASS**

  In Unity Test Runner → EditMode → Run All. `HeroStatsTests` should be green.

- [ ] **Step 4: Commit**

  ```bash
  git add Assets/Scripts/Hero/HeroStats.cs Assets/Tests/EditMode/HeroStatsTests.cs
  git commit -m "feat: add HeroStats ScriptableObject with growth stats"
  ```

---

## Task 4: GoldManager (pure logic + tests)

**Files:**
- Create: `Assets/Scripts/Economy/GoldManagerLogic.cs`
- Create: `Assets/Scripts/Economy/GoldManager.cs`
- Create: `Assets/Tests/EditMode/GoldManagerTests.cs`

- [ ] **Step 1: Write failing tests**

  ```csharp
  // Assets/Tests/EditMode/GoldManagerTests.cs
  using NUnit.Framework;

  public class GoldManagerTests
  {
      private GoldManagerLogic _gm;

      [SetUp]
      public void SetUp() { _gm = new GoldManagerLogic(); _gm.Init(0); }

      [Test]
      public void AddGold_IncreasesBalance()
      {
          _gm.Add(0, 200);
          Assert.AreEqual(200, _gm.Get(0));
      }

      [Test]
      public void TrySpend_SucceedsWhenAffordable()
      {
          _gm.Add(0, 500);
          bool ok = _gm.TrySpend(0, 400);
          Assert.IsTrue(ok);
          Assert.AreEqual(100, _gm.Get(0));
      }

      [Test]
      public void TrySpend_FailsWhenUnaffordable()
      {
          _gm.Add(0, 100);
          bool ok = _gm.TrySpend(0, 400);
          Assert.IsFalse(ok);
          Assert.AreEqual(100, _gm.Get(0));
      }

      [Test]
      public void CalculateDrop_IsHalfRoundedDown()
      {
          _gm.Add(0, 201);
          Assert.AreEqual(100, _gm.CalculateDrop(0));
      }

      [Test]
      public void ApplyDrop_ReducesBalance()
      {
          _gm.Add(0, 200);
          _gm.ApplyDrop(0);
          Assert.AreEqual(100, _gm.Get(0));
      }
  }
  ```

  Run in Test Runner → expect **FAIL** (GoldManagerLogic not defined).

- [ ] **Step 2: Create GoldManagerLogic.cs**

  ```csharp
  // Assets/Scripts/Economy/GoldManagerLogic.cs
  using System.Collections.Generic;

  public class GoldManagerLogic
  {
      public const int MINION_KILL  = 40;
      public const int HERO_KILL    = 200;
      public const int HERO_ASSIST  = 100;
      public const int TOWER_KILL   = 150;
      public const float DROP_RATE  = 0.5f;

      private readonly Dictionary<int, int> _gold = new();

      public void Init(int playerId) => _gold[playerId] = 0;

      public void Add(int playerId, int amount)
      {
          if (!_gold.ContainsKey(playerId)) _gold[playerId] = 0;
          _gold[playerId] = System.Math.Max(0, _gold[playerId] + amount);
      }

      public int Get(int playerId) => _gold.GetValueOrDefault(playerId, 0);

      public int CalculateDrop(int playerId) => (int)(Get(playerId) * DROP_RATE);

      public void ApplyDrop(int playerId)
      {
          int drop = CalculateDrop(playerId);
          _gold[playerId] -= drop;
      }

      public bool CanAfford(int playerId, int cost) => Get(playerId) >= cost;

      public bool TrySpend(int playerId, int cost)
      {
          if (!CanAfford(playerId, cost)) return false;
          _gold[playerId] -= cost;
          return true;
      }
  }
  ```

- [ ] **Step 3: Run tests — expect PASS**

- [ ] **Step 4: Create GoldManager.cs (MonoBehaviour wrapper)**

  ```csharp
  // Assets/Scripts/Economy/GoldManager.cs
  using UnityEngine;

  public class GoldManager : MonoBehaviour
  {
      public static GoldManager Instance { get; private set; }
      private GoldManagerLogic _logic = new();

      private void Awake()
      {
          if (Instance != null) { Destroy(gameObject); return; }
          Instance = this;
      }

      public void Init(int playerId) => _logic.Init(playerId);

      public void Add(int playerId, int amount)
      {
          _logic.Add(playerId, amount);
          EventBus.Emit(EventBus.GOLD_CHANGED, playerId);
      }

      public int Get(int playerId) => _logic.Get(playerId);

      public int CalculateDrop(int playerId) => _logic.CalculateDrop(playerId);

      public void ApplyDrop(int playerId)
      {
          _logic.ApplyDrop(playerId);
          EventBus.Emit(EventBus.GOLD_CHANGED, playerId);
      }

      public bool TrySpend(int playerId, int cost)
      {
          bool ok = _logic.TrySpend(playerId, cost);
          if (ok) EventBus.Emit(EventBus.GOLD_CHANGED, playerId);
          return ok;
      }
  }
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add Assets/Scripts/Economy/ Assets/Tests/EditMode/GoldManagerTests.cs
  git commit -m "feat: add GoldManagerLogic (tested) + GoldManager MonoBehaviour"
  ```

---

## Task 5: Map Scene — Placeholder Layout (Lanes, Towers, Crystal, Spawns)

**Files:**
- Create: `Assets/Scripts/Map/Crystal.cs`
- Create: `Assets/Scripts/Map/TowerController.cs`
- Create: `Assets/Scripts/Map/LaneData.cs`
- Scene: `Assets/Scenes/GameScene.unity` (manual setup in Unity editor)

- [ ] **Step 1: Create placeholder sprites**

  In Unity, create simple colored sprites for placeholder art. Use the built-in Sprite shapes:
  - White square 1×1 → save as `Assets/Sprites/Placeholders/White1x1.png`
  - Or use Unity's built-in **Sprites/Default** material with colored SpriteRenderer

  For the map, draw colored boxes directly in the scene using `Sprite Renderer` + solid color material.

- [ ] **Step 2: Create GameScene layout in Unity Editor**

  Create scene `Assets/Scenes/GameScene.unity`. Build the layout:

  ```
  Portrait resolution: 1080×1920 (set in Game view dropdown)

  Hierarchy structure:
  GameScene
  ├── GameManager (empty GameObject, attach GameManager.cs later)
  ├── GoldManager (attach GoldManager.cs)
  ├── Map
  │   ├── Background (SpriteRenderer, dark green 18×32 units)
  │   ├── RadiantBase
  │   │   ├── Crystal          (white square, position: 0, -12)
  │   │   ├── Spawn_0          (empty, position: -1, -13)
  │   │   ├── Spawn_1          (empty, position:  0, -13)
  │   │   └── Spawn_2          (empty, position:  1, -13)
  │   ├── DireBase
  │   │   ├── Crystal          (white square, position: 0,  12)
  │   │   ├── Spawn_0          (empty, position: -1,  13)
  │   │   ├── Spawn_1          (empty, position:  0,  13)
  │   │   └── Spawn_2          (empty, position:  1,  13)
  │   ├── TopLane
  │   │   ├── Tower_Radiant_1  (position: -3, -6)
  │   │   ├── Tower_Radiant_2  (position: -3,  0)
  │   │   ├── Tower_Dire_1     (position: -3,  6)
  │   │   └── Tower_Dire_2     (position: -3,  3)
  │   ├── MidLane
  │   │   ├── Tower_Radiant_1  (position:  0, -6)
  │   │   ├── Tower_Radiant_2  (position:  0, -2)
  │   │   ├── Tower_Dire_1     (position:  0,  6)
  │   │   └── Tower_Dire_2     (position:  0,  2)
  │   └── BotLane
  │       ├── Tower_Radiant_1  (position:  3, -6)
  │       ├── Tower_Radiant_2  (position:  3,  0)
  │       ├── Tower_Dire_1     (position:  3,  6)
  │       └── Tower_Dire_2     (position:  3,  3)
  ├── UI (Canvas, Screen Space - Overlay)
  └── Main Camera (Orthographic, size 9)
  ```

- [ ] **Step 3: Create Crystal.cs**

  ```csharp
  // Assets/Scripts/Map/Crystal.cs
  using UnityEngine;

  public class Crystal : MonoBehaviour
  {
      [SerializeField] public Team team;
      public float maxHp = 3000f;
      public float CurrentHp { get; private set; }
      public bool IsDestroyed { get; private set; }

      private void Awake() => CurrentHp = maxHp;

      public void TakeDamage(float damage)
      {
          if (IsDestroyed) return;
          CurrentHp = Mathf.Max(0, CurrentHp - damage);
          if (CurrentHp <= 0) Destroy();
      }

      private void Destroy()
      {
          IsDestroyed = true;
          EventBus.Emit(EventBus.CRYSTAL_DESTROYED, team);
          gameObject.SetActive(false);
      }
  }
  ```

- [ ] **Step 4: Create TowerController.cs**

  ```csharp
  // Assets/Scripts/Map/TowerController.cs
  using UnityEngine;

  public class TowerController : MonoBehaviour
  {
      [SerializeField] public Team team;
      public float maxHp         = 2000f;
      public float attack        = 120f;
      public float attackRange   = 3f;
      public float attackCooldown = 1.5f;
      public float physicalArmor = 0.3f; // 30% damage reduction

      public bool IsDestroyed { get; private set; }
      private float _currentHp;
      private float _attackTimer;

      private void Awake() { _currentHp = maxHp; _attackTimer = 0; }

      private void Update()
      {
          if (IsDestroyed) return;
          _attackTimer -= Time.deltaTime;
          if (_attackTimer > 0) return;
          var target = FindNearestEnemyHero();
          if (target == null) return;
          target.TakeDamage(attack);
          _attackTimer = attackCooldown;
      }

      private HeroBase FindNearestEnemyHero()
      {
          var hits = Physics2D.OverlapCircleAll(transform.position, attackRange, LayerMask.GetMask("Hero"));
          HeroBase best = null;
          float bestDist = float.MaxValue;
          foreach (var h in hits)
          {
              var hero = h.GetComponent<HeroBase>();
              if (hero == null || hero.Team == team || hero.IsDead) continue;
              float d = Vector2.Distance(transform.position, hero.transform.position);
              if (d < bestDist) { bestDist = d; best = hero; }
          }
          return best;
      }

      public void TakeDamage(float damage, bool isMagic = false)
      {
          if (IsDestroyed) return;
          float reduced = isMagic ? damage : damage * (1f - physicalArmor);
          _currentHp = Mathf.Max(0, _currentHp - reduced);
          if (_currentHp <= 0) DestroyTower();
      }

      private void DestroyTower()
      {
          IsDestroyed = true;
          EventBus.Emit(EventBus.TOWER_DESTROYED, this);
          // Award gold to all enemies (handled by GoldManager listener)
          gameObject.SetActive(false);
      }
  }
  ```

- [ ] **Step 5: Create LaneData.cs**

  ```csharp
  // Assets/Scripts/Map/LaneData.cs
  using UnityEngine;

  [CreateAssetMenu(fileName = "NewLane", menuName = "FingerMOBA/LaneData")]
  public class LaneData : ScriptableObject
  {
      public string laneName; // "Top", "Mid", "Bot"
      public Transform[] radiantWaypoints; // ordered bottom→top
      public Transform[] direWaypoints;    // ordered top→bottom
  }
  ```

  In the editor, create 3 LaneData assets (`Assets/ScriptableObjects/Lanes/Top.asset`, `Mid.asset`, `Bot.asset`). Assign waypoint Transforms (create empty GameObjects along each lane path in the scene).

- [ ] **Step 6: Assign TowerController + Crystal components in scene**

  Select each Tower object in the hierarchy, add `TowerController` component, set `team` field. Select each Crystal, add `Crystal` component, set `team`. Assign layers: Heroes on "Hero" layer, Towers on "Tower" layer.

- [ ] **Step 7: Manual test**

  Enter Play mode in Unity. The map should render with placeholder boxes. No errors in Console.

- [ ] **Step 8: Commit**

  ```bash
  git add Assets/Scripts/Map/ Assets/Scenes/
  git commit -m "feat: map scene layout, TowerController, Crystal with CRYSTAL_DESTROYED event"
  ```

---

## Task 6: Camera — Portrait Lock + Follow Player Hero

**Files:**
- Create: `Assets/Scripts/Camera/CameraFollow.cs`

- [ ] **Step 1: Create CameraFollow.cs**

  ```csharp
  // Assets/Scripts/Camera/CameraFollow.cs
  using UnityEngine;

  public class CameraFollow : MonoBehaviour
  {
      [SerializeField] private float smoothSpeed = 8f;
      [SerializeField] private float topLimit   =  10f;
      [SerializeField] private float bottomLimit = -10f;

      private Transform _target;

      public void SetTarget(Transform t) => _target = t;

      private void LateUpdate()
      {
          if (_target == null) return;
          float targetY = Mathf.Clamp(_target.position.y, bottomLimit, topLimit);
          Vector3 desired = new Vector3(0f, targetY, transform.position.z);
          transform.position = Vector3.Lerp(transform.position, desired, smoothSpeed * Time.deltaTime);
      }
  }
  ```

- [ ] **Step 2: Attach to Main Camera in scene**

  Select **Main Camera** in GameScene hierarchy → Add Component → `CameraFollow`. Set:
  - Smooth Speed: `8`
  - Top Limit: `10`
  - Bottom Limit: `-10`
  - Orthographic Size: `9`

- [ ] **Step 3: Manual test**

  Enter Play mode. Camera should be static (no target yet). Verify no console errors.

- [ ] **Step 4: Commit**

  ```bash
  git add Assets/Scripts/Camera/CameraFollow.cs
  git commit -m "feat: portrait camera follow with vertical clamp"
  ```

---

## Task 7: Virtual Joystick

**Files:**
- Create: `Assets/Scripts/UI/VirtualJoystick.cs`

- [ ] **Step 1: Create VirtualJoystick.cs**

  ```csharp
  // Assets/Scripts/UI/VirtualJoystick.cs
  using UnityEngine;
  using UnityEngine.EventSystems;

  public class VirtualJoystick : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
  {
      [SerializeField] private RectTransform _background;
      [SerializeField] private RectTransform _handle;
      [SerializeField] private float _maxRadius = 70f;

      public Vector2 Direction { get; private set; }
      public bool IsActive { get; private set; }

      private Vector2 _originPos;

      public void OnPointerDown(PointerEventData e)
      {
          IsActive = true;
          _background.position = e.position;
          _originPos = e.position;
          UpdateHandle(e.position);
      }

      public void OnDrag(PointerEventData e) => UpdateHandle(e.position);

      public void OnPointerUp(PointerEventData e)
      {
          IsActive = false;
          Direction = Vector2.zero;
          _handle.anchoredPosition = Vector2.zero;
      }

      private void UpdateHandle(Vector2 pos)
      {
          Vector2 delta = pos - _originPos;
          if (delta.magnitude > _maxRadius) delta = delta.normalized * _maxRadius;
          Direction = delta / _maxRadius;
          _handle.anchoredPosition = delta;
      }
  }
  ```

- [ ] **Step 2: Set up joystick UI in GameScene**

  Under the **UI Canvas** in GameScene:
  ```
  Canvas
  └── JoystickArea  (RectTransform: anchor bottom-left, size 300×300, pos 150,150)
      ├── Background  (Image, gray circle sprite, size 140×140)
      └── Handle      (Image, white circle sprite, size 60×60)
  ```

  Attach `VirtualJoystick` to `JoystickArea`. Assign `_background` → `Background`, `_handle` → `Handle`. Add **Event System** to scene if not present (GameObject → UI → Event System).

- [ ] **Step 3: Manual test**

  Enter Play mode. Touch/click the bottom-left area. The joystick handle should follow your finger and `Direction` should update (verify via Debug.Log in `OnDrag` temporarily).

- [ ] **Step 4: Commit**

  ```bash
  git add Assets/Scripts/UI/VirtualJoystick.cs
  git commit -m "feat: floating virtual joystick with normalized direction output"
  ```

---

## Task 8: HeroBase — HP, XP, Level, Death, Respawn

**Files:**
- Create: `Assets/Scripts/Hero/HeroBase.cs`
- Create: `Assets/Tests/EditMode/HeroBehaviorTests.cs` (XP/level logic)

- [ ] **Step 1: Write failing XP tests**

  ```csharp
  // Assets/Tests/EditMode/HeroBehaviorTests.cs
  using NUnit.Framework;
  using UnityEngine;

  public class HeroBehaviorTests
  {
      [Test]
      public void XpThreshold_Level1To2_Requires100Xp()
      {
          // XP_TO_NEXT[0] = 100 (to go from Lv1 to Lv2)
          Assert.AreEqual(100, HeroBase.XP_TO_NEXT[0]);
      }

      [Test]
      public void RespawnTime_Level1_Is7Seconds()
      {
          Assert.AreEqual(7f, HeroBase.CalcRespawnTime(1));
      }

      [Test]
      public void RespawnTime_Level10_Is25Seconds()
      {
          Assert.AreEqual(25f, HeroBase.CalcRespawnTime(10));
      }
  }
  ```

  Run → expect **FAIL**.

- [ ] **Step 2: Create HeroBase.cs**

  ```csharp
  // Assets/Scripts/Hero/HeroBase.cs
  using System.Collections;
  using UnityEngine;

  public class HeroBase : MonoBehaviour
  {
      public static readonly int[] XP_TO_NEXT = { 100, 150, 180, 200, 220, 250, 280, 300, 350 };

      public static float CalcRespawnTime(int level) => 5f + level * 2f;

      public HeroStats Stats { get; private set; }
      public Team Team { get; private set; }
      public int PlayerId { get; private set; }

      public float CurrentHp { get; private set; }
      public float MaxHp => Stats.maxHp + (Level - 1) * Stats.hpPerLevel;
      public float Attack => Stats.attack + (Level - 1) * Stats.attackPerLevel;

      public int Level { get; private set; } = 1;
      public int Xp { get; private set; } = 0;
      public bool IsDead { get; private set; }

      private Transform _spawnPoint;

      public void Init(HeroStats stats, Team team, int playerId, Transform spawnPoint)
      {
          Stats = stats;
          Team = team;
          PlayerId = playerId;
          _spawnPoint = spawnPoint;
          CurrentHp = MaxHp;
          IsDead = false;
          Level = 1;
          Xp = 0;
          GoldManager.Instance?.Init(playerId);
      }

      public void TakeDamage(float damage, HeroBase attacker = null)
      {
          if (IsDead) return;
          CurrentHp = Mathf.Max(0f, CurrentHp - damage);
          if (CurrentHp <= 0f) Die(attacker);
      }

      private void Die(HeroBase killer)
      {
          IsDead = true;
          gameObject.SetActive(false);

          int drop = GoldManager.Instance?.CalculateDrop(PlayerId) ?? 0;
          GoldManager.Instance?.ApplyDrop(PlayerId);

          int reward = GoldManagerLogic.HERO_KILL;
          if (killer != null)
              GoldManager.Instance?.Add(killer.PlayerId, reward);

          EventBus.Emit(EventBus.HERO_DIED, new HeroDiedData { Hero = this, Killer = killer });
          StartCoroutine(RespawnRoutine(CalcRespawnTime(Level)));
      }

      private IEnumerator RespawnRoutine(float delay)
      {
          yield return new WaitForSeconds(delay);
          CurrentHp = MaxHp;
          transform.position = _spawnPoint.position;
          IsDead = false;
          gameObject.SetActive(true);
      }

      public void GainXp(int amount)
      {
          if (Level >= 10) return;
          Xp += amount;
          while (Level < 10 && Xp >= XP_TO_NEXT[Level - 1])
          {
              Xp -= XP_TO_NEXT[Level - 1];
              LevelUp();
          }
      }

      private void LevelUp()
      {
          Level++;
          CurrentHp = Mathf.Min(CurrentHp + Stats.hpPerLevel, MaxHp);
          EventBus.Emit(EventBus.HERO_LEVEL_UP, this);
      }
  }
  ```

- [ ] **Step 3: Run tests — expect PASS**

- [ ] **Step 4: Commit**

  ```bash
  git add Assets/Scripts/Hero/HeroBase.cs Assets/Tests/EditMode/HeroBehaviorTests.cs
  git commit -m "feat: HeroBase with HP, XP/leveling, death/respawn + unit tests"
  ```

---

## Task 9: HeroController — Player Movement + Basic Attack

**Files:**
- Create: `Assets/Scripts/Hero/HeroController.cs`

- [ ] **Step 1: Create HeroController.cs**

  ```csharp
  // Assets/Scripts/Hero/HeroController.cs
  using UnityEngine;

  [RequireComponent(typeof(HeroBase))]
  public class HeroController : MonoBehaviour
  {
      private HeroBase _hero;
      private VirtualJoystick _joystick;
      private HeroBase _lockedTarget;
      private float _attackTimer;

      private void Awake() => _hero = GetComponent<HeroBase>();

      private void Start()
          => _joystick = FindObjectOfType<VirtualJoystick>();

      private void Update()
      {
          if (_hero.IsDead) return;
          HandleMovement();
          HandleAutoAttack();
      }

      private void HandleMovement()
      {
          if (_joystick == null || !_joystick.IsActive) return;
          Vector2 dir = _joystick.Direction;
          transform.Translate(dir * (_hero.MoveSpeed * Time.deltaTime));
          // Flip sprite based on horizontal direction
          if (dir.x != 0)
              transform.localScale = new Vector3(dir.x > 0 ? 1 : -1, 1, 1);
      }

      private void HandleAutoAttack()
      {
          _attackTimer -= Time.deltaTime;
          if (_lockedTarget == null || _lockedTarget.IsDead) { _lockedTarget = null; return; }
          float dist = Vector2.Distance(transform.position, _lockedTarget.transform.position);
          if (dist > _hero.Stats.attackRange) return;
          if (_attackTimer > 0) return;
          _lockedTarget.TakeDamage(_hero.Attack, _hero);
          GainXpFromKill(_lockedTarget);
          _attackTimer = 1f / _hero.Stats.attackSpeed;
      }

      private void GainXpFromKill(HeroBase target)
      {
          // XP from attacking (small amount per hit; kills are handled in HeroBase.Die)
      }

      public void SetTarget(HeroBase target) => _lockedTarget = target;

      private void OnMouseDown()
      {
          // Allow clicking on enemies to lock target (editor only)
      }
  }
  ```

- [ ] **Step 2: Create placeholder hero prefab**

  In Unity: create a 2D sprite GameObject (white circle), add `HeroBase` component. Save as `Assets/Prefabs/Heroes/HeroPlaceholder.prefab`. Assign the prefab to a new `HeroStats` asset.

  Create `Assets/ScriptableObjects/Heroes/Guardian.asset`: right-click in Project → Create → FingerMOBA → HeroStats. Fill in:
  - heroName: "Guardian"
  - maxHp: 1200, attack: 55, moveSpeed: 3.3, attackSpeed: 0.8, attackRange: 1.5
  - hpPerLevel: 80, attackPerLevel: 4
  - prefab: HeroPlaceholder

- [ ] **Step 3: Wire up GameManager in scene**

  Select `GameManager` object in GameScene. Assign:
  - Player Hero Stats: `Guardian`
  - Radiant Spawns: `RadiantBase/Spawn_0`, `Spawn_1`, `Spawn_2`
  - Dire Spawns: `DireBase/Spawn_0`, `Spawn_1`, `Spawn_2`

- [ ] **Step 4: Manual test**

  Play the scene. The player hero (white circle) should spawn at the Radiant base. Drag the joystick to move it around the map. Verify movement direction and sprite flip.

- [ ] **Step 5: Commit**

  ```bash
  git add Assets/Scripts/Hero/HeroController.cs Assets/ScriptableObjects/
  git commit -m "feat: HeroController with joystick movement and auto-attack targeting"
  ```

---

## Task 10: Minion System — Spawning + Lane Pathfinding + Combat

**Files:**
- Create: `Assets/Scripts/Map/MinionSpawner.cs`
- Create: `Assets/Scripts/Map/MinionController.cs`

- [ ] **Step 1: Create MinionController.cs**

  ```csharp
  // Assets/Scripts/Map/MinionController.cs
  using UnityEngine;

  public class MinionController : MonoBehaviour
  {
      public Team Team { get; private set; }
      public bool IsDead { get; private set; }

      [SerializeField] private float maxHp        = 400f;
      [SerializeField] private float attack        = 30f;
      [SerializeField] private float moveSpeed     = 2.0f;
      [SerializeField] private float attackRange   = 0.8f;
      [SerializeField] private float attackCooldown = 1.2f;
      [SerializeField] private int   xpReward      = 30;
      [SerializeField] private int   goldReward     = 40; // for last-hitter

      private float _currentHp;
      private float _attackTimer;
      private Transform[] _waypoints;
      private int _wpIndex;

      public void Init(Team team, Transform[] waypoints)
      {
          Team = team;
          _currentHp = maxHp;
          _waypoints = waypoints;
          _wpIndex = 0;
      }

      private void Update()
      {
          if (IsDead) return;
          _attackTimer -= Time.deltaTime;

          Transform enemy = FindNearestEnemy();
          if (enemy != null && Vector2.Distance(transform.position, enemy.position) <= attackRange)
          {
              if (_attackTimer <= 0)
              {
                  AttackEnemy(enemy);
                  _attackTimer = attackCooldown;
              }
          }
          else
          {
              FollowWaypoints();
          }
      }

      private Transform FindNearestEnemy()
      {
          int mask = LayerMask.GetMask("Hero", "Tower", "Minion");
          var hits = Physics2D.OverlapCircleAll(transform.position, attackRange * 2f, mask);
          Transform nearest = null;
          float nearestDist = float.MaxValue;
          foreach (var h in hits)
          {
              bool isEnemy = IsEnemyTarget(h);
              if (!isEnemy) continue;
              float d = Vector2.Distance(transform.position, h.transform.position);
              if (d < nearestDist) { nearestDist = d; nearest = h.transform; }
          }
          return nearest;
      }

      private bool IsEnemyTarget(Collider2D col)
      {
          var hero = col.GetComponent<HeroBase>();
          if (hero != null && hero.Team != Team && !hero.IsDead) return true;
          var minion = col.GetComponent<MinionController>();
          if (minion != null && minion.Team != Team && !minion.IsDead) return true;
          var tower = col.GetComponent<TowerController>();
          if (tower != null && tower.team != Team && !tower.IsDestroyed) return true;
          var crystal = col.GetComponent<Crystal>();
          if (crystal != null && crystal.team != Team && !crystal.IsDestroyed) return true;
          return false;
      }

      private void AttackEnemy(Transform target)
      {
          target.GetComponent<HeroBase>()?.TakeDamage(attack);
          target.GetComponent<MinionController>()?.TakeDamage(attack, null);
          target.GetComponent<TowerController>()?.TakeDamage(attack);
          target.GetComponent<Crystal>()?.TakeDamage(attack);
      }

      private void FollowWaypoints()
      {
          if (_waypoints == null || _wpIndex >= _waypoints.Length) return;
          Transform wp = _waypoints[_wpIndex];
          transform.position = Vector2.MoveTowards(transform.position, wp.position, moveSpeed * Time.deltaTime);
          if (Vector2.Distance(transform.position, wp.position) < 0.05f) _wpIndex++;
      }

      public void TakeDamage(float damage, HeroBase attacker)
      {
          if (IsDead) return;
          _currentHp = Mathf.Max(0, _currentHp - damage);
          if (_currentHp <= 0) Die(attacker);
      }

      private void Die(HeroBase killer)
      {
          IsDead = true;
          if (killer != null)
          {
              GoldManager.Instance?.Add(killer.PlayerId, goldReward);
              killer.GainXp(xpReward);
          }
          EventBus.Emit(EventBus.MINION_DIED, this);
          Destroy(gameObject, 0.3f);
      }
  }
  ```

- [ ] **Step 2: Create MinionSpawner.cs**

  ```csharp
  // Assets/Scripts/Map/MinionSpawner.cs
  using UnityEngine;

  public class MinionSpawner : MonoBehaviour
  {
      [SerializeField] private GameObject minionPrefab;
      [SerializeField] private float spawnInterval = 30f;
      [SerializeField] private int minionsPerWave  = 4; // 3 melee + 1 ranged (same prefab for now)

      [Header("Lane Waypoints")]
      [SerializeField] private Transform[] radiantTopWaypoints;
      [SerializeField] private Transform[] radiantMidWaypoints;
      [SerializeField] private Transform[] radiantBotWaypoints;
      [SerializeField] private Transform[] direTopWaypoints;
      [SerializeField] private Transform[] direMidWaypoints;
      [SerializeField] private Transform[] direBotWaypoints;

      [Header("Spawn Points")]
      [SerializeField] private Transform radiantSpawnPoint;
      [SerializeField] private Transform direSpawnPoint;

      private float _timer;

      private void Start() => _timer = 5f; // first wave after 5s

      private void Update()
      {
          _timer -= Time.deltaTime;
          if (_timer > 0) return;
          _timer = spawnInterval;
          SpawnWave(Team.Radiant, radiantTopWaypoints, radiantMidWaypoints, radiantBotWaypoints);
          SpawnWave(Team.Dire, direTopWaypoints, direMidWaypoints, direBotWaypoints);
      }

      private void SpawnWave(Team team, Transform[] top, Transform[] mid, Transform[] bot)
      {
          SpawnLane(team, top);
          SpawnLane(team, mid);
          SpawnLane(team, bot);
      }

      private void SpawnLane(Team team, Transform[] waypoints)
      {
          if (waypoints == null || waypoints.Length == 0) return;
          Transform spawnPt = team == Team.Radiant ? radiantSpawnPoint : direSpawnPoint;
          for (int i = 0; i < minionsPerWave; i++)
          {
              Vector3 offset = new Vector3(Random.Range(-0.3f, 0.3f), i * 0.4f, 0);
              GameObject go = Instantiate(minionPrefab, spawnPt.position + offset, Quaternion.identity);
              go.GetComponent<MinionController>().Init(team, waypoints);
          }
      }
  }
  ```

- [ ] **Step 3: Create minion prefab**

  Create a small colored sprite (green for Radiant, red for Dire — use different materials or tinted sprites), add `MinionController` component. Add `CircleCollider2D`, set layer to "Minion". Save as `Assets/Prefabs/Minions/Minion.prefab`.

- [ ] **Step 4: Set up waypoints in scene**

  Create empty GameObjects along each lane path as waypoints. For Mid lane:
  - Radiant Mid Waypoints: y=-10 → y=-4 → y=0 → y=4 → y=10 (toward DireBase)
  - Dire Mid Waypoints: y=10 → y=4 → y=0 → y=-4 → y=-10 (toward RadiantBase)

  Create a `MinionSpawner` GameObject in the scene, attach `MinionSpawner.cs`, assign all waypoint arrays and spawn points.

- [ ] **Step 5: Manual test**

  Enter Play mode. After 5 seconds, minions should spawn from both bases and walk toward the enemy. When they meet in the middle, they should attack each other.

- [ ] **Step 6: Commit**

  ```bash
  git add Assets/Scripts/Map/Minion*.cs Assets/Prefabs/Minions/
  git commit -m "feat: minion spawner with 3-lane waves, waypoint pathfinding, last-hit gold"
  ```

---

## Task 11: SkillBase + 6 Hero Skills

**Files:**
- Create: `Assets/Scripts/Hero/SkillBase.cs`
- Create: `Assets/Scripts/Hero/Skills/GuardianCharge.cs`
- Create: `Assets/Scripts/Hero/Skills/GuardianShield.cs`
- Create: `Assets/Scripts/Hero/Skills/AssassinBlink.cs`
- Create: `Assets/Scripts/Hero/Skills/AssassinCombo.cs`
- Create: `Assets/Scripts/Hero/Skills/MageLightning.cs`
- Create: `Assets/Scripts/Hero/Skills/MageStorm.cs`

- [ ] **Step 1: Create SkillBase.cs**

  ```csharp
  // Assets/Scripts/Hero/SkillBase.cs
  using System.Collections;
  using UnityEngine;

  public abstract class SkillBase : MonoBehaviour
  {
      [SerializeField] protected float cooldown = 8f;

      public float CooldownRemaining { get; private set; }
      public bool IsReady => CooldownRemaining <= 0f;
      protected HeroBase _hero;

      protected virtual void Awake() => _hero = GetComponent<HeroBase>();

      protected virtual void Update()
      {
          if (CooldownRemaining > 0f) CooldownRemaining -= Time.deltaTime;
      }

      // direction: normalized direction from skill button drag (Vector2.zero for non-directional skills)
      public void TryCast(Vector2 direction, HeroBase target = null)
      {
          if (!IsReady || _hero.IsDead) return;
          CooldownRemaining = cooldown;
          Cast(direction, target);
      }

      protected abstract void Cast(Vector2 direction, HeroBase target);
  }
  ```

- [ ] **Step 2: Create GuardianCharge.cs**

  ```csharp
  // Assets/Scripts/Hero/Skills/GuardianCharge.cs
  using System.Collections;
  using UnityEngine;

  public class GuardianCharge : SkillBase
  {
      [SerializeField] private float dashDistance = 4f;
      [SerializeField] private float dashSpeed    = 20f;
      [SerializeField] private float stunDuration = 1f;
      [SerializeField] private float damageAmount = 80f;

      protected override void Awake() { base.Awake(); cooldown = 8f; }

      protected override void Cast(Vector2 direction, HeroBase target)
      {
          if (direction == Vector2.zero) direction = Vector2.up * (int)_hero.Team == 0 ? 1 : -1;
          StartCoroutine(DashRoutine(direction));
      }

      private IEnumerator DashRoutine(Vector2 dir)
      {
          Vector3 dest = transform.position + (Vector3)(dir.normalized * dashDistance);
          float elapsed = 0f;
          float duration = dashDistance / dashSpeed;
          Vector3 startPos = transform.position;
          while (elapsed < duration)
          {
              elapsed += Time.deltaTime;
              transform.position = Vector3.Lerp(startPos, dest, elapsed / duration);
              // Check for enemies hit during dash
              var hits = Physics2D.OverlapCircleAll(transform.position, 0.6f, LayerMask.GetMask("Hero"));
              foreach (var h in hits)
              {
                  var hero = h.GetComponent<HeroBase>();
                  if (hero == null || hero == _hero || hero.Team == _hero.Team || hero.IsDead) continue;
                  hero.TakeDamage(damageAmount, _hero);
                  hero.ApplyStun(stunDuration);
              }
              yield return null;
          }
          transform.position = dest;
      }
  }
  ```

  Add `ApplyStun` to HeroBase:
  ```csharp
  // In HeroBase.cs — add this method
  private bool _stunned;
  private float _stunTimer;

  public void ApplyStun(float duration)
  {
      _stunned = true;
      _stunTimer = Mathf.Max(_stunTimer, duration);
  }

  private void Update()
  {
      if (_stunTimer > 0)
      {
          _stunTimer -= Time.deltaTime;
          if (_stunTimer <= 0) _stunned = false;
      }
  }

  public bool IsStunned => _stunned;
  ```

  Also update `HeroController.HandleMovement` to check `if (_hero.IsStunned) return;`.

- [ ] **Step 3: Create GuardianShield.cs**

  ```csharp
  // Assets/Scripts/Hero/Skills/GuardianShield.cs
  using System.Collections;
  using UnityEngine;

  public class GuardianShield : SkillBase
  {
      [SerializeField] private float shieldAmount  = 300f;
      [SerializeField] private float shieldDuration = 4f;

      private float _shieldRemaining;

      protected override void Awake() { base.Awake(); cooldown = 12f; }

      protected override void Cast(Vector2 direction, HeroBase target)
          => StartCoroutine(ShieldRoutine());

      private IEnumerator ShieldRoutine()
      {
          _shieldRemaining = shieldAmount;
          yield return new WaitForSeconds(shieldDuration);
          _shieldRemaining = 0f;
      }

      // Call this from HeroBase.TakeDamage before applying damage
      public float AbsorbDamage(float incoming)
      {
          if (_shieldRemaining <= 0) return incoming;
          float absorbed = Mathf.Min(_shieldRemaining, incoming);
          _shieldRemaining -= absorbed;
          return incoming - absorbed;
      }
  }
  ```

  Update `HeroBase.TakeDamage` to call shield absorption:
  ```csharp
  public void TakeDamage(float damage, HeroBase attacker = null)
  {
      if (IsDead) return;
      var shield = GetComponent<GuardianShield>();
      if (shield != null) damage = shield.AbsorbDamage(damage);
      CurrentHp = Mathf.Max(0f, CurrentHp - damage);
      if (CurrentHp <= 0f) Die(attacker);
  }
  ```

- [ ] **Step 4: Create AssassinBlink.cs**

  ```csharp
  // Assets/Scripts/Hero/Skills/AssassinBlink.cs
  using UnityEngine;

  public class AssassinBlink : SkillBase
  {
      [SerializeField] private float damageMultiplier = 2.0f;

      protected override void Awake() { base.Awake(); cooldown = 10f; }

      protected override void Cast(Vector2 direction, HeroBase target)
      {
          if (target == null) target = FindNearestEnemy();
          if (target == null) return;
          // Teleport behind target
          Vector3 behind = target.transform.position - (target.transform.position - transform.position).normalized * 0.5f;
          transform.position = behind;
          float dmg = _hero.Attack * damageMultiplier;
          target.TakeDamage(dmg, _hero);
      }

      private HeroBase FindNearestEnemy()
      {
          var hits = Physics2D.OverlapCircleAll(transform.position, 5f, LayerMask.GetMask("Hero"));
          HeroBase best = null; float bestDist = float.MaxValue;
          foreach (var h in hits)
          {
              var hero = h.GetComponent<HeroBase>();
              if (hero == null || hero.Team == _hero.Team || hero.IsDead) continue;
              float d = Vector2.Distance(transform.position, hero.transform.position);
              if (d < bestDist) { bestDist = d; best = hero; }
          }
          return best;
      }
  }
  ```

- [ ] **Step 5: Create AssassinCombo.cs**

  ```csharp
  // Assets/Scripts/Hero/Skills/AssassinCombo.cs
  using System.Collections;
  using UnityEngine;

  public class AssassinCombo : SkillBase
  {
      [SerializeField] private int   hitCount      = 3;
      [SerializeField] private float perHitMulti   = 0.6f;
      [SerializeField] private float timeBetweenHits = 0.15f;

      protected override void Awake() { base.Awake(); cooldown = 6f; }

      protected override void Cast(Vector2 direction, HeroBase target)
      {
          if (target == null) target = FindNearestEnemy();
          if (target != null) StartCoroutine(ComboRoutine(target));
      }

      private IEnumerator ComboRoutine(HeroBase target)
      {
          for (int i = 0; i < hitCount; i++)
          {
              if (target == null || target.IsDead) yield break;
              target.TakeDamage(_hero.Attack * perHitMulti, _hero);
              yield return new WaitForSeconds(timeBetweenHits);
          }
      }

      private HeroBase FindNearestEnemy()
      {
          var hits = Physics2D.OverlapCircleAll(transform.position, _hero.Stats.attackRange * 1.5f, LayerMask.GetMask("Hero"));
          HeroBase best = null; float bestDist = float.MaxValue;
          foreach (var h in hits)
          {
              var hero = h.GetComponent<HeroBase>();
              if (hero == null || hero.Team == _hero.Team || hero.IsDead) continue;
              float d = Vector2.Distance(transform.position, hero.transform.position);
              if (d < bestDist) { bestDist = d; best = hero; }
          }
          return best;
      }
  }
  ```

- [ ] **Step 6: Create MageLightning.cs**

  ```csharp
  // Assets/Scripts/Hero/Skills/MageLightning.cs
  using System.Collections;
  using UnityEngine;

  public class MageLightning : SkillBase
  {
      [SerializeField] private float primaryDamage = 280f;
      [SerializeField] private float chainDamage   = 140f;
      [SerializeField] private int   chainCount    = 2;
      [SerializeField] private float chainRadius   = 3f;
      [SerializeField] private float projectileSpeed = 12f;

      protected override void Awake() { base.Awake(); cooldown = 7f; }

      protected override void Cast(Vector2 direction, HeroBase target)
          => StartCoroutine(FireBolt(direction));

      private IEnumerator FireBolt(Vector2 dir)
      {
          if (dir == Vector2.zero) dir = _hero.Team == Team.Radiant ? Vector2.up : Vector2.down;
          Vector3 pos = transform.position;
          float maxRange = 8f;
          float traveled = 0f;
          while (traveled < maxRange)
          {
              pos += (Vector3)(dir.normalized * projectileSpeed * Time.deltaTime);
              traveled += projectileSpeed * Time.deltaTime;

              var hit = Physics2D.OverlapCircle(pos, 0.3f, LayerMask.GetMask("Hero"));
              if (hit != null)
              {
                  var target = hit.GetComponent<HeroBase>();
                  if (target != null && target.Team != _hero.Team && !target.IsDead)
                  {
                      target.TakeDamage(primaryDamage, _hero);
                      ChainToNearby(target);
                      yield break;
                  }
              }
              yield return null;
          }
      }

      private void ChainToNearby(HeroBase firstTarget)
      {
          var hits = Physics2D.OverlapCircleAll(firstTarget.transform.position, chainRadius, LayerMask.GetMask("Hero"));
          int chained = 0;
          foreach (var h in hits)
          {
              if (chained >= chainCount) break;
              var hero = h.GetComponent<HeroBase>();
              if (hero == null || hero == firstTarget || hero.Team == _hero.Team || hero.IsDead) continue;
              hero.TakeDamage(chainDamage, _hero);
              chained++;
          }
      }
  }
  ```

- [ ] **Step 7: Create MageStorm.cs**

  ```csharp
  // Assets/Scripts/Hero/Skills/MageStorm.cs
  using System.Collections;
  using UnityEngine;

  public class MageStorm : SkillBase
  {
      [SerializeField] private float damagePerSecond = 120f;
      [SerializeField] private float duration        = 3f;
      [SerializeField] private float radius          = 2.5f;

      protected override void Awake() { base.Awake(); cooldown = 15f; }

      protected override void Cast(Vector2 direction, HeroBase target)
      {
          // Place storm at target location or in cast direction
          Vector3 center = target != null
              ? target.transform.position
              : transform.position + (Vector3)direction.normalized * 3f;
          StartCoroutine(StormRoutine(center));
      }

      private IEnumerator StormRoutine(Vector3 center)
      {
          float elapsed = 0f;
          while (elapsed < duration)
          {
              elapsed += Time.deltaTime;
              var hits = Physics2D.OverlapCircleAll(center, radius, LayerMask.GetMask("Hero"));
              foreach (var h in hits)
              {
                  var hero = h.GetComponent<HeroBase>();
                  if (hero == null || hero.Team == _hero.Team || hero.IsDead) continue;
                  hero.TakeDamage(damagePerSecond * Time.deltaTime, _hero);
              }
              yield return null;
          }
      }
  }
  ```

- [ ] **Step 8: Create hero prefabs + ScriptableObjects**

  For each hero, duplicate `HeroPlaceholder.prefab`:
  - **Guardian**: add `GuardianCharge` + `GuardianShield` components. Color sprite blue.
  - **Assassin**: add `AssassinBlink` + `AssassinCombo`. Color sprite red.
  - **Mage**: add `MageLightning` + `MageStorm`. Color sprite purple.

  Create `ScriptableObjects/Heroes/Assassin.asset` and `Mage.asset`, fill in stats from spec.

- [ ] **Step 9: Manual test**

  Spawn as Guardian. Attack an enemy. Use skill button (wired up in Task 13). Observe dash + stun. No console errors.

- [ ] **Step 10: Commit**

  ```bash
  git add Assets/Scripts/Hero/
  git commit -m "feat: SkillBase + 6 hero skills (Guardian, Assassin, Mage) with cooldowns"
  ```

---

## Task 12: Bot AI — Behavior Tree

**Files:**
- Create: `Assets/Scripts/AI/BehaviorNode.cs`
- Create: `Assets/Scripts/AI/BotController.cs`
- Create: `Assets/Tests/EditMode/BehaviorNodeTests.cs`

- [ ] **Step 1: Write failing behavior tree tests**

  ```csharp
  // Assets/Tests/EditMode/BehaviorNodeTests.cs
  using NUnit.Framework;

  public class BehaviorNodeTests
  {
      [Test]
      public void ShouldRetreat_WhenHpBelow20Percent()
      {
          Assert.IsTrue(BotLogic.ShouldRetreat(19f, 100f));
          Assert.IsFalse(BotLogic.ShouldRetreat(20f, 100f));
      }

      [Test]
      public void IsInRange_TrueWhenWithinDistance()
      {
          Assert.IsTrue(BotLogic.IsInRange(1.4f, 1.5f));
          Assert.IsFalse(BotLogic.IsInRange(1.6f, 1.5f));
      }
  }
  ```

  Run → expect **FAIL**.

- [ ] **Step 2: Create BehaviorNode.cs (pure logic)**

  ```csharp
  // Assets/Scripts/AI/BehaviorNode.cs
  public static class BotLogic
  {
      public static bool ShouldRetreat(float currentHp, float maxHp)
          => currentHp / maxHp < 0.20f;

      public static bool IsInRange(float distance, float range)
          => distance <= range;
  }
  ```

- [ ] **Step 3: Run tests — expect PASS**

- [ ] **Step 4: Create BotController.cs**

  ```csharp
  // Assets/Scripts/AI/BotController.cs
  using UnityEngine;

  [RequireComponent(typeof(HeroBase))]
  public class BotController : MonoBehaviour
  {
      private HeroBase _hero;
      private Transform _retreatPoint;
      private float _attackTimer;
      private Transform[] _laneWaypoints;
      private int _wpIndex;

      public void Init(HeroBase hero)
      {
          _hero = hero;
          // Assign a lane based on hero index — simple distribution
          // (assigned externally via GameManager)
      }

      public void SetLane(Transform[] waypoints, Transform retreatPoint)
      {
          _laneWaypoints = waypoints;
          _retreatPoint = retreatPoint;
          _wpIndex = 0;
      }

      private void Update()
      {
          if (_hero == null || _hero.IsDead || _hero.IsStunned) return;
          _attackTimer -= Time.deltaTime;

          if (BotLogic.ShouldRetreat(_hero.CurrentHp, _hero.MaxHp))
          {
              MoveTo(_retreatPoint != null ? _retreatPoint.position : _hero.transform.position);
              return;
          }

          HeroBase enemyHero = FindNearestEnemyHero();
          if (enemyHero != null)
          {
              float dist = Vector2.Distance(transform.position, enemyHero.transform.position);
              if (BotLogic.IsInRange(dist, _hero.Stats.attackRange))
              {
                  TryCastSkill(enemyHero);
                  if (_attackTimer <= 0)
                  {
                      enemyHero.TakeDamage(_hero.Attack, _hero);
                      _attackTimer = 1f / _hero.Stats.attackSpeed;
                  }
              }
              else
              {
                  MoveTo(enemyHero.transform.position);
              }
              return;
          }

          PushLane();
      }

      private void TryCastSkill(HeroBase target)
      {
          var skills = GetComponents<SkillBase>();
          foreach (var skill in skills)
          {
              if (skill.IsReady)
              {
                  skill.TryCast(Vector2.zero, target);
                  return;
              }
          }
      }

      private HeroBase FindNearestEnemyHero()
      {
          var hits = Physics2D.OverlapCircleAll(transform.position, 6f, LayerMask.GetMask("Hero"));
          HeroBase best = null; float bestDist = float.MaxValue;
          foreach (var h in hits)
          {
              var hero = h.GetComponent<HeroBase>();
              if (hero == null || hero.Team == _hero.Team || hero.IsDead) continue;
              float d = Vector2.Distance(transform.position, hero.transform.position);
              if (d < bestDist) { bestDist = d; best = hero; }
          }
          return best;
      }

      private void PushLane()
      {
          if (_laneWaypoints == null || _wpIndex >= _laneWaypoints.Length) return;
          MoveTo(_laneWaypoints[_wpIndex].position);
          if (Vector2.Distance(transform.position, _laneWaypoints[_wpIndex].position) < 0.15f)
              _wpIndex++;
      }

      private void MoveTo(Vector3 target)
      {
          Vector3 dir = (target - transform.position).normalized;
          transform.position = Vector3.MoveTowards(transform.position, target,
              _hero.MoveSpeed * Time.deltaTime);
          if (dir.x != 0)
              transform.localScale = new Vector3(dir.x > 0 ? 1 : -1, 1, 1);
      }
  }
  ```

- [ ] **Step 5: Update GameManager to assign lanes to bots**

  In `GameManager.SpawnHero`, after adding BotController, assign lane:
  ```csharp
  // In SpawnHero, for bots:
  var bot = go.AddComponent<BotController>();
  bot.Init(hero);
  // Assign lanes: bot index 0 → top, 1 → mid, 2 → bot
  // Reference LaneData assets from GameManager fields
  ```

  Add `[SerializeField] private Transform[][] botLaneWaypoints;` or expose individual lane references.

- [ ] **Step 6: Manual test**

  Enter Play mode. The 5 bots should spawn, walk their assigned lanes, attack enemies on sight, and retreat when low HP.

- [ ] **Step 7: Commit**

  ```bash
  git add Assets/Scripts/AI/
  git commit -m "feat: BotController with behavior tree (retreat, attack, push lane)"
  ```

---

## Task 13: Shop UI + 4 Items

**Files:**
- Create: `Assets/Scripts/Economy/ItemData.cs`
- Create: `Assets/Scripts/Economy/ShopController.cs`
- Create: `Assets/Scripts/UI/ShopUI.cs`

- [ ] **Step 1: Create ItemData.cs**

  ```csharp
  // Assets/Scripts/Economy/ItemData.cs
  using UnityEngine;

  [CreateAssetMenu(fileName = "NewItem", menuName = "FingerMOBA/ItemData")]
  public class ItemData : ScriptableObject
  {
      public string itemName;
      public int cost;
      public float bonusAttack;
      public float bonusHp;
      public float bonusMagicPower; // multiplier on skill damage
      public float bonusMoveSpeed;  // flat addition to moveSpeed
      public Sprite icon;
  }
  ```

- [ ] **Step 2: Create 4 item assets**

  Create in `Assets/ScriptableObjects/Items/`:

  | File | itemName | cost | bonusAttack | bonusHp | bonusMagicPower | bonusMoveSpeed |
  |---|---|---|---|---|---|---|
  | Sword.asset | 短剑 | 400 | 15 | 0 | 0 | 0 |
  | IronArmor.asset | 铁甲 | 500 | 0 | 200 | 0 | 0 |
  | MageStaff.asset | 法杖 | 600 | 0 | 0 | 40 | 0 |
  | SpeedBoots.asset | 速靴 | 300 | 0 | 0 | 0 | 0.5 |

- [ ] **Step 3: Create ShopController.cs**

  ```csharp
  // Assets/Scripts/Economy/ShopController.cs
  using UnityEngine;

  public class ShopController : MonoBehaviour
  {
      public static ShopController Instance { get; private set; }

      [SerializeField] private ItemData[] availableItems;

      private void Awake()
      {
          if (Instance != null) { Destroy(gameObject); return; }
          Instance = this;
      }

      public bool TryBuy(HeroBase hero, ItemData item)
      {
          bool purchased = GoldManager.Instance.TrySpend(hero.PlayerId, item.cost);
          if (!purchased) return false;
          ApplyItem(hero, item);
          return true;
      }

      private void ApplyItem(HeroBase hero, ItemData item)
      {
          hero.AddBonusAttack(item.bonusAttack);
          hero.AddBonusHp(item.bonusHp);
          hero.AddBonusMagicPower(item.bonusMagicPower);
          hero.AddBonusMoveSpeed(item.bonusMoveSpeed);
      }

      public ItemData[] GetAvailableItems() => availableItems;
  }
  ```

  Add bonus stat fields and methods to `HeroBase`:
  ```csharp
  // In HeroBase.cs — add bonus fields
  private float _bonusAttack;
  private float _bonusHp;
  private float _bonusMagicPower;
  private float _bonusMoveSpeed;

  public float Attack => Stats.attack + (Level - 1) * Stats.attackPerLevel + _bonusAttack;
  public float MagicPower => _bonusMagicPower;
  public float MoveSpeed => Stats.moveSpeed + _bonusMoveSpeed;

  public void AddBonusAttack(float v)     { _bonusAttack += v; }
  public void AddBonusHp(float v)         { _bonusHp += v; CurrentHp += v; }
  public void AddBonusMagicPower(float v) { _bonusMagicPower += v; }
  public void AddBonusMoveSpeed(float v)  { _bonusMoveSpeed += v; }

  // Update MaxHp to include bonusHp
  public float MaxHp => Stats.maxHp + (Level - 1) * Stats.hpPerLevel + _bonusHp;
  ```

- [ ] **Step 4: Create Shop UI**

  Under Canvas in GameScene:
  ```
  ShopPanel (initially inactive)
  ├── Background (semi-transparent black panel)
  ├── Title (Text: "商店")
  ├── ItemGrid (GridLayoutGroup, 2 columns)
  │   ├── ItemButton_0 (Button + Image + Text for price)
  │   ├── ItemButton_1
  │   ├── ItemButton_2
  │   └── ItemButton_3
  └── CloseButton
  ```

  Create `Assets/Scripts/UI/ShopUI.cs`:
  ```csharp
  // Assets/Scripts/UI/ShopUI.cs
  using UnityEngine;
  using UnityEngine.UI;

  public class ShopUI : MonoBehaviour
  {
      [SerializeField] private GameObject _panel;
      [SerializeField] private Button[] _itemButtons;
      [SerializeField] private Text[] _priceTexts;

      private HeroBase _playerHero;

      private void Start()
      {
          var items = ShopController.Instance.GetAvailableItems();
          for (int i = 0; i < _itemButtons.Length && i < items.Length; i++)
          {
              int idx = i;
              _priceTexts[i].text = $"{items[i].itemName}\n{items[i].cost}金";
              _itemButtons[i].onClick.AddListener(() => OnBuyItem(idx));
          }
          _panel.SetActive(false);
      }

      public void Toggle() => _panel.SetActive(!_panel.activeSelf);

      private void OnBuyItem(int idx)
      {
          if (_playerHero == null) return;
          var item = ShopController.Instance.GetAvailableItems()[idx];
          bool ok = ShopController.Instance.TryBuy(_playerHero, item);
          if (!ok) Debug.Log("金币不足");
      }

      public void SetPlayerHero(HeroBase hero) => _playerHero = hero;
  }
  ```

  Add a **Shop** button to the HUD that calls `ShopUI.Toggle()`.

- [ ] **Step 5: Manual test**

  Play scene. Click the Shop button. Buy 短剑. Verify gold decreases by 400 and hero attack stat increases.

- [ ] **Step 6: Commit**

  ```bash
  git add Assets/Scripts/Economy/ItemData.cs Assets/Scripts/Economy/ShopController.cs Assets/Scripts/UI/ShopUI.cs Assets/ScriptableObjects/Items/
  git commit -m "feat: shop system with 4 items, buy applies stat bonuses to hero"
  ```

---

## Task 14: HUD — HP Bars, Skill CD Rings, Gold + Level Display

**Files:**
- Create: `Assets/Scripts/UI/HeroHUD.cs`
- Create: `Assets/Scripts/UI/SkillButton.cs`

- [ ] **Step 1: Create SkillButton.cs**

  ```csharp
  // Assets/Scripts/UI/SkillButton.cs
  using UnityEngine;
  using UnityEngine.EventSystems;
  using UnityEngine.UI;

  public class SkillButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IDragHandler
  {
      [SerializeField] private Image _cdFill;       // Image type = Filled, Fill Method = Radial360
      [SerializeField] private Image _icon;
      [SerializeField] private int   _skillIndex;   // 0 = Skill A, 1 = Skill B

      private SkillBase _skill;
      private HeroController _controller;
      private Vector2 _dragStart;
      private Vector2 _dragDir;

      public void Init(SkillBase skill, HeroController ctrl)
      {
          _skill = skill;
          _controller = ctrl;
      }

      private void Update()
      {
          if (_skill == null) return;
          float fill = _skill.IsReady ? 0f : _skill.CooldownRemaining / _skill.Cooldown;
          // Expose Cooldown property: public float Cooldown => cooldown; in SkillBase
          _cdFill.fillAmount = fill;
          _icon.color = _skill.IsReady ? Color.white : Color.gray;
      }

      public void OnPointerDown(PointerEventData e)  => _dragStart = e.position;
      public void OnDrag(PointerEventData e)         => _dragDir = (e.position - _dragStart).normalized;
      public void OnPointerUp(PointerEventData e)
      {
          if (_skill == null || !_skill.IsReady) return;
          // If drag distance > 20px, directional cast; else target-based
          Vector2 dir = (e.position - _dragStart).magnitude > 20f ? _dragDir : Vector2.zero;
          _skill.TryCast(dir);
      }
  }
  ```

  Add `public float Cooldown => cooldown;` to `SkillBase.cs`.

- [ ] **Step 2: Create HeroHUD.cs**

  ```csharp
  // Assets/Scripts/UI/HeroHUD.cs
  using UnityEngine;
  using UnityEngine.UI;

  public class HeroHUD : MonoBehaviour
  {
      [SerializeField] private Slider  _hpBar;
      [SerializeField] private Text    _levelText;
      [SerializeField] private Text    _goldText;
      [SerializeField] private SkillButton _skillA;
      [SerializeField] private SkillButton _skillB;

      private HeroBase _hero;
      private HeroController _controller;

      public void Init(HeroBase hero, HeroController ctrl)
      {
          _hero = hero;
          _controller = ctrl;
          var skills = hero.GetComponents<SkillBase>();
          if (skills.Length > 0) _skillA.Init(skills[0], ctrl);
          if (skills.Length > 1) _skillB.Init(skills[1], ctrl);
          FindObjectOfType<ShopUI>()?.SetPlayerHero(hero);
      }

      private void Update()
      {
          if (_hero == null) return;
          _hpBar.value = _hero.CurrentHp / _hero.MaxHp;
          _levelText.text = $"Lv.{_hero.Level}";
          _goldText.text = $"{GoldManager.Instance?.Get(_hero.PlayerId) ?? 0}金";
      }
  }
  ```

- [ ] **Step 3: Build HUD layout in GameScene Canvas**

  ```
  Canvas
  ├── TopHUD
  │   ├── RadiantHP  (Slider, fill color green, top-left)
  │   └── DireHP     (Slider, fill color red, top-right)
  ├── PlayerHUD (bottom area)
  │   ├── HPBar      (Slider, red fill, width 80%, bottom-center)
  │   ├── LevelText  (Text, bottom-left)
  │   └── GoldText   (Text, bottom-center)
  ├── SkillPanel (bottom-right)
  │   ├── SkillButtonA (128×128 button with circular CD fill)
  │   └── SkillButtonB (128×128 button)
  └── ShopButton  (small button, bottom-center, "商店")
  ```

- [ ] **Step 4: Update GameManager to call HeroHUD.Init after spawning player**

  ```csharp
  // In GameManager.SpawnHero, after adding HeroController:
  var hud = FindObjectOfType<HeroHUD>();
  hud?.Init(hero, go.GetComponent<HeroController>());
  ```

- [ ] **Step 5: Manual test**

  Play scene. HP bar should reflect hero's current HP. Take damage from tower — bar decreases. Level up by killing minions — level text updates. Buy items — gold text decreases. Skill buttons show cooldown overlay when cast.

- [ ] **Step 6: Commit**

  ```bash
  git add Assets/Scripts/UI/HeroHUD.cs Assets/Scripts/UI/SkillButton.cs
  git commit -m "feat: HUD with HP bar, level/gold display, skill buttons with CD ring"
  ```

---

## Task 15: Result Screen + Full Game Flow

**Files:**
- Create: `Assets/Scripts/UI/ResultScreen.cs`
- Create: `Assets/Scenes/MainMenu.unity`

- [ ] **Step 1: Create ResultScreen.cs**

  ```csharp
  // Assets/Scripts/UI/ResultScreen.cs
  using UnityEngine;
  using UnityEngine.SceneManagement;
  using UnityEngine.UI;

  public class ResultScreen : MonoBehaviour
  {
      [SerializeField] private GameObject _panel;
      [SerializeField] private Text       _resultText;
      [SerializeField] private Button     _restartButton;

      private void Start()
      {
          _panel.SetActive(false);
          EventBus.On(EventBus.GAME_OVER, OnGameOver);
          _restartButton.onClick.AddListener(() => SceneManager.LoadScene("GameScene"));
      }

      private void OnGameOver(object data)
      {
          var d = (GameOverData)data;
          bool playerWon = d.Winner == Team.Radiant;
          _resultText.text = playerWon ? "胜利！" : "失败";
          _resultText.color = playerWon ? Color.yellow : Color.gray;
          _panel.SetActive(true);
          Time.timeScale = 0f;
      }

      private void OnDestroy()
      {
          EventBus.Off(EventBus.GAME_OVER, OnGameOver);
          Time.timeScale = 1f;
      }
  }
  ```

- [ ] **Step 2: Add ResultScreen to GameScene Canvas**

  ```
  Canvas
  └── ResultPanel (full-screen dark overlay, initially inactive)
      ├── ResultText   (large center text)
      └── RestartButton (Text: "再来一局")
  ```

  Attach `ResultScreen` component. Assign fields.

- [ ] **Step 3: Create MainMenu scene**

  Create `Assets/Scenes/MainMenu.unity`. Simple layout:
  ```
  Canvas
  ├── Title (Text: "FingerMOBA")
  └── StartButton (Text: "开始游戏")
  ```

  StartButton onClick: `SceneManager.LoadScene("GameScene")`.

  Add both scenes to Build Settings (File → Build Settings → Add Open Scenes).

- [ ] **Step 4: Manual test full game flow**

  1. Play from MainMenu → click 开始游戏 → GameScene loads
  2. Play until Radiant crystal is destroyed (or use Unity editor to simulate: manually call `EventBus.Emit(EventBus.CRYSTAL_DESTROYED, Team.Radiant)` from a debug menu)
  3. Result panel appears showing 胜利/失败
  4. Click 再来一局 → scene reloads, game restarts

- [ ] **Step 5: Commit**

  ```bash
  git add Assets/Scripts/UI/ResultScreen.cs Assets/Scenes/MainMenu.unity
  git commit -m "feat: result screen (win/lose overlay), main menu, full scene flow"
  ```

---

## Task 16: Android Build + Final Integration Test

**Files:**
- Modify: `ProjectSettings/ProjectSettings.asset` (via Unity UI)

- [ ] **Step 1: Set Android build configuration**

  File → Build Settings → Android → Player Settings:
  - Company Name: `WorldEngine`
  - Product Name: `FingerMOBA`
  - Package Name: `ai.worldengine.fingermoba`
  - Minimum API Level: `26`
  - Scripting Backend: **IL2CPP**
  - Target Architecture: **ARM64** (check ARMv7 too for wider compat)

- [ ] **Step 2: Build APK**

  File → Build Settings → Build → save as `Builds/fingermoba-demo.apk`.

  Expected: Build completes with 0 errors. Warnings about deprecated APIs are acceptable.

- [ ] **Step 3: Install on Android device**

  ```bash
  adb install Builds/fingermoba-demo.apk
  ```

  Or transfer APK manually and enable "Install from unknown sources".

- [ ] **Step 4: Integration test checklist on device**

  - [ ] Game launches without crash
  - [ ] Portrait orientation locked
  - [ ] Joystick appears on touch, hero moves
  - [ ] Minions spawn after ~5 seconds
  - [ ] Towers attack hero when in range
  - [ ] Killing a minion grants gold (HUD updates)
  - [ ] Hero levels up after enough XP
  - [ ] Skill buttons visible, CD ring animates after use
  - [ ] Shop opens, can buy item, gold decreases
  - [ ] Bots walk lanes and engage in combat
  - [ ] Game ends when crystal is destroyed

- [ ] **Step 5: Final commit + tag**

  ```bash
  git add .
  git commit -m "feat: Android build config, IL2CPP ARM64, complete demo integration"
  git tag v0.1.0-demo
  ```

---

## Quick Reference — Key Constants

| Constant | Value | Location |
|---|---|---|
| Minion spawn interval | 30s | `MinionSpawner.spawnInterval` |
| Minion gold reward | 40 | `MinionController.goldReward` |
| Hero kill gold | 200 | `GoldManagerLogic.HERO_KILL` |
| Tower kill gold | 150 | `GoldManagerLogic.TOWER_KILL` |
| Death gold drop | 50% | `GoldManagerLogic.DROP_RATE` |
| Respawn time | 5 + level×2 s | `HeroBase.CalcRespawnTime` |
| Max hero level | 10 | `HeroBase.XP_TO_NEXT.Length + 1` |
