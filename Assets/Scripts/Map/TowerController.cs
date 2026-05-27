using UnityEngine;

public class TowerController : MonoBehaviour
{
    [SerializeField] public Team team;
    public float maxHp          = 2000f;
    public float attack         = 120f;
    public float attackRange    = 3f;
    public float attackCooldown = 1.5f;
    public float physicalArmor  = 0.3f; // 30% reduction

    public bool IsDestroyed { get; private set; }
    private float _currentHp;
    private float _attackTimer;

    private void Awake() { _currentHp = maxHp; _attackTimer = 0f; }

    private void Update()
    {
        if (IsDestroyed) return;
        _attackTimer -= Time.deltaTime;
        if (_attackTimer > 0f) return;

        var target = FindNearestEnemyHero();
        if (target == null) return;
        target.TakeDamage(attack);
        _attackTimer = attackCooldown;
    }

    private HeroBase FindNearestEnemyHero()
    {
        var hits = Physics2D.OverlapCircleAll(transform.position, attackRange, LayerMask.GetMask("Hero"));
        HeroBase best = null;
        float bestDist = float.MaxValue;
        foreach (var h in hits)
        {
            var hero = h.GetComponent<HeroBase>();
            if (hero == null || hero.Team == team || hero.IsDead) continue;
            float d = Vector2.Distance(transform.position, hero.transform.position);
            if (d < bestDist) { bestDist = d; best = hero; }
        }
        return best;
    }

    public void TakeDamage(float damage, bool isMagic = false)
    {
        if (IsDestroyed) return;
        float reduced = isMagic ? damage : damage * (1f - physicalArmor);
        _currentHp = Mathf.Max(0f, _currentHp - reduced);
        if (_currentHp <= 0f) DestroyTower();
    }

    private void DestroyTower()
    {
        IsDestroyed = true;
        EventBus.Emit(EventBus.TOWER_DESTROYED, this);
        gameObject.SetActive(false);
    }
}
