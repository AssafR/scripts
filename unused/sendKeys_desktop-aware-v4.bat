@if (@X)==(@Y) @end /* JScript comment
        @echo off
        cscript //E:JScript //nologo "%~f0" "%~nx0" %*
        exit /b %errorlevel%
@if (@X)==(@Y) @end JScript comment */

var sh = new ActiveXObject("WScript.Shell");
var ARGS = WScript.Arguments;
var scriptName = ARGS.Item(0);
var title = "";
var keys = "";

function printHelp() {
    WScript.Echo(scriptName + " - activates an application window (across virtual desktops) and sends keys");
    WScript.Echo("Usage:");
    WScript.Echo("call " + scriptName + " title string");
    WScript.Echo("title  - application/window title");
    WScript.Echo("string - keys to send");
    WScript.Echo("use \"\" as title to send keys to the current foreground window");
}

function parseArgs() {
    if (ARGS.Length < 3) {
        WScript.Echo("insufficient arguments");
        printHelp();
        WScript.Quit(43);
    }
    title = ARGS.Item(1);
    keys = ARGS.Item(2);
}

function escapeRegExp(str) {
    return str.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");
}

function replaceAll(str, find, replace) {
    return str.replace(new RegExp(escapeRegExp(find), 'g'), replace);
}

parseArgs();
keys = replaceAll(keys, "^^", "^");

// Global shortcut: preserve original behavior and do not inspect desktops.
if (title === "") {
    sh.SendKeys(keys);
    WScript.Quit(0);
}

// IMPORTANT: do NOT use AppActivate() as a test for "same desktop".
// On Windows 11 it can return true for a window on another virtual desktop,
// while merely flashing that application's taskbar icon.
var env = sh.Environment("PROCESS");
env("SENDKEYS_WINDOW_TITLE") = title;

var psCommand =
    'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "' +
    'Import-Module VirtualDesktop; ' +
    '$t=$env:SENDKEYS_WINDOW_TITLE; ' +
    '$h=Find-WindowHandle $t; ' +
    'if (-not $h -and $t.Length -ge 2 -and $t[0] -eq \'[\' -and $t[$t.Length-1] -eq \']\') { $h=Find-WindowHandle $t.Substring(1,$t.Length-2) }; ' +
    'if (-not $h) { exit 1 }; ' +
    '$targetDesktop=Get-DesktopFromWindow $h; ' +
    'if (-not $targetDesktop) { exit 2 }; ' +
    '$target=Get-DesktopIndex $targetDesktop; ' +
    '$current=Get-DesktopIndex (Get-CurrentDesktop); ' +
    'if ($current -ne $target) { ' +
    '  $targetDesktop | Switch-Desktop -NoAnimation; ' +
    '  $ok=$false; ' +
    '  for ($i=0; $i -lt 40; $i++) { ' +
    '    Start-Sleep -Milliseconds 50; ' +
    '    if ((Get-DesktopIndex (Get-CurrentDesktop)) -eq $target) { $ok=$true; break } ' +
    '  }; ' +
    '  if (-not $ok) { exit 3 } ' +
    '}; ' +
    'exit 0"';

var rc = sh.Run(psCommand, 0, true);
env("SENDKEYS_WINDOW_TITLE") = "";

if (rc !== 0) {
    WScript.Echo("Failed to locate/switch to application with title " + title + " (desktop stage rc=" + rc + ")");
    WScript.Quit(rc);
}

// Now that the target desktop is definitely current, activate the window.
// Retry because activation immediately after a desktop switch can race Explorer.
for (var attempt = 0; attempt < 30; attempt++) {
    if (sh.AppActivate(title)) {
        // Give Windows a tiny moment to commit foreground activation before sending keys.
        WScript.Sleep(50);
        sh.SendKeys(keys);
        WScript.Quit(0);
    }
    WScript.Sleep(75);
}

WScript.Echo("Switched to the correct desktop but failed to activate application with title " + title);
WScript.Quit(4);
