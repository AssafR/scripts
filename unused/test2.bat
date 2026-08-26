@echo on

echo Raw arg: %1
echo Stripped arg: %~1

"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\Users\Assaf\Dropbox\scripts\AHK\focusWindowOnce.ahk" %1

echo ERRORLEVEL=%ERRORLEVEL%
