using System.Collections;
using UnityEngine;

public class MageStorm : SkillBase
{
    [SerializeField] private float damagePerSecond = 120f;
    [SerializeField] private float duration        = 3f;
    [SerializeField] private float radius          = 2.5f;
    [SerializeField] private float castRange       = 3f;

    protected override void Awake() { base.Awake(); cooldown = 15f; }

    protected override void Cast(Vector2 direction, HeroBase target)
    {
        Vector3 center = target != null
            ? target.transform.position
            : transform.position + (Vector3)(direction.normalized * castRange);
        StartCoroutine(StormRoutine(center));
    }

    private IEnumerator StormRoutine(Vector3 center)
    {
        float elapsed = 0f;
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            var hits = Physics2D.OverlapCircleAll(center, radius, LayerMask.GetMask("Hero"));
            foreach (var h in hits)
            {
                var hero = h.GetComponent<HeroBase>();
                if (hero == null || hero.Team == _hero.Team || hero.IsDead) continue;
                hero.TakeDamage(damagePerSecond * (1f + _hero.MagicPower / 100f) * Time.deltaTime, _hero);
            }
            yield return null;
        }
    }
}
