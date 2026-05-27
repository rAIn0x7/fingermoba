using UnityEngine;

public abstract class SkillBase : MonoBehaviour
{
    [SerializeField] protected float cooldown = 8f;

    public float Cooldown => cooldown;
    public float CooldownRemaining { get; private set; }
    public bool IsReady => CooldownRemaining <= 0f;

    protected HeroBase _hero;

    protected virtual void Awake() => _hero = GetComponent<HeroBase>();

    protected virtual void Update()
    {
        if (CooldownRemaining > 0f) CooldownRemaining -= Time.deltaTime;
    }

    public void TryCast(Vector2 direction, HeroBase target = null)
    {
        if (!IsReady || _hero.IsDead || _hero.IsStunned) return;
        CooldownRemaining = cooldown;
        Cast(direction, target);
    }

    protected abstract void Cast(Vector2 direction, HeroBase target);
}
