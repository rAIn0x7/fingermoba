using NUnit.Framework;
using UnityEngine;

public class HeroStatsTests
{
    [Test]
    public void HeroStats_DefaultValues_AreReasonable()
    {
        var stats = ScriptableObject.CreateInstance<HeroStats>();
        stats.maxHp      = 1000f;
        stats.hpPerLevel = 80f;
        Assert.AreEqual(1000f, stats.maxHp);
        Assert.AreEqual(80f,   stats.hpPerLevel);
    }
}
