@echo off
setlocal
cd /d "%~dp0"
set "PATH=%~dp0bin;%SystemRoot%\System32;%SystemRoot%"
if not exist "checks" mkdir "checks"
copy /y "outputs\demo_sequence.avi" "checks\demo_sequence.avi" >nul
>"checks\check_log.txt" echo Portable project checks - %DATE% %TIME%
echo Running geometry and feature tests...
"bin\core_tests.exe" >>"checks\check_log.txt" 2>&1
if errorlevel 1 goto failed
echo Running real image and video synchronization checks...
"bin\inspect.exe" verify --output checks >>"checks\check_log.txt" 2>&1
if errorlevel 1 goto failed
echo Opening the automated OpenGL test window...
"bin\inspect.exe" view --smoke --output checks --image "data\KolektorSDD2\test\20042.png" >>"checks\check_log.txt" 2>&1
if errorlevel 1 goto failed
echo PASS - all automated checks completed.
echo PASS - all automated checks completed.>>"checks\check_log.txt"
echo Results, genuine screenshots and logs are in the checks folder.
if /i "%~1"=="--no-pause" exit /b 0
pause
exit /b 0
:failed
echo A check failed. Please send checks\check_log.txt.
type "checks\check_log.txt"
if /i "%~1"=="--no-pause" exit /b 1
pause
exit /b 1
