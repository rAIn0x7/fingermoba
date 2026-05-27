using System.Collections.Generic;

public class GoldManagerLogic
{
    public const int   MINION_KILL = 40;
    public const int   HERO_KILL   = 200;
    public const int   HERO_ASSIST = 100;
    public const int   TOWER_KILL  = 150;
    public const float DROP_RATE   = 0.5f;

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
        if (!_gold.ContainsKey(playerId)) return;
        _gold[playerId] -= CalculateDrop(playerId);
    }

    public bool CanAfford(int playerId, int cost) => Get(playerId) >= cost;

    public bool TrySpend(int playerId, int cost)
    {
        if (!CanAfford(playerId, cost)) return false;
        _gold[playerId] -= cost;
        return true;
    }
}
