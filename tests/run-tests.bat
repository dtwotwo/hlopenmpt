@echo off
setlocal

call "%~dp0test-miniaudio.bat"
if errorlevel 1 exit /b %ERRORLEVEL%

call "%~dp0test-openal.bat"
if errorlevel 1 exit /b %ERRORLEVEL%

call "%~dp0test-heaps.bat"
if errorlevel 1 exit /b %ERRORLEVEL%

echo All hlopenmpt tests passed.