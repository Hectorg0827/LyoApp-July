using UnityEngine;
using Lyo.Classroom.Core;

namespace Lyo.Classroom.Systems
{
    public class WorldTemplate : MonoBehaviour
    {
        public LessonData lessonData;

        void Start()
        {
            // Example usage
            if (lessonData != null)
            {
                Debug.Log($"Loaded lesson: {lessonData.lessonId}");
            }
        }
    }
}
