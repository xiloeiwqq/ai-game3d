param(
    [string]$GodotPath = $env:GODOT_PATH
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BuildDirectory = Join-Path $ProjectRoot 'build\windows'

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $candidate = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate) { $GodotPath = $candidate.Source }
}
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $portable = Join-Path $env:LOCALAPPDATA 'Temp\opencode\ai-world-tools\godot\Godot_v4.7.2-stable_win64_console.exe'
    if (Test-Path $portable) { $GodotPath = $portable }
}
if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path $GodotPath)) {
    throw 'Godot 4.7.2 was not found. Pass -GodotPath or set GODOT_PATH.'
}

New-Item -ItemType Directory -Force -Path $BuildDirectory | Out-Null
& $GodotPath --headless --path $ProjectRoot --export-release 'Windows Desktop' (Join-Path $BuildDirectory 'AIWorldGenerator.exe')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$Executable = Join-Path $BuildDirectory 'AIWorldGenerator.exe'
if (-not (Test-Path $Executable)) { throw 'Godot reported success, but the executable is missing.' }
Write-Host "Windows build created: $Executable"
