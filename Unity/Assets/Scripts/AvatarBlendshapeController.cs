using UnityEngine;
using System.Collections;

/// <summary>
/// Controls facial expressions using blendshapes (VRM standard)
/// Maps moods to specific facial expressions and manages micro-animations
/// </summary>
public class AvatarBlendshapeController : MonoBehaviour
{
    [Header("References")]
    public SkinnedMeshRenderer faceMesh;

    [Header("Blendshape Settings")]
    [Range(0f, 1f)]
    public float transitionSpeed = 0.3f;

    [Range(0f, 1f)]
    public float idleVariation = 0.15f;

    // VRM Standard Blendshape Indices
    // Note: These should match your 3D model's blendshape names
    private const int BLINK_LEFT = 0;
    private const int BLINK_RIGHT = 1;
    private const int SMILE = 2;
    private const int MOUTH_OPEN = 3;
    private const int MOUTH_WIDE = 4;
    private const int EYEBROW_UP_LEFT = 5;
    private const int EYEBROW_UP_RIGHT = 6;
    private const int EYEBROW_DOWN = 7;
    private const int EYE_WIDE = 8;

    // State
    private string currentMood = "neutral";
    private bool isBlinking = false;
    private Coroutine autoBlinkRoutine;

    #region Public API

    public void SetMood(string mood)
    {
        if (currentMood == mood) return;

        Debug.Log($"[BlendshapeController] Setting mood: {mood}");
        currentMood = mood;

        StopAllCoroutines();
        ResetAllBlendshapes();

        switch (mood)
        {
            case "happy":
                ApplyHappyExpression();
                break;

            case "excited":
                ApplyExcitedExpression();
                break;

            case "concerned":
                ApplyConcernedExpression();
                break;

            case "thinking":
                ApplyThinkingExpression();
                break;

            case "encouraging":
                ApplyEncouragingExpression();
                break;

            case "calm":
                ApplyCalmExpression();
                break;

            case "celebrating":
                ApplyCelebratingExpression();
                break;

            default:
                ApplyNeutralExpression();
                break;
        }

        // Restart automatic blinking
        StartAutoBlinking();

        // Add subtle idle variation
        StartCoroutine(IdleVariation());
    }

    public void Blink()
    {
        if (!isBlinking)
        {
            StartCoroutine(BlinkSequence());
        }
    }

    public void ResetToNeutral()
    {
        SetMood("neutral");
    }

    #endregion

    #region Mood Expressions

    private void ApplyNeutralExpression()
    {
        StartCoroutine(AnimateBlendshape(SMILE, 20f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_LEFT, 10f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_RIGHT, 10f, transitionSpeed));
    }

    private void ApplyHappyExpression()
    {
        StartCoroutine(AnimateBlendshape(SMILE, 70f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_LEFT, 30f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_RIGHT, 30f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(EYE_WIDE, 0f, transitionSpeed));
    }

    private void ApplyExcitedExpression()
    {
        StartCoroutine(AnimateBlendshape(SMILE, 100f, transitionSpeed * 0.5f)); // Fast smile
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_LEFT, 80f, transitionSpeed * 0.5f));
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_RIGHT, 80f, transitionSpeed * 0.5f));
        StartCoroutine(AnimateBlendshape(EYE_WIDE, 50f, transitionSpeed * 0.5f));
        StartCoroutine(AnimateBlendshape(MOUTH_WIDE, 40f, transitionSpeed * 0.5f));
    }

    private void ApplyConcernedExpression()
    {
        StartCoroutine(AnimateBlendshape(EYEBROW_DOWN, 60f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(SMILE, 15f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(MOUTH_OPEN, 10f, transitionSpeed));
    }

    private void ApplyThinkingExpression()
    {
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_LEFT, 50f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_RIGHT, 20f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(SMILE, 10f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(MOUTH_OPEN, 5f, transitionSpeed));
    }

    private void ApplyEncouragingExpression()
    {
        StartCoroutine(AnimateBlendshape(SMILE, 80f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_LEFT, 50f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_RIGHT, 50f, transitionSpeed));
        StartCoroutine(AnimateBlendshape(EYE_WIDE, 30f, transitionSpeed));
    }

    private void ApplyCalmExpression()
    {
        StartCoroutine(AnimateBlendshape(SMILE, 30f, transitionSpeed * 1.5f)); // Slower
        StartCoroutine(AnimateBlendshape(BLINK_LEFT, 10f, transitionSpeed * 1.5f)); // Half-closed eyes
        StartCoroutine(AnimateBlendshape(BLINK_RIGHT, 10f, transitionSpeed * 1.5f));
    }

    private void ApplyCelebratingExpression()
    {
        // Similar to excited but with mouth wide open
        StartCoroutine(AnimateBlendshape(SMILE, 100f, transitionSpeed * 0.3f));
        StartCoroutine(AnimateBlendshape(MOUTH_OPEN, 70f, transitionSpeed * 0.3f));
        StartCoroutine(AnimateBlendshape(MOUTH_WIDE, 60f, transitionSpeed * 0.3f));
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_LEFT, 90f, transitionSpeed * 0.3f));
        StartCoroutine(AnimateBlendshape(EYEBROW_UP_RIGHT, 90f, transitionSpeed * 0.3f));
        StartCoroutine(AnimateBlendshape(EYE_WIDE, 80f, transitionSpeed * 0.3f));
    }

    #endregion

    #region Animation Utilities

    private IEnumerator AnimateBlendshape(int index, float targetWeight, float duration)
    {
        if (faceMesh == null || index < 0 || index >= faceMesh.sharedMesh.blendShapeCount)
        {
            yield break;
        }

        float startWeight = faceMesh.GetBlendShapeWeight(index);
        float elapsed = 0f;

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float progress = elapsed / duration;

            // Use ease-in-out curve for smoother animation
            float smoothProgress = Mathf.SmoothStep(0f, 1f, progress);

            float currentWeight = Mathf.Lerp(startWeight, targetWeight, smoothProgress);
            faceMesh.SetBlendShapeWeight(index, currentWeight);

            yield return null;
        }

        faceMesh.SetBlendShapeWeight(index, targetWeight);
    }

    private void ResetAllBlendshapes()
    {
        if (faceMesh == null) return;

        for (int i = 0; i < faceMesh.sharedMesh.blendShapeCount; i++)
        {
            faceMesh.SetBlendShapeWeight(i, 0f);
        }
    }

    #endregion

    #region Automatic Behaviors

    private void StartAutoBlinking()
    {
        if (autoBlinkRoutine != null)
        {
            StopCoroutine(autoBlinkRoutine);
        }

        autoBlinkRoutine = StartCoroutine(AutoBlinkRoutine());
    }

    private IEnumerator AutoBlinkRoutine()
    {
        while (true)
        {
            // Random interval between blinks (2-5 seconds)
            float waitTime = Random.Range(2f, 5f);
            yield return new WaitForSeconds(waitTime);

            // Perform blink
            yield return BlinkSequence();

            // Occasional double blink
            if (Random.value < 0.2f) // 20% chance
            {
                yield return new WaitForSeconds(0.15f);
                yield return BlinkSequence();
            }
        }
    }

    private IEnumerator BlinkSequence()
    {
        isBlinking = true;

        // Close eyes quickly
        yield return StartCoroutine(AnimateBlendshape(BLINK_LEFT, 100f, 0.05f));
        yield return StartCoroutine(AnimateBlendshape(BLINK_RIGHT, 100f, 0.05f));

        // Brief pause
        yield return new WaitForSeconds(0.08f);

        // Open eyes
        yield return StartCoroutine(AnimateBlendshape(BLINK_LEFT, 0f, 0.08f));
        yield return StartCoroutine(AnimateBlendshape(BLINK_RIGHT, 0f, 0.08f));

        isBlinking = false;
    }

    private IEnumerator IdleVariation()
    {
        // Add subtle random movements to make avatar feel alive
        while (true)
        {
            yield return new WaitForSeconds(Random.Range(3f, 8f));

            // Subtle eyebrow movement
            if (Random.value > 0.5f)
            {
                int eyebrow = Random.value > 0.5f ? EYEBROW_UP_LEFT : EYEBROW_UP_RIGHT;
                float currentWeight = faceMesh.GetBlendShapeWeight(eyebrow);
                float variation = Random.Range(-10f, 10f);
                float targetWeight = Mathf.Clamp(currentWeight + variation, 0f, 100f);

                yield return StartCoroutine(AnimateBlendshape(eyebrow, targetWeight, 0.5f));
                yield return new WaitForSeconds(1f);
                yield return StartCoroutine(AnimateBlendshape(eyebrow, currentWeight, 0.5f));
            }

            // Subtle smile variation
            if (Random.value > 0.7f)
            {
                float currentSmile = faceMesh.GetBlendShapeWeight(SMILE);
                float variation = Random.Range(-5f, 15f);
                float targetSmile = Mathf.Clamp(currentSmile + variation, 0f, 100f);

                yield return StartCoroutine(AnimateBlendshape(SMILE, targetSmile, 0.8f));
                yield return new WaitForSeconds(1.5f);
                yield return StartCoroutine(AnimateBlendshape(SMILE, currentSmile, 0.8f));
            }
        }
    }

    #endregion

    #region Unity Lifecycle

    private void Start()
    {
        if (faceMesh == null)
        {
            faceMesh = GetComponent<SkinnedMeshRenderer>();
        }

        if (faceMesh == null)
        {
            Debug.LogError("[BlendshapeController] No SkinnedMeshRenderer found!");
            enabled = false;
            return;
        }

        // Verify blendshapes exist
        if (faceMesh.sharedMesh.blendShapeCount == 0)
        {
            Debug.LogWarning("[BlendshapeController] No blendshapes found on mesh!");
        }
        else
        {
            Debug.Log($"[BlendshapeController] Found {faceMesh.sharedMesh.blendShapeCount} blendshapes");
        }

        // Start in neutral mood
        SetMood("neutral");
    }

    private void OnDisable()
    {
        StopAllCoroutines();
    }

    #endregion

    #region Debug Utilities

    #if UNITY_EDITOR
    [ContextMenu("List All Blendshapes")]
    private void ListAllBlendshapes()
    {
        if (faceMesh == null || faceMesh.sharedMesh == null) return;

        Debug.Log("=== Blendshapes ===");
        for (int i = 0; i < faceMesh.sharedMesh.blendShapeCount; i++)
        {
            string name = faceMesh.sharedMesh.GetBlendShapeName(i);
            Debug.Log($"{i}: {name}");
        }
    }

    [ContextMenu("Test Happy Expression")]
    private void TestHappy() => SetMood("happy");

    [ContextMenu("Test Excited Expression")]
    private void TestExcited() => SetMood("excited");

    [ContextMenu("Test Concerned Expression")]
    private void TestConcerned() => SetMood("concerned");
    #endif

    #endregion
}
