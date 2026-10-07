function ConvertTo-WindowsArgument([string]$Value) {
    # Windows CRT quoting, including embedded quotes and trailing backslashes.
    if ($Value -notmatch '[\s"]' -and $Value.Length) { return $Value }
    $quoted = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $quoted = [regex]::Replace($quoted, '(\\+)$', '$1$1')
    return '"' + $quoted + '"'
}
function Test-WindowsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Invoke-WindowsCommand {
    param($State, [string]$Executable, [string[]]$Arguments, [switch]$Administrator)
    Write-Host ('  ' + $Executable + ' ' + (($Arguments | ForEach-Object { ConvertTo-WindowsArgument $_ }) -join ' '))
    if ($State.DryRun) { return 0 }
    $resolved = Get-Command $Executable -CommandType Application -ErrorAction Stop | Select-Object -First 1
    if ($Administrator -and -not (Test-WindowsAdministrator)) {
        Initialize-WindowsTemporary $State
        $request = Join-Path $State.Temp ('request-' + [guid]::NewGuid().ToString('N') + '.json')
        $result = $request + '.result'
        @{ executable=$resolved.Source; arguments=$Arguments } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $request -Encoding UTF8
        $worker = Join-Path $State.RepoRoot 'scripts/windows/elevated.ps1'
        $workerArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$worker,'-Request',$request,'-Result',$result)
        $process = Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList (($workerArgs | ForEach-Object { ConvertTo-WindowsArgument $_ }) -join ' ') -Verb RunAs -WindowStyle Hidden -Wait -PassThru
        if (-not (Test-Path -LiteralPath $result)) { throw "Elevated operation failed/cancelled (exit $($process.ExitCode))." }
        return [int](Get-Content -LiteralPath $result -Raw)
    }
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName=$resolved.Source; $info.Arguments=(($Arguments | ForEach-Object { ConvertTo-WindowsArgument $_ }) -join ' ')
    $info.UseShellExecute=$false
    $process = [Diagnostics.Process]::Start($info)
    $process.WaitForExit()
    $code=$process.ExitCode; $process.Dispose()
    return $code
}
function Assert-WindowsExitCode($State, [int]$Code) {
    if ($Code -eq 3010 -or $Code -eq 1641) { $State.Reboot=$true; return }
    if ($Code -ne 0) { throw "Installer failed with exit code $Code" }
}
function Update-WindowsProcessPath {
    $machine = [Environment]::GetEnvironmentVariable('Path','Machine')
    $user = [Environment]::GetEnvironmentVariable('Path','User')
    $parts = @($machine -split ';') + @($user -split ';') + @($env:Path -split ';')
    $env:Path = (@($parts | Where-Object { $_ } | Select-Object -Unique) -join ';')
    foreach ($name in 'NVM_HOME','NVM_SYMLINK','PNPM_HOME','BUN_INSTALL','DENO_INSTALL') {
        $value=[Environment]::GetEnvironmentVariable($name,'User')
        if (-not $value) { $value=[Environment]::GetEnvironmentVariable($name,'Machine') }
        if ($value) { [Environment]::SetEnvironmentVariable($name,$value,'Process') }
    }
}
function Get-WindowsDownload($State, [string]$Url, [string]$Name) {
    if ($Url -notmatch '^https://') { throw 'Only HTTPS downloads are allowed.' }
    if ($State.DryRun) { Write-Host "  [dry-run] download $Url"; return '' }
    Initialize-WindowsTemporary $State
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $file = Join-Path $State.Temp $Name
    Invoke-WebRequest -Uri $Url -OutFile $file -UseBasicParsing
    return $file
}
function Ensure-WindowsChocolatey($State) {
    if (Get-Command choco.exe -ErrorAction SilentlyContinue) { return }
    if ($State.DryRun) { Write-Host '  [dry-run] prepare Chocolatey via official install.ps1; UAC required'; return }
    $file=Get-WindowsDownload $State 'https://community.chocolatey.org/install.ps1' 'chocolatey-install.ps1'
    $code=Invoke-WindowsCommand $State "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" @('-NoProfile','-ExecutionPolicy','Bypass','-File',$file) -Administrator
    Assert-WindowsExitCode $State $code
    Update-WindowsProcessPath
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) { throw 'Chocolatey is unavailable after bootstrap.' }
}
function Get-WindowsPackageCommand($State, $Item) {
    $w=$Item.windows
    $destination=Get-WindowsInstallPath $State $Item
    if ($w.method -eq 'choco') {
        $cache=if ($State.Temp) { Join-Path $State.Temp 'cache' } else { '<run-owned-cache>' }
        $commandArgs=@('install',$w.package,'--yes','--no-progress','--use-package-exit-codes','--source=https://community.chocolatey.org/api/v2/',"--cache-location=$cache")
        if ($w.installArgs) { $commandArgs += '--install-arguments=' + $w.installArgs.Replace('{destination}',$destination) }
        if ($w.params) { $commandArgs += '--package-parameters=' + $w.params.Replace('{destination}',$destination) }
        return @{ executable='choco.exe'; arguments=$commandArgs; administrator=$true }
    }
    if ($w.method -eq 'winget') {
        $source='winget'; if ($w.sourceName) { $source=$w.sourceName }
        $commandArgs=@('install','--id',$w.package,'--exact','--source',$source,'--no-upgrade','--accept-package-agreements','--accept-source-agreements')
        if ($destination) { $commandArgs += '--location',$destination }
        return @{ executable='winget.exe'; arguments=$commandArgs; administrator=$false }
    }
    throw "Not a package manager route: $($w.method)"
}
function Expand-WindowsArchive([string]$Archive, [string]$Destination) {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=[IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        $root=[IO.Path]::GetFullPath($Destination).TrimEnd('\') + '\'
        foreach ($entry in $zip.Entries) {
            $target=[IO.Path]::GetFullPath((Join-Path $Destination $entry.FullName))
            if (-not $target.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or $entry.FullName.Contains(':')) { throw 'Archive path escapes its extraction directory.' }
        }
    } finally { $zip.Dispose() }
    Expand-Archive -LiteralPath $Archive -DestinationPath $Destination -Force
}
function Install-WindowsZip($State, $Item) {
    $destination=Get-WindowsInstallPath $State $Item
    Assert-WindowsDestination $State $destination
    if ($State.DryRun) { Write-Host "  [dry-run] latest stable $($Item.windows.package), asset $($Item.windows.asset) -> $destination"; return }
    if ((Test-Path -LiteralPath $destination) -and @(Get-ChildItem -LiteralPath $destination -Force).Count) { throw "Destination already contains files; inspect manually: $destination" }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $release=Invoke-RestMethod -Uri "https://api.github.com/repos/$($Item.windows.package)/releases/latest" -Headers @{ 'User-Agent'='ramon-dotfiles' }
    $assets=@($release.assets | Where-Object { $_.name -match $Item.windows.asset })
    if ($assets.Count -ne 1) { throw 'Latest release has no unique supported Windows x64 asset.' }
    $file=Get-WindowsDownload $State $assets[0].browser_download_url ($Item.id + '.zip')
    if ($assets[0].PSObject.Properties['digest'] -and $assets[0].digest -match '^sha256:(.+)$') {
        if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $Matches[1]) { throw 'Release digest mismatch.' }
    }
    $extract=Join-Path $State.Temp ($Item.id + '-extract')
    Expand-WindowsArchive $file $extract
    $executables=@(Get-ChildItem -LiteralPath $extract -Filter $Item.windows.exe -Recurse -File)
    if ($executables.Count -ne 1) { throw 'Archive does not contain a unique expected executable.' }
    Assert-WindowsDestination $State $destination
    $null=New-Item -ItemType Directory -Path $destination -Force
    Copy-Item -LiteralPath $executables[0].DirectoryName -Destination (Join-Path $destination 'bin') -Recurse
    Add-WindowsUserPath $State (Join-Path $destination 'bin')
}
function Install-WindowsModule($State, $Item) {
    if ($State.DryRun) { Write-Host "  [dry-run] Install-Module $($Item.windows.package) -Scope CurrentUser -Repository PSGallery"; return }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
        $null=Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force
    }
    Install-Module -Name $Item.windows.package -Scope CurrentUser -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
}
function Install-WindowsNative($State, $Item) {
    $w=$Item.windows; $destination=Get-WindowsInstallPath $State $Item
    if ($destination) { Assert-WindowsDestination $State $destination }
    if ($State.DryRun) { Write-Host "  [dry-run] official $($w.url) -> $(Get-WindowsLocationText $State $Item)"; return }
    # Upstream scripts may edit shell profiles; preserve all relevant originals first.
    foreach ($profilePath in Get-WindowsProfilePaths) { Backup-WindowsFile $State $profilePath | Out-Null }
    # Upstream installers can change PATH independently of this assistant.
    $originalPath=[Environment]::GetEnvironmentVariable('Path','User')
    Add-WindowsBackupEntry $State @{ id=[guid]::NewGuid().ToString('N'); type='environment'; target='Path'; original=$originalPath }
    if ($w.variable) {
        $existing=[Environment]::GetEnvironmentVariable($w.variable,'User')
        if (-not $existing) { $existing=[Environment]::GetEnvironmentVariable($w.variable,'Process') }
        if ($existing -and $existing -ne $destination) { throw "Existing $($w.variable) differs; preserve it and resolve the installation manually." }
        Set-WindowsUserVariable $State $w.variable $destination
    }
    if ($w.method -eq 'native-exe') {
        $file=Get-WindowsDownload $State $w.url ($Item.id + '.exe')
        $signature=Get-AuthenticodeSignature -LiteralPath $file
        if ($signature.Status -ne 'Valid') { throw 'Official installer does not have a valid Authenticode signature.' }
        $code=Invoke-WindowsCommand $State $file @('/VERYSILENT','/NORESTART',$w.installArgs.Replace('{destination}',$destination))
    } else {
        $file=Get-WindowsDownload $State $w.url ($Item.id + '-install.ps1')
        $code=Invoke-WindowsCommand $State "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" @('-NoProfile','-ExecutionPolicy','Bypass','-File',$file)
    }
    Assert-WindowsExitCode $State $code
    if ($destination) {
        Add-WindowsUserPath $State $destination
        if (Test-Path -LiteralPath (Join-Path $destination 'bin')) { Add-WindowsUserPath $State (Join-Path $destination 'bin') }
    }
}
function Install-WindowsOption($State, $Item) {
    if (Test-WindowsInstalled $Item (Get-WindowsInventory $State) $State) { Write-Host "Already installed: $($Item.label)"; return }
    Write-Host "`n+ $($Item.label)"
    $destination=Get-WindowsInstallPath $State $Item
    if ($destination) { Assert-WindowsDestination $State $destination }
    switch ($Item.windows.method) {
        'manual' { Write-Host "Manual: $($Item.windows.package)"; $State.Manual.Add($Item.id); return }
        'choco' {
            Ensure-WindowsChocolatey $State
            Initialize-WindowsTemporary $State
            $cmd=Get-WindowsPackageCommand $State $Item
            $code=Invoke-WindowsCommand $State $cmd.executable $cmd.arguments -Administrator
            Assert-WindowsExitCode $State $code
        }
        'winget' {
            if (-not $State.DryRun -and -not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
                Write-Host 'Install App Installer: https://aka.ms/getwinget ; then rerun.'
                $State.Manual.Add($Item.id); return
            }
            $cmd=Get-WindowsPackageCommand $State $Item
            $code=Invoke-WindowsCommand $State $cmd.executable $cmd.arguments
            Assert-WindowsExitCode $State $code
        }
        'zip' { Install-WindowsZip $State $Item }
        'module' { Install-WindowsModule $State $Item }
        'native' { Install-WindowsNative $State $Item }
        'native-exe' { Install-WindowsNative $State $Item }
        default { throw "Unsupported Windows method: $($Item.windows.method)" }
    }
    if (-not $State.DryRun) {
        Update-WindowsProcessPath
        if (-not (Test-WindowsInstalled $Item (Get-WindowsInventory $State) $State)) { throw 'Installation presence could not be verified.' }
        if ($destination -and -not (Test-Path -LiteralPath $destination -PathType Container)) { throw "Installer ignored requested destination: $destination" }
    }
    $State.InstalledNow.Add($Item.id)
}
function Invoke-WindowsSetup($State, $Catalog, $Inventory, $Choices) {
    $State.KeepDownloads = -not $Choices['@clean']
    # Git installs before packages that depend on it; no global OS upgrade.
    foreach ($item in $Catalog | Sort-Object @{Expression={ if ($_.id -eq 'git') {0} else {1} }}) {
        if (-not $Choices[$item.id] -or (Test-WindowsInstalled $item $Inventory $State)) { continue }
        try { Install-WindowsOption $State $item }
        catch { $State.Failed.Add($item.id); Write-Warning "$($item.id): $_" }
    }
    $actions=@{}
    if ($Choices['@shell']) { $actions['profile']={ Set-WindowsProfile $State } }
    if ($Choices['@terminal']) { $actions['terminal']={ Set-WindowsTerminal $State } }
    if ($Choices['@git']) { $actions['git']={ Set-WindowsGit $State } }
    if ($Choices['@auth']) { $actions['github']={ Connect-WindowsGitHub $State } }
    if ($Choices['@dev']) { $actions['dev']={ New-WindowsDevFolders $State } }
    if ($Choices['@ollama-data'] -and $State.InstalledNow.Contains('ollama')) { $actions['ollama-data']={ Set-WindowsOllamaData $State } }
    foreach ($name in $actions.Keys) {
        try { & $actions[$name] }
        catch { $State.Failed.Add($name); Write-Warning "${name}: $_" }
    }
    if ($State.Manual.Count) { Write-Host ('Manual pending: ' + ($State.Manual -join ', ')) }
    if ($State.Backup) { Write-Host "Backups: $($State.Backup)" }
    if ($State.Reboot) { Write-Host 'A restart is required by an installer; no restart was requested by this assistant.' }
}
