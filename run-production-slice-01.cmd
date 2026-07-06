@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\open_godot_project.ps1" -Run -ProductionSliceMap %*
