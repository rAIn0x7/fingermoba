using UnityEngine;

[CreateAssetMenu(fileName = "NewLane", menuName = "FingerMOBA/LaneData")]
public class LaneData : ScriptableObject
{
    public string laneName;                  // "Top", "Mid", "Bot"
    public Transform[] radiantWaypoints;    // bottom → top
    public Transform[] direWaypoints;       // top → bottom
}
