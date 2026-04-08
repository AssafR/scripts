call choco upgrade all /y 
call winget upgrade yt-dlp.yt-dlp --skip-dependencies -e
REM call winget upgrade --all --include-unknown
call winget upgrade --all --include-unknown --accept-source-agreements --accept-package-agreements
