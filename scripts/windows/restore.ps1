#requires -Version 5.1
[CmdletBinding()]
param([switch]$List, [string]$Backup, [string]$Id, [switch]$DryRun)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/common.ps1"
. "$PSScriptRoot/config.ps1"
. "$PSScriptRoot/restore-functions.ps1"
$state=New-WindowsState -RepoRoot (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -DryRun:$DryRun
if ($List) {
    $root=Join-Path $state.StateRoot 'backups'
    Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $manifest=Join-Path $_.FullName 'manifest.json'
        if (Test-Path -LiteralPath $manifest -PathType Leaf) {
            Write-Host "`n$($_.FullName)"
            $entries=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($manifest))
            foreach ($entry in $entries) { Write-Host "$($entry.id) | $($entry.type) | $($entry.target) | $($entry.original)" }
        }
    }
    return
}
$entry=Get-WindowsRestoreEntry $state $Backup $Id
Write-Host "Restore: $($entry.target) [$($entry.type)]"
if (-not $DryRun) {
    if ([Console]::IsInputRedirected) { throw 'Interactive confirmation required.' }
    if ((Read-Host 'Type RESTORE to back up the current state and restore this entry') -cne 'RESTORE') { return }
}
Restore-WindowsEntry $state $Backup $entry
if ($state.Backup) { Write-Host "Previous state backed up: $($state.Backup)" }
