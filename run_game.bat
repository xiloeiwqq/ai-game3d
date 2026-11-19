@echo off
setlocal
set "ROOT=%~dp0"
if exist "%ROOT%build\windows\AIWorldGenerator.exe" (
  start "AI World Generator" "%ROOT%build\windows\AIWorldGenerator.exe"
  exit /b 0
)
where godot4 >nul 2>nul && (godot4 --path "%ROOT%" & exit /b %errorlevel%)
where godot >nul 2>nul && (godot --path "%ROOT%" & exit /b %errorlevel%)
echo AIWorldGenerator.exe or Godot 4 was not found.
echo Run tools\build_windows.ps1 first, or install Godot 4.7.2.
pause
exit /b 1
