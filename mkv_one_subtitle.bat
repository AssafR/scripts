@echo off
setlocal

if "%~1"=="" (
    echo Usage: %~nx0 "input.mkv"
    exit /b 1
)

ffmpeg -hide_banner -i "%~1" ^
    -map 0:v:0 ^
    -map 0:a:0? ^
    -map 0:s:0? ^
    -c copy ^
    "%~dpn1_one_sub.mkv"

endlocal