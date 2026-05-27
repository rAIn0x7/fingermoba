using UnityEngine;

[RequireComponent(typeof(HeroBase))]
public class BotController : MonoBehaviour
{
    private HeroBase _hero;
    private Transform _retreatPoint;
    private Transform[] _laneWaypoints;
    private int _wpIndex;
    private float _attackTimer;

    public void Init(HeroBase hero) => _hero = hero;

    public void SetLane(Transform[] waypoints, Transform retreatPoint)
    {
        _laneWaypoints = waypoints;
        _retreatPoint = retreatPoint;
        _wpIndex = 0;
    }

    private void Update()
    {
        if (_hero == null || _hero.IsDead || _hero.IsStunned) return;
        _attackTimer -= Time.deltaTime;

        if (BotLogic.ShouldRetreat(_hero.CurrentHp, _hero.MaxHp))
        {
            if (_retreatPoint != null) MoveTo(_retreatPoint.position);
            return;
        }

        HeroBase enemy = FindNearestEnemyHero();
        if (enemy != null)
        {
            float dist = Vector2.Distance(transform.position, enemy.transform.position);
            if (BotLogic.IsInRange(dist, _hero.Stats.attackRange))
            {
                TryCastSkill(enemy);
                if (_attackTimer <= 0f)
                {
                    enemy.TakeDamage(_hero.Attack, _hero);
                    _attackTimer = 1f / _hero.Stats.attackSpeed;
                }
            }
            else
            {
                MoveTo(enemy.transform.position);
            }
            return;
        }

        PushLane();
    }

    private void TryCastSkill(HeroBase target)
    {
        foreach (var skill in GetComponents<SkillBase>())
        {
            if (!skill.IsReady) continue;
            skill.TryCast(Vector2.zero, target);
            return;
        }
    }

    private HeroBase FindNearestEnemyHero()
    {
        var hits = Physics2D.OverlapCircleAll(transform.position, 6f, LayerMask.GetMask("Hero"));
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

    private void PushLane()
    {
        if (_laneWaypoints == null || _wpIndex >= _laneWaypoints.Length) return;
        MoveTo(_laneWaypoints[_wpIndex].position);
        if (Vector2.Distance(transform.position, _laneWaypoints[_wpIndex].position) < 0.15f)
            _wpIndex++;
    }

    private void MoveTo(Vector3 target)
    {
        Vector3 dir = (target - transform.position).normalized;
        transform.position = Vector3.MoveTowards(transform.position, target, _hero.MoveSpeed * Time.deltaTime);
        if (dir.x != 0)
            transform.localScale = new Vector3(dir.x > 0 ? 1f : -1f, 1f, 1f);
    }
}
