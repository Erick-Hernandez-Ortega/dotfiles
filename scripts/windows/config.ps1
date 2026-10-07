function Get-WindowsProfilePaths {
    $documents=[Environment]::GetFolderPath('MyDocuments')
    if (-not $documents) { $documents=Join-Path $env:USERPROFILE 'Documents' }
    foreach ($folder in 'WindowsPowerShell','PowerShell') {
        foreach ($file in 'profile.ps1','Microsoft.PowerShell_profile.ps1') { Join-Path (Join-Path $documents $folder) $file }
    }
}
function Get-WindowsTerminalPaths {
    @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
    )
}
function Initialize-WindowsBackup($State) {
    if ($State.DryRun -or $State.Backup) { return }
    $State.Backup=Join-Path $State.StateRoot ('backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N'))
    $null=New-Item -ItemType Directory -Path $State.Backup -Force
}
function Add-WindowsBackupEntry($State, $Entry) {
    Initialize-WindowsBackup $State
    $manifest=Join-Path $State.Backup 'manifest.json'
    $entries=@()
    if (Test-Path -LiteralPath $manifest) { $entries=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($manifest)) }
    $entries = @($entries) + @($Entry)
    [IO.File]::WriteAllText($manifest,(ConvertTo-Json -InputObject $entries -Depth 8),[Text.UTF8Encoding]::new($false))
}
function Backup-WindowsFile($State, [string]$Path) {
    if ($State.DryRun) { Write-Host "  [dry-run] backup $Path"; return }
    Initialize-WindowsBackup $State
    $pathFull=[IO.Path]::GetFullPath($Path)
    $id=[guid]::NewGuid().ToString('N')
    $entry=@{ id=$id; type='file'; target=$pathFull; original='absent'; linkTarget='' }
    $item=Get-Item -LiteralPath $pathFull -Force -ErrorAction SilentlyContinue
    if ($item) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            if (-not $item.PSObject.Properties['Target'] -or -not $item.Target) { throw "Unsupported reparse point: $Path" }
            $entry.original='symlink'; $entry.linkTarget=[string]@($item.Target)[0]
        } elseif ($item.PSIsContainer) { throw "Refusing to replace directory: $Path" }
        else { $entry.original='file'; Copy-Item -LiteralPath $pathFull -Destination (Join-Path $State.Backup $id) }
    }
    Add-WindowsBackupEntry $State $entry
    return $id
}
function Write-WindowsFile($State, [string]$Path, [string]$Content, [switch]$Bom) {
    if ($State.DryRun) { Write-Host "  [dry-run] update $Path (backup first)"; return }
    if ((Test-Path -LiteralPath $Path -PathType Leaf) -and [IO.File]::ReadAllText($Path) -eq $Content) { return }
    Backup-WindowsFile $State $Path | Out-Null
    $parent=Split-Path -Parent $Path
    $null=New-Item -ItemType Directory -Path $parent -Force
    $staged=Join-Path $parent ('.ramon-stage-' + [guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllText($staged,$Content,[Text.UTF8Encoding]::new([bool]$Bom))
        $item=Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            # Delete only the file link, never its referent or a directory junction.
            if ($item.PSIsContainer) { throw 'Refusing directory reparse point.' }
            [IO.File]::Delete($Path)
        }
        Move-Item -LiteralPath $staged -Destination $Path -Force
    } finally { if (Test-Path -LiteralPath $staged) { Remove-Item -LiteralPath $staged -Force } }
}
function Set-WindowsUserVariable($State, [string]$Name, [AllowNull()][string]$Value) {
    if ($Name -notin 'Path','BUN_INSTALL','DENO_INSTALL','PNPM_HOME','OLLAMA_MODELS') { throw "Unsupported managed variable: $Name" }
    if ($State.DryRun) { Write-Host "  [dry-run] user variable $Name=$Value (backup first)"; return }
    $original=[Environment]::GetEnvironmentVariable($Name,'User')
    if ($original -eq $Value) {
        if ($Name -ne 'Path') { [Environment]::SetEnvironmentVariable($Name,$Value,'Process') }
        return
    }
    Add-WindowsBackupEntry $State @{ id=[guid]::NewGuid().ToString('N'); type='environment'; target=$Name; original=$original }
    [Environment]::SetEnvironmentVariable($Name,$Value,'User')
    if ($Name -ne 'Path') { [Environment]::SetEnvironmentVariable($Name,$Value,'Process') }
}
function Add-WindowsUserPath($State, [string]$Directory) {
    $existing=[Environment]::GetEnvironmentVariable('Path','User')
    $parts=@($existing -split ';' | Where-Object { $_ })
    if ($parts -contains $Directory) { return }
    Set-WindowsUserVariable $State 'Path' ((@($parts) + $Directory) -join ';')
    if (-not $State.DryRun) { Update-WindowsProcessPath }
}
function Set-WindowsProfile($State, [string]$ProfilePath) {
    if (-not $ProfilePath) {
        $folder=if ($PSVersionTable.PSEdition -eq 'Core') {'PowerShell'} else {'WindowsPowerShell'}
        $ProfilePath=@(Get-WindowsProfilePaths | Where-Object { $_ -like "*\$folder\Microsoft.PowerShell_profile.ps1" })[0]
    }
    $content=if (Test-Path -LiteralPath $ProfilePath -PathType Leaf) { [IO.File]::ReadAllText($ProfilePath) } else { '' }
    $begin='# >>> ramon-dotfiles >>>'; $end='# <<< ramon-dotfiles <<<'
    $escaped=(Join-Path $State.RepoRoot 'shell/windows/profile.ps1').Replace("'","''")
    $block="$begin`r`n`$ramonProfile = '$escaped'`r`nif (Test-Path -LiteralPath `$ramonProfile) { . `$ramonProfile }`r`n$end"
    if ($content.Contains($begin) -xor $content.Contains($end)) { throw 'Incomplete managed profile block; inspect manually.' }
    if ($content.Contains($begin)) {
        $pattern='(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end)
        $content=[regex]::Replace($content,$pattern,[Text.RegularExpressions.MatchEvaluator]{ param($m) $block })
    } else { $content=$content.TrimEnd() + "`r`n`r`n" + $block + "`r`n" }
    Write-WindowsFile $State $ProfilePath $content -Bom
}
function Get-JsoncTokens([string]$Text) {
    $tokens=[Collections.Generic.List[object]]::new()
    $clean=$Text.ToCharArray()
    $i=0
    while ($i -lt $Text.Length) {
        $c=$Text[$i]
        if ([char]::IsWhiteSpace($c)) { $i++; continue }
        if ($c -eq '/' -and $i+1 -lt $Text.Length -and $Text[$i+1] -in '/','*') {
            $start=$i; $line=$Text[$i+1] -eq '/'; $i+=2
            if ($line) { while ($i -lt $Text.Length -and $Text[$i] -ne "`n") { $i++ } }
            else {
                while ($i+1 -lt $Text.Length -and -not ($Text[$i] -eq '*' -and $Text[$i+1] -eq '/')) { $i++ }
                if ($i+1 -ge $Text.Length) { throw 'Unterminated JSONC comment.' }; $i+=2
            }
            for ($j=$start; $j -lt $i; $j++) { if ($clean[$j] -notin "`r","`n") { $clean[$j]=' ' } }
            continue
        }
        $start=$i
        if ($c -eq '"') {
            $i++; $closed=$false
            while ($i -lt $Text.Length) {
                if ($Text[$i] -eq '\') { $i+=2; continue }
                if ($Text[$i] -eq '"') { $i++; $closed=$true; break }; $i++
            }
            if (-not $closed) { throw 'Unterminated JSON string.' }
            $kind='string'
        } elseif ($c -in '{','}','[',']',':',',') { $kind=[string]$c; $i++ }
        else {
            while ($i -lt $Text.Length -and -not [char]::IsWhiteSpace($Text[$i]) -and $Text[$i] -notin ',',']','}') { $i++ }
            if ($i -eq $start) { throw 'Invalid JSON token.' }; $kind='value'
        }
        $tokens.Add(@{ kind=$kind; start=$start; end=$i; text=$Text.Substring($start,$i-$start) })
    }
    for ($j=0; $j -lt $tokens.Count-1; $j++) {
        if ($tokens[$j].kind -eq ',' -and $tokens[$j+1].kind -in '}',']') { $clean[$tokens[$j].start]=' ' }
    }
    return @{ tokens=$tokens; clean=(-join $clean) }
}
function Read-JsoncNode($Tokens, [ref]$Index) {
    if ($Index.Value -ge $Tokens.Count) { throw 'Unexpected end of JSON.' }
    $token=$Tokens[$Index.Value]; $Index.Value++
    $node=@{ kind=$token.kind; start=$token.start; end=$token.end; properties=@{} }
    if ($token.kind -eq '{') {
        while ($Tokens[$Index.Value].kind -ne '}') {
            $key=$Tokens[$Index.Value]
            if ($key.kind -ne 'string') { throw 'Expected JSON property.' }
            $name=ConvertFrom-Json -InputObject $key.text
            if ($node.properties.ContainsKey($name)) { throw 'Duplicate JSON properties require manual review.' }
            $Index.Value++
            if ($Tokens[$Index.Value].kind -ne ':') { throw 'Expected JSON colon.' }; $Index.Value++
            $node.properties[$name]=Read-JsoncNode $Tokens $Index
            if ($Tokens[$Index.Value].kind -eq ',') { $Index.Value++ } elseif ($Tokens[$Index.Value].kind -ne '}') { throw 'Expected comma.' }
        }
        $node.end=$Tokens[$Index.Value].end; $Index.Value++
    } elseif ($token.kind -eq '[') {
        while ($Tokens[$Index.Value].kind -ne ']') {
            $null=Read-JsoncNode $Tokens $Index
            if ($Tokens[$Index.Value].kind -eq ',') { $Index.Value++ } elseif ($Tokens[$Index.Value].kind -ne ']') { throw 'Expected comma.' }
        }
        $node.end=$Tokens[$Index.Value].end; $Index.Value++
    }
    return $node
}
function Read-WindowsJsonc([string]$Text) {
    $parsed=Get-JsoncTokens $Text
    $value=ConvertFrom-Json -InputObject $parsed.clean -ErrorAction Stop
    $index=0; $root=Read-JsoncNode $parsed.tokens ([ref]$index)
    if ($root.kind -ne '{' -or $index -ne $parsed.tokens.Count) { throw 'Settings must contain one JSON object.' }
    return @{ value=$value; root=$root; tokens=$parsed.tokens }
}
function Set-WindowsJsoncProperty([string]$Text, [string[]]$Path, $Value) {
    $doc=Read-WindowsJsonc $Text; $node=$doc.root
    for ($i=0; $i -lt $Path.Count-1; $i++) {
        if (-not $node.properties.ContainsKey($Path[$i])) {
            $prefix=@($Path[0..$i])
            $Text=Set-WindowsJsoncProperty $Text $prefix ([pscustomobject]@{})
            $doc=Read-WindowsJsonc $Text; $node=$doc.root
            for ($j=0; $j -le $i; $j++) { $node=$node.properties[$Path[$j]] }
        } else { $node=$node.properties[$Path[$i]] }
        if ($node.kind -ne '{') { throw 'Expected object at settings path; preserve original and inspect manually.' }
    }
    $name=$Path[-1]; $json=ConvertTo-Json -InputObject $Value -Depth 30 -Compress
    if ($node.properties.ContainsKey($name)) {
        $target=$node.properties[$name]
        return $Text.Substring(0,$target.start) + $json + $Text.Substring($target.end)
    }
    $last=@($doc.tokens | Where-Object { $_.start -lt $node.end-1 -and $_.start -ge $node.start })[-1]
    $separator=if ($node.properties.Count -and $last.kind -ne ',') { ',' } else { '' }
    $insertion=$separator + "`n" + (ConvertTo-Json -InputObject $name -Compress) + ': ' + $json + "`n"
    return $Text.Insert($node.end-1,$insertion)
}
function Set-WindowsTerminal($State, [string]$SettingsPath) {
    if (-not $SettingsPath) { $SettingsPath=@(Get-WindowsTerminalPaths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1)[0] }
    if (-not $SettingsPath) { Write-Host 'Open Windows Terminal once, then apply appearance. No existing settings file found.'; $State.Manual.Add('terminal-settings'); return }
    $text=[IO.File]::ReadAllText($SettingsPath)
    $doc=Read-WindowsJsonc $text
    $text=Set-WindowsJsoncProperty $text @('profiles','defaults','colorScheme') 'One Half Dark'
    $text=Set-WindowsJsoncProperty $text @('profiles','defaults','font','face') 'FiraCode Nerd Font Mono'
    $keys=@('ctrl+c','ctrl+v','ctrl+shift+f','alt+shift+d')
    $bindings=@()
    foreach ($binding in @($doc.value.keybindings)) {
        if (-not $binding) { continue }
        if (@($binding.keys | Where-Object { $_ -in $keys }).Count -eq 0) { $bindings+=$binding }
    }
    $ids=@('Terminal.CopyToClipboard','Terminal.PasteFromClipboard','Terminal.FindText','Terminal.DuplicatePaneAuto')
    for ($i=0; $i -lt $keys.Count; $i++) { $bindings+=[pscustomobject]@{ id=$ids[$i]; keys=$keys[$i] } }
    $text=Set-WindowsJsoncProperty $text @('keybindings') $bindings
    $null=Read-WindowsJsonc $text
    Write-WindowsFile $State $SettingsPath $text
}
function Set-WindowsGit($State) {
    if ($State.DryRun) { Write-Host '  [dry-run] backup Git config; set personal name/email and repo include'; return }
    $path=$env:GIT_CONFIG_GLOBAL
    if (-not $path) { $path=Join-Path $env:USERPROFILE '.gitconfig' }
    $item=Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))) { throw 'Configure a linked/directory Git config manually; no linked file is edited.' }
    Backup-WindowsFile $State $path | Out-Null
    $include=(Join-Path $State.RepoRoot 'git/config').Replace('\','/')
    $existing=@(& git config --global --get-all include.path)
    if ($existing -notcontains $include) { Assert-WindowsExitCode $State (Invoke-WindowsCommand $State 'git.exe' @('config','--global','--add','include.path',$include)) }
    foreach ($pair in @(@('user.name','Erick Ramon Hernandez Ortega'),@('user.email','erickramon47@live.com.mx'))) {
        Assert-WindowsExitCode $State (Invoke-WindowsCommand $State 'git.exe' @('config','--global',$pair[0],$pair[1]))
    }
}
function Connect-WindowsGitHub($State) {
    if ($State.DryRun) { Write-Host '  [dry-run] verify Erick-Hernandez-Ortega; gh auth login --web --git-protocol https; gh auth setup-git'; return }
    $account=(& gh api user --jq .login 2>$null)
    if ($LASTEXITCODE -ne 0 -or $account -ne 'Erick-Hernandez-Ortega') {
        Assert-WindowsExitCode $State (Invoke-WindowsCommand $State 'gh.exe' @('auth','login','--hostname','github.com','--git-protocol','https','--web'))
        $account=(& gh api user --jq .login)
        if ($LASTEXITCODE -ne 0 -or $account -ne 'Erick-Hernandez-Ortega') { throw 'Unexpected GitHub account.' }
    }
    Assert-WindowsExitCode $State (Invoke-WindowsCommand $State 'gh.exe' @('auth','setup-git','--hostname','github.com'))
}
function New-WindowsDevFolders($State) {
    Assert-WindowsDestination $State $State.DevRoot
    foreach ($folder in 'Frontend\Next','Frontend\React','Frontend\Astro','Frontend\Angular','Frontend\Vue',
        'Backend\NestJS','Backend\Node','Backend\Python','Mobile\ReactNative','Mobile\Flutter','Mobile\Android',
        'Desktop\Electron','Desktop\Tauri','Libraries','Scripts','Playground','Others','AI\OpenCode') {
        $path=Join-Path $State.DevRoot $folder
        if ($State.DryRun) { Write-Host "  [dry-run] mkdir $path" }
        else { Assert-WindowsDestination $State $path; $null=New-Item -ItemType Directory -Path $path -Force }
    }
}
function Set-WindowsOllamaData($State) {
    if ([Environment]::GetEnvironmentVariable('OLLAMA_MODELS','User') -or $env:OLLAMA_MODELS) { Write-Host 'Preserving existing OLLAMA_MODELS.'; return }
    $path=Join-Path $State.DataRoot 'Ollama'
    Assert-WindowsDestination $State $path
    if (-not $State.DryRun) { $null=New-Item -ItemType Directory -Path $path -Force }
    Set-WindowsUserVariable $State 'OLLAMA_MODELS' $path
    Write-Host 'Restart Ollama to use the new model location. No models were downloaded or moved.'
}
