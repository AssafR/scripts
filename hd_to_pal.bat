SET CLI="C:\Program Files\Handbrake\HandBrakeCLI.exe"
SET IN=%1
SET OUT="%~dpn1_PAL.mkv"
SET RES=-w 720 -l 576 --crop 0:0:0:0 --custom-anamorphic  --display-width 720 --pixel-aspect 16:9  --modulus 2
SET ALG=--x264-preset=veryslow  --x264-profile=main  --h264-level="4.0"  -e x264 -b 1500 -2  -T  -r 25 --cfr 
SET AUD= -a 1 -E copy -6 auto -R Auto -B 0 -D 0 --gain 0 --audio-fallback ffac3
SET PROCESS=--deinterlace="slower" 
REM --denoise="weak"
SET TYPE=-f mkv -e x264 -r 25 --cfr -t 1 --angle 1 -c 1-200
%CLI% -i %IN%  -o %OUT%  %TYPE% %RES% %PROCESS% %AUD% %ALG% --verbose=1