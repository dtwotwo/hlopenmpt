@echo off
setlocal

cd /d "%~dp0"
if errorlevel 1 exit /b 1
copy /Y "..\out\build\release\extension\openmpt.hdll" "testMain\openmpt.hdll" >nul
cd testMain

echo [1/2] Compiling Heaps smoke test...
haxe test-heaps.hxml
if errorlevel 1 goto :fail

echo [2/2] Running Heaps smoke test...
hl test-heaps.hl
if errorlevel 1 goto :fail

exit /b 0

:fail
echo Tests failed with exit code %ERRORLEVEL%.
exit /b %ERRORLEVEL%
