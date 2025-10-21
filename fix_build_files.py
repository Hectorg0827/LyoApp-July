#!/usr/bin/env python3
import re

# List of bad build file IDs that are duplicates (these should be removed)
BAD_BUILD_IDS = [
    '34416D352EA33191007655C2',  # QuantumGateRiftButton
    '34416D3E2EA33191007655C2',  # APIConfig
    '34416D452EA33191007655C2',  # APIError
    '34416D4C2EA33191007655C2',  # NetworkLayer
    '34416D532EA33191007655C2',  # AIModels
    '34416D5A2EA33191007655C2',  # APIResponseModels
    '34416D612EA33191007655C2',  # LearningComponents
    '34416D682EA33191007655C2',  # LearningResource
    '34416D6F2EA33191007655C2',  # LessonModels
    '34416D762EA33191007655C2',  # AIAvatarIntegration
    '34416D7D2EA33191007655C2',  # APIClient
    '34416D842EA33191007655C2',  # GamificationOverlay
    '34416D8B2EA33191007655C2',  # DownloadStatus
    '34416D922EA33191007655C2',  # ClassroomViewModel
    '34416D992EA33191007655C2',  # AIAvatarView
    '34416DA02EA33191007655C2',  # AIOnboardingFlowView
    '34416DA72EA33191007655C2',  # AISearchView
    '34416DAE2EA33191007655C2',  # AuthenticationView
    '34416DB52EA33191007655C2',  # CommunityView
    '34416DBC2EA33191007655C2',  # MessengerView
    '34416DC32EA33191007655C2',  # MoreTabView
    '34416DCA2EA33191007655C2',  # SettingsView
    '34416DD12EA33191007655C2',  # BackendConnectivityTest
    '34416DD82EA33191007655C2',  # CompilationSentinel
]

with open('/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

removed_count = 0

# Remove each duplicate build file definition
for bad_id in BAD_BUILD_IDS:
    # Pattern: 34416D... /* filename in Sources */ = {isa = PBXBuildFile; ...}; 
    pattern = rf'{bad_id} /\*.*?in Sources \*/ = {{isa = PBXBuildFile;.*?}};\n'
    if re.search(pattern, content):
        content = re.sub(pattern, '', content, flags=re.DOTALL)
        removed_count += 1
        print(f"Removed definition for {bad_id}")

# Also remove these IDs from the files array in PBXSourcesBuildPhase
for bad_id in BAD_BUILD_IDS:
    pattern = rf'\s*{bad_id} /\*.*?in Sources \*/,\n'
    if re.search(pattern, content):
        content = re.sub(pattern, '', content)
        print(f"Removed from files array: {bad_id}")

with open('/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print(f"\n✅ Removed {removed_count} duplicate build file definitions")
