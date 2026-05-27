public enum Team { Radiant, Dire }
public enum GamePhase { Playing, GameOver }

public class HeroDiedData
{
    public HeroBase Hero;
    public HeroBase Killer; // null = killed by tower or minion
}

public class GameOverData
{
    public Team Winner;
}
