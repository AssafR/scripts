#Requires AutoHotkey v2.0
#SingleInstance Off

DetectHiddenWindows True
SetTitleMatchMode 2
SetWorkingDir A_ScriptDir

if A_Args.Length < 1 {
    ExitApp 43
}

needle := A_Args[1]

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

target := FindTargetWindow(needle)

if !IsObject(target)
    ExitApp 46

hwnd := target.hwnd
desktop := target.desktop

result := DllCall(
    GoToDesktopNumberProc,
    "Int", desktop,
    "Int"
)

if result < 0
    ExitApp 47

Sleep 50

targetSpec := "ahk_id " hwnd

try {
    if WinGetMinMax(targetSpec) = -1
        WinRestore targetSpec
}

try WinActivate targetSpec

try {
    if WinWaitActive(targetSpec, , 0.50)
        ExitApp 0
}

; Stronger foreground fallback.
DllCall("user32\BringWindowToTop", "Ptr", hwnd, "Int")
DllCall("user32\SetForegroundWindow", "Ptr", hwnd, "Int")
try WinActivate targetSpec

try {
    if WinWaitActive(targetSpec, , 0.50)
        ExitApp 0
}

ExitApp 48


FindTargetWindow(needle) {
    global GetWindowDesktopNumberProc

    for hwnd in WinGetList() {
        try windowTitle := WinGetTitle("ahk_id " hwnd)
        catch
            continue

        if !InStr(windowTitle, needle, false)
            continue

        desktop := DllCall(
            GetWindowDesktopNumberProc,
            "Ptr", hwnd,
            "Int"
        )

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
