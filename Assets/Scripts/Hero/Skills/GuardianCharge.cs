using System.Collections;
using UnityEngine;

public class GuardianCharge : SkillBase
{
    [SerializeField] private float dashDistance = 4f;
    [SerializeField] private float dashSpeed    = 20f;
    [SerializeField] private float stunDuration = 1f;
    [SerializeField] private float damage       = 80f;

    protected override void Awake() { base.Awake(); cooldown = 8f; }

    protected override void Cast(Vector2 direction, HeroBase target)
    {
        if (direction == Vector2.zero)
            direction = _hero.Team == Team.Radiant ? Vector2.up : Vector2.down;
        StartCoroutine(DashRoutine(direction.normalized));
    }

    private IEnumerator DashRoutine(Vector2 dir)
    {
        Vector3 start = transform.position;
        Vector3 dest  = start + (Vector3)(dir * dashDistance);
        float duration = dashDistance / dashSpeed;
        float elapsed  = 0f;

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            transform.position = Vector3.Lerp(start, dest, elapsed / duration);

            var hits = Physics2D.OverlapCircleAll(transform.position, 0.6f, LayerMask.GetMask("Hero"));
            foreach (var h in hits)
            {
                var hero = h.GetComponent<HeroBase>();
                if (hero == null || hero == _hero || hero.Team == _hero.Team || hero.IsDead) continue;
                hero.TakeDamage(damage, _hero);
                hero.ApplyStun(stunDuration);
            }
            yield return null;
        }
        transform.position = dest;
    }
}
