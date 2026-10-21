ffmpeg -hide_banner -i "%~1" ^
  -map 0 ^
  -c copy ^
  "%~dpn1_remux_all.mkv"