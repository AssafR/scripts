@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ---- Input handling (space-safe) ----
REM Always quote the input path when calling this script.
REM You can also drag-and-drop a file onto the .cmd.

if "%~1"=="" (
  echo Usage: %~nx0 "full\path\to\input.mkv" [audio_index]
  echo Example: %~nx0 "S:\TV Shows\Pluribus\Pluribus S01E07 ....mkv" 0
  exit /b 1
)

set "IN=%~1"
set "AIDX=%~2"
if "%AIDX%"=="" set "AIDX=0"

REM ---- Build output path safely ----
set "OUT=%~dpn1_plex.mkv"

echo Input : "%IN%"
echo Audio : index %AIDX%
echo Output: "%OUT%"
echo.

REM Cleaning the video
ffmpeg -hide_banner -y ^
  -loglevel error -stats ^
  -fflags +genpts ^
  -avoid_negative_ts make_zero ^
  -i "%IN%" ^
  -map 0:v:0 ^
  -map 0:a:%AIDX%? ^
  -map -0:s ^
  -map -0:d? ^
  -c:v copy ^
  -c:a copy ^
  -disposition:a:0 default ^
  -muxpreload 0 -muxdelay 0 ^
  -max_interleave_delta 0 ^
  "%OUT%"


rem --- Build subtitle base name from output file ---
for %%F in ("%OUT%") do set "SUBBASE=%%~dpnF"

rem --- Reset detected subtitle stream indexes ---
set "ENGSUB="
set "HEBSUB="

for /f "usebackq tokens=1,2 delims=," %%A in (`
  ffprobe  ^
    -v error ^
	-hide_banner ^
    -select_streams s ^
    -show_entries stream^=index:stream_tags^=language ^
    -of csv^=p^=0 "%IN%"
`) do (
  rem %%A = stream index
  rem %%B = language


  if not defined ENGSUB (
    if /I "%%B"=="eng" set "ENGSUB=%%A"
    if /I "%%B"=="en"  set "ENGSUB=%%A"
  )

  if not defined HEBSUB (
    if /I "%%B"=="heb" set "HEBSUB=%%A"
    if /I "%%B"=="he"  set "HEBSUB=%%A"
  )
)


rem --- Extract English subtitle if found ---
if defined ENGSUB (
  echo Extracting "%SUBBASE%.en.srt"
  ffmpeg -hide_banner -loglevel error -y -i "%IN%" -map 0:%ENGSUB% -c:s copy "%SUBBASE%.en.srt"
) else (
  echo No English subtitle stream found.
)

if defined HEBSUB (
  echo Extracting "%SUBBASE%.he.srt"
  ffmpeg -hide_banner -loglevel error -y -i "%IN%" -map 0:%HEBSUB% -c:s copy "%SUBBASE%.he.srt"
) else (
  echo No Hebrew subtitle stream found.
)

  
if errorlevel 1 (
  echo.
  echo ERROR: ffmpeg failed.
  echo Try a different audio_index: 0 or 1 are most common.
  exit /b 1
)

echo.
echo Done.
endlocal
