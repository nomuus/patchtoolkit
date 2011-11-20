@echo off
:: Patch ID Converter - Converts GUIDs to Patch IDs
:: Copyright (c) 2011, nomuus.
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

:: ---------------------------------------------------------------------------

:: pid-conv.bat
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
set VERSION=1.0.6.0
::
::
::
::
setlocal enabledelayedexpansion enableextensions
if not "%~1" == "" (
	set s=%~1
	set s=!s:}=!
	set s=!s:{=!
	set s=!s:-=!
	echo !s! | findstr /i /r "^^[0-9a-fA-F][0-9a-fA-F]*[^^!-~]$" 1>&2 > NUL
	if !errorlevel! equ 0 goto :main
	echo Invalid GUID specified. 
	goto :DONE
) else (
	call :DISPLAY_BANNER
	echo.%~n0%~x0 guid
	echo.
	echo.guid     GUID contained within MSI/MSP files.
	echo.
	echo.Note
	echo.The GUID within the MSP/MSI file can be located by using Microsoft Orca
	echo.by selecting "View", "Summary Information", then "Patch Code"
	echo.
	echo.Examples
	echo.%~n0%~x0 {0123456789ABC-DEF0-1234-56789ABCDEF0}
	echo.%~n0%~x0 0123456789ABC-DEF0-1234-56789ABCDEF0
	echo.%~n0%~x0 0123456789ABCDEF0123456789ABCDEF0
	goto :DONE
)

:main
call :strlen !s! s_len
if %s_len% neq 32 (
	echo Invalid GUID specified; length.
	goto :DONE
)

rem First pass shift 4, 1 byte (2) at a time
set buf=
for /l %%A in (0, 2, 31) do (
	call set b=0x%%s:~%%A,2%%
	set /a h="(b >> 4) | ((b & 0xf) << 4)"
	call :tohex h
	set buf=!buf!!h!
)

rem Second pass shift 8 on first 8 bytes (16), 2 bytes (4) at a time
rem This won't work on 16-bit systems, sorry about your old os
set s=!buf!
set buf=
for /l %%A in (0, 4, 15) do (
	call set b=0x!!s:~%%A,4!!
	set /a h="(b >> 8) | ((b & 0xff) << 8)"
	call :tohex h
	set buf=!buf!!h!
)
set s=!buf!!s:~16,16!

rem Third pass; do it the easy way since everything is already shifted
set buf=!s:~4,4!!s:~0,4!!s:~8,24!
set s=!buf!

rem Display the results
echo !s!

:DONE
rem clean-up
set buf=
set h=
set b=
set s_len=
endlocal

goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:strlen %str% RETURN
::
:: By:   nomuus/11-15-2011/1.0.0.0
::
:: Func: This will return the length of a string in a variable.
::
:: Args: %str% is the name of the variable containing the string.
::       RETURN is the variable name used to store the return value.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
setlocal enableextensions
set str=%1
set /a len=0
:while_str
if defined str (
	set str=%str:~1%
	set /a len+=1
	goto :while_str
)
endlocal&set "%~2=%len%"&set len=&goto :EOF
 
goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:tohex VARIABLE
::
:: Credit:  joshpoley/06-29-2011, 8:27 AM
:: License:  None
:: URL:  http://blogs.msdn.com/b/joshpoley/archive/2011/06/29/hex-conversion-via-a-batch-file.aspx
::
:: Modifications:
:: nomuus/11-15-2011/1.0.0.0 -- Input validation, Zero pad, Function enhancement, Minor tweaks
::
:: Func: This will return the hex representation of the number.
::
:: Args: VARIABLE is the variable name containing data to be converted and used to store the return value.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
    set _DECVAL=%1
    set _HEXVAL=
    set _VAL=%1
	
	if "%1" == "" goto :eof
	
    if %1 LSS 0 (
        REM break the number into two parts so that we can output the
        REM full value within the bounds of a 32 bit signed value
        set /A _offset="-(-2147483647 - !_VAL!) + 2"
        set /A _VAL="!_offset! / 16 + 0x7FFFFFF"
        set /A _P="!_offset! %% 16 + 0xF"

        if !_P! GEQ 16 (
        set /A _VAL="!_VAL! + 1"
        set /A _P="!_P! %% 16"
        )
        if !_P! LEQ 9 set _HEXVAL=!_P!!_HEXVAL!
        if "!_P!" == "10" set _HEXVAL=A!_HEXVAL!
        if "!_P!" == "11" set _HEXVAL=B!_HEXVAL!
        if "!_P!" == "12" set _HEXVAL=C!_HEXVAL!
        if "!_P!" == "13" set _HEXVAL=D!_HEXVAL!
        if "!_P!" == "14" set _HEXVAL=E!_HEXVAL!
        if "!_P!" == "15" set _HEXVAL=F!_HEXVAL!
    )
    :hexloop
    set /A _P="%_VAL% %% 16"
    if %_P% LEQ 9 set _HEXVAL=%_P%%_HEXVAL%
    if "%_P%" == "10" set _HEXVAL=A%_HEXVAL%
    if "%_P%" == "11" set _HEXVAL=B%_HEXVAL%
    if "%_P%" == "12" set _HEXVAL=C%_HEXVAL%
    if "%_P%" == "13" set _HEXVAL=D%_HEXVAL%
    if "%_P%" == "14" set _HEXVAL=E%_HEXVAL%
    if "%_P%" == "15" set _HEXVAL=F%_HEXVAL%
    set /A _VAL="%_VAL% / 16"
    if "%_VAL%" == "0" goto :endloop
    goto :hexloop
    :endloop
    
	set _offset=
    set _P=
    set _VAL=
	
	if !_HEXVAL! leq 16 (
		set _HEXVAL=0!_HEXVAL!
	)
endlocal&set "%~1=%_HEXVAL%"&set _HEXVAL=&goto :eof


:DISPLAY_BANNER
SETLOCAL ENABLEEXTENSIONS
	echo.
	echo Patch ID Converter !VERSION! - Converts GUIDs to Patch IDs
	echo %~n0%~x0  Copyright ^(C^) 2011  nomuus
	echo ----------------------------------------------------------------------
	echo This program comes with ABSOLUTELY NO WARRANTY.
	echo This is free software, and you are welcome to redistribute it
	echo under certain conditions.
	echo.
	echo For details on warranty and conditions, visit
	echo http://www.gnu.org/licenses/.
	echo ----------------------------------------------------------------------
ENDLOCAL&goto :EOF