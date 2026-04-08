REM SET CLI="C:\Users\assafr\Dropbox\HandBrake-0.9.9-x86_64-Win_CLI\HandBrakeCLI.exe"
SET CLI="C:\Program Files\Handbrake\HandBrakeCLI.exe"
SET SRC=%1
REM SET DST=S:\Video\%~n1_.mkv
REM -w 1280
SET DST="%~dpn1_1_.mkv"
SET AUD= -a 1 -E faac -6 mono -R Auto -B 112 -D 0 --gain 0 --audio-fallback ffac3 
SET params=-t 1 --angle 1 -c 1  -f mkv  --deinterlace="slow"  --loose-anamorphic  --keep-display-aspect --crop 0:0:0:0 --modulus 2 -e x264 -b 800 -2  --vfr -x b-adapt=2:direct=auto:me=umh:subme=10:trellis=2:aq-strength=1.3 --verbose=1
echo DST=%DST%
%CLI% -i %1 -o %DST% %AUD% %params%
