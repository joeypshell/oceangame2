param(
    [string]$GodotPath = $env:GODOT_EXE,
    [string]$MapPath = "",
    [switch]$Run,
    [switch]$DebugOverlay,
    [switch]$OriginalMap,
    [switch]$OrganicMap,
    [switch]$FullSketchMap,
    [switch]$ProductionLevelMap,
    [switch]$ProductionSliceMap,
    [switch]$ProductionSlice2Map,
    [switch]$ProductionSlice3Map,
    [switch]$ProductionSlice4Map,
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
    $MapShortcutCount = 0
    if ($OriginalMap) { $MapShortcutCount += 1 }
    if ($OrganicMap) { $MapShortcutCount += 1 }
    if ($FullSketchMap) { $MapShortcutCount += 1 }
    if ($ProductionLevelMap) { $MapShortcutCount += 1 }
    if ($ProductionSliceMap) { $MapShortcutCount += 1 }
    if ($ProductionSlice2Map) { $MapShortcutCount += 1 }
    if ($ProductionSlice3Map) { $MapShortcutCount += 1 }
    if ($ProductionSlice4Map) { $MapShortcutCount += 1 }
    if ($MapShortcutCount -gt 1) {
        throw "Use only one map shortcut: -OriginalMap, -OrganicMap, -FullSketchMap, -ProductionLevelMap, -ProductionSliceMap, -ProductionSlice2Map, -ProductionSlice3Map, or -ProductionSlice4Map."
    }
    if ($OriginalMap) {
        $MapPath = "res://maps/cave_salvage_test_01.greybox.json"
    }
    if ($OrganicMap) {
        $MapPath = "res://maps/cave_salvage_organic_01.greybox.json"
    }
    if ($FullSketchMap) {
        $MapPath = "res://maps/full_cave_sketch_01.greybox.json"
    }
    if ($ProductionLevelMap) {
        $GodotArgs += "--production-level-map"
    }
    if ($ProductionSliceMap) {
        $MapPath = "res://maps/production_slice_01.greybox.json"
    }
    if ($ProductionSlice2Map) {
        $MapPath = "res://maps/production_slice_02.greybox.json"
    }
    if ($ProductionSlice3Map) {
        $MapPath = "res://maps/production_slice_03.greybox.json"
    }
    if ($ProductionSlice4Map) {
        $MapPath = "res://maps/production_slice_04.greybox.json"
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
