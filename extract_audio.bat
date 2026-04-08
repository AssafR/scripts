REM SET ffmpeg=E:\Dropbox\software\ffmpeg\bin\ffmpeg.exe
SET ffmpeg="C:\Program Files\MediaCoder\codecs64\ffmpeg.exe"
SET infile=%1
SET outfile="%~dpn1.aac"
REM also: ffmpeg -i Sample.avi -vn -ar 44100 -ac 2 -ab 192 -f mp3 Sample.mp3


 %ffmpeg% -i %infile% -vn -acodec copy %outfile%
