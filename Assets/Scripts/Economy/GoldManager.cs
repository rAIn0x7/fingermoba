using UnityEngine;

public class GoldManager : MonoBehaviour
{
    public static GoldManager Instance { get; private set; }

    private readonly GoldManagerLogic _logic = new();

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
