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

    [Test]
    public void GoldCannotGoBelowZero()
    {
        _gm.Add(0, 50);
        _gm.Add(0, -200);
        Assert.AreEqual(0, _gm.Get(0));
    }
}
