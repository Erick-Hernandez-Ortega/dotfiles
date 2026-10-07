# Shared Windows helpers. Loading this file never creates files or changes settings.
function Get-WindowsText($State, [string]$Es, [string]$En) {
    if ($State.Language -eq 'es') { return $Es }; return $En
}
function New-WindowsState {
    param([string]$RepoRoot, [switch]$DryRun, [string]$Language = 'es', [string]$StateRoot)
    if (-not $StateRoot) { $StateRoot = Join-Path $env:LOCALAPPDATA 'ramon-dotfiles' }
    return @{
        RepoRoot = [IO.Path]::GetFullPath($RepoRoot); DryRun = [bool]$DryRun; Language = $Language
        StateRoot = $StateRoot; Temp = ''; Backup = ''; TargetDrive = ''; SoftwareRoot = ''; DevRoot = ''; DataRoot = ''
        Failed = [Collections.Generic.List[string]]::new(); Manual = [Collections.Generic.List[string]]::new()
        Reboot = $false; KeepDownloads = $false; InstalledNow = [Collections.Generic.List[string]]::new()
    }
}
function Get-WindowsCatalog([string]$RepoRoot) {
    foreach ($name in 'tools','apps','fonts') {
        foreach ($item in (Get-Content -LiteralPath (Join-Path $RepoRoot "catalog/$name.json") -Raw -Encoding UTF8 | ConvertFrom-Json)) {
            if ($item.PSObject.Properties['windows'] -and $item.windows) { $item }
        }
    }
}
function Get-WindowsDrives {
    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        if ($drive.Root -notmatch '^[A-Za-z]:\\$') { continue }
        $free = $null
        # Some restricted hosts report zero for both values instead of an error.
        if ($drive.Free -gt 0 -or $drive.Used -gt 0) { $free = [math]::Round($drive.Free / 1GB, 1) }
        [pscustomobject]@{ Root = $drive.Root; Label = $drive.Description; FreeGB = $free }
    }
}
function Resolve-WindowsPath([string]$Path) {
    if ($Path -notmatch '^[A-Za-z]:\\' -or $Path.IndexOfAny([char[]]'"<>|*?') -ge 0 -or $Path.Contains("`n") -or $Path.Contains("`r")) {
        throw "Use an absolute local drive path: $Path"
    }
    $full = [IO.Path]::GetFullPath($Path)
    if ($full.TrimEnd('\') -eq [IO.Path]::GetPathRoot($full).TrimEnd('\')) { throw 'Choose a folder, not the drive root.' }
    return $full.TrimEnd('\')
}
function Set-WindowsPaths($State, [string]$TargetDrive, [string]$SoftwareRoot, [string]$DevRoot, [string]$DataRoot) {
    $documents = [Environment]::GetFolderPath('MyDocuments')
    if (-not $documents) { $documents = Join-Path $env:USERPROFILE 'Documents' }
    if ($TargetDrive) {
        if ($TargetDrive -notmatch '^[A-Za-z]:\\?$') { throw 'TargetDrive must be a drive such as E:.' }
        $TargetDrive = $TargetDrive.Substring(0,2) + '\'
    } elseif (Test-Path -LiteralPath 'E:\' -PathType Container) { $TargetDrive = 'E:\' }
    else { $TargetDrive = [IO.Path]::GetPathRoot($env:USERPROFILE) }
    $State.TargetDrive = $TargetDrive
    if (-not $SoftwareRoot) { $SoftwareRoot = [IO.Path]::Combine($TargetDrive,'Software') }
    if (-not $DevRoot) {
        if ($TargetDrive -eq [IO.Path]::GetPathRoot($env:USERPROFILE)) { $DevRoot = Join-Path $documents 'Development' }
        else { $DevRoot = [IO.Path]::Combine($TargetDrive,'Development') }
    }
    if (-not $DataRoot) { $DataRoot = [IO.Path]::Combine($TargetDrive,'Data') }
    $State.SoftwareRoot = Resolve-WindowsPath $SoftwareRoot
    $State.DevRoot = Resolve-WindowsPath $DevRoot
    $State.DataRoot = Resolve-WindowsPath $DataRoot
}
function Assert-WindowsDestination($State, [string]$Path, [bool]$ReadOnly = $false) {
    $full = Resolve-WindowsPath $Path
    $root = [IO.Path]::GetPathRoot($full)
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Destination disconnected/unavailable: $root" }
    if (Test-Path -LiteralPath $full -PathType Leaf) { throw "Destination is a file: $full" }
    if ($State.DryRun -or $ReadOnly) { return }
    $parent = $full
    while (-not (Test-Path -LiteralPath $parent)) { $parent = Split-Path -Parent $parent }
    $probe = Join-Path $parent ('.ramon-write-' + [guid]::NewGuid().ToString('N'))
    try { [IO.File]::WriteAllText($probe, '') }
    finally { if (Test-Path -LiteralPath $probe) { Remove-Item -LiteralPath $probe -Force } }
}
function Expand-WindowsKnownPath($State, [string]$Path) {
    $map = @{ software = $State.SoftwareRoot; user = $env:USERPROFILE; local = $env:LOCALAPPDATA
        programfiles = $env:ProgramFiles; nvmhome = $env:NVM_HOME; nvmlink = $env:NVM_SYMLINK }
    foreach ($key in $map.Keys) {
        if ($Path.Contains("{$key}")) {
            if (-not $map[$key]) { return '' }
            $Path = $Path.Replace("{$key}", $map[$key])
        }
    }
    return $Path
}
function Get-WindowsInventory($State) {
    $keys = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $apps = @(Get-ItemProperty $keys -ErrorAction SilentlyContinue | Where-Object DisplayName)
    $chocoRoot = $env:ChocolateyInstall
    if (-not $chocoRoot) { $chocoRoot = Join-Path $env:ProgramData 'chocolatey' }
    $packages = @(Get-ChildItem -LiteralPath (Join-Path $chocoRoot 'lib') -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    $store = @(Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'Packages') -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    $fonts = @()
    foreach ($key in 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts','HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts') {
        $props = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
        if ($props) { $fonts += @($props.PSObject.Properties | Where-Object Name -NotMatch '^PS' | ForEach-Object { $_.Name; [string]$_.Value }) }
    }
    return @{ Apps = $apps; Choco = $packages; Store = $store; Fonts = $fonts; Modules = @(Get-Module -ListAvailable | Select-Object -ExpandProperty Name -Unique) }
}
function Test-WindowsInstalled($Item, $Inventory, $State) {
    $w = $Item.windows
    if ($w.method -eq 'module') { return ($Inventory.Modules -contains $w.package) }
    if ($w.method -eq 'choco' -and $Inventory.Choco -contains $w.package) { return $true }
    if ($w.detect -and @($Inventory.Apps | Where-Object { $_.DisplayName -match $w.detect }).Count) { return $true }
    if ($w.store -and @($Inventory.Store | Where-Object { $_ -like ($w.store + '*') }).Count) { return $true }
    if ($Item.kind -eq 'font' -and $w.font -and @($Inventory.Fonts | Where-Object { $_ -match $w.font }).Count) { return $true }
    foreach ($command in @($w.commands)) {
        $found = Get-Command $command -ErrorAction SilentlyContinue
        # Windows Store's Python aliases are not installed interpreters.
        if ($found -and -not ($Item.id -eq 'python3' -and $found.Source -like '*\WindowsApps\*')) { return $true }
    }
    foreach ($path in @($w.paths)) {
        $expanded = Expand-WindowsKnownPath $State $path
        if ($expanded -and (Test-Path -LiteralPath $expanded -PathType Leaf)) { return $true }
    }
    return $false
}
function Get-WindowsInstallPath($State, $Item) {
    if ($Item.windows.location -ne 'custom') { return '' }
    return Join-Path $State.SoftwareRoot $Item.windows.folder
}
function Get-WindowsLocationText($State, $Item) {
    $path = Get-WindowsInstallPath $State $Item
    if ($path) { return "$path (configuration/shared components may remain on C:)" }
    if ($Item.windows.method -eq 'manual') { return 'manual / see upstream instructions' }
    return 'system/user default; no verified custom location'
}
function Show-WindowsInventory($State, $Catalog, $Inventory) {
    Write-Host 'RAMON | WINDOWS SETUP | x64'
    Write-Host "Software: $($State.SoftwareRoot) | Dev: $($State.DevRoot) | Data: $($State.DataRoot)"
    foreach ($item in $Catalog) {
        $status = if (Test-WindowsInstalled $item $Inventory $State) { 'installed / instalado' } elseif ($item.windows.method -eq 'manual') { 'manual' } else { 'selectable / seleccionable' }
        $description = if ($State.Language -eq 'es') { $item.description_es } else { $item.description_en }
        Write-Host "`n$($item.label) [$status]`n  $description`n  $($item.windows.method):$($item.windows.package)`n  $(Get-WindowsLocationText $State $item)"
    }
}
function Initialize-WindowsTemporary($State) {
    if ($State.DryRun -or $State.Temp) { return }
    $State.Temp = Join-Path ([IO.Path]::GetTempPath()) ('ramon-dotfiles-' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $State.Temp
}
function Clear-WindowsTemporary($State) {
    if (-not $State.Temp) { return }
    $full = [IO.Path]::GetFullPath($State.Temp)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $full.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path $full -Leaf) -notmatch '^ramon-dotfiles-[a-f0-9]{32}$') { throw 'Refusing cleanup outside run-owned temporary directory.' }
    if (Test-Path -LiteralPath $full) {
        if ($State.KeepDownloads) {
            $cache = Join-Path $State.StateRoot ('downloads\' + (Split-Path $full -Leaf))
            $null = New-Item -ItemType Directory -Path $cache -Force
            foreach ($file in Get-ChildItem -LiteralPath $full -File | Where-Object Extension -In '.exe','.msi','.zip','.nupkg') {
                Copy-Item -LiteralPath $file.FullName -Destination $cache
            }
            if (Test-Path -LiteralPath (Join-Path $full 'cache')) { Copy-Item -LiteralPath (Join-Path $full 'cache') -Destination $cache -Recurse }
        }
        Remove-Item -LiteralPath $full -Recurse -Force
    }
    $State.Temp = ''
}
