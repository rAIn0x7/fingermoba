using UnityEngine;

public class MinionController : MonoBehaviour
{
    public Team Team { get; private set; }
    public bool IsDead { get; private set; }

    [SerializeField] private float maxHp         = 400f;
    [SerializeField] private float attack         = 30f;
    [SerializeField] private float moveSpeed      = 2.0f;
    [SerializeField] private float attackRange    = 0.8f;
    [SerializeField] private float attackCooldown = 1.2f;
    [SerializeField] private int   xpReward       = 30;
    [SerializeField] private int   goldReward      = 40;

    private float _currentHp;
    private float _attackTimer;
    private Transform[] _waypoints;
    private int _wpIndex;

    public void Init(Team team, Transform[] waypoints)
    {
        Team = team;
        _currentHp = maxHp;
        _waypoints = waypoints;
        _wpIndex = 0;
    }

    private void Update()
    {
        if (IsDead) return;
        _attackTimer -= Time.deltaTime;

        Transform enemy = FindNearestEnemy();
        if (enemy != null && Vector2.Distance(transform.position, enemy.position) <= attackRange)
        {
            if (_attackTimer <= 0f) { AttackEnemy(enemy); _attackTimer = attackCooldown; }
        }
        else
        {
            FollowWaypoints();
        }
    }

    private Transform FindNearestEnemy()
    {
        int mask = LayerMask.GetMask("Hero", "Tower", "Minion");
        var hits = Physics2D.OverlapCircleAll(transform.position, attackRange * 2f, mask);
        Transform nearest = null;
        float nearestDist = float.MaxValue;
        foreach (var h in hits)
        {
            if (!IsEnemyTarget(h)) continue;
            float d = Vector2.Distance(transform.position, h.transform.position);
            if (d < nearestDist) { nearestDist = d; nearest = h.transform; }
        }
        return nearest;
    }

    private bool IsEnemyTarget(Collider2D col)
    {
        var hero = col.GetComponent<HeroBase>();
        if (hero != null && hero.Team != Team && !hero.IsDead) return true;
        var minion = col.GetComponent<MinionController>();
        if (minion != null && minion.Team != Team && !minion.IsDead) return true;
        var tower = col.GetComponent<TowerController>();
        if (tower != null && tower.team != Team && !tower.IsDestroyed) return true;
        var crystal = col.GetComponent<Crystal>();
        if (crystal != null && crystal.team != Team && !crystal.IsDestroyed) return true;
        return false;
    }

    private void AttackEnemy(Transform target)
    {
        target.GetComponent<HeroBase>()?.TakeDamage(attack);
        target.GetComponent<MinionController>()?.TakeDamage(attack, null);
        target.GetComponent<TowerController>()?.TakeDamage(attack);
        target.GetComponent<Crystal>()?.TakeDamage(attack);
    }

    private void FollowWaypoints()
    {
        if (_waypoints == null || _wpIndex >= _waypoints.Length) return;
        Transform wp = _waypoints[_wpIndex];
        transform.position = Vector2.MoveTowards(transform.position, wp.position, moveSpeed * Time.deltaTime);
        if (Vector2.Distance(transform.position, wp.position) < 0.05f) _wpIndex++;
    }

    public void TakeDamage(float damage, HeroBase attacker)
    {
        if (IsDead) return;
        _currentHp = Mathf.Max(0f, _currentHp - damage);
        if (_currentHp <= 0f) Die(attacker);
    }

    private void Die(HeroBase killer)
    {
        IsDead = true;
        if (killer != null)
        {
            GoldManager.Instance?.Add(killer.PlayerId, goldReward);
            killer.GainXp(xpReward);
        }
        EventBus.Emit(EventBus.MINION_DIED, this);
        Destroy(gameObject, 0.3f);
    }
}
