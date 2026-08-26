@if (@X)==(@Y) @end /* JScript comment 
        @echo off 
       
        rem :: the first argument is the script name as it will be used for proper help message 
        cscript //E:JScript //nologo "%~f0" "%~nx0" %* 
        exit /b %errorlevel% 
@if (@X)==(@Y) @end JScript comment */ 


var sh=new ActiveXObject("WScript.Shell"); 
var ARGS = WScript.Arguments; 
var scriptName=ARGS.Item(0); 

var title="";
var keys="";

function printHelp(){ 
        WScript.Echo(scriptName + " - sends keys to a applicaion with given title"); 
        WScript.Echo("Usage:"); 
        WScript.Echo("call " + scriptName + " title string"); 
        WScript.Echo("title  - the title of the application"); 
        WScript.Echo("string - keys to be send"); 
		WScript.Echo("to send keys to no particular window use \"\" as title (e.g. shortcut keys) "); 
		WScript.Echo("  refence with special keys -> http://social.technet.microsoft.com/wiki/contents/articles/5169.vbscript-sendkeys-method.aspx");
} 

function parseArgs(){ 
                
        if (ARGS.Length < 3) { 
                WScript.Echo("insufficient arguments"); 
                printHelp(); 
                WScript.Quit(43); 
        }
		
		title=ARGS.Item(1);
		keys=ARGS.Item(2);
}


function escapeRegExp(str) {
    return str.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");
}

function replaceAll(str, find, replace) {
  return str.replace(new RegExp(escapeRegExp(find), 'g'), replace);
}

parseArgs();
//in case the script is called with CALL command the carets will be doubled
keys=replaceAll(keys,"^^","^");

if (title === "") {
	sh.SendKeys(keys);
	WScript.Quit(0);
}

// Fast path: the window is already on the current virtual desktop.
if (sh.AppActivate(title)) {
	sh.SendKeys(keys);
	WScript.Quit(0);
}

// AppActivate cannot activate a window on another Windows virtual desktop.
// PSVirtualDesktop's direct Switch-Desktop call is unreliable on Windows 11
// 25H2 / build 26200, for which the module does not officially claim support.
// We still use the module for discovery (which works on this machine), but
// perform the actual desktop change using Windows' native Win+Ctrl+Left/Right
// keyboard shortcut. This lets Explorer itself perform the switch.
var env = sh.Environment("PROCESS");
env("SENDKEYS_WINDOW_TITLE") = title;

var psCommand =
    'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "' +
    'Import-Module VirtualDesktop; ' +
    '$t=$env:SENDKEYS_WINDOW_TITLE; ' +
    '$h=Find-WindowHandle $t; ' +
    'if (-not $h -and $t.Length -ge 2 -and $t[0] -eq \'[\' -and $t[$t.Length-1] -eq \']\') ' +
    '{ $h=Find-WindowHandle $t.Substring(1,$t.Length-2) }; ' +
    'if (-not $h) { exit 1 }; ' +
    '$d=Get-DesktopFromWindow $h; ' +
    '$target=Get-DesktopIndex $d; ' +
    '$sig=\'[System.Runtime.InteropServices.DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, System.UIntPtr dwExtraInfo);\'; ' +
    'Add-Type -MemberDefinition $sig -Name NativeKeys -Namespace SendKeysVD -ErrorAction SilentlyContinue; ' +
    'function StepVD([bool]$right) { ' +
    '  $win=0x5B; $ctrl=0x11; if ($right) { $arrow=0x27 } else { $arrow=0x25 }; $up=0x2; ' +
    '  [SendKeysVD.NativeKeys]::keybd_event($win,0,0,[UIntPtr]::Zero); ' +
    '  [SendKeysVD.NativeKeys]::keybd_event($ctrl,0,0,[UIntPtr]::Zero); ' +
    '  [SendKeysVD.NativeKeys]::keybd_event($arrow,0,0,[UIntPtr]::Zero); ' +
    '  Start-Sleep -Milliseconds 25; ' +
    '  [SendKeysVD.NativeKeys]::keybd_event($arrow,0,$up,[UIntPtr]::Zero); ' +
    '  [SendKeysVD.NativeKeys]::keybd_event($ctrl,0,$up,[UIntPtr]::Zero); ' +
    '  [SendKeysVD.NativeKeys]::keybd_event($win,0,$up,[UIntPtr]::Zero) ' +
    '}; ' +
    'for ($guard=0; $guard -lt 5; $guard++) { ' +
    '  $current=Get-DesktopIndex (Get-CurrentDesktop); ' +
    '  if ($current -eq $target) { exit 0 }; ' +
    '  $before=$current; StepVD ($target -gt $current); ' +
    '  for ($i=0; $i -lt 20; $i++) { ' +
    '    Start-Sleep -Milliseconds 50; ' +
    '    $now=Get-DesktopIndex (Get-CurrentDesktop); ' +
    '    if ($now -ne $before) { break } ' +
    '  } ' +
    '}; ' +
    'if ((Get-DesktopIndex (Get-CurrentDesktop)) -eq $target) { exit 0 } else { exit 2 }"';

var rc = sh.Run(psCommand, 0, true);
env("SENDKEYS_WINDOW_TITLE") = "";

if (rc === 0) {
	// Desktop switching is asynchronous. Even after Windows reports the target
	// desktop as current, the target window may not yet accept activation.
	// Retry for up to ~2.5 seconds instead of relying on one timing-sensitive call.
	for (var attempt = 0; attempt < 25; attempt++) {
		if (sh.AppActivate(title)) {
			sh.SendKeys(keys);
			WScript.Quit(0);
		}
		WScript.Sleep(100);
	}
}

WScript.Echo("Failed to activate application with title " + title);
WScript.Quit(1);
