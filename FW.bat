@echo off
cd %~dp0

cd C:\AnaplanInterface\

powershell.exe  -ExecutionPolicy ByPass -file FileWatch.ps1 %1
if errorlevel 1 (
  exit /b
) 
