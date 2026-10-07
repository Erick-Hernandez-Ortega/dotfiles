# Run ONLY in a disposable Windows Sandbox/VM. This intentionally installs software.
[CmdletBinding()]
param([switch]$DisposableMachine)
$ErrorActionPreference='Stop'
if (-not $DisposableMachine) { throw 'This installs software. Run only in a disposable Windows VM with -DisposableMachine.' }
$repo=Split-Path $PSScriptRoot -Parent
. "$repo/scripts/windows/common.ps1"
. "$repo/scripts/windows/install.ps1"
. "$repo/scripts/windows/config.ps1"
$root=Join-Path $env:USERPROFILE ('ramon-smoke-' + [guid]::NewGuid().ToString('N'))
$state=New-WindowsState -RepoRoot $repo -StateRoot (Join-Path $root 'state')
Set-WindowsPaths $state ([IO.Path]::GetPathRoot($root)) (Join-Path $root 'External Apps') (Join-Path $root 'Projects') (Join-Path $root 'Data')
try {
    $catalog=@(Get-WindowsCatalog $repo)
    foreach ($id in 'eza','bat','fd','fastfetch','git','terminal-icons') {
        $item=@($catalog | Where-Object id -EQ $id)[0]
        Install-WindowsOption $state $item
        if (-not (Test-WindowsInstalled $item (Get-WindowsInventory $state) $state)) { throw "Missing after install: $id" }
    }
    $profile=Join-Path $root 'profile.ps1'
    Set-WindowsProfile $state $profile
    $tokens=$null; $errors=$null
    $null=[Management.Automation.Language.Parser]::ParseFile($profile,[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw $errors }
    Write-Host "Smoke passed. Dispose of the VM to remove installed software and fixtures: $root"
} finally { Clear-WindowsTemporary $state }
