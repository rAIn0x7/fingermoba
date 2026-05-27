using UnityEngine;

public class Crystal : MonoBehaviour
{
    [SerializeField] public Team team;
    public float maxHp = 3000f;
    public float CurrentHp { get; private set; }
    public bool IsDestroyed { get; private set; }

    private void Awake() => CurrentHp = maxHp;

    public void TakeDamage(float damage)
    {
        if (IsDestroyed) return;
        CurrentHp = Mathf.Max(0f, CurrentHp - damage);
        if (CurrentHp <= 0f) DestroyCrystal();
    }

    private void DestroyCrystal()
    {
        IsDestroyed = true;
        EventBus.Emit(EventBus.CRYSTAL_DESTROYED, team);
        gameObject.SetActive(false);
    }
}
