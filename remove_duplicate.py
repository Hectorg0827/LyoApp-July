import os
import sys

duplicate_file = "/Users/republicalatuya/Desktop/LyoApp July/LyoApp/LearningHub/Models/LearningSearchViewModel.swift"

if os.path.exists(duplicate_file):
    try:
        os.remove(duplicate_file)
        print(f"Successfully removed {duplicate_file}")
    except Exception as e:
        print(f"Error removing file: {e}")
else:
    print("File does not exist")

print("Done")
