#Requires AutoHotkey v2.0
#SingleInstance Force

; Resident helper for sendKeys.bat.
; Requires VirtualDesktopAccessor.dll in the same directory.

DetectHiddenWindows True
SetTitleMatchMode 2
SetWorkingDir A_ScriptDir
A_IconTip := "sendKeysHelper (Virtual Desktop)"

VDA_PATH := A_ScriptDir "\VirtualDesktopAccessor.dll"

hVDA := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")
if !hVDA {
    MsgBox "Could not load:`n" VDA_PATH
    ExitApp
}

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

if (!GetWindowDesktopNumberProc || !GoToDesktopNumberProc) {
    MsgBox "Could not find required VirtualDesktopAccessor functions."
    ExitApp
}

QueueDir := A_Temp "\sendKeysHelper"
DirCreate QueueDir

; Do not execute stale requests from an old/crashed helper.
Loop Files QueueDir "\req_*.txt", "F" {
    try FileDelete A_LoopFileFullPath
}
Loop Files QueueDir "\done_*.txt", "F" {
    try FileDelete A_LoopFileFullPath
}
Loop Files QueueDir "\*.tmp", "F" {
    try FileDelete A_LoopFileFullPath
}

SetTimer ProcessRequests, 10


ProcessRequests() {
    global QueueDir

    Loop Files QueueDir "\req_*.txt", "F" {
        reqPath := A_LoopFileFullPath
        reqName := A_LoopFileName
        id := RegExReplace(reqName, "^req_(.*)\.txt$", "$1")

        if id = reqName
            continue

        donePath := QueueDir "\done_" id ".txt"
        tmpDone := donePath ".tmp"

        response := ""

        try {
            title := FileRead(reqPath)
            title := Trim(title, "`r`n`t ")

            if title = ""
                response := "ERR|empty window title"
            else
                response := FocusWindow(title)
        }
        catch as err {
            response := "ERR|" err.Message
        }

        try FileDelete reqPath

        try FileDelete tmpDone
        FileAppend response, tmpDone, "UTF-16"
        FileMove tmpDone, donePath, 1
    }
}


FocusWindow(needle) {
    global GetWindowDesktopNumberProc
    global GoToDesktopNumberProc

    target := FindTargetWindow(needle)

    if !IsObject(target)
        return "ERR|window not found: " needle

    hwnd := target.hwnd
    targetDesktop := target.desktop

    ; IMPORTANT:
    ; Always request the target desktop.
    ; Do NOT rely on GetCurrentDesktopNumber() here: on recent Windows 11
    ; builds it can disagree with the visually active desktop.
    result := DllCall(
        GoToDesktopNumberProc,
        "Int", targetDesktop,
        "Int"
    )

    if result < 0
        return "ERR|desktop switch failed"

    ; This mirrors the standalone AHK test that proved reliable and fast.
    Sleep 50

    targetSpec := "ahk_id " hwnd

    ; Restore only if minimized; preserve maximized/normal state.
    try {
        if WinGetMinMax(targetSpec) = -1
            WinRestore targetSpec
    }

    try WinActivate targetSpec

    try {
        if WinWaitActive(targetSpec, , 0.40)
            return "OK"
    }

    ; Foreground fallback.
    DllCall("user32\BringWindowToTop", "Ptr", hwnd, "Int")
    DllCall("user32\SetForegroundWindow", "Ptr", hwnd, "Int")
    try WinActivate targetSpec

    try {
        if WinWaitActive(targetSpec, , 0.40)
            return "OK"
    }

    return "ERR|desktop requested, but target window did not obtain focus"
}


FindTargetWindow(needle) {
    global GetWindowDesktopNumberProc

    ; Literal, case-insensitive substring search over all windows.
    ; DetectHiddenWindows=True lets us find windows on inactive desktops.
    for hwnd in WinGetList() {
        try {
            windowTitle := WinGetTitle("ahk_id " hwnd)
        }
        catch {
            continue
        }

        if !InStr(windowTitle, needle, false)
            continue

        desktop := DllCall(
            GetWindowDesktopNumberProc,
            "Ptr", hwnd,
            "Int"
        )

        ; Ignore transient/auxiliary windows not associated with a desktop.
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
