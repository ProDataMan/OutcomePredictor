#!/usr/bin/osascript

# AppleScript to automate Xcode project creation

tell application "Xcode"
    activate
    delay 2
end tell

tell application "System Events"
    tell process "Xcode"
        -- File > New > Project
        keystroke "n" using {command down, shift down}
        delay 2

        -- Select iOS tab and App template
        -- Note: This requires GUI scripting which may need accessibility permissions

        click button "iOS" of window 1
        delay 1

        click button "App" of window 1
        delay 1

        click button "Next" of window 1
        delay 1

        -- Fill in project details
        set value of text field "Product Name" of window 1 to "NFLPredictor"
        delay 0.5

        click button "Next" of window 1
        delay 1

        -- Save location
        -- Navigate to /Users/baysideuser/GitRepos/
        keystroke "g" using {command down, shift down}
        delay 1

        set value of text field 1 of sheet 1 of window 1 to "/Users/baysideuser/GitRepos/"
        delay 0.5

        click button "Go" of sheet 1 of window 1
        delay 1

        click button "Create" of window 1
        delay 2

    end tell
end tell

return "Project creation initiated"
