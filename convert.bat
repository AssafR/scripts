SET encoder="C:\Program Files\Handbrake\HandBrakeCLI.exe"

SET person=%1
SET EP=%2
SET start_ntsc=%3
SET length_ntsc=%5
SET start_pal=%6
SET length_pal=%8
SET input=%9
SET outputdir=C:\MyDocuments\Copy assaf@razon-family.com\Buffy
SET params=-t 1 --angle 1 -c 1-200  -f mkv  -w 720 --crop 0:0:0:0 --loose-anamorphic  --modulus 2 -e x264 -q 20 -r 25 --cfr -a 1 -E faac -6 stereo -R Auto -B 256 -D 0 --gain 0 --audio-fallback ffac3  --x264-preset=veryslow  --x264-profile=main --h264-level="4.0"  --verbose=1


SET PAL_output="C:\MyDocuments\Copy assaf@razon-family.com\Buffy\Buffy.3x03.faith, Hope And Trick.x264-1.mkv"
SET PAL_startduration=%start_pal%
SET PAL_lengthduration=%length_pal%
SET PAL_output=%outputdir%\%person%_%EP%_PAL.mkv
SET PAL_duration=--start-at duration:%PAL_startduration% --stop-at duration:%PAL_lengthduration%


SET NTSC_output="C:\MyDocuments\Copy assaf@razon-family.com\Buffy\Buffy.3x03.faith, Hope And Trick.x264-1.mkv"
SET NTSC_startduration=%start_ntsc%
SET NTSC_lengthduration=%length_ntsc%
SET NTSC_output=%outputdir%\%person%_%EP%_NTSC.mkv
SET NTSC_duration=--start-at duration:%NTSC_startduration% --stop-at duration:%NTSC_lengthduration%
REM --markers="C:\Users\assaf\AppData\Local\Temp\Buffy.3x03.faith, Hope And Trick.x264-1-1-chapters.csv"

%encoder% -i %input% -o "%NTSC_output%" %NTSC_duration% %params%
%encoder% -i %input% -o "%PAL_output%"  %PAL_duration%  %params%   


:end
