using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class ResultScreen : MonoBehaviour
{
    [SerializeField] private GameObject _panel;
    [SerializeField] private Text       _resultText;
    [SerializeField] private Button     _restartButton;

    private void Start()
    {
        _panel.SetActive(false);
        EventBus.On(EventBus.GAME_OVER, OnGameOver);
        _restartButton.onClick.AddListener(() =>
        {
            Time.timeScale = 1f;
            SceneManager.LoadScene("GameScene");
        });
    }

    private void OnGameOver(object data)
    {
        var d = (GameOverData)data;
        bool playerWon = d.Winner == Team.Radiant;
        _resultText.text  = playerWon ? "胜利！" : "失败";
        _resultText.color = playerWon ? Color.yellow : Color.gray;
        _panel.SetActive(true);
        Time.timeScale = 0f;
    }

    private void OnDestroy()
    {
        EventBus.Off(EventBus.GAME_OVER, OnGameOver);
        Time.timeScale = 1f;
    }
}
