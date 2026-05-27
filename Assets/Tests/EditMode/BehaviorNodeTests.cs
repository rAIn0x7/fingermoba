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

    [Test]
    public void ShouldRetreat_Exactly20Percent_ReturnsFalse()
        => Assert.IsFalse(BotLogic.ShouldRetreat(20f, 100f));
}
