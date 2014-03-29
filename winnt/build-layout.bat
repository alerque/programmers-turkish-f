@echo off
setlocal enableextensions enabledelayedexpansion
if "%BASEDIR%" equ "" set BASEDIR=%ProgramFiles%\WinDDK\3790.1830
set PATH=%BASEDIR%\bin\x86;%WINDIR%\System32;%ProgramFiles%\Suppor~1
set INCLUDE=%BASEDIR%\inc\wxp;%BASEDIR%\inc\crt
set LIB=%BASEDIR%\lib\wxp\i386;%BASEDIR%\lib\crt\i386
nmake -nologo -fkbddvp.mak "WINDDK=%BASEDIR%" %*
endlocal
