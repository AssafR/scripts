
set year=%date:~10,4%
echo year=%year%
set month=%date:~4,2%
if "%month:~0,1%" == " " set month=0%month:~1,1%
echo month=%month%
set day=%date:~7,2%
if "%day:~0,1%" == " " set day=0%day:~1,1%
echo day=%day%

set datetime=%year%-%month%-%day%
echo datetime = %datetime%
for %%b in (%1) do ( 

    set target = ""
	REM echo rename %%b "%datetime%-%%b"
	REM ECHO filedrive=%%~db
	REM ECHO filepath=%%~pb
	REM ECHO filename=%%~nb
	REM ECHO fileextension=%%~xab
	
	REM SET target="%%~db%%~pb\%datetime%-%%~nb%%~xb"
	SET target="%datetime%-%%~nb%%~xb"

	echo src = %%b
	echo rename %%b %target%
	
)
