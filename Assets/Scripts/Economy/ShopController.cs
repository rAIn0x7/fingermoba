using UnityEngine;

public class ShopController : MonoBehaviour
{
    public static ShopController Instance { get; private set; }

    [SerializeField] private ItemData[] availableItems;

    private void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
    }

    public ItemData[] GetAvailableItems() => availableItems;

    public bool TryBuy(HeroBase hero, ItemData item)
    {
        if (!GoldManager.Instance.TrySpend(hero.PlayerId, item.cost)) return false;
        hero.AddBonusAttack(item.bonusAttack);
        hero.AddBonusHp(item.bonusHp);
        hero.AddBonusMagicPower(item.bonusMagicPower);
        hero.AddBonusMoveSpeed(item.bonusMoveSpeed);
        return true;
    }
}
