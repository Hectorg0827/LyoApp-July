using UnityEngine;
using System;

/// <summary>
/// Receives lesson IDs from the native Swift app and displays lesson content in 3D
/// This script should be attached to a GameObject named "LessonLoader" in the Unity scene
/// </summary>
public class LessonLoader : MonoBehaviour
{
    [Header("UI References")]
    [SerializeField] private TextMesh lessonTitleText;
    [SerializeField] private TextMesh lessonContentText;
    [SerializeField] private GameObject lessonEnvironment;
    
    [Header("3D Models")]
    [SerializeField] private GameObject[] interactiveModels;
    
    [Header("Debug")]
    [SerializeField] private bool enableDebugLogs = true;
    
    private string currentCourseId;
    private string currentLessonId;
    
    void Start()
    {
        if (enableDebugLogs)
        {
            Debug.Log("✅ LessonLoader initialized and ready");
        }
    }
    
    /// <summary>
    /// Called by the Swift UnityBridge to load a specific lesson
    /// Message format: "courseId|lessonId"
    /// </summary>
    /// <param name="payload">Combined course and lesson IDs separated by |</param>
    public void LoadLesson(string payload)
    {
        if (enableDebugLogs)
        {
            Debug.Log($"📥 Received lesson payload from Swift: {payload}");
        }
        
        // Parse the payload
        string[] ids = payload.Split('|');
        if (ids.Length != 2)
        {
            Debug.LogError($"❌ Invalid lesson payload format: {payload}");
            return;
        }
        
        currentCourseId = ids[0];
        currentLessonId = ids[1];
        
        DisplayLesson(currentCourseId, currentLessonId);
    }
    
    /// <summary>
    /// Displays the lesson content in the 3D environment
    /// </summary>
    private void DisplayLesson(string courseId, string lessonId)
    {
        if (enableDebugLogs)
        {
            Debug.Log($"🎯 Loading lesson {lessonId} from course {courseId}");
        }
        
        // Activate the lesson environment
        if (lessonEnvironment != null)
        {
            lessonEnvironment.SetActive(true);
        }
        
        // Update lesson title and content
        // In a real app, this would fetch data from a server
        if (lessonTitleText != null)
        {
            lessonTitleText.text = "Lesson: " + lessonId.Substring(0, 8);
        }
        
        if (lessonContentText != null)
        {
            lessonContentText.text = "Interactive lesson content loads here";
        }
        
        // Activate interactive models for this lesson
        ActivateInteractiveModels(lessonId);
        
        // Send confirmation back to Swift
        SendMessageToSwift("LessonLoaded", lessonId);
    }
    
    /// <summary>
    /// Activates 3D models relevant to this lesson
    /// </summary>
    private void ActivateInteractiveModels(string lessonId)
    {
        if (interactiveModels == null || interactiveModels.Length == 0)
        {
            return;
        }
        
        // Example: Activate different models based on lesson
        // In a real app, this would be data-driven
        foreach (var model in interactiveModels)
        {
            if (model != null)
            {
                model.SetActive(true);
            }
        }
        
        if (enableDebugLogs)
        {
            Debug.Log($"✅ Activated {interactiveModels.Length} interactive models");
        }
    }
    
    /// <summary>
    /// Called when user completes the lesson (e.g., by button press)
    /// </summary>
    public void OnLessonComplete()
    {
        if (enableDebugLogs)
        {
            Debug.Log($"🎉 Lesson {currentLessonId} marked as complete");
        }
        
        // Send completion event back to Swift
        SendMessageToSwift("LessonCompleted", currentLessonId);
    }
    
    /// <summary>
    /// Sends a message back to the Swift app
    /// </summary>
    private void SendMessageToSwift(string methodName, string message)
    {
        string formattedMessage = $"LessonLoader:{methodName}:{message}";
        
        #if UNITY_IOS && !UNITY_EDITOR
        UnityEngine.iOS.Device.SetNoBackupFlag(formattedMessage);
        #endif
        
        if (enableDebugLogs)
        {
            Debug.Log($"📤 Sent message to Swift: {formattedMessage}");
        }
    }
}
