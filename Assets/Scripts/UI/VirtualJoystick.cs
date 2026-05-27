using UnityEngine;
using UnityEngine.EventSystems;

public class VirtualJoystick : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
{
    [SerializeField] private RectTransform _background;
    [SerializeField] private RectTransform _handle;
    [SerializeField] private float _maxRadius = 70f;

    public Vector2 Direction { get; private set; }
    public bool IsActive { get; private set; }

    private Vector2 _originPos;

    public void OnPointerDown(PointerEventData e)
    {
        IsActive = true;
        _background.position = e.position;
        _originPos = e.position;
        UpdateHandle(e.position);
    }

    public void OnDrag(PointerEventData e) => UpdateHandle(e.position);

    public void OnPointerUp(PointerEventData e)
    {
        IsActive = false;
        Direction = Vector2.zero;
        _handle.anchoredPosition = Vector2.zero;
    }

    private void UpdateHandle(Vector2 pos)
    {
        Vector2 delta = pos - _originPos;
        if (delta.magnitude > _maxRadius) delta = delta.normalized * _maxRadius;
        Direction = delta / _maxRadius;
        _handle.anchoredPosition = delta;
    }
}
