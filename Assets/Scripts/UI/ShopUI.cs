using UnityEngine;
using UnityEngine.UI;

public class ShopUI : MonoBehaviour
{
    [SerializeField] private GameObject _panel;
    [SerializeField] private Button[]   _itemButtons;
    [SerializeField] private Text[]     _itemLabels;

    private HeroBase _playerHero;

    private void Start()
    {
        _panel.SetActive(false);
        var items = ShopController.Instance?.GetAvailableItems();
        if (items == null) return;
        for (int i = 0; i < _itemButtons.Length && i < items.Length; i++)
        {
            int idx = i;
            _itemLabels[i].text = $"{items[i].itemName}\n{items[i].cost}金";
            _itemButtons[i].onClick.AddListener(() => OnBuyItem(idx));
        }
    }

    public void Toggle() => _panel.SetActive(!_panel.activeSelf);

    public void SetPlayerHero(HeroBase hero) => _playerHero = hero;

    private void OnBuyItem(int idx)
    {
        if (_playerHero == null) return;
        var items = ShopController.Instance.GetAvailableItems();
        if (idx >= items.Length) return;
        bool ok = ShopController.Instance.TryBuy(_playerHero, items[idx]);
        if (!ok) Debug.Log("金币不足");
    }
}
