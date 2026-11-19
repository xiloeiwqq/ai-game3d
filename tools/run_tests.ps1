param(
    [string]$GodotPath = $env:GODOT_PATH
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot

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

& $GodotPath --headless --path $ProjectRoot 'res://tests/test_runner.tscn'
exit $LASTEXITCODE
