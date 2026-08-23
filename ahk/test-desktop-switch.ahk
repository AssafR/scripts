#Requires AutoHotkey v2.0
#SingleInstance Force

SetTitleMatchMode 2
DetectHiddenWindows True
SetWorkingDir A_ScriptDir

VDA_PATH := A_ScriptDir "\VirtualDesktopAccessor.dll"

hVDA := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")

if !hVDA {
    MsgBox "Could not load:`n" VDA_PATH
    ExitApp
}

GetWindowDesktopNumberProc :=
    DllCall("GetProcAddress",
        "Ptr", hVDA,
        "AStr", "GetWindowDesktopNumber",
        "Ptr")

GoToDesktopNumberProc :=
    DllCall("GetProcAddress",
        "Ptr", hVDA,
        "AStr", "GoToDesktopNumber",
        "Ptr")

if !GetWindowDesktopNumberProc || !GoToDesktopNumberProc {
    MsgBox "Could not find required VirtualDesktopAccessor functions."
    ExitApp
}


FocusWindow(title) {
    global GetWindowDesktopNumberProc, GoToDesktopNumberProc

    hwnd := WinExist(title)

    if !hwnd {
        MsgBox "Window not found:`n" title
        return
    }

    desktop :=
        DllCall(GetWindowDesktopNumberProc,
            "Ptr", hwnd,
            "Int")

    if desktop < 0 {
        MsgBox "Could not determine desktop for:`n" title
        return
    }

    ; Switch directly to the desktop containing this window.
    result :=
        DllCall(GoToDesktopNumberProc,
            "Int", desktop,
            "Int")

    if result < 0 {
        MsgBox "Desktop switch failed."
        return
    }

    ; Give Explorer a moment to finish switching.
    Sleep 50

    ; Restore if minimized, then explicitly activate exact HWND.
    try WinRestore("ahk_id " hwnd)

    WinActivate("ahk_id " hwnd)

    if !WinWaitActive("ahk_id " hwnd, , 0.75) {
        ; Extra Win32 attempt if Windows rejected normal activation.
        DllCall("user32\BringWindowToTop",
            "Ptr", hwnd)

        DllCall("user32\SetForegroundWindow",
            "Ptr", hwnd)

        if !WinWaitActive("ahk_id " hwnd, , 0.75) {
            MsgBox "Desktop switched, but window did not receive focus."
        }
    }
}


; TEST HOTKEY:
; Ctrl + Alt + F = go to your [FACEBOOK] Firefox window.
^!f::FocusWindow("[FACEBOOK]")