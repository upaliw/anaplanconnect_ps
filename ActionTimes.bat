@echo off
:: This script looks up the current date, writes it to a csv file, and sends it to Anaplan 

:: Here we set the file path of the csv file we will be writing the current date too
set FileName=".\ActionTimes.csv"

:: rem This is a simple for loop that parses the date /t function
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "yyyy=%dt:~0,4%"
set "mm=%dt:~4,2%"
set "dd=%dt:~6,2%"
set "h=%dt:~8,2%"
set "m=%dt:~10,2%"
set "s=%dt:~12,2%"

set actionName=%1
set actionStart=%yyyy%-%mm%-%dd% %h%:%m%:%s%

@echo "Action Name","Action Date"> %FileName%
@echo "%actionName%","%actionStart%">> %FileName%

call ./config/AnaplanConfig.bat

set WorkspaceId=%2
set ModelId=%3

set Operation=-file "ActionTimes.csv" -put "ActionTimes.csv" -process "Update Action Time" -execute

rem *** End of settings - Do not edit below this line ***

setlocal enableextensions enabledelayedexpansion || exit /b 1
cd %~dp0
set Credentials=-k %Keystore% -ka %KeystoreAlias% -kp %KeystorePassword%
if not %AnaplanUser% == "" set Credentials=-user %AnaplanUser%
set Command=.\AnaplanClient.bat -s %ServiceLocation% -auth %AuthenticationLocation% %Credentials% -w %WorkspaceId% -m %ModelId% %Operation%
echo %Command%
cmd /c %Command%
