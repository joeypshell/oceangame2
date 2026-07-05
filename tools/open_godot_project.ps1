param(
    [string]$GodotPath = $env:GODOT_EXE,
    [string]$MapPath = "",
    [switch]$Run,
    [switch]$DebugOverlay,
    [switch]$OriginalMap,
    [switch]$OrganicMap,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ProjectFile = Join-Path $ProjectRoot "project.godot"

function Resolve-GodotExecutable {
    param([string]$RequestedPath)

    $candidates = @()
    if ($RequestedPath) {
        $candidates += $RequestedPath
    }

    $candidates += @(
        "C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe",
        "C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Unable to find Godot. Set GODOT_EXE or pass -GodotPath with the full path to a Godot 4.7 executable."
}

if (-not (Test-Path -LiteralPath $ProjectFile)) {
    throw "Unable to find project.godot at $ProjectFile"
}

$GodotExe = Resolve-GodotExecutable -RequestedPath $GodotPath

if ($Run) {
    $GodotArgs = @("--path", $ProjectRoot)
    if ($OriginalMap -and $OrganicMap) {
        throw "Use either -OriginalMap or -OrganicMap, not both."
    }
    if ($OriginalMap) {
        $MapPath = "res://maps/cave_salvage_test_01.greybox.json"
    }
    if ($OrganicMap) {
        $MapPath = "res://maps/cave_salvage_organic_01.greybox.json"
    }
    if ($MapPath) {
        $GodotArgs += "--map-path=$MapPath"
    }
    if ($DebugOverlay) {
        $GodotArgs += "--show-debug-overlay"
    }
    $Mode = "project"
} else {
    $GodotArgs = @("--editor", "--path", $ProjectRoot)
    $Mode = "editor"
}

Write-Host "Godot: $GodotExe"
Write-Host "Project: $ProjectRoot"
Write-Host "Mode: $Mode"
Write-Host "Args: $($GodotArgs -join ' ')"

if ($CheckOnly) {
    return
}

Start-Process -FilePath $GodotExe -ArgumentList $GodotArgs -WorkingDirectory $ProjectRoot
