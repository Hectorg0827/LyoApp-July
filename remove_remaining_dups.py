#!/usr/bin/env python3
import re

files_to_fix = [
    'APIConfig.swift',
    'APIError.swift',
    'AIModels.swift',
    'APIResponseModels.swift',
    'LearningComponents.swift',
    'LessonModels.swift',
    'AIAvatarIntegration.swift',
    'APIClient.swift',
    'GamificationOverlay.swift',
    'DownloadStatus.swift',
    'ClassroomViewModel.swift',
    'AIAvatarView.swift',
    'AIOnboardingFlowView.swift',
    'AISearchView.swift',
    'AuthenticationView.swift',
    'CommunityView.swift',
    'MoreTabView.swift',
    'SettingsView.swift',
    'BackendConnectivityTest.swift',
    'CompilationSentinel.swift',
]

with open('/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

removed = 0

# For each file, find all occurrences in the "files" array and remove duplicates
for filename in files_to_fix:
    # Find pattern like: /* filename in Sources */,
    # We'll keep the first occurrence and remove subsequent ones
    pattern = rf'(\s+)([A-F0-9]{{24}}) /\* .*{re.escape(filename)}.*in Sources \*/,'
    
    all_matches = list(re.finditer(pattern, content))
    
    if len(all_matches) > 1:
        # Keep first, remove rest (in reverse so indices don't shift)
        for match in reversed(all_matches[1:]):
            content = content[:match.start()] + content[match.end():]
            removed += 1
            print(f"Removed duplicate reference to {filename}")

with open('/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print(f"\n✅ Removed {removed} duplicate file references from Xcode project")
