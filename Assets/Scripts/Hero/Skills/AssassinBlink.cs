using UnityEngine;

public class AssassinBlink : SkillBase
{
    [SerializeField] private float damageMultiplier = 2.0f;
    [SerializeField] private float seekRange        = 5f;

    protected override void Awake() { base.Awake(); cooldown = 10f; }

    protected override void Cast(Vector2 direction, HeroBase target)
    {
        if (target == null) target = FindNearestEnemy();
        if (target == null) return;

        Vector3 toTarget = (target.transform.position - transform.position).normalized;
        transform.position = target.transform.position - toTarget * 0.5f;
        target.TakeDamage(_hero.Attack * damageMultiplier, _hero);
    }

    private HeroBase FindNearestEnemy()
    {
        var hits = Physics2D.OverlapCircleAll(transform.position, seekRange, LayerMask.GetMask("Hero"));
        HeroBase best = null;
        float bestDist = float.MaxValue;
        foreach (var h in hits)
        {
            var hero = h.GetComponent<HeroBase>();
            if (hero == null || hero.Team == _hero.Team || hero.IsDead) continue;
            float d = Vector2.Distance(transform.position, hero.transform.position);
            if (d < bestDist) { bestDist = d; best = hero; }
        }
        return best;
    }
}
