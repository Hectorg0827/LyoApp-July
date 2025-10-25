-- AppleScript to add Nuke packages to Xcode target
-- This automates the manual clicking process

tell application "Xcode"
	activate
	delay 1
end tell

tell application "System Events"
	tell process "Xcode"
		-- Wait for Xcode to be active
		delay 1
		
		-- Click on Build Phases tab
		-- Note: This is a simplified version. Full automation would require
		-- more complex UI scripting which can be fragile.
		
		display dialog "⚠️ Semi-Automated Fix for NukeUI

This script will help you, but you still need to do a few manual steps:

1. In Xcode, select the 'LyoApp' TARGET (not project)
2. Click the 'Build Phases' tab at the top
3. Expand 'Link Binary With Libraries' section
4. Click the '+' button
5. Select: Nuke, NukeUI (at minimum)
6. Click 'Add'
7. Build with Cmd+B

Would you like me to open detailed instructions in a browser?" buttons {"Cancel", "Show Instructions", "I'll Do It Manually"} default button "Show Instructions"
		
		if button returned of result is "Show Instructions" then
			do shell script "open 'https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app'"
		end if
	end tell
end tell
