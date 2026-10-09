#Requires -Version 5.1
<#
.SYNOPSIS
    Backward-compatible entry point for Update-Windows11.ps1.
.DESCRIPTION
    Replaces the unsafe legacy implementation. This wrapper delegates all work
    to the maintained script, preserving its preview, confirmation and skip
    options. No Windows Update operations are implemented here.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$CreateRestorePoint,
    [string]$LogPath,
    [switch]$SkipWindowsUpdate,
    [switch]$SkipWingetUpdate,
    [switch]$SkipStoreUpdate
)

$maintainedScript = Join-Path -Path $PSScriptRoot -ChildPath 'Update-Windows11.ps1'
if (-not (Test-Path -LiteralPath $maintainedScript -PathType Leaf)) {
    throw "Maintained update script not found: $maintainedScript"
}

if ($WhatIfPreference) {
    & $maintainedScript @PSBoundParameters
    return
}

if ($PSCmdlet.ShouldProcess('Windows 11 update workflow', 'Run maintained update script')) {
    & $maintainedScript @PSBoundParameters
}
