#requires -Version 5.1
param([ValidateSet('es','en')][string]$Lang='es', [string]$TargetDrive, [string]$SoftwareRoot, [string]$DevRoot, [string]$DataRoot)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/common.ps1"
. "$PSScriptRoot/config.ps1"
$state=New-WindowsState -RepoRoot (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -DryRun -Language $Lang
Set-WindowsPaths $state $TargetDrive $SoftwareRoot $DevRoot $DataRoot
Show-WindowsInventory $state @(Get-WindowsCatalog $state.RepoRoot) (Get-WindowsInventory $state)
$failures=0
foreach ($path in 'SoftwareRoot','DevRoot','DataRoot') {
    try { Assert-WindowsDestination $state $state[$path] }
    catch { $failures++; Write-Warning $_ }
}
Get-ChildItem -LiteralPath (Join-Path $state.RepoRoot 'scripts/windows') -Filter '*.ps1' | ForEach-Object {
    $tokens=$null; $errors=$null
    $null=[Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$errors)
    if ($errors.Count) { $failures++; Write-Warning ($errors | Out-String) }
}
foreach ($profilePath in Get-WindowsProfilePaths) {
    $item=Get-Item -LiteralPath $profilePath -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -and -not (Test-Path -LiteralPath $profilePath)) { $failures++; Write-Warning "Broken profile link: $profilePath" }
    if (Test-Path -LiteralPath $profilePath -PathType Leaf) {
        $text=[IO.File]::ReadAllText($profilePath)
        if ($text.Contains('# >>> ramon-dotfiles >>>')) {
            if ($text -match '\$ramonProfile\s*=\s*''((?:[^'']|'''')*)''') {
                $source=$Matches[1].Replace("''","'")
                if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { $failures++; Write-Warning "Managed profile source missing: $source" }
            } else { $failures++; Write-Warning 'Managed profile block has no recognizable source.' }
        }
    }
}
foreach ($settings in Get-WindowsTerminalPaths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }) {
    try { $null=Read-WindowsJsonc ([IO.File]::ReadAllText($settings)); Write-Host "Valid Terminal JSONC: $settings" }
    catch { $failures++; Write-Warning "${settings}: $_" }
}
Write-Host 'Runtime locations:'
Get-Command git,node,nvm,bun,pnpm,deno,python3,uv,java,docker,gh -ErrorAction SilentlyContinue | Select-Object Name,Source | Format-Table -AutoSize
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host 'Git identity:'
    & git config --global --get user.name
    & git config --global --get user.email
}
if (Get-Command docker -ErrorAction SilentlyContinue) {
    & docker compose version
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Compose unavailable.' }
    & docker info --format '{{.ServerVersion}}'
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Docker daemon inaccessible; check service, context and permissions.' }
}
Write-Host "Configuration errors: $failures"
if ($failures) { exit 1 }
