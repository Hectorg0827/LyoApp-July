using UnityEngine;
using System;
using System.Collections.Generic;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;

/// <summary>
/// Main controller for 3D avatar - receives commands from Swift and manages avatar state
/// Integrates with Unity Addressables for dynamic asset loading
/// </summary>
public class AvatarManager : MonoBehaviour
{
    [Header("Avatar Components")]
    public SkinnedMeshRenderer bodyMesh;
    public SkinnedMeshRenderer hairMesh;
    public SkinnedMeshRenderer outfitMesh;
    public GameObject accessoriesParent;

    [Header("Controllers")]
    public Animator animator;
    public AvatarBlendshapeController blendshapes;
    public AvatarLipSyncController lipSync;

    [Header("Effects")]
    public ParticleSystem moodGlow;
    public Light avatarLight;

    [Header("Materials")]
    public Material skinMaterial;
    public List<Material> skinToneMaterials = new List<Material>();
    public List<Material> hairColorMaterials = new List<Material>();

    // Current state
    private AvatarConfig currentConfig;
    private string currentMood = "neutral";
    private bool isSpeaking = false;
    private List<GameObject> loadedAccessories = new List<GameObject>();

    #region Unity Lifecycle

    private void Start()
    {
        Debug.Log("[AvatarManager] Initialized and ready to receive commands from Swift");

        // Set default idle animation
        if (animator != null)
        {
            animator.SetTrigger("Idle");
        }
    }

    private void Update()
    {
        // Update light intensity based on mood
        if (avatarLight != null)
        {
            float targetIntensity = isSpeaking ? 1.2f : 0.8f;
            avatarLight.intensity = Mathf.Lerp(avatarLight.intensity, targetIntensity, Time.deltaTime * 2f);
        }
    }

    #endregion

    #region Swift Bridge Methods

    /// <summary>
    /// Called from Swift: Load avatar configuration
    /// </summary>
    public void LoadAvatar(string jsonConfig)
    {
        Debug.Log($"[AvatarManager] Loading avatar configuration: {jsonConfig}");

        try
        {
            currentConfig = JsonUtility.FromJson<AvatarConfig>(jsonConfig);
            ApplyAvatarConfiguration();
        }
        catch (Exception e)
        {
            Debug.LogError($"[AvatarManager] Failed to parse avatar config: {e.Message}");
        }
    }

    /// <summary>
    /// Called from Swift: Update avatar mood/emotion
    /// </summary>
    public void SetMood(string mood)
    {
        Debug.Log($"[AvatarManager] Setting mood to: {mood}");

        if (currentMood == mood) return;

        currentMood = mood;

        // Trigger mood animation
        if (animator != null)
        {
            animator.SetTrigger($"Mood_{mood}");
        }

        // Update visual effects
        UpdateMoodGlow(mood);
        UpdateLighting(mood);

        // Update facial expression
        if (blendshapes != null)
        {
            blendshapes.SetMood(mood);
        }
    }

    /// <summary>
    /// Called from Swift: Toggle speaking state and lip sync
    /// </summary>
    public void SetSpeaking(string speaking)
    {
        bool wasSpeaking = isSpeaking;
        isSpeaking = speaking.ToLower() == "true";

        Debug.Log($"[AvatarManager] Speaking state changed: {isSpeaking}");

        if (animator != null)
        {
            animator.SetBool("IsSpeaking", isSpeaking);
        }

        if (lipSync != null)
        {
            if (isSpeaking && !wasSpeaking)
            {
                lipSync.StartLipSync();
            }
            else if (!isSpeaking && wasSpeaking)
            {
                lipSync.StopLipSync();
            }
        }
    }

    /// <summary>
    /// Called from Swift: Play specific animation
    /// </summary>
    public void PlayAnimation(string animationName)
    {
        Debug.Log($"[AvatarManager] Playing animation: {animationName}");

        if (animator != null)
        {
            animator.SetTrigger(animationName);
        }
    }

    /// <summary>
    /// Called from Swift: Update avatar position/rotation
    /// </summary>
    public void SetTransform(string transformJson)
    {
        try
        {
            var transform = JsonUtility.FromJson<TransformData>(transformJson);
            this.transform.position = new Vector3(transform.x, transform.y, transform.z);
            this.transform.eulerAngles = new Vector3(transform.rotX, transform.rotY, transform.rotZ);
            this.transform.localScale = Vector3.one * transform.scale;
        }
        catch (Exception e)
        {
            Debug.LogError($"[AvatarManager] Failed to parse transform: {e.Message}");
        }
    }

    #endregion

    #region Avatar Configuration

    private void ApplyAvatarConfiguration()
    {
        Debug.Log($"[AvatarManager] Applying configuration for {currentConfig.name}");

        // Load body mesh based on style
        LoadBodyStyle(currentConfig.style);

        // Apply skin tone
        ApplySkinTone(currentConfig.skinTone);

        // Load hair
        LoadHairStyle(currentConfig.hairStyle, currentConfig.hairColor);

        // Load outfit
        LoadOutfit(currentConfig.outfit);

        // Load accessories
        LoadAccessories(currentConfig.accessories);

        // Set initial mood
        SetMood("neutral");
    }

    private void LoadBodyStyle(string style)
    {
        Debug.Log($"[AvatarManager] Loading body style: {style}");

        // Use Unity Addressables to load body mesh
        string addressableKey = $"Avatars/Bodies/{style}";

        Addressables.LoadAssetAsync<GameObject>(addressableKey).Completed += (AsyncOperationHandle<GameObject> handle) =>
        {
            if (handle.Status == AsyncOperationStatus.Succeeded)
            {
                Debug.Log($"[AvatarManager] Successfully loaded body: {style}");
                // Replace body mesh with loaded prefab
                if (bodyMesh != null && bodyMesh.transform.parent != null)
                {
                    Instantiate(handle.Result, bodyMesh.transform.parent);
                }
            }
            else
            {
                Debug.LogWarning($"[AvatarManager] Failed to load body style: {style}. Using default.");
            }
        };
    }

    private void ApplySkinTone(int toneIndex)
    {
        if (toneIndex < 0 || toneIndex >= skinToneMaterials.Count)
        {
            Debug.LogWarning($"[AvatarManager] Invalid skin tone index: {toneIndex}");
            return;
        }

        Debug.Log($"[AvatarManager] Applying skin tone: {toneIndex}");

        if (bodyMesh != null)
        {
            Material[] materials = bodyMesh.materials;
            materials[0] = skinToneMaterials[toneIndex]; // Assume first material is skin
            bodyMesh.materials = materials;
        }
    }

    private void LoadHairStyle(int styleIndex, int colorIndex)
    {
        Debug.Log($"[AvatarManager] Loading hair - style: {styleIndex}, color: {colorIndex}");

        string addressableKey = $"Avatars/Hair/Style_{styleIndex}";

        Addressables.LoadAssetAsync<GameObject>(addressableKey).Completed += (AsyncOperationHandle<GameObject> handle) =>
        {
            if (handle.Status == AsyncOperationStatus.Succeeded)
            {
                // Instantiate hair
                GameObject hair = Instantiate(handle.Result, transform);

                // Apply hair color
                if (colorIndex >= 0 && colorIndex < hairColorMaterials.Count)
                {
                    SkinnedMeshRenderer hairRenderer = hair.GetComponent<SkinnedMeshRenderer>();
                    if (hairRenderer != null)
                    {
                        hairRenderer.material = hairColorMaterials[colorIndex];
                    }
                }

                // Store reference
                hairMesh = hair.GetComponent<SkinnedMeshRenderer>();
            }
            else
            {
                Debug.LogWarning($"[AvatarManager] Failed to load hair style: {styleIndex}");
            }
        };
    }

    private void LoadOutfit(int outfitIndex)
    {
        Debug.Log($"[AvatarManager] Loading outfit: {outfitIndex}");

        string addressableKey = $"Avatars/Outfits/Outfit_{outfitIndex}";

        Addressables.LoadAssetAsync<GameObject>(addressableKey).Completed += (AsyncOperationHandle<GameObject> handle) =>
        {
            if (handle.Status == AsyncOperationStatus.Succeeded)
            {
                GameObject outfit = Instantiate(handle.Result, transform);
                outfitMesh = outfit.GetComponent<SkinnedMeshRenderer>();
            }
            else
            {
                Debug.LogWarning($"[AvatarManager] Failed to load outfit: {outfitIndex}");
            }
        };
    }

    private void LoadAccessories(List<int> accessoryIndices)
    {
        Debug.Log($"[AvatarManager] Loading {accessoryIndices.Count} accessories");

        // Clear existing accessories
        ClearAccessories();

        foreach (int index in accessoryIndices)
        {
            string addressableKey = $"Avatars/Accessories/Accessory_{index}";

            Addressables.LoadAssetAsync<GameObject>(addressableKey).Completed += (AsyncOperationHandle<GameObject> handle) =>
            {
                if (handle.Status == AsyncOperationStatus.Succeeded)
                {
                    GameObject accessory = Instantiate(handle.Result, accessoriesParent.transform);
                    loadedAccessories.Add(accessory);
                }
            };
        }
    }

    private void ClearAccessories()
    {
        foreach (GameObject accessory in loadedAccessories)
        {
            if (accessory != null)
            {
                Destroy(accessory);
            }
        }
        loadedAccessories.Clear();
    }

    #endregion

    #region Visual Effects

    private void UpdateMoodGlow(string mood)
    {
        if (moodGlow == null) return;

        Color glowColor = mood switch
        {
            "excited" => new Color(1f, 0.92f, 0.016f),     // Yellow
            "celebrating" => new Color(0.8f, 0f, 1f),      // Purple
            "encouraging" => new Color(0.3f, 1f, 0.3f),    // Green
            "thoughtful" => new Color(0.3f, 0.6f, 1f),     // Blue
            "concerned" => new Color(1f, 0.6f, 0f),        // Orange
            "calm" => new Color(0.6f, 0.8f, 1f),           // Light blue
            "happy" => new Color(1f, 0.8f, 0.9f),          // Pink
            _ => new Color(1f, 1f, 1f)                     // White (neutral)
        };

        var main = moodGlow.main;
        main.startColor = glowColor;

        // Adjust particle emission based on mood intensity
        var emission = moodGlow.emission;
        emission.rateOverTime = mood switch
        {
            "excited" or "celebrating" => 50f,
            "encouraging" or "happy" => 30f,
            _ => 20f
        };
    }

    private void UpdateLighting(string mood)
    {
        if (avatarLight == null) return;

        Color lightColor = mood switch
        {
            "excited" => Color.yellow,
            "celebrating" => new Color(1f, 0f, 1f),
            "encouraging" => Color.green,
            "thoughtful" => Color.cyan,
            _ => Color.white
        };

        avatarLight.color = lightColor;
    }

    #endregion

    #region Public API for Effects

    /// <summary>
    /// Trigger a level-up celebration effect
    /// </summary>
    public void TriggerLevelUp()
    {
        Debug.Log("[AvatarManager] LEVEL UP!");

        if (animator != null)
        {
            animator.SetTrigger("LevelUp");
        }

        StartCoroutine(LevelUpSequence());
    }

    private System.Collections.IEnumerator LevelUpSequence()
    {
        // Burst of particles
        if (moodGlow != null)
        {
            moodGlow.Emit(100);
        }

        // Scale up animation
        Vector3 originalScale = transform.localScale;
        float duration = 0.5f;
        float elapsed = 0f;

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float scale = Mathf.Lerp(1f, 1.3f, Mathf.Sin(elapsed / duration * Mathf.PI));
            transform.localScale = originalScale * scale;
            yield return null;
        }

        transform.localScale = originalScale;
    }

    #endregion
}

#region Data Classes

[Serializable]
public class AvatarConfig
{
    public string id;
    public string name;
    public string style;
    public int skinTone;
    public int hairStyle;
    public int hairColor;
    public int outfit;
    public List<int> accessories = new List<int>();
}

[Serializable]
public class TransformData
{
    public float x, y, z;
    public float rotX, rotY, rotZ;
    public float scale = 1f;
}

#endregion
