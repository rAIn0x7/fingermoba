using System;
using System.Collections.Generic;

public static class EventBus
{
    public const string HERO_DIED         = "hero.died";
    public const string HERO_LEVEL_UP     = "hero.levelup";
    public const string TOWER_DESTROYED   = "tower.destroyed";
    public const string CRYSTAL_DESTROYED = "crystal.destroyed";
    public const string GOLD_CHANGED      = "gold.changed";
    public const string MINION_DIED       = "minion.died";
    public const string GAME_OVER         = "game.over";

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
