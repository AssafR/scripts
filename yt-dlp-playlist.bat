@echo off
setlocal EnableExtensions

if "%~1"=="" (
  echo USAGE: %~nx0 "https://www.youtube.com/playlist?list=..."
  echo NOTE: URL must be in quotes.
  exit /b 1
)

set "URL=%~1"

where yt-dlp >nul 2>&1
if errorlevel 1 (
  echo ERROR: yt-dlp not found in PATH.
  exit /b 1
)

set "PLID_FILE=%TEMP%\ytpl_id_%RANDOM%.txt"
set "SAMPLE_FILE=%TEMP%\ytpl_sample_%RANDOM%.txt"
set "IDS_FILE=%TEMP%\ytpl_ids_%RANDOM%.txt"

echo [INFO ] Reading playlist ID...
rem stdout -> file, stderr -> NUL
yt-dlp --no-warnings --flat-playlist --playlist-items 1 --print "%%(playlist_id)s" "%URL%" > "%PLID_FILE%" 2>nul
if errorlevel 1 goto ERR_PLID

set "PLID="
for /f "usebackq delims=" %%A in ("%PLID_FILE%") do if not defined PLID set "PLID=%%A"
del /f /q "%PLID_FILE%" >nul 2>&1
if not defined PLID goto ERR_PLID_EMPTY
echo [INFO ] Playlist ID: %PLID%

echo [INFO ] Computing output folder...
rem stdout -> file, stderr -> NUL
yt-dlp --no-warnings --skip-download --playlist-items 1 ^
  -o "%%(playlist_title)s\%%(playlist_index)02d - %%(title)s.%%(ext)s" ^
  --print filename "%URL%" > "%SAMPLE_FILE%" 2>nul
if errorlevel 1 goto ERR_SAMPLE

set "SAMPLEFILE="
for /f "usebackq delims=" %%A in ("%SAMPLE_FILE%") do if not defined SAMPLEFILE set "SAMPLEFILE=%%A"
del /f /q "%SAMPLE_FILE%" >nul 2>&1
if not defined SAMPLEFILE goto ERR_SAMPLE_EMPTY

for %%I in ("%SAMPLEFILE%") do set "OUTDIR=%%~dpI"
if "%OUTDIR%"=="" goto ERR_OUTDIR

echo [INFO ] Output folder: "%OUTDIR%"
mkdir "%OUTDIR%" >nul 2>&1

set "ARCHIVE=%OUTDIR%archive-%PLID%.txt"
echo [INFO ] Archive file: "%ARCHIVE%"

rem ===== Summary prep =====
echo [INFO ] Counting playlist items...
rem Get ALL item IDs in playlist (stdout only)
yt-dlp --no-warnings --flat-playlist --print "%%(id)s" "%URL%" > "%IDS_FILE%" 2>nul

set "TOTAL=0"
for /f %%N in ('find /v /c "" ^< "%IDS_FILE%"') do set "TOTAL=%%N"

set "PRE=0"
if exist "%ARCHIVE%" for /f %%N in ('find /v /c "" ^< "%ARCHIVE%"') do set "PRE=%%N"

echo [INFO ] Starting download...
yt-dlp -i ^
  -o "%%(playlist_title)s\%%(playlist_index)02d - %%(title)s.%%(ext)s" ^
  --download-archive "%ARCHIVE%" ^
  --no-overwrites "%URL%"

rem ===== Post-run counts =====
set "POST=%PRE%"
if exist "%ARCHIVE%" for /f %%N in ('find /v /c "" ^< "%ARCHIVE%"') do set "POST=%%N"

set /a DOWNLOADED=POST-PRE
if %DOWNLOADED% LSS 0 set "DOWNLOADED=0"

rem Succeeded overall = min(POST, TOTAL)
set "SUCCEEDED=%POST%"
if %SUCCEEDED% GTR %TOTAL% set "SUCCEEDED=%TOTAL%"

rem Already in archive this run = min(PRE, TOTAL)
set "ALREADY=%PRE%"
if %ALREADY% GTR %TOTAL% set "ALREADY=%TOTAL%"

set /a FAILED=TOTAL-SUCCEEDED
if %FAILED% LSS 0 set "FAILED=0"

echo.
echo [SUMMARY]
echo   Total items in playlist : %TOTAL%
echo   Already in archive      : %ALREADY%
echo   Downloaded this run     : %DOWNLOADED%
echo   Failed / unavailable    : %FAILED%
echo.
echo [DONE ] Files saved under:
echo          %OUTDIR%

del /f /q "%IDS_FILE%" >nul 2>&1
exit /b 0

:ERR_PLID
echo ERROR: Failed reading playlist ID. (Network/permissions? Ensure URL is quoted.)
exit /b 1

:ERR_PLID_EMPTY
echo ERROR: Couldn't read playlist ID. The URL may be private/region-locked, or quoting was missed.
exit /b 1

:ERR_SAMPLE
echo ERROR: Failed computing sample filename (yt-dlp couldn't resolve the first item).
exit /b 1

:ERR_SAMPLE_EMPTY
echo ERROR: Couldn't compute sample filename.
exit /b 1

:ERR_OUTDIR
echo ERROR: Couldn't parse output folder from: %SAMPLEFILE%
exit /b 1
