using NUnit.Framework;

public class HeroBehaviorTests
{
    [Test]
    public void XpThreshold_Level1To2_Requires100Xp()
        => Assert.AreEqual(100, HeroBase.XP_TO_NEXT[0]);

    [Test]
    public void RespawnTime_Level1_Is7Seconds()
        => Assert.AreEqual(7f, HeroBase.CalcRespawnTime(1));

    [Test]
    public void RespawnTime_Level10_Is25Seconds()
        => Assert.AreEqual(25f, HeroBase.CalcRespawnTime(10));

    [Test]
    public void XpArray_HasNineEntries_ForLevels1Through9()
        => Assert.AreEqual(9, HeroBase.XP_TO_NEXT.Length);
}
