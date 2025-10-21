using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// Main controller for the LyoApp Unity classroom integration
/// Receives messages from Swift via UnitySendMessage and manages the 3D learning environment
/// </summary>
public class ClassroomController : MonoBehaviour
{
    #region Inspector Fields
    
    [Header("Environment Prefabs")]
    [Tooltip("Default modern classroom environment")]
    public GameObject defaultClassroom;
    
    [Tooltip("Ancient Maya civilization environment with temples")]
    public GameObject mayaCivilization;
    
    [Tooltip("Science laboratory with equipment")]
    public GameObject chemistryLab;
    
    [Tooltip("Mars surface exploration environment")]
    public GameObject marsExploration;
    
    [Tooltip("Mathematics studio with visualizations")]
    public GameObject mathematicsStudio;
    
    [Header("Interactive Elements")]
    public GameObject[] interactiveObjects;
    public Transform[] lessonMarkers;
    
    [Header("Audio")]
    public AudioSource backgroundMusic;
    public AudioClip[] environmentSounds;
    
    #endregion
    
    #region Private Fields
    
    private CourseData currentCourse;
    private string currentEnvironmentName;
    private float courseProgress = 0f;
    private List<GameObject> activeEnvironments = new List<GameObject>();
    
    #endregion
    
    #region Unity Lifecycle
    
    private void Awake()
    {
        Debug.Log("[ClassroomController] Initializing...");
        
        // Deactivate all environments on start
        DeactivateAllEnvironments();
    }
    
    private void Start()
    {
        Debug.Log("[ClassroomController] Ready to receive course data from Swift");
    }
    
    #endregion
    
    #region Public Methods (Called from Swift via UnitySendMessage)
    
    /// <summary>
    /// Main entry point called from Swift with course JSON data
    /// Format: {"courseId":"...", "title":"...", "environment":"...", ...}
    /// </summary>
    public void LoadCourse(string jsonData)
    {
        Debug.Log($"[ClassroomController] 📥 Received course data from Swift: {jsonData}");
        
        try
        {
            // Parse JSON
            currentCourse = JsonUtility.FromJson<CourseData>(jsonData);
            
            Debug.Log($"[ClassroomController] ✅ Parsed course: {currentCourse.title}");
            Debug.Log($"[ClassroomController]    Environment: {currentCourse.environment}");
            Debug.Log($"[ClassroomController]    Difficulty: {currentCourse.difficulty}");
            Debug.Log($"[ClassroomController]    Category: {currentCourse.category}");
            
            // Load appropriate environment
            LoadEnvironment(currentCourse.environment);
            
            // Configure course-specific elements
            ConfigureCourseElements();
            
            // Reset progress
            courseProgress = 0f;
            
            // Play environment audio
            PlayEnvironmentAudio();
            
            Debug.Log("[ClassroomController] 🎓 Course loaded successfully!");
        }
        catch (Exception e)
        {
            Debug.LogError($"[ClassroomController] ❌ Failed to load course: {e.Message}");
            Debug.LogError($"[ClassroomController] Stack trace: {e.StackTrace}");
            
            // Fallback to default classroom
            LoadEnvironment("DefaultClassroom");
        }
    }
    
    /// <summary>
    /// Update course progress (0.0 to 1.0)
    /// </summary>
    public void UpdateProgress(string progressString)
    {
        if (float.TryParse(progressString, out float progress))
        {
            courseProgress = Mathf.Clamp01(progress);
            Debug.Log($"[ClassroomController] 📊 Progress updated: {courseProgress * 100}%");
            
            // TODO: Update UI progress bar
            // TODO: Unlock new areas based on progress
        }
    }
    
    /// <summary>
    /// Highlight a specific lesson marker
    /// </summary>
    public void HighlightLesson(string lessonIndex)
    {
        if (int.TryParse(lessonIndex, out int index))
        {
            if (index >= 0 && index < lessonMarkers.Length)
            {
                Debug.Log($"[ClassroomController] 🎯 Highlighting lesson {index}");
                // TODO: Add visual highlight effect
            }
        }
    }
    
    /// <summary>
    /// Enable/disable interactive mode
    /// </summary>
    public void SetInteractiveMode(string enabled)
    {
        bool isEnabled = enabled.ToLower() == "true";
        Debug.Log($"[ClassroomController] 🖱️ Interactive mode: {isEnabled}");
        
        foreach (var obj in interactiveObjects)
        {
            if (obj != null)
            {
                // Enable/disable interaction scripts
                var interactable = obj.GetComponent<Interactable>();
                if (interactable != null)
                {
                    interactable.enabled = isEnabled;
                }
            }
        }
    }
    
    #endregion
    
    #region Private Methods
    
    private void LoadEnvironment(string environmentName)
    {
        Debug.Log($"[ClassroomController] 🌍 Loading environment: {environmentName}");
        
        // Deactivate all environments first
        DeactivateAllEnvironments();
        
        // Activate requested environment
        GameObject targetEnvironment = null;
        
        switch (environmentName.ToLower())
        {
            case "mayacivilization":
            case "historical":
                targetEnvironment = mayaCivilization;
                currentEnvironmentName = "Maya Civilization";
                break;
                
            case "chemistrylab":
            case "laboratory":
            case "science":
                targetEnvironment = chemistryLab;
                currentEnvironmentName = "Chemistry Lab";
                break;
                
            case "marsexploration":
            case "cosmos":
            case "space":
                targetEnvironment = marsExploration;
                currentEnvironmentName = "Mars Exploration";
                break;
                
            case "mathematicsstudio":
            case "math":
                targetEnvironment = mathematicsStudio;
                currentEnvironmentName = "Mathematics Studio";
                break;
                
            case "defaultclassroom":
            default:
                targetEnvironment = defaultClassroom;
                currentEnvironmentName = "Modern Classroom";
                break;
        }
        
        if (targetEnvironment != null)
        {
            targetEnvironment.SetActive(true);
            activeEnvironments.Add(targetEnvironment);
            Debug.Log($"[ClassroomController] ✅ Environment activated: {currentEnvironmentName}");
        }
        else
        {
            Debug.LogWarning($"[ClassroomController] ⚠️ Environment prefab not assigned: {environmentName}");
            
            // Fallback to default
            if (defaultClassroom != null)
            {
                defaultClassroom.SetActive(true);
                currentEnvironmentName = "Default Classroom (Fallback)";
                Debug.Log("[ClassroomController] 📍 Loaded fallback environment");
            }
        }
    }
    
    private void DeactivateAllEnvironments()
    {
        if (defaultClassroom != null) defaultClassroom.SetActive(false);
        if (mayaCivilization != null) mayaCivilization.SetActive(false);
        if (chemistryLab != null) chemistryLab.SetActive(false);
        if (marsExploration != null) marsExploration.SetActive(false);
        if (mathematicsStudio != null) mathematicsStudio.SetActive(false);
        
        activeEnvironments.Clear();
    }
    
    private void ConfigureCourseElements()
    {
        if (currentCourse == null) return;
        
        Debug.Log("[ClassroomController] 🔧 Configuring course-specific elements");
        
        // Configure lesson markers based on course duration
        int estimatedLessons = ParseDurationToLessons(currentCourse.estimatedDuration);
        Debug.Log($"[ClassroomController]    Estimated lessons: {estimatedLessons}");
        
        // Configure difficulty-based elements
        ConfigureDifficulty(currentCourse.difficulty);
        
        // Add category-specific interactions
        ConfigureCategoryInteractions(currentCourse.category);
    }
    
    private int ParseDurationToLessons(string duration)
    {
        // Simple heuristic: 1 lesson per 15 minutes
        // "45 min" → 3 lessons
        // "1h 30m" → 6 lessons
        
        if (string.IsNullOrEmpty(duration)) return 3; // Default
        
        int minutes = 0;
        
        if (duration.Contains("h"))
        {
            var parts = duration.Split('h');
            if (parts.Length > 0 && int.TryParse(parts[0].Trim(), out int hours))
            {
                minutes += hours * 60;
            }
        }
        
        if (duration.Contains("min"))
        {
            var parts = duration.Split(new[] { "min", "m" }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length > 0)
            {
                var lastPart = parts[parts.Length - 1].Trim();
                if (int.TryParse(lastPart, out int mins))
                {
                    minutes += mins;
                }
            }
        }
        
        return Mathf.Max(1, minutes / 15); // At least 1 lesson
    }
    
    private void ConfigureDifficulty(string difficulty)
    {
        switch (difficulty.ToLower())
        {
            case "beginner":
                Debug.Log("[ClassroomController]    Difficulty: Beginner - Adding extra guidance");
                // Add tutorial markers, hints, etc.
                break;
                
            case "intermediate":
                Debug.Log("[ClassroomController]    Difficulty: Intermediate - Standard setup");
                // Standard configuration
                break;
                
            case "advanced":
            case "expert":
                Debug.Log("[ClassroomController]    Difficulty: Advanced - Minimal guidance");
                // Reduce hints, add challenges
                break;
        }
    }
    
    private void ConfigureCategoryInteractions(string category)
    {
        Debug.Log($"[ClassroomController]    Category: {category}");
        
        // Category-specific interactive elements
        switch (category.ToLower())
        {
            case "history":
                // Enable historical artifacts, timelines
                break;
                
            case "science":
                // Enable lab equipment, experiments
                break;
                
            case "math":
                // Enable graphing tools, calculators
                break;
                
            case "programming":
                // Enable code editors, debugging tools
                break;
        }
    }
    
    private void PlayEnvironmentAudio()
    {
        if (backgroundMusic == null) return;
        
        // Select appropriate audio clip based on environment
        if (environmentSounds != null && environmentSounds.Length > 0)
        {
            int clipIndex = UnityEngine.Random.Range(0, environmentSounds.Length);
            backgroundMusic.clip = environmentSounds[clipIndex];
            backgroundMusic.Play();
        }
    }
    
    #endregion
    
    #region Callback Methods (Send data back to Swift)
    
    /// <summary>
    /// Report progress back to Swift (Not currently implemented - requires Swift callback setup)
    /// </summary>
    private void ReportProgressToSwift(float percentage)
    {
        // TODO: Implement callback mechanism to Swift
        // This would require additional setup in UnityManager.swift
        Debug.Log($"[ClassroomController] 📤 Would report to Swift: {percentage}% complete");
    }
    
    #endregion
}

#region Data Models

/// <summary>
/// Course data model matching the JSON structure sent from Swift
/// Must match LearningResource.toUnityJSON() format
/// </summary>
[Serializable]
public class CourseData
{
    public string courseId;
    public string title;
    public string description;
    public string difficulty;
    public string estimatedDuration;
    public string category;
    public string environment;
    public string provider;
    public float rating;
    public int enrolledCount;
    public string[] tags;
}

/// <summary>
/// Example interactable component for objects in the scene
/// </summary>
public class Interactable : MonoBehaviour
{
    public void OnInteract()
    {
        Debug.Log($"[Interactable] User interacted with {gameObject.name}");
        // Implement interaction logic
    }
}

#endregion
