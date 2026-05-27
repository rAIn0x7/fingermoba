using UnityEngine;

public class MinionSpawner : MonoBehaviour
{
    [SerializeField] private GameObject minionPrefab;
    [SerializeField] private float spawnInterval = 30f;
    [SerializeField] private int   minionsPerLane = 4;

    [Header("Radiant Waypoints (bottom→top)")]
    [SerializeField] private Transform[] radiantTopWaypoints;
    [SerializeField] private Transform[] radiantMidWaypoints;
    [SerializeField] private Transform[] radiantBotWaypoints;

    [Header("Dire Waypoints (top→bottom)")]
    [SerializeField] private Transform[] direTopWaypoints;
    [SerializeField] private Transform[] direMidWaypoints;
    [SerializeField] private Transform[] direBotWaypoints;

    [SerializeField] private Transform radiantSpawnPoint;
    [SerializeField] private Transform direSpawnPoint;

    private float _timer;

    private void Start() => _timer = 5f; // first wave after 5 seconds

    private void Update()
    {
        _timer -= Time.deltaTime;
        if (_timer > 0f) return;
        _timer = spawnInterval;
        SpawnWave(Team.Radiant);
        SpawnWave(Team.Dire);
    }

    private void SpawnWave(Team team)
    {
        bool isRadiant = team == Team.Radiant;
        SpawnLane(team, isRadiant ? radiantTopWaypoints : direTopWaypoints);
        SpawnLane(team, isRadiant ? radiantMidWaypoints : direMidWaypoints);
        SpawnLane(team, isRadiant ? radiantBotWaypoints : direBotWaypoints);
    }

    private void SpawnLane(Team team, Transform[] waypoints)
    {
        if (waypoints == null || waypoints.Length == 0) return;
        Transform spawnPt = team == Team.Radiant ? radiantSpawnPoint : direSpawnPoint;
        for (int i = 0; i < minionsPerLane; i++)
        {
            Vector3 offset = new Vector3(Random.Range(-0.3f, 0.3f), i * 0.4f, 0f);
            var go = Instantiate(minionPrefab, spawnPt.position + offset, Quaternion.identity);
            go.GetComponent<MinionController>().Init(team, waypoints);
        }
    }
}
