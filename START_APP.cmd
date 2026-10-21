@echo off
setlocal
cd /d "%~dp0"
set "PATH=%~dp0bin;%SystemRoot%\System32;%SystemRoot%"
"%~dp0bin\inspect.exe" view --image "data\KolektorSDD2\test\20042.png"
if errorlevel 1 (
  echo Application failed. Please send the displayed error message.
  pause
)
