@echo off
cd %~dp0

powershell.exe -ExecutionPolicy ByPass -file FileWatch.ps1 %1
if errorlevel 1 (
  exit /b 1
) else (
  powershell.exe -ExecutionPolicy ByPass -file FileCopy.ps1 %1
  if errorlevel 1 (
    exit /b 1
  ) else (
    powershell.exe -ExecutionPolicy ByPass -file FileRun.ps1 %1
    if errorlevel 1 (
      exit /b 1
    )
  )
)
