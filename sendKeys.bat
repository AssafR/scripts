@echo off
rem Desktop-aware SendKeys launcher.
rem
rem Existing calling convention is preserved:
rem   call sendKeys.bat "[Facebook]" ""
rem   call sendKeys.bat "[VLC]" "{SPACE}"
rem   call sendKeys.bat "" "^!x"
rem
rem IMPORTANT: START is intentional.  Do not remove it.
rem CMD waits for GUI programs when launched from a batch file; waiting here
rem can cause the console to reclaim the foreground after AutoHotkey switches
rem desktops.  START makes the AHK process asynchronous.

set "AHK_EXE=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
set "AHK_SCRIPT=%~dp0AHK\sendKeysOnce.ahk"

if not exist "%AHK_EXE%" (
    echo AutoHotkey not found: "%AHK_EXE%"
    exit /b 44
)

if not exist "%AHK_SCRIPT%" (
    echo AHK helper not found: "%AHK_SCRIPT%"
    exit /b 45
)

start "" /b "%AHK_EXE%" "%AHK_SCRIPT%" %*

rem Asynchronous launch: this only confirms that START itself succeeded.
exit /b %errorlevel%
