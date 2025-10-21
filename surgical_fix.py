#!/usr/bin/env python3
import re

# These specific files have duplicates (per the build warnings)
dup_files = [
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

# For each duplicate file, find ALL occurrences in the files list and keep only the first
for filename in dup_files:
    # Match pattern: TAB + 24-hex-chars + SPACE + /* ... filename ... in Sources */,
    # We need to find LAST occurrence(s) and remove them
    
    # Find all matches for this file
    pattern = r'(\t+)([A-F0-9]{24}) /\* [^*]*' + re.escape(filename) + r'[^*]* in Sources \*/,'
    
    matches = list(re.finditer(pattern, content))
    
    if len(matches) > 1:
        # Keep the first, remove the rest (in reverse order to maintain positions)
        for match in reversed(matches[1:]):
            old_content_len = len(content)
            content = content[:match.start()] + content[match.end():]
            new_removed = old_content_len - len(content)
            removed += 1
            print(f"✓ Removed {filename} (occurrence #{matches.index(match) + 1})")

with open('/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print(f"\n✅ Removed {removed} duplicate file entries")
