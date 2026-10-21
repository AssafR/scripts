@echo off
setlocal EnableExtensions

if "%~1"=="" (
    echo.
    echo Usage: %~nx0 "input video"
    echo.
    pause
    exit /b 1
)

set "INPUT=%~1"

REM ============================================================
REM CROP
REM ============================================================

set "CROP_LEFT=12"
set "CROP_RIGHT=28"
set "CROP_TOP=0"
set "CROP_BOTTOM=32"

REM ============================================================
REM NVENC QUALITY
REM ============================================================

set "CQ=21"

REM ============================================================
REM OUTPUT
REM ============================================================

set "OUTPUT=%~dpn1_CUSTOMER_50p.mp4"

echo.
echo ============================================================
echo VHS CUSTOMER CONVERSION
echo ============================================================
echo Input : "%INPUT%"
echo Output: "%OUTPUT%"
echo.
echo Crop: L=%CROP_LEFT% R=%CROP_RIGHT% T=%CROP_TOP% B=%CROP_BOTTOM%
echo Deinterlace: BWDIF CUDA, field rate / 50p
echo Encoder: H.264 NVENC, CQ %CQ%
echo ============================================================
echo.


ffmpeg ^
    -hide_banner ^
    -y ^
    -i "%INPUT%" ^
    -map 0:v:0 ^
    -map 0:a:0? ^
    -vf "crop=iw-%CROP_LEFT%-%CROP_RIGHT%:ih-%CROP_TOP%-%CROP_BOTTOM%:%CROP_LEFT%:%CROP_TOP%,format=nv12,hwupload_cuda,bwdif_cuda=mode=send_field:parity=auto:deint=all" ^
    -c:v h264_nvenc ^
    -preset p6 ^
    -tune hq ^
    -rc vbr ^
    -cq %CQ% ^
    -b:v 0 ^
    -profile:v high ^
    -aspect 4:3 ^
    -colorspace bt470bg ^
    -color_primaries bt470bg ^
    -color_trc bt709 ^
    -c:a aac ^
    -b:a 128k ^
    -ar 48000 ^
    -movflags +faststart ^
    "%OUTPUT%"


if errorlevel 1 (
    echo.
    echo ============================================================
    echo Conversion failed!
    echo ============================================================
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo Finished successfully:
echo "%OUTPUT%"
echo ============================================================
echo.

pause
endlocal