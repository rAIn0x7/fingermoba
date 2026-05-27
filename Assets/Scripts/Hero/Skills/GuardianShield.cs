using System.Collections;
using UnityEngine;

public class GuardianShield : SkillBase
{
    [SerializeField] private float shieldAmount  = 300f;
    [SerializeField] private float shieldDuration = 4f;

    private float _shieldRemaining;

    protected override void Awake() { base.Awake(); cooldown = 12f; }

    protected override void Cast(Vector2 direction, HeroBase target)
        => StartCoroutine(ShieldRoutine());

    private IEnumerator ShieldRoutine()
    {
        _shieldRemaining = shieldAmount;
        yield return new WaitForSeconds(shieldDuration);
        _shieldRemaining = 0f;
    }

    // Called by HeroBase.TakeDamage to absorb incoming damage
    public float AbsorbDamage(float incoming)
    {
        if (_shieldRemaining <= 0f) return incoming;
        float absorbed = Mathf.Min(_shieldRemaining, incoming);
        _shieldRemaining -= absorbed;
        return incoming - absorbed;
    }
}
