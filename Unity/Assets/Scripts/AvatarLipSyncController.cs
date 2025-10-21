using UnityEngine;
using System.Collections;

/// <summary>
/// Controls lip sync animation for avatar speech
/// Supports both procedural animation and OVR LipSync integration
/// </summary>
public class AvatarLipSyncController : MonoBehaviour
{
    [Header("References")]
    public SkinnedMeshRenderer faceMesh;
    public AudioSource audioSource;

    [Header("Lip Sync Settings")]
    public LipSyncMode mode = LipSyncMode.Procedural;
    [Range(0f, 1f)]
    public float intensity = 0.8f;
    [Range(0f, 2f)]
    public float speed = 1.0f;

    [Header("Blendshape Indices")]
    public int mouthOpenIndex = 3;
    public int mouthWideIndex = 4;
    public int mouthPuckerIndex = 5;

    // State
    private bool isLipSyncing = false;
    private Coroutine lipSyncRoutine;

    // Audio analysis
    private float[] audioSpectrum = new float[256];
    private float currentVolume = 0f;

    public enum LipSyncMode
    {
        Procedural,      // Simple random movement
        AudioReactive,   // Based on audio volume
        OVRLipSync       // Using OVR LipSync plugin (future)
    }

    #region Public API

    public void StartLipSync()
    {
        if (isLipSyncing) return;

        Debug.Log($"[LipSyncController] Starting lip sync - Mode: {mode}");
        isLipSyncing = true;

        if (lipSyncRoutine != null)
        {
            StopCoroutine(lipSyncRoutine);
        }

        switch (mode)
        {
            case LipSyncMode.Procedural:
                lipSyncRoutine = StartCoroutine(ProceduralLipSync());
                break;

            case LipSyncMode.AudioReactive:
                lipSyncRoutine = StartCoroutine(AudioReactiveLipSync());
                break;

            case LipSyncMode.OVRLipSync:
                // Initialize OVR LipSync if available
                Debug.LogWarning("[LipSyncController] OVR LipSync not yet implemented, using procedural");
                lipSyncRoutine = StartCoroutine(ProceduralLipSync());
                break;
        }
    }

    public void StopLipSync()
    {
        if (!isLipSyncing) return;

        Debug.Log("[LipSyncController] Stopping lip sync");
        isLipSyncing = false;

        if (lipSyncRoutine != null)
        {
            StopCoroutine(lipSyncRoutine);
            lipSyncRoutine = null;
        }

        // Reset mouth to closed
        StartCoroutine(CloseMouth());
    }

    #endregion

    #region Lip Sync Modes

    /// <summary>
    /// Simple procedural lip sync with random movements
    /// Good for basic speech animation without audio analysis
    /// </summary>
    private IEnumerator ProceduralLipSync()
    {
        while (isLipSyncing)
        {
            // Random mouth open amount
            float targetOpen = Random.Range(30f, 70f) * intensity;
            float targetWide = Random.Range(0f, 40f) * intensity;

            // Animate to target
            yield return AnimateBlendshape(mouthOpenIndex, targetOpen, 0.08f / speed);
            yield return AnimateBlendshape(mouthWideIndex, targetWide, 0.08f / speed);

            // Hold briefly
            yield return new WaitForSeconds(Random.Range(0.05f, 0.15f) / speed);

            // Close
            yield return AnimateBlendshape(mouthOpenIndex, 0f, 0.06f / speed);
            yield return AnimateBlendshape(mouthWideIndex, 0f, 0.06f / speed);

            // Brief pause between phonemes
            yield return new WaitForSeconds(Random.Range(0.03f, 0.1f) / speed);

            // Occasional mouth shapes
            if (Random.value > 0.7f)
            {
                // Pucker lips (for "oo" sounds)
                yield return AnimateBlendshape(mouthPuckerIndex, Random.Range(30f, 60f) * intensity, 0.05f);
                yield return new WaitForSeconds(0.08f / speed);
                yield return AnimateBlendshape(mouthPuckerIndex, 0f, 0.05f);
            }
        }

        yield return CloseMouth();
    }

    /// <summary>
    /// Audio-reactive lip sync using microphone or audio playback analysis
    /// More realistic as it responds to actual audio amplitude
    /// </summary>
    private IEnumerator AudioReactiveLipSync()
    {
        while (isLipSyncing)
        {
            // Get audio volume
            float volume = GetAudioVolume();

            // Map volume to mouth open amount (0-100)
            float targetOpen = Mathf.Lerp(0f, 80f, volume) * intensity;

            // Add some width based on higher frequencies
            float targetWide = Mathf.Lerp(0f, 40f, volume * 0.7f) * intensity;

            // Smooth transition
            yield return AnimateBlendshape(mouthOpenIndex, targetOpen, 0.05f);
            yield return AnimateBlendshape(mouthWideIndex, targetWide, 0.05f);

            // Wait for next frame
            yield return null;
        }

        yield return CloseMouth();
    }

    /// <summary>
    /// Get current audio volume from audio source or microphone
    /// </summary>
    private float GetAudioVolume()
    {
        if (audioSource == null || !audioSource.isPlaying)
        {
            // Fall back to random for testing
            return Random.Range(0.3f, 0.9f);
        }

        // Get audio spectrum data
        audioSource.GetSpectrumData(audioSpectrum, 0, FFTWindow.BlackmanHarris);

        // Calculate volume from lower frequencies (speech range: 80-255 Hz)
        float sum = 0f;
        for (int i = 10; i < 100; i++) // Focus on speech frequencies
        {
            sum += audioSpectrum[i];
        }

        // Smooth the volume
        float targetVolume = Mathf.Clamp01(sum * 10f);
        currentVolume = Mathf.Lerp(currentVolume, targetVolume, Time.deltaTime * 20f);

        return currentVolume;
    }

    /// <summary>
    /// Close mouth smoothly
    /// </summary>
    private IEnumerator CloseMouth()
    {
        float duration = 0.2f;
        float elapsed = 0f;

        float startOpen = faceMesh.GetBlendShapeWeight(mouthOpenIndex);
        float startWide = faceMesh.GetBlendShapeWeight(mouthWideIndex);
        float startPucker = faceMesh.GetBlendShapeWeight(mouthPuckerIndex);

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float progress = elapsed / duration;

            faceMesh.SetBlendShapeWeight(mouthOpenIndex, Mathf.Lerp(startOpen, 0f, progress));
            faceMesh.SetBlendShapeWeight(mouthWideIndex, Mathf.Lerp(startWide, 0f, progress));
            faceMesh.SetBlendShapeWeight(mouthPuckerIndex, Mathf.Lerp(startPucker, 0f, progress));

            yield return null;
        }

        faceMesh.SetBlendShapeWeight(mouthOpenIndex, 0f);
        faceMesh.SetBlendShapeWeight(mouthWideIndex, 0f);
        faceMesh.SetBlendShapeWeight(mouthPuckerIndex, 0f);
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
            float currentWeight = Mathf.Lerp(startWeight, targetWeight, progress);
            faceMesh.SetBlendShapeWeight(index, currentWeight);
            yield return null;
        }

        faceMesh.SetBlendShapeWeight(index, targetWeight);
    }

    #endregion

    #region Unity Lifecycle

    private void Start()
    {
        if (faceMesh == null)
        {
            faceMesh = GetComponent<SkinnedMeshRenderer>();
        }

        if (audioSource == null)
        {
            audioSource = GetComponent<AudioSource>();
        }

        Debug.Log($"[LipSyncController] Initialized - Mode: {mode}");
    }

    private void OnDisable()
    {
        StopLipSync();
    }

    #endregion

    #region OVR LipSync Integration (Future)

    // TODO: Integrate with OVR LipSync SDK
    // Reference: https://developer.oculus.com/downloads/package/oculus-lipsync-unity/
    //
    // private OVRLipSync.Frame frame = new OVRLipSync.Frame();
    //
    // private IEnumerator OVRLipSyncRoutine()
    // {
    //     while (isLipSyncing)
    //     {
    //         // Get viseme data from OVR LipSync
    //         OVRLipSync.ProcessFrame(audioSource, frame);
    //
    //         // Map visemes to blendshapes
    //         // visemes[0] = sil (silence)
    //         // visemes[1] = PP (mouth closed)
    //         // visemes[2] = FF (teeth on lower lip)
    //         // ... etc
    //
    //         yield return null;
    //     }
    // }

    #endregion

    #region Debug Utilities

    #if UNITY_EDITOR
    [ContextMenu("Test Lip Sync (3 seconds)")]
    private void TestLipSync()
    {
        StartCoroutine(TestLipSyncRoutine());
    }

    private IEnumerator TestLipSyncRoutine()
    {
        StartLipSync();
        yield return new WaitForSeconds(3f);
        StopLipSync();
    }
    #endif

    #endregion
}
