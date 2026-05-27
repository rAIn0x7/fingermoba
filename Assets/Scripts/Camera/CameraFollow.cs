using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    [SerializeField] private float smoothSpeed  = 8f;
    [SerializeField] private float topLimit     =  10f;
    [SerializeField] private float bottomLimit  = -10f;

    private Transform _target;

    public void SetTarget(Transform t) => _target = t;

    private void LateUpdate()
    {
        if (_target == null) return;
        float targetY = Mathf.Clamp(_target.position.y, bottomLimit, topLimit);
        Vector3 desired = new Vector3(0f, targetY, transform.position.z);
        transform.position = Vector3.Lerp(transform.position, desired, smoothSpeed * Time.deltaTime);
    }
}
