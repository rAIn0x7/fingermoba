using System.Collections;
using UnityEngine;

public class MageLightning : SkillBase
{
    [SerializeField] private float primaryDamage   = 280f;
    [SerializeField] private float chainDamage     = 140f;
    [SerializeField] private int   chainCount      = 2;
    [SerializeField] private float chainRadius     = 3f;
    [SerializeField] private float projectileSpeed = 12f;
    [SerializeField] private float maxRange        = 8f;

    protected override void Awake() { base.Awake(); cooldown = 7f; }

    protected override void Cast(Vector2 direction, HeroBase target)
    {
        if (direction == Vector2.zero)
            direction = _hero.Team == Team.Radiant ? Vector2.up : Vector2.down;
        StartCoroutine(FireBolt(direction.normalized));
    }

    private IEnumerator FireBolt(Vector2 dir)
    {
        Vector3 pos = transform.position;
        float traveled = 0f;

        while (traveled < maxRange)
        {
            float step = projectileSpeed * Time.deltaTime;
            pos += (Vector3)(dir * step);
            traveled += step;

            var hit = Physics2D.OverlapCircle(pos, 0.3f, LayerMask.GetMask("Hero"));
            if (hit != null)
            {
                var hero = hit.GetComponent<HeroBase>();
                if (hero != null && hero.Team != _hero.Team && !hero.IsDead)
                {
                    hero.TakeDamage(primaryDamage * (1f + _hero.MagicPower / 100f), _hero);
                    ChainToNearby(hero);
                    yield break;
                }
            }
            yield return null;
        }
    }

    private void ChainToNearby(HeroBase firstTarget)
    {
        var hits = Physics2D.OverlapCircleAll(firstTarget.transform.position, chainRadius, LayerMask.GetMask("Hero"));
        int chained = 0;
        foreach (var h in hits)
        {
            if (chained >= chainCount) break;
            var hero = h.GetComponent<HeroBase>();
            if (hero == null || hero == firstTarget || hero.Team == _hero.Team || hero.IsDead) continue;
            hero.TakeDamage(chainDamage * (1f + _hero.MagicPower / 100f), _hero);
            chained++;
        }
    }
}
