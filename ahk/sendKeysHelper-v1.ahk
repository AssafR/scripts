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

GetCurrentDesktopNumberProc := DllCall(
    "GetProcAddress",
    "Ptr", hVDA,
    "AStr", "GetCurrentDesktopNumber",
    "Ptr"
)

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

if (!GetCurrentDesktopNumberProc
    || !GetWindowDesktopNumberProc
    || !GoToDesktopNumberProc) {
    MsgBox "Could not find required VirtualDesktopAccessor functions."
    ExitApp
}

QueueDir := A_Temp "\sendKeysHelper"
DirCreate QueueDir

; Do not execute stale requests left behind by an old/crashed helper.
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

        ; If the filename somehow did not match, ignore it.
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

        ; Delete request before publishing completion.
        try FileDelete reqPath

        ; Atomic-ish response publication: write temp, then rename.
        try FileDelete tmpDone
        FileAppend response, tmpDone, "UTF-16"
        FileMove tmpDone, donePath, 1
    }
}


FocusWindow(needle) {
    global GetCurrentDesktopNumberProc
    global GetWindowDesktopNumberProc
    global GoToDesktopNumberProc

    target := FindTargetWindow(needle)

    if !IsObject(target)
        return "ERR|window not found: " needle

    hwnd := target.hwnd
    targetDesktop := target.desktop

    currentDesktop := DllCall(
        GetCurrentDesktopNumberProc,
        "Int"
    )

    if currentDesktop < 0
        return "ERR|could not determine current desktop"

    if targetDesktop != currentDesktop {
        result := DllCall(
            GoToDesktopNumberProc,
            "Int", targetDesktop,
            "Int"
        )

        if result < 0
            return "ERR|desktop switch failed"

        ; Wait until VDA confirms that the target desktop is current.
        deadline := A_TickCount + 1000
        switched := false

        while A_TickCount < deadline {
            currentDesktop := DllCall(
                GetCurrentDesktopNumberProc,
                "Int"
            )

            if currentDesktop = targetDesktop {
                switched := true
                break
            }

            Sleep 10
        }

        if !switched
            return "ERR|desktop switch timed out"

        ; Small settling delay for Explorer/window manager.
        Sleep 15
    }

    targetSpec := "ahk_id " hwnd

    ; Preserve maximized state; restore only if actually minimized.
    try {
        if WinGetMinMax(targetSpec) = -1
            WinRestore targetSpec
    }

    try WinActivate targetSpec

    try {
        if WinWaitActive(targetSpec, , 0.30)
            return "OK"
    }

    ; Foreground fallback. Windows can occasionally refuse a normal
    ; activation request after a virtual-desktop switch.
    DllCall("user32\BringWindowToTop", "Ptr", hwnd, "Int")
    DllCall("user32\SetForegroundWindow", "Ptr", hwnd, "Int")

    try WinActivate targetSpec

    try {
        if WinWaitActive(targetSpec, , 0.30)
            return "OK"
    }

    return "ERR|window found and desktop switched, but focus was not obtained"
}


FindTargetWindow(needle) {
    global GetWindowDesktopNumberProc

    ; Enumerate all windows and use a literal, case-insensitive substring
    ; match. This makes markers such as [FACEBOOK] unambiguous and avoids
    ; transient Firefox windows which have no Virtual Desktop association.
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
