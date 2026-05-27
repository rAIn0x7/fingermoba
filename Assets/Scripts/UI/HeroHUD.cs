using UnityEngine;
using UnityEngine.UI;

public class HeroHUD : MonoBehaviour
{
    [SerializeField] private Slider      _hpBar;
    [SerializeField] private Text        _levelText;
    [SerializeField] private Text        _goldText;
    [SerializeField] private SkillButton _skillButtonA;
    [SerializeField] private SkillButton _skillButtonB;

    private HeroBase _hero;

    public void Init(HeroBase hero, HeroController controller)
    {
        _hero = hero;
        var skills = hero.GetComponents<SkillBase>();
        if (skills.Length > 0) _skillButtonA?.Init(skills[0]);
        if (skills.Length > 1) _skillButtonB?.Init(skills[1]);
    }

    private void Update()
    {
        if (_hero == null) return;
        if (_hpBar != null)   _hpBar.value   = _hero.CurrentHp / _hero.MaxHp;
        if (_levelText != null) _levelText.text = $"Lv.{_hero.Level}";
        if (_goldText != null)
            _goldText.text = $"{GoldManager.Instance?.Get(_hero.PlayerId) ?? 0}金";
    }
}
