public static class BotLogic
{
    public static bool ShouldRetreat(float currentHp, float maxHp)
        => currentHp / maxHp < 0.20f;

    public static bool IsInRange(float distance, float range)
        => distance <= range;
}
