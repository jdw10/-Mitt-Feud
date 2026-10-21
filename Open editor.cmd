@echo off
setlocal
set "APPDATA=%~dp0saves"
if not exist "%APPDATA%" mkdir "%APPDATA%"
start "" "%~dp0runtime\Godot.exe" --editor --path "%~dp0."
