#requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$List, [switch]$DryRun,
    [ValidateSet('es','en')][string]$Lang = 'es',
    [string]$TargetDrive, [string]$SoftwareRoot, [string]$DevRoot, [string]$DataRoot
)
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Use bash bootstrap.sh on macOS/Linux. WSL configures Linux, not the Windows host.'
}
if (-not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
    throw 'Windows automatic installation currently supports x64 only.'
}
$build=[int](Get-ItemPropertyValue -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuild)
if ($build -lt 17763) { throw 'Windows 10 1809 or newer / Windows 11 is required.' }
. "$PSScriptRoot/scripts/windows/common.ps1"
. "$PSScriptRoot/scripts/windows/install.ps1"
. "$PSScriptRoot/scripts/windows/config.ps1"
. "$PSScriptRoot/scripts/windows/ui.ps1"
$state = New-WindowsState -RepoRoot $PSScriptRoot -DryRun:$DryRun -Language $Lang
Set-WindowsPaths $state $TargetDrive $SoftwareRoot $DevRoot $DataRoot
$catalog = @(Get-WindowsCatalog $state.RepoRoot)
$inventory = Get-WindowsInventory $state
if ($List) { Show-WindowsInventory $state $catalog $inventory; return }
$interactive = Test-WindowsInteractive
if (-not $interactive -and -not $DryRun) { throw 'Interactive input required. Use -List or -DryRun.' }
$choices = New-WindowsChoices $catalog $inventory $state
if ($interactive) {
    if (-not (Show-WindowsWizard $state $catalog $inventory $choices)) { return }
}
Add-WindowsDependencies $choices $catalog $inventory $state
Show-WindowsSummary $state $catalog $inventory $choices
if (-not $DryRun -and (Read-Host (Get-WindowsText $state 'Escribe SI para ejecutar' 'Type YES to execute')) -notmatch '^(SI|YES)$') { return }
try {
    Invoke-WindowsSetup $state $catalog $inventory $choices
} finally {
    Clear-WindowsTemporary $state
}
if ($state.Failed.Count) { throw ('Incomplete actions: ' + ($state.Failed -join ', ')) }
Write-Host (Get-WindowsText $state 'Terminado. Abre una terminal nueva.' 'Done. Open a new terminal.')
