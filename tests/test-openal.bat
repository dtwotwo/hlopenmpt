@echo off
setlocal

cd /d "%~dp0"
if errorlevel 1 exit /b 1
copy /Y "..\out\build\release\extension\openmpt.hdll" "testMain\openmpt.hdll" >nul
cd testMain

echo [1/2] Compiling OpenAL tests...
haxe test-openal.hxml
if errorlevel 1 goto :fail

echo [2/2] Running OpenAL tests...
hl test-openal.hl
if errorlevel 1 goto :fail

exit /b 0

:fail
echo Tests failed with exit code %ERRORLEVEL%.
pause
