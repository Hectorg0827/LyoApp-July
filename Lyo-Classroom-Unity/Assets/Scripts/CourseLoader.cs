using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// Receives course IDs from the native Swift app and dynamically loads course content
/// This script should be attached to a GameObject named "CourseLoader" in the Unity scene
/// </summary>
public class CourseLoader : MonoBehaviour
{
    [Header("UI References")]
    [SerializeField] private TextMesh courseTitleText;
    [SerializeField] private TextMesh courseDescriptionText;
    [SerializeField] private GameObject[] lessonObjects;
    
    [Header("Debug")]
    [SerializeField] private bool enableDebugLogs = true;
    
    private string currentCourseId;
    private Dictionary<string, CourseData> courseDatabase = new Dictionary<string, CourseData>();
    
    void Start()
    {
        // Initialize with some sample course data
        // In a real app, this would be loaded from a server or local database
        InitializeSampleCourses();
        
        if (enableDebugLogs)
        {
            Debug.Log("✅ CourseLoader initialized and ready to receive course IDs from Swift");
        }
    }
    
    /// <summary>
    /// Called by the Swift UnityBridge when a course should be loaded
    /// This method name must match the methodName parameter in sendMessageToUnity()
    /// </summary>
    /// <param name="courseId">The UUID string of the course to load</param>
    public void LoadCourse(string courseId)
    {
        if (enableDebugLogs)
        {
            Debug.Log($"📥 Received course ID from Swift: {courseId}");
        }
        
        currentCourseId = courseId;
        
        // Check if we have this course in our database
        if (courseDatabase.ContainsKey(courseId))
        {
            CourseData course = courseDatabase[courseId];
            DisplayCourse(course);
            
            // Send confirmation back to Swift
            SendMessageToSwift("CourseLoaded", courseId);
        }
        else
        {
            // Course not found - could trigger a download or show error
            if (enableDebugLogs)
            {
                Debug.LogWarning($"⚠️ Course {courseId} not found in database");
            }
            
            // For demo purposes, create a placeholder course
            CreatePlaceholderCourse(courseId);
        }
    }
    
    /// <summary>
    /// Displays the course content in the 3D environment
    /// </summary>
    private void DisplayCourse(CourseData course)
    {
        if (enableDebugLogs)
        {
            Debug.Log($"🎓 Loading course: {course.title}");
        }
        
        // Update UI elements
        if (courseTitleText != null)
        {
            courseTitleText.text = course.title;
        }
        
        if (courseDescriptionText != null)
        {
            courseDescriptionText.text = course.description;
        }
        
        // Activate lesson objects based on course content
        int lessonCount = Mathf.Min(course.lessons.Count, lessonObjects != null ? lessonObjects.Length : 0);
        
        if (lessonObjects != null)
        {
            for (int i = 0; i < lessonObjects.Length; i++)
            {
                if (i < lessonCount)
                {
                    lessonObjects[i].SetActive(true);
                    // You could set lesson-specific data here
                }
                else
                {
                    lessonObjects[i].SetActive(false);
                }
            }
        }
        
        // Trigger any course-specific effects
        StartCoroutine(AnimateCourseLoad());
    }
    
    /// <summary>
    /// Animates the course loading with a fade-in effect
    /// </summary>
    private IEnumerator AnimateCourseLoad()
    {
        // Example: Fade in the course content
        float duration = 1.0f;
        float elapsed = 0f;
        
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float alpha = Mathf.Lerp(0f, 1f, elapsed / duration);
            
            // Apply alpha to materials/renderers
            // (Implementation depends on your 3D environment setup)
            
            yield return null;
        }
        
        if (enableDebugLogs)
        {
            Debug.Log("✅ Course load animation complete");
        }
    }
    
    /// <summary>
    /// Sends a message back to the Swift app
    /// </summary>
    private void SendMessageToSwift(string methodName, string message)
    {
        // Unity's mechanism to send messages back to native code
        // Format: "GameObjectName:MethodName:Message"
        string formattedMessage = $"CourseLoader:{methodName}:{message}";
        
        #if UNITY_IOS && !UNITY_EDITOR
        // This will be received by UnityBridge.onMessage() in Swift
        UnityEngine.iOS.Device.SetNoBackupFlag(formattedMessage);
        #endif
        
        if (enableDebugLogs)
        {
            Debug.Log($"📤 Sent message to Swift: {formattedMessage}");
        }
    }
    
    /// <summary>
    /// Initializes sample course data for testing
    /// </summary>
    private void InitializeSampleCourses()
    {
        // Sample course 1: Swift Programming
        CourseData swiftCourse = new CourseData
        {
            id = Guid.NewGuid().ToString(),
            title = "Introduction to Swift Programming",
            description = "Learn the fundamentals of Swift programming for iOS development",
            lessons = new List<LessonData>
            {
                new LessonData { title = "Swift Basics", duration = "30 min" },
                new LessonData { title = "Variables and Constants", duration = "25 min" },
                new LessonData { title = "Functions and Closures", duration = "40 min" }
            }
        };
        courseDatabase[swiftCourse.id] = swiftCourse;
        
        // Sample course 2: Machine Learning
        CourseData mlCourse = new CourseData
        {
            id = Guid.NewGuid().ToString(),
            title = "Machine Learning Fundamentals",
            description = "Understand the core concepts of machine learning and AI",
            lessons = new List<LessonData>
            {
                new LessonData { title = "What is Machine Learning?", duration = "20 min" },
                new LessonData { title = "Supervised vs Unsupervised Learning", duration = "35 min" },
                new LessonData { title = "Neural Networks Basics", duration = "45 min" }
            }
        };
        courseDatabase[mlCourse.id] = mlCourse;
        
        if (enableDebugLogs)
        {
            Debug.Log($"✅ Initialized {courseDatabase.Count} sample courses");
        }
    }
    
    /// <summary>
    /// Creates a placeholder course when the requested course is not found
    /// </summary>
    private void CreatePlaceholderCourse(string courseId)
    {
        CourseData placeholder = new CourseData
        {
            id = courseId,
            title = "Course Loading...",
            description = "This course is being prepared for you",
            lessons = new List<LessonData>
            {
                new LessonData { title = "Introduction", duration = "TBD" }
            }
        };
        
        courseDatabase[courseId] = placeholder;
        DisplayCourse(placeholder);
    }
}

/// <summary>
/// Data structure for course information
/// </summary>
[Serializable]
public class CourseData
{
    public string id;
    public string title;
    public string description;
    public List<LessonData> lessons;
}

/// <summary>
/// Data structure for lesson information
/// </summary>
[Serializable]
public class LessonData
{
    public string title;
    public string duration;
}
