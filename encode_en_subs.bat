@echo off
setlocal

REM ============================================================
REM Burn English subtitles, resize to 540p, encode H.264 NVENC
REM Usage:
REM   burn_english_subs.bat "input file.mp4"
REM
REM Expected subtitle:
REM   input file.en.srt
REM ============================================================

if "%~1"=="" (
    echo ERROR: No input file specified.
    exit /b 1
)

set "INPUT=%~f1"
set "DIR=%~dp1"
set "NAME=%~n1"
set "SUBTITLE=%NAME%.en.srt"
set "OUTPUT=%NAME%_ENG_SUB_540p.mp4"

if not exist "%INPUT%" (
    echo ERROR: Input file not found:
    echo "%INPUT%"
    exit /b 1
)

if not exist "%DIR%%SUBTITLE%" (
    echo ERROR: Subtitle file not found:
    echo "%DIR%%SUBTITLE%"
    exit /b 1
)

pushd "%DIR%"

echo.
echo Input:    "%INPUT%"
echo Subtitle: "%SUBTITLE%"
echo Output:   "%DIR%%OUTPUT%"
echo.

ffmpeg -i "%INPUT%" ^
-vf "scale=-2:540:flags=lanczos,subtitles='%SUBTITLE%':charenc=UTF-8:force_style='PrimaryColour=&H0000FFFF&,OutlineColour=&H00000000&,BorderStyle=1,Outline=2,Shadow=1'" ^
-c:v h264_nvenc ^
-preset p7 ^
-tune hq ^
-rc vbr ^
-cq 27 ^
-b:v 0 ^
-pix_fmt yuv420p ^
-c:a aac ^
-ac 2 ^
-b:a 96k ^
-movflags +faststart ^
"%OUTPUT%"

set "FFERROR=%ERRORLEVEL%"

popd

if not "%FFERROR%"=="0" (
    echo.
    echo ERROR: FFmpeg failed.
    exit /b %FFERROR%
)

echo.
echo Done:
echo "%DIR%%OUTPUT%"

endlocal