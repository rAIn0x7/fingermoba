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
        // Player hero (Radiant index 0)
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
            var hud = FindObjectOfType<HeroHUD>();
            hud?.Init(hero, go.GetComponent<HeroController>());
            FindObjectOfType<ShopUI>()?.SetPlayerHero(hero);
        }
        else
        {
            var bot = go.AddComponent<BotController>();
            bot.Init(hero);
            // Lane assignment: Radiant bots index 1→top, 2→bot; Dire bots 10→top, 11→mid, 12→bot
            AssignLane(bot, team, id);
        }
    }

    private void AssignLane(BotController bot, Team team, int id)
    {
        // Subclasses or a LaneRegistry can override; wired up in editor
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
