using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class SkillButton : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
{
    [SerializeField] private Image _cdFill;   // Image type=Filled, FillMethod=Radial360
    [SerializeField] private Image _icon;

    private SkillBase _skill;
    private Vector2 _dragStart;
    private Vector2 _dragDir;

    public void Init(SkillBase skill)
    {
        _skill = skill;
        if (_icon != null && skill != null)
            _icon.color = Color.white;
    }

    private void Update()
    {
        if (_skill == null) return;
        bool ready = _skill.IsReady;
        if (_cdFill != null)
            _cdFill.fillAmount = ready ? 0f : _skill.CooldownRemaining / _skill.Cooldown;
        if (_icon != null)
            _icon.color = ready ? Color.white : new Color(0.5f, 0.5f, 0.5f);
    }

    public void OnPointerDown(PointerEventData e) => _dragStart = e.position;
    public void OnDrag(PointerEventData e)
    {
        Vector2 delta = e.position - _dragStart;
        if (delta.magnitude > 20f) _dragDir = delta.normalized;
    }

    public void OnPointerUp(PointerEventData e)
    {
        if (_skill == null) return;
        Vector2 dir = (e.position - _dragStart).magnitude > 20f ? _dragDir : Vector2.zero;
        _skill.TryCast(dir);
        _dragDir = Vector2.zero;
    }
}
