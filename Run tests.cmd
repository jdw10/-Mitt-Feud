@echo off
setlocal
set "APPDATA=%~dp0saves"
if not exist "%APPDATA%" mkdir "%APPDATA%"
"%~dp0runtime\Godot_console.exe" --headless --path "%~dp0." --script tests.gd
pause
