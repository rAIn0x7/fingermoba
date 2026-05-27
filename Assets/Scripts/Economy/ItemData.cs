using UnityEngine;

[CreateAssetMenu(fileName = "NewItem", menuName = "FingerMOBA/ItemData")]
public class ItemData : ScriptableObject
{
    public string itemName;
    public int    cost;
    public float  bonusAttack;
    public float  bonusHp;
    public float  bonusMagicPower;  // adds to hero.MagicPower
    public float  bonusMoveSpeed;   // flat addition to moveSpeed
    public Sprite icon;
}
