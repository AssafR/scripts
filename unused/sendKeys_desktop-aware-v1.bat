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
// Ask the VirtualDesktop PowerShell module to find the window, switch to the
// desktop containing it, then retry AppActivate.
//
// Pass the title through an environment variable instead of embedding it in
// the PowerShell command line, so spaces and quotes in window titles are safe.
var env = sh.Environment("PROCESS");
env("SENDKEYS_WINDOW_TITLE") = title;

var psCommand =
	'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "' +
	'Import-Module VirtualDesktop; ' +
	'$t=$env:SENDKEYS_WINDOW_TITLE; ' +
	'$h=Find-WindowHandle $t; ' +
	// Existing callers such as [Facebook] may use brackets for AppActivate.
	// If the module does not find that literal title, also try without them.
	'if (-not $h -and $t.Length -ge 2 -and $t[0] -eq \'[\' -and $t[$t.Length-1] -eq \']\') ' +
	'{ $h=Find-WindowHandle $t.Substring(1,$t.Length-2) }; ' +
	'if ($h) { ' +
	'  Get-DesktopFromWindow $h | Switch-Desktop -NoAnimation | Out-Null; ' +
	'  Start-Sleep -Milliseconds 100; ' +
	'  exit 0 ' +
	'} else { exit 1 }"';

var rc = sh.Run(psCommand, 0, true);
env("SENDKEYS_WINDOW_TITLE") = "";

if (rc === 0 && sh.AppActivate(title)) {
	sh.SendKeys(keys);
	WScript.Quit(0);
}

WScript.Echo("Failed to find application with title " + title);
WScript.Quit(1);
