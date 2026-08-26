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

var env = sh.Environment("PROCESS");
env("SENDKEYS_WINDOW_TITLE") = title;

// Fast path: the user's bracketed markers (e.g. [FACEBOOK]) are unique, and
// Find-WindowHandle can locate them directly.  Validate that handle against
// the virtual-desktop API.  Only if that rare validation fails do the slower
// full-window enumeration used by v6.
var psCommand =
    'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "' +
    'Import-Module VirtualDesktop; ' +
    '$t=$env:SENDKEYS_WINDOW_TITLE; ' +
    '$targetDesktop=$null; $targetHandle=$null; ' +
    'try { ' +
    '  $h=Find-WindowHandle $t; ' +
    '  if ($null -ne $h -and [int64]$h -ne 0) { ' +
    '    $d=Get-DesktopFromWindow $h -ErrorAction Stop; ' +
    '    if ($null -ne $d) { $targetDesktop=$d; $targetHandle=$h } ' +
    '  } ' +
    '} catch { }; ' +
    'if ($null -eq $targetDesktop) { ' +
    '  $matches=Find-WindowHandle * | Where-Object { ' +
    '    $null -ne $_.Title -and $_.Title.IndexOf($t,[System.StringComparison]::OrdinalIgnoreCase) -ge 0 ' +
    '  }; ' +
    '  foreach ($w in $matches) { ' +
    '    try { ' +
    '      $d=Get-DesktopFromWindow $w.Handle -ErrorAction Stop; ' +
    '      if ($null -ne $d) { $targetDesktop=$d; $targetHandle=$w.Handle; break } ' +
    '    } catch { } ' +
    '  } ' +
    '}; ' +
    'if ($null -eq $targetDesktop) { exit 2 }; ' +
    'if (-not (Test-CurrentDesktop $targetDesktop)) { ' +
    '  $targetDesktop | Switch-Desktop -NoAnimation; ' +
    '  $ok=$false; ' +
    '  for ($i=0; $i -lt 50; $i++) { ' +
    '    Start-Sleep -Milliseconds 50; ' +
    '    if (Test-CurrentDesktop $targetDesktop) { $ok=$true; break } ' +
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

// Now that the target desktop is current, activate the ORIGINAL literal title
// (e.g. [Facebook]), preserving the behavior of the old sendKeys.bat.
for (var attempt = 0; attempt < 40; attempt++) {
    if (sh.AppActivate(title)) {
        if (keys !== "") {
            WScript.Sleep(30);
            sh.SendKeys(keys);
        }
        WScript.Quit(0);
    }
    WScript.Sleep(75);
}

WScript.Echo("Switched to the correct desktop but failed to activate application with title " + title);
WScript.Quit(4);
