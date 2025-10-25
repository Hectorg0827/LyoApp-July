using UnityEngine;
using Lyo.Classroom.Systems;

namespace Lyo.Classroom.Systems.Templates
{
    public class SkillSimTemplate : MonoBehaviour
    {
        public AvatarController avatarController;

        void Start()
        {
            // Example usage
            if (avatarController != null)
            {
                Debug.Log("AvatarController is assigned.");
            }
        }
    }
}
