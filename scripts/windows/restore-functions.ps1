function Assert-WindowsNoReparseAncestors([string]$Path) {
    $current=[IO.Path]::GetFullPath($Path)
    while ($current) {
        $item=Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Refusing a reparse ancestor: $current" }
        $parent=Split-Path -Parent $current
        if ($parent -eq $current) { break }; $current=$parent
    }
}
function Get-WindowsRestoreEntry($State, [string]$Backup, [string]$Id) {
    if (-not $Backup -or $Id -notmatch '^[a-f0-9]{32}$') { throw 'Choose -Backup and -Id from -List.' }
    $root=[IO.Path]::GetFullPath((Join-Path $State.StateRoot 'backups')).TrimEnd('\') + '\'
    $full=[IO.Path]::GetFullPath($Backup).TrimEnd('\')
    if (-not $full.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)) { throw 'Backup must be under the local state backup directory.' }
    Assert-WindowsNoReparseAncestors $full
    $manifest=Join-Path $full 'manifest.json'
    Assert-WindowsNoReparseAncestors $manifest
    $manifestEntries=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($manifest))
    $entries=@($manifestEntries | Where-Object id -EQ $Id)
    if ($entries.Count -ne 1) { throw 'Missing/ambiguous manifest entry.' }
    $entry=$entries[0]
    if ($entry.type -eq 'environment') {
        if ($entry.target -notin 'Path','BUN_INSTALL','DENO_INSTALL','PNPM_HOME','OLLAMA_MODELS') { throw 'Unsupported variable.' }
    } elseif ($entry.type -eq 'file') {
        $target=[IO.Path]::GetFullPath($entry.target)
        $allowed=@($env:USERPROFILE,[Environment]::GetFolderPath('MyDocuments'))
        $inside=$false
        foreach ($base in $allowed) {
            if ($base -and $target.StartsWith(([IO.Path]::GetFullPath($base).TrimEnd('\') + '\'),[StringComparison]::OrdinalIgnoreCase)) { $inside=$true }
        }
        if (-not $inside) { throw 'Restore target must be inside the original user home or Documents.' }
        Assert-WindowsNoReparseAncestors (Split-Path -Parent $target)
        $item=Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
        if ($item -and $item.PSIsContainer) { throw 'Refusing to restore over a directory.' }
        if ($entry.original -notin 'file','absent','symlink') { throw 'Unsupported original file type.' }
        if ($entry.original -eq 'file') {
            $source=Join-Path $full $Id
            Assert-WindowsNoReparseAncestors $source
            if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw 'Backup payload missing.' }
        }
        if ($entry.original -eq 'symlink' -and -not $entry.linkTarget) { throw 'Missing link target.' }
    } else { throw 'Unsupported manifest type.' }
    return $entry
}
function Restore-WindowsEntry($State, [string]$Backup, $Entry) {
    # Always revalidate even when called directly rather than through the CLI.
    $entry=Get-WindowsRestoreEntry $State $Backup $Entry.id
    if ($State.DryRun) { Write-Host "  [dry-run] restore $($entry.target); back up current state; replace file itself"; return }
    if ($entry.type -eq 'environment') {
        Set-WindowsUserVariable $State $entry.target $entry.original
        if ($entry.target -eq 'Path') { Update-WindowsProcessPath }
        return
    }
    $target=$entry.target
    $parent=Split-Path -Parent $target
    $null=New-Item -ItemType Directory -Path $parent -Force
    $staged=Join-Path $parent ('.ramon-restore-' + [guid]::NewGuid().ToString('N'))
    try {
        if ($entry.original -eq 'file') { Copy-Item -LiteralPath (Join-Path $Backup $entry.id) -Destination $staged }
        if ($entry.original -eq 'symlink') { $null=New-Item -ItemType SymbolicLink -Path $staged -Target $entry.linkTarget -ErrorAction Stop }
        Backup-WindowsFile $State $target | Out-Null
        $current=Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
        if ($current) { [IO.File]::Delete($target) }
        if ($entry.original -ne 'absent') { Move-Item -LiteralPath $staged -Destination $target }
    } finally { if (Get-Item -LiteralPath $staged -Force -ErrorAction SilentlyContinue) { [IO.File]::Delete($staged) } }
}
