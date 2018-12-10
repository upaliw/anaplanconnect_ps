@echo off
rem This is the main process to interact with Anaplan using AnaplanConnect 

call AnaplanConfig.bat

set WorkspaceId=%2
set ModelId=%3

if "%1" == "IMPORT" (set Operation=-s %ServiceLocation% -auth %AuthenticationLocation% -file %4 -put %5 -import %6 -execute -output %7)
if "%1" == "IMPORTANDPROCESS" (set Operation=-s %ServiceLocation% -auth %AuthenticationLocation% %~4 -process %5 -execute -output %6)
if "%1" == "EXPORT" (set Operation=-s %ServiceLocation% -auth %AuthenticationLocation% -export %4 -execute -get %5)
if "%1" == "ACTION" (set Operation=-s %ServiceLocation% -auth %AuthenticationLocation% -action %4 -execute)
if "%1" == "PROCESS" (set Operation=-s %ServiceLocation% -auth %AuthenticationLocation% -process %4 -execute)
if "%1" == "JDBCIMPORT" (set Operation=-s %ServiceLocation% -auth %AuthenticationLocation% -file %4 -jdbcproperties %5 -import %6 -execute -output %7)
if "%1" == "JDBCPROCESS" (set Operation=-s %ServiceLocation% -auth %AuthenticationLocation% -file %4 -jdbcproperties %5 -process %6 -execute -output %7)

rem *** End of settings - Do not edit below this line ***
setlocal enableextensions enabledelayedexpansion || exit /b 1
cd %~dp0
set Credentials=-k %Keystore% -ka %KeystoreAlias% -kp %KeystorePassword%
if not %AnaplanUser% == "" set Credentials=-u %AnaplanUser%
set Command=.\AnaplanClient.bat -debug %Credentials% -w %WorkspaceId% -m %ModelId% %Operation%
@echo %Command%
cmd /c %Command%
