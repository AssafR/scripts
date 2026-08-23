@if (@X)==(@Y) @end /* JScript comment
        @echo off

        rem :: the first argument is the script name as it will be used for proper help message
        cscript //E:JScript //nologo "%~f0" "%~nx0" %*
        exit /b %errorlevel%
@if (@X)==(@Y) @end JScript comment */


var sh = new ActiveXObject("WScript.Shell");
var fso = new ActiveXObject("Scripting.FileSystemObject");
var ARGS = WScript.Arguments;

var scriptName = ARGS.Item(0);
var title = "";
var keys = "";

function printHelp() {
    WScript.Echo(scriptName + " - sends keys to an application with the given title");
    WScript.Echo("Usage:");
    WScript.Echo("call " + scriptName + " title string");
    WScript.Echo("title  - application/window title substring");
    WScript.Echo("string - keys to be sent");
    WScript.Echo("to send keys to no particular window use \"\" as title");
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
    return str.replace(new RegExp(escapeRegExp(find), "g"), replace);
}

function quoteArg(str) {
    // Sufficient for our window-title arguments (e.g. [Facebook]).
    // Escape embedded quotes defensively.
    return '"' + String(str).replace(/"/g, '\\"') + '"';
}

parseArgs();

// In case the script is called with CALL, carets may be doubled.
keys = replaceAll(keys, "^^", "^");

// Preserve old behavior for global shortcuts: no window activation required.
if (title === "") {
    sh.SendKeys(keys);
    WScript.Quit(0);
}

// focusWindowOnce.ahk and VirtualDesktopAccessor.dll live in:
//   <scripts folder>\AHK\
var scriptsDir = fso.GetParentFolderName(WScript.ScriptFullName);
var ahkScript = fso.BuildPath(fso.BuildPath(scriptsDir, "AHK"), "focusWindowOnce.ahk");
var ahkExe = "C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey64.exe";

if (!fso.FileExists(ahkExe)) {
    WScript.Echo("AutoHotkey executable not found: " + ahkExe);
    WScript.Quit(44);
}

if (!fso.FileExists(ahkScript)) {
    WScript.Echo("AHK helper not found: " + ahkScript);
    WScript.Quit(45);
}

// Run the one-shot AHK helper synchronously.
// It finds the exact window across all virtual desktops, switches to its
// desktop, activates it, and exits only after focus has been confirmed.
var command = quoteArg(ahkExe) + " " + quoteArg(ahkScript) + " " + quoteArg(title);
var rc = sh.Run(command, 0, true);

if (rc !== 0) {
    WScript.Echo("Failed to focus application with title " + title + " (AHK rc=" + rc + ")");
    WScript.Quit(rc);
}

// The target window is now confirmed active. Keep using WScript.SendKeys so
// all existing callers retain their current SendKeys syntax.
if (keys !== "") {
    sh.SendKeys(keys);
}

WScript.Quit(0);
