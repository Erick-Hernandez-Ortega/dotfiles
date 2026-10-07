# Portable personal initialization; private settings stay outside the repository.
# Existing profiles may already initialize these tools. Avoid duplicate prompts/modules.
if (-not $global:RamonDotfilesInitialized) {
    $global:RamonDotfilesInitialized=$true
    $posh=Get-Command oh-my-posh -ErrorAction SilentlyContinue
    if ($posh -and -not (Get-Variable POSH_THEME -ErrorAction SilentlyContinue) -and -not $env:POSH_THEME) {
        $theme=Join-Path $PSScriptRoot 'robbyrussell.omp.json'
        if (Test-Path -LiteralPath $theme) { & $posh.Source init pwsh --config $theme | Out-String | Invoke-Expression }
    }
    if (-not (Get-Module Terminal-Icons) -and (Get-Module -ListAvailable Terminal-Icons)) { Import-Module Terminal-Icons }
    if (-not (Get-Module PSReadLine) -and (Get-Module -ListAvailable PSReadLine)) { Import-Module PSReadLine }
    $choco=$env:ChocolateyInstall
    if ($choco) {
        $completion=Join-Path $choco 'helpers\chocolateyProfile.psm1'
        if ((Test-Path -LiteralPath $completion) -and -not (Get-Module chocolateyProfile)) { Import-Module $completion }
    }
}
$private=Join-Path $env:USERPROFILE '.config\ramon-dotfiles\windows.local.ps1'
if (Test-Path -LiteralPath $private) { . $private }
