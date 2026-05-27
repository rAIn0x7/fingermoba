using UnityEngine;

[RequireComponent(typeof(HeroBase))]
public class HeroController : MonoBehaviour
{
    private HeroBase _hero;
    private VirtualJoystick _joystick;
    private HeroBase _lockedTarget;
    private float _attackTimer;

    private void Awake() => _hero = GetComponent<HeroBase>();

    private void Start() => _joystick = FindObjectOfType<VirtualJoystick>();

    private void Update()
    {
        if (_hero.IsDead) return;
        HandleMovement();
        HandleAutoAttack();
    }

    private void HandleMovement()
    {
        if (_hero.IsStunned) return;
        if (_joystick == null || !_joystick.IsActive) return;
        Vector2 dir = _joystick.Direction;
        transform.Translate(dir * (_hero.MoveSpeed * Time.deltaTime));
        if (dir.x != 0)
            transform.localScale = new Vector3(dir.x > 0 ? 1f : -1f, 1f, 1f);
    }

    private void HandleAutoAttack()
    {
        _attackTimer -= Time.deltaTime;
        if (_lockedTarget == null || _lockedTarget.IsDead) { _lockedTarget = null; return; }
        float dist = Vector2.Distance(transform.position, _lockedTarget.transform.position);
        if (dist > _hero.Stats.attackRange || _attackTimer > 0f) return;
        _lockedTarget.TakeDamage(_hero.Attack, _hero);
        _hero.GainXp(5); // small XP per hit
        _attackTimer = 1f / _hero.Stats.attackSpeed;
    }

    public void SetTarget(HeroBase target) => _lockedTarget = target;
}
