using System.Collections;
using UnityEngine;

public class AssassinCombo : SkillBase
{
    [SerializeField] private int   hitCount         = 3;
    [SerializeField] private float perHitMultiplier = 0.6f;
    [SerializeField] private float timeBetweenHits  = 0.15f;

    protected override void Awake() { base.Awake(); cooldown = 6f; }

    protected override void Cast(Vector2 direction, HeroBase target)
    {
        if (target == null) target = FindNearestEnemy();
        if (target != null) StartCoroutine(ComboRoutine(target));
    }

    private IEnumerator ComboRoutine(HeroBase target)
    {
        for (int i = 0; i < hitCount; i++)
        {
            if (target == null || target.IsDead) yield break;
            target.TakeDamage(_hero.Attack * perHitMultiplier, _hero);
            yield return new WaitForSeconds(timeBetweenHits);
        }
    }

    private HeroBase FindNearestEnemy()
    {
        var hits = Physics2D.OverlapCircleAll(transform.position, _hero.Stats.attackRange * 1.5f, LayerMask.GetMask("Hero"));
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
