hwnd := WinExist("[FACEBOOK]")

targetDesktop := GetWindowDesktopNumber(hwnd)
GoToDesktopNumber(targetDesktop)

WinRestore("ahk_id " hwnd)
WinActivate("ahk_id " hwnd)

if !WinWaitActive("ahk_id " hwnd, , 0.5)
    ; stronger foreground-focus fallback here