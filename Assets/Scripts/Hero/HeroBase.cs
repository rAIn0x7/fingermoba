using System.Collections;
using UnityEngine;

public class HeroBase : MonoBehaviour
{
    // XP needed to advance from Level N to N+1 (index = Level - 1)
    public static readonly int[] XP_TO_NEXT = { 100, 150, 180, 200, 220, 250, 280, 300, 350 };

    public static float CalcRespawnTime(int level) => 5f + level * 2f;

    public HeroStats Stats { get; private set; }
    public Team Team { get; private set; }
    public int PlayerId { get; private set; }

    public float CurrentHp { get; private set; }
    public float MaxHp => Stats.maxHp + (Level - 1) * Stats.hpPerLevel + _bonusHp;
    public float Attack => Stats.attack + (Level - 1) * Stats.attackPerLevel + _bonusAttack;
    public float MoveSpeed => Stats.moveSpeed + _bonusMoveSpeed;
    public float MagicPower => _bonusMagicPower;

    public int Level { get; private set; } = 1;
    public int Xp { get; private set; }
    public bool IsDead { get; private set; }
    public bool IsStunned => _stunTimer > 0f;

    private float _bonusAttack;
    private float _bonusHp;
    private float _bonusMagicPower;
    private float _bonusMoveSpeed;
    private float _stunTimer;
    private Transform _spawnPoint;

    public void Init(HeroStats stats, Team team, int playerId, Transform spawnPoint)
    {
        Stats = stats;
        Team = team;
        PlayerId = playerId;
        _spawnPoint = spawnPoint;
        CurrentHp = MaxHp;
        IsDead = false;
        Level = 1;
        Xp = 0;
        GoldManager.Instance?.Init(playerId);
    }

    private void Update()
    {
        if (_stunTimer > 0f) _stunTimer -= Time.deltaTime;
    }

    public void TakeDamage(float damage, HeroBase attacker = null)
    {
        if (IsDead) return;
        var shield = GetComponent<GuardianShield>();
        if (shield != null) damage = shield.AbsorbDamage(damage);
        CurrentHp = Mathf.Max(0f, CurrentHp - damage);
        if (CurrentHp <= 0f) Die(attacker);
    }

    private void Die(HeroBase killer)
    {
        IsDead = true;
        gameObject.SetActive(false);

        GoldManager.Instance?.ApplyDrop(PlayerId);

        if (killer != null)
            GoldManager.Instance?.Add(killer.PlayerId, GoldManagerLogic.HERO_KILL);

        EventBus.Emit(EventBus.HERO_DIED, new HeroDiedData { Hero = this, Killer = killer });
        StartCoroutine(RespawnRoutine(CalcRespawnTime(Level)));
    }

    private IEnumerator RespawnRoutine(float delay)
    {
        yield return new WaitForSeconds(delay);
        CurrentHp = MaxHp;
        transform.position = _spawnPoint.position;
        IsDead = false;
        gameObject.SetActive(true);
    }

    public void GainXp(int amount)
    {
        if (Level >= 10) return;
        Xp += amount;
        while (Level < 10 && Xp >= XP_TO_NEXT[Level - 1])
        {
            Xp -= XP_TO_NEXT[Level - 1];
            LevelUp();
        }
    }

    private void LevelUp()
    {
        Level++;
        CurrentHp = Mathf.Min(CurrentHp + Stats.hpPerLevel, MaxHp);
        EventBus.Emit(EventBus.HERO_LEVEL_UP, this);
    }

    public void ApplyStun(float duration)
        => _stunTimer = Mathf.Max(_stunTimer, duration);

    public void AddBonusAttack(float v)      { _bonusAttack += v; }
    public void AddBonusHp(float v)          { _bonusHp += v; CurrentHp += v; }
    public void AddBonusMagicPower(float v)  { _bonusMagicPower += v; }
    public void AddBonusMoveSpeed(float v)   { _bonusMoveSpeed += v; }
}
