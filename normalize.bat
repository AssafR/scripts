ffmpeg-normalize "%~1" ^
  -o "%~dpn1_NORM.mkv" ^
  -v -pr ^
  -nt ebu -t -16 -tp -2 ^
  --keep-loudness-range-target ^
  --auto-lower-loudness-target ^
  -c:a aac -b:a 96k ^
  -ar 48000 -ac 1