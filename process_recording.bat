@echo off
setlocal
set "HERE=%~dp0"

if "%~1"=="" (
  echo Usage: %~nx0 "input.ts" [extra ps args...]
  exit /b 2
)

set "IN=%~1"

set "REPAIR_PROGRAM=%HERE%fix_video_file.bat"
set "TRIM_PROGRAM=uv run C:\Users\Assaf\program\VidUtils\trim_blue_ends.py"
set "OUTPUT=%~dpn1.mkv"

echo REPAIR
call "%REPAIR_PROGRAM%" "%~1"
echo TRIM
%TRIM_PROGRAM% "%OUTPUT%"

set "EC=%errorlevel%"
endlocal
exit /b %EC%
