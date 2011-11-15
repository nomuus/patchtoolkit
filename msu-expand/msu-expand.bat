@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: MSU Expander - Automates the Microsoft Expansion Utility
:: Copyright (C) 2010, 2011  nomuus
::
:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.
::
:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.
:: 
:: You should have received a copy of the GNU General Public License
:: along with this program.  If not, see <http://www.gnu.org/licenses/>.

:: ----------------------------------------------------------------------------

:: msu-expand.bat
:: nomuus/2011-11-12/1.0.546.1 -- Public release.
:: nomuus/2010-05-16/1.0.0.0 -- Initial release.
::
:: @echo start uncomment to show obfuscated address.
:: @echo off & call :show_email & goto :eof
:: :show_email
:: setlocal
:: set liame=adu-wsu-wm-wexter-wnum@n-womu-wus.c-wom
:: set liame=%liame:-=%
:: set email=%liame:w=%
:: echo.%email%
:: endlocal&set liame=&set email=&goto :eof
:: @echo end uncomment to show obfuscated address.
::
set VERSION=1.0.546.1
::
:: MSU Expander batch script was created to automate the process of
:: extracting multiple MSU patch files using the Expansion Utility.
:: Typically one would need to use expand to extract the CAB file,
:: then from that CAB file extract the desired file.  This batch
:: script does the tedious tasks associated with the process so more
:: time can be spent examining patched files rather than 
:: extracting/expanding them.
::
:: Execute without arguments to see usage and examples.
:: 
:: The batch script will:
:: 1) Determine if expand.exe exists and it is 6.x or higher.
:: 2) Initialize and parse command line arguments.
:: 3) Loop through the file names (i.e. matching source specification)
::    in the current working directory.
:: 4) Determine the CAB file name within the MSU file.
:: 5) Create any needed output directories using the original file name.
:: 6) Expand the CAB file from the MSU file.
:: 7) Expand from the CAB file any of the desired user-specified files.
:: 8) Delete the CAB file, and repeat if there are more MSU files.
::
:: Troubleshooting?  (Remember...this is a BATCH FILE).
:: Redirect the output to stderr, 2> err.txt


:INIT_EXE
REM Edit to point to expand.exe binary
set EXPANDER=%systemroot%\system32\expand.exe

if not exist !EXPANDER! (
	echo Error:  !EXPANDER! not found.
	goto DONE
)


:INIT_DEPENDS
SETLOCAL ENABLEEXTENSIONS
REM Check dependency, expand.exe 6.x or newer
for /f "delims=" %%v in ('!EXPANDER! ^| findstr /I /R "Version 6\..*"') do @set tmpv=%%v
set expand_ver=%tmpv:Microsoft (R) File Expansion Utility  Version =%
set tmpv=

for /f "delims=." %%v in ( "!expand_ver!" ) do if /i %%v LSS 6 goto DEPENDENCY_WARN
set expand_ver=
ENDLOCAL


:INIT_ARGS
REM "Global", Source file specification
set SOURCE=

SETLOCAL ENABLEEXTENSIONS
REM Default source file specification, edit to change default.
set SRC=*KB*.msu

REM Parse command line arguments
:ARG1
if not "%1"=="" (
	echo "%1" | findstr /i /l "\\.." 1>&2 > NUL && echo ^[^^!^] Escape characters not permitted. && goto :EOF
	echo "%1" | findstr /i /l "\/.." 1>&2 > NUL && echo ^[^^!^] Escape characters not permitted. && goto :EOF
	echo "%1" | findstr /i /l "..\\" 1>&2 > NUL && echo ^[^^!^] Escape characters not permitted. && goto :EOF
	echo "%1" | findstr /i /l "..\/" 1>&2 > NUL && echo ^[^^!^] Escape characters not permitted. && goto :EOF
	goto ARG2 
) else (
	call :DISPLAY_BANNER
	echo %~n0%~x0 ^Files ^[Source^]
	echo.
	echo  Files  Files to expand from MSU cab file.
	echo         Use * for all files.
	echo Source  Source file specification. Wildcards may be used.
	echo         Default, !SRC!
	echo.
	echo.
	echo %~n0%~x0 *
	echo.
	echo   Expand every file from MSU files matching default source ^(!SRC!^).
	echo.
	echo %~n0%~x0 * Windows6.0-*.msu
	echo.
	echo   Expand every file from MSU files matching Windows6.0-*.msu.
	echo.
	echo %~n0%~x0 inetcomm.dll *KB978542*.msu
	echo.
	echo   Expand inetcomm.dll from MSU files matching *KB978542*.msu.
	echo.
	goto DONE
)
:ARG2
if not "%2"=="" (
	echo "%2" | findstr /i /l "\\.." 1>&2 > NUL && echo ^[^^!^] Escape characters not permitted. && goto :EOF
	echo "%2" | findstr /i /l "\/.." 1>&2 > NUL && echo ^[^^!^] Escape characters not permitted. && goto :EOF
	echo "%2" | findstr /i /l "..\\" 1>&2 > NUL && echo ^[^^!^] Escape characters not permitted. && goto :EOF
	echo "%2" | findstr /i /l "..\/" 1>&2 > NUL && echo ^[^^!^] Escape characters not permitted. && goto :EOF
	if not "%~x2"==".msu" (
		REM Note: Results at end of :MAIN remove the .msu for displaying directories
		echo Source specification missing .msu extension.
		choice /T 5 /D Y /M "Add missing .msu extension"
		if errorlevel 1 (
			set SRC=%~n2.msu
		) else (
			set SRC=
			goto DONE
		)
	) else (
		set SRC=%2
	)
)
ENDLOCAL&set SOURCE=%SRC%&goto :MAIN

:MAIN
@echo off
set COMPLETED=N
call :DISPLAY_BANNER
for %%x in (%SOURCE%) do (
	if not exist %%~nx (
		mkdir "%%~nx"
	)
	set CABFILE=
	
	echo Found msu file:  %%x
	REM Parse the cab filename from the msu
	call :PARSECAB "%%x" CABFILE
	echo Parse cab file:  !CABFILE!
	echo.
	
	if "!CABFILE!" == "ERROR" (
		echo.
		echo ^[^^!^] Error parsing cab file.
		goto :DONE
	)
	
	REM Second expand the CAB file.
	!EXPANDER! "%%x" -F:"!CABFILE!" "%%~nx" || goto :DISPLAY_ERROR
	
	REM Next expand the desired file from the CAB.
	!EXPANDER! "%%~nx\!CABFILE!" -F:"%1" "%%~nx" || goto :DISPLAY_ERROR
	echo.
	
	REM Last delete the CAB file.
	if exist "%%~nx\!CABFILE!" (
		echo ^[i^] del "%%~nx\!CABFILE!" ...
		echo.
		del "%%~nx\!CABFILE!"
		set CABFILE=
	) else (
		goto :DISPLAY_ERROR
	)
	set COMPLETED=Y
)
:RESULTS
if not "!COMPLETED!" == "Y" (
	echo ^[^^!^] An error was encountered.  Check the source specification.
	goto :DONE
)
REM Displays the directories matching source spec, not 100% accurate.
SETLOCAL ENABLEEXTENSIONS
echo.
echo ^[i^] Expanded %1 from !SOURCE! in %CD% to:
for /d %%z in (%SOURCE:.msu=%) do (
	echo/ %%z\
	set /a cx=0
	set /a max=10
	set /a once=0
	for /f "usebackq" %%y in (`dir /b %%z`) do (
		if /i !cx! LSS !max! (
			echo/ ^|-- %%y
		) else (
			if /i !once! NEQ 1 (
				echo/ ^|-- ...
				set /a once=1
			)
			rem else (
			rem	set /a once=0
			rem )
			
		)
		set /a cx+=1
	)
)
ENDLOCAL
goto :DONE


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:PARSECAB %filename% CABFILE
::
:: By:   nomuus/05-15-2010/1.0.0.0
::
:: Func: This will parse the cab file name from the supplied msu file by
::       listing the files within the msu then searching for ":.*KB.*\.cab$
::       For #1: Finds the cab file name in the msu
::       For #2: Strips out the msu file name from the results
::       For #3: Strips out spaces from start of string
::       Result is set to %cf% and control returned to the callee.
::
:: Args: %filename% is the name of the msu file.
::       CABFILE is the return value
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SETLOCAL ENABLEEXTENSIONS
for /f "delims=" %%v in ('!EXPANDER! -D %1 ^| findstr /I /R ":.*KB.*\.cab$"') do set tmpfile=%%v
for /f "tokens=2 delims=:" %%a in ("%tmpfile%") do set tmpfile2=%%a
for /f "delims= " %%a in ("%tmpfile2%") do set tmpfile=%%a

if "!tmpfile:~-4!" == ".cab" (
	set cf=%tmpfile%
) else (
	set cf=ERROR
)
set tmpfile=
set tmpfile2=

ENDLOCAL&set %2=%cf%&goto :EOF
goto :DONE


:DEPENDENCY_WARN
echo Warning:  Dependency missing, Microsoft (R) File Expansion Utility 6.0,
echo           Obtain version 6.0 or newer and edit the EXPANDER variable.
goto :DONE


:DISPLAY_BANNER
SETLOCAL ENABLEEXTENSIONS
	echo.
	echo MSU Expander !VERSION! - Automates the Microsoft Expansion Utility.
	echo %~n0%~x0  Copyright ^(C^) 2010, 2011  nomuus
	echo ----------------------------------------------------------------------
	echo This program comes with ABSOLUTELY NO WARRANTY.
	echo This is free software, and you are welcome to redistribute it
	echo under certain conditions.
	echo.
	echo For details on warranty and conditions, visit
	echo http://www.gnu.org/licenses/.
	echo ----------------------------------------------------------------------
	echo.
	echo.
ENDLOCAL&goto :EOF	


goto :DONE
:DISPLAY_ERROR
echo ^[^^!^] An error was encountered.  Expansion failed.
goto :DONE


:DONE
set EXPANDER=
set SOURCE=