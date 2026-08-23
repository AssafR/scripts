#Requires AutoHotkey v2.0
#SingleInstance Off

; One-shot backend for sendKeys.bat
; Usage:
;   AutoHotkey64.exe sendKeysOnce.ahk "[Facebook]" ""
;   AutoHotkey64.exe sendKeysOnce.ahk "[VLC]" "{SPACE}"
;   AutoHotkey64.exe sendKeysOnce.ahk "" "^!x"
;
; VirtualDesktopAccessor.dll must be in the same directory.

DetectHiddenWindows True
SetTitleMatchMode 2
SetWorkingDir A_ScriptDir

if A_Args.Length < 2
    ExitApp 43

needle := A_Args[1]
keys   := A_Args[2]

; The old sendKeys.bat compensated for CALL doubling carets.
keys := StrReplace(keys, "^^", "^")

; If a target window was requested, switch to its virtual desktop
; and make the exact HWND foreground.
if needle != "" {
    VDA_PATH := A_ScriptDir "\VirtualDesktopAccessor.dll"

    hVDA := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")
    if !hVDA
        ExitApp 44

    GetWindowDesktopNumberProc := DllCall(
        "GetProcAddress",
        "Ptr", hVDA,
        "AStr", "GetWindowDesktopNumber",
        "Ptr"
    )

    GoToDesktopNumberProc := DllCall(
        "GetProcAddress",
        "Ptr", hVDA,
        "AStr", "GoToDesktopNumber",
        "Ptr"
    )

    if (!GetWindowDesktopNumberProc || !GoToDesktopNumberProc)
        ExitApp 45

    target := FindTargetWindow(needle, GetWindowDesktopNumberProc)

    if !IsObject(target)
        ExitApp 46

    hwnd := target.hwnd
    desktop := target.desktop

    ; Always request the target desktop. This is deliberately the same
    ; sequence that proved reliable in direct command-line testing.
    result := DllCall(
        GoToDesktopNumberProc,
        "Int", desktop,
        "Int"
    )

    if result < 0
        ExitApp 47

    Sleep 50

    targetSpec := "ahk_id " hwnd

    ; Restore only if minimized; preserve normal/maximized state.
    try {
        if WinGetMinMax(targetSpec) = -1
            WinRestore targetSpec
    }

    try WinActivate targetSpec

    focused := false
    try focused := WinWaitActive(targetSpec, , 0.50)

    if !focused {
        ; Stronger foreground fallback.
        DllCall("user32\BringWindowToTop", "Ptr", hwnd, "Int")
        DllCall("user32\SetForegroundWindow", "Ptr", hwnd, "Int")
        try WinActivate targetSpec

        try focused := WinWaitActive(targetSpec, , 0.50)
    }

    if !focused
        ExitApp 48
}

; Preserve the exact WScript.Shell.SendKeys syntax used by the old batch.
if keys != "" {
    try {
        ws := ComObject("WScript.Shell")
        ws.SendKeys(keys)
    }
    catch {
        ExitApp 49
    }
}

ExitApp 0


FindTargetWindow(needle, getDesktopProc) {
    ; Literal, case-insensitive substring matching over all windows.
    ; This preserves unique markers such as [FACEBOOK] and [Twitter].
    for hwnd in WinGetList() {
        try windowTitle := WinGetTitle("ahk_id " hwnd)
        catch
            continue

        if !InStr(windowTitle, needle, false)
            continue

        desktop := DllCall(
            getDesktopProc,
            "Ptr", hwnd,
            "Int"
        )

        ; Ignore Firefox/other transient auxiliary windows which are not
        ; associated with a real virtual desktop.
        if desktop >= 0 {
            return {
                hwnd: hwnd,
                desktop: desktop,
                title: windowTitle
            }
        }
    }

    return 0
}
