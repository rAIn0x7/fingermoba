using UnityEngine;

[CreateAssetMenu(fileName = "NewHeroStats", menuName = "FingerMOBA/HeroStats")]
public class HeroStats : ScriptableObject
{
    public string heroName;

    [Header("Base Stats")]
    public float maxHp       = 1000f;
    public float attack      = 60f;
    public float moveSpeed   = 3.3f;   // Unity units/sec
    public float attackSpeed = 1.0f;   // attacks/sec
    public float attackRange = 1.5f;   // Unity units
    public float physicalArmor = 0f;   // 0–1, flat % reduction
    public float magicResist   = 0f;

    [Header("Per Level Growth")]
    public float hpPerLevel     = 80f;
    public float attackPerLevel = 4f;

    [Header("Visuals")]
    public GameObject prefab;
    public Sprite portrait;
}
