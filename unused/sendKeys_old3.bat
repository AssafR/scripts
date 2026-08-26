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

function sleep(ms) {
    WScript.Sleep(ms);
}

function readUnicodeFile(path) {
    var f = fso.OpenTextFile(path, 1, false, -1); // ForReading, Unicode
    var text = f.ReadAll();
    f.Close();
    return text;
}

function writeUnicodeFile(path, text) {
    var f = fso.CreateTextFile(path, true, true); // overwrite, Unicode
    f.Write(text);
    f.Close();
}

function ensureFolder(path) {
    if (!fso.FolderExists(path)) {
        fso.CreateFolder(path);
    }
}

function makeRequestId() {
    return String(new Date().getTime()) +
           "_" +
           String(Math.floor(Math.random() * 1000000000));
}

function focusViaHelper(windowTitle) {
    var queueDir = sh.ExpandEnvironmentStrings("%TEMP%") + "\\sendKeysHelper";
    ensureFolder(queueDir);

    var id = makeRequestId();
    var tmpReq = queueDir + "\\req_" + id + ".tmp";
    var req = queueDir + "\\req_" + id + ".txt";
    var done = queueDir + "\\done_" + id + ".txt";

    // Write completely, then rename so the resident helper never reads a
    // partially-written request.
    writeUnicodeFile(tmpReq, windowTitle);
    fso.MoveFile(tmpReq, req);

    // Normally the resident AHK helper responds in a few tens of ms.
    // Allow enough time for a real virtual-desktop switch/focus operation.
    var deadline = new Date().getTime() + 1800;

    while (new Date().getTime() < deadline) {
        if (fso.FileExists(done)) {
            var response = readUnicodeFile(done);
            try {
                fso.DeleteFile(done, true);
            } catch (e) {
            }

            if (response.indexOf("OK") === 0) {
                return true;
            }

            WScript.Echo(
                "sendKeysHelper failed for title " +
                windowTitle +
                ": " +
                response
            );
            return false;
        }

        sleep(10);
    }

    // Clean up our request if the helper was not running/responding.
    try {
        if (fso.FileExists(req))
            fso.DeleteFile(req, true);
    } catch (e2) {
    }

    WScript.Echo(
        "sendKeysHelper did not respond. " +
        "Make sure sendKeysHelper.ahk is running."
    );
    return false;
}


parseArgs();

// In case the script is called with CALL, carets may be doubled.
keys = replaceAll(keys, "^^", "^");

// Preserve the old, instantaneous global-shortcut behavior.
if (title === "") {
    sh.SendKeys(keys);
    WScript.Quit(0);
}

// Ask the resident AHK helper to find the exact window across virtual
// desktops, switch there, and verify that it actually has foreground focus.
if (!focusViaHelper(title)) {
    WScript.Quit(1);
}

// Keep WScript.Shell.SendKeys for compatibility with all existing callers
// and their current SendKeys syntax.
if (keys !== "") {
    sh.SendKeys(keys);
}

WScript.Quit(0);
