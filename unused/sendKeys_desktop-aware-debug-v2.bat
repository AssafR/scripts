@if (@X)==(@Y) @end /* JScript comment
        @echo off
        cscript //E:JScript //nologo "%~f0" "%~nx0" %*
        exit /b %errorlevel%
@if (@X)==(@Y) @end JScript comment */

var sh = new ActiveXObject("WScript.Shell");
var fso = new ActiveXObject("Scripting.FileSystemObject");
var ARGS = WScript.Arguments;
var scriptName = ARGS.Item(0);
var title = "";
var keys = "";
var logPath = sh.ExpandEnvironmentStrings("%TEMP%\\sendKeys-vd.log");

function pad2(n) {
    return (n < 10 ? "0" : "") + n;
}

function pad3(n) {
    if (n < 10) return "00" + n;
    if (n < 100) return "0" + n;
    return "" + n;
}

function timestamp() {
    var d = new Date();
    return d.getFullYear() + "-" +
           pad2(d.getMonth() + 1) + "-" +
           pad2(d.getDate()) + " " +
           pad2(d.getHours()) + ":" +
           pad2(d.getMinutes()) + ":" +
           pad2(d.getSeconds()) + "." +
           pad3(d.getMilliseconds());
}

function log(s) {
    var f = fso.OpenTextFile(logPath, 8, true, -1);
    f.WriteLine(timestamp() + "  " + s);
    f.Close();
}

function parseArgs() {
    if (ARGS.Length < 3) {
        log("ERROR insufficient arguments");
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
log("BEGIN title=" + title);

if (title === "") {
    log("global SendKeys");
    sh.SendKeys(keys);
    WScript.Quit(0);
}

if (sh.AppActivate(title)) {
    log("FAST-PATH AppActivate succeeded on current desktop");
    sh.SendKeys(keys);
    WScript.Quit(0);
}
log("FAST-PATH AppActivate failed; starting VD discovery/switch");

var env = sh.Environment("PROCESS");
env("SENDKEYS_WINDOW_TITLE") = title;
env("SENDKEYS_VD_LOG") = logPath;

var psCommand =
    'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "' +
    '$log=$env:SENDKEYS_VD_LOG; function L($s){Add-Content -LiteralPath $log -Value ((Get-Date -Format o)+\'  PS \' + $s)}; ' +
    'Import-Module VirtualDesktop; ' +
    '$t=$env:SENDKEYS_WINDOW_TITLE; ' +
    '$h=Find-WindowHandle $t; ' +
    'if (-not $h -and $t.Length -ge 2 -and $t[0] -eq \'[\' -and $t[$t.Length-1] -eq \']\') { $h=Find-WindowHandle $t.Substring(1,$t.Length-2) }; ' +
    'if (-not $h) { L \'Find-WindowHandle FAILED\'; exit 1 }; ' +
    'L (\'HWND=\'+$h); ' +
    '$d=Get-DesktopFromWindow $h; $target=Get-DesktopIndex $d; $initial=Get-DesktopIndex (Get-CurrentDesktop); ' +
    'L (\'initial=\'+$initial+\' target=\'+$target); ' +
    '$sig=\'[System.Runtime.InteropServices.DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, System.UIntPtr dwExtraInfo);\'; ' +
    'Add-Type -MemberDefinition $sig -Name NativeKeys -Namespace SendKeysVD -ErrorAction SilentlyContinue; ' +
    'function StepVD([bool]$right) { ' +
    '  $win=0x5B; $ctrl=0x11; if ($right) {$arrow=0x27} else {$arrow=0x25}; $up=0x2; ' +
    '  [SendKeysVD.NativeKeys]::keybd_event($win,0,0,[UIntPtr]::Zero); [SendKeysVD.NativeKeys]::keybd_event($ctrl,0,0,[UIntPtr]::Zero); [SendKeysVD.NativeKeys]::keybd_event($arrow,0,0,[UIntPtr]::Zero); ' +
    '  Start-Sleep -Milliseconds 25; [SendKeysVD.NativeKeys]::keybd_event($arrow,0,$up,[UIntPtr]::Zero); [SendKeysVD.NativeKeys]::keybd_event($ctrl,0,$up,[UIntPtr]::Zero); [SendKeysVD.NativeKeys]::keybd_event($win,0,$up,[UIntPtr]::Zero) }; ' +
    'for ($guard=0; $guard -lt 5; $guard++) { ' +
    '  $current=Get-DesktopIndex (Get-CurrentDesktop); L (\'guard=\'+$guard+\' current=\'+$current+\' target=\'+$target); ' +
    '  if ($current -eq $target) { L \'module reports target reached\'; exit 0 }; ' +
    '  $before=$current; L (\'sending native switch direction=\'+($(if($target -gt $current){\'RIGHT\'}else{\'LEFT\'}))); StepVD ($target -gt $current); ' +
    '  for ($i=0; $i -lt 20; $i++) { Start-Sleep -Milliseconds 50; $now=Get-DesktopIndex (Get-CurrentDesktop); if ($now -ne $before) { L (\'desktop changed according to module: \'+$before+\' -> \'+$now); break } }; ' +
    '}; ' +
    '$final=Get-DesktopIndex (Get-CurrentDesktop); L (\'FINAL current=\'+$final+\' target=\'+$target); if ($final -eq $target) {exit 0} else {exit 2}"';

var rc = sh.Run(psCommand, 0, true);
log("PowerShell returned rc=" + rc);
env("SENDKEYS_WINDOW_TITLE") = "";
env("SENDKEYS_VD_LOG") = "";

if (rc === 0) {
    for (var attempt = 0; attempt < 25; attempt++) {
        if (sh.AppActivate(title)) {
            log("POST-SWITCH AppActivate succeeded attempt=" + attempt);
            sh.SendKeys(keys);
            WScript.Quit(0);
        }
        WScript.Sleep(100);
    }
    log("POST-SWITCH AppActivate failed after retries");
} else {
    log("VD switch stage failed rc=" + rc);
}

WScript.Echo("Failed to activate application with title " + title + ". Debug log: " + logPath);
WScript.Quit(1);
