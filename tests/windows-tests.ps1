# Dependency-free regression suite. All writes stay in a disposable workspace fixture.
# Run: powershell -NoProfile -File tests/windows-tests.ps1
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
. "$repo/scripts/windows/common.ps1"
. "$repo/scripts/windows/install.ps1"
. "$repo/scripts/windows/config.ps1"
. "$repo/scripts/windows/restore-functions.ps1"
. "$repo/scripts/windows/ui.ps1"
$testRoot=Join-Path $repo ('.state\windows-tests-' + [guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $testRoot -Force
$passed=0; $failed=0; $skipped=0
function Assert($Condition, [string]$Message='Assertion failed') { if (-not $Condition) { throw $Message } }
function Test([string]$Name, [scriptblock]$Body) {
    try { & $Body; $script:passed++; Write-Host "PASS $Name" }
    catch { $script:failed++; Write-Host "FAIL ${Name}: $_" }
}
function New-FixtureState([switch]$DryRun) {
    $state=New-WindowsState -RepoRoot $repo -StateRoot (Join-Path $testRoot 'state') -DryRun:$DryRun
    Set-WindowsPaths $state ([IO.Path]::GetPathRoot($testRoot)) (Join-Path $testRoot 'Software') (Join-Path $testRoot 'Development') (Join-Path $testRoot 'Data')
    return $state
}
$originalHome=$env:USERPROFILE
$originalLocal=$env:LOCALAPPDATA
try {
    $env:USERPROFILE=$testRoot; $env:LOCALAPPDATA=Join-Path $testRoot 'Local'
    Test 'PowerShell syntax for every Windows source' {
        foreach ($file in @(Get-ChildItem "$repo/scripts/windows","$repo/shell/windows" -Filter '*.ps1' -Recurse) + (Get-Item "$repo/bootstrap.ps1")) {
            $tokens=$null; $errors=$null
            $null=[Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
            Assert ($errors.Count -eq 0) "$($file.Name): $errors"
        }
    }
    $catalog=@(Get-WindowsCatalog $repo)
    Test 'Windows catalog uses unique IDs and documented routes' {
        Assert (($catalog.id | Select-Object -Unique).Count -eq $catalog.Count)
        foreach ($item in $catalog) {
            Assert ($item.windows.method -in 'choco','winget','zip','module','native','native-exe','manual')
            Assert ($item.windows.source -match '^https://')
            if ($item.windows.location -eq 'custom') { Assert ($item.windows.folder -notmatch '[\\/:]') }
        }
    }
    Test 'Reject relative paths, drive roots and command characters' {
        foreach ($path in 'relative','E:\','E:\bad"path','E:\bad|path','\\server\share') {
            $rejected=$false; try { $null=Resolve-WindowsPath $path } catch { $rejected=$true }; Assert $rejected $path
        }
    }
    Test 'Selectable drive propagates to all roots' {
        $state=New-FixtureState -DryRun
        Set-WindowsPaths $state 'Z:' '' '' ''
        Assert ($state.SoftwareRoot -eq 'Z:\Software')
        Assert ($state.DevRoot -eq 'Z:\Development')
        Assert ($state.DataRoot -eq 'Z:\Data')
    }
    Test 'Custom paths with spaces are retained' {
        $state=New-FixtureState -DryRun
        Set-WindowsPaths $state 'E:' 'E:\External Apps' 'E:\My Projects' 'E:\My Data'
        Assert ($state.SoftwareRoot -eq 'E:\External Apps')
        Assert ($state.DevRoot -eq 'E:\My Projects')
    }
    Test 'Missing drive fails without falling back to C' {
        $state=New-FixtureState -DryRun
        $missing=@('Z','Y','X','W' | Where-Object { -not (Test-Path "${_}:\") })[0]
        $rejected=$false; try { Assert-WindowsDestination $state "${missing}:\Software" } catch { $rejected=$true }
        Assert $rejected
    }
    Test 'Read-only destination checks create no probe or directory' {
        $state=New-FixtureState
        $path=Join-Path $testRoot 'not-created'
        Assert-WindowsDestination $state $path $true
        Assert (-not (Test-Path $path))
        Assert (@(Get-ChildItem $testRoot -Filter '.ramon-write-*').Count -eq 0)
    }
    Test 'Reject a file as destination' {
        $path=Join-Path $testRoot 'is-file'; [IO.File]::WriteAllText($path,'original')
        $rejected=$false; try { Assert-WindowsDestination (New-FixtureState) $path } catch { $rejected=$true }; Assert $rejected
    }
    Test 'Existing installation outside PATH detected from registry' {
        $item=@($catalog | Where-Object id -EQ 'nvm')[0]
        $inventory=@{ Apps=@([pscustomobject]@{ DisplayName='NVM for Windows 1.2.2' }); Choco=@(); Store=@(); Fonts=@(); Modules=@() }
        Assert (Test-WindowsInstalled $item $inventory (New-FixtureState -DryRun))
    }
    Test 'Existing Store application and font detected without commands' {
        $inventory=@{ Apps=@(); Choco=@(); Store=@('5319275A.WhatsAppDesktop_test'); Fonts=@('FiraCode Nerd Font Mono (TrueType)'); Modules=@() }
        Assert (Test-WindowsInstalled @($catalog | Where-Object id -EQ 'whatsapp')[0] $inventory (New-FixtureState -DryRun))
        Assert (Test-WindowsInstalled @($catalog | Where-Object id -EQ 'firacode-nerd')[0] $inventory (New-FixtureState -DryRun))
    }
    Test 'Required configuration dependencies are visible in choices' {
        $choices=@{ '@shell'=$true; '@terminal'=$true; '@auth'=$true }
        Add-WindowsDependencies $choices $catalog @{} (New-FixtureState -DryRun)
        foreach ($id in 'oh-my-posh','terminal-icons','psreadline','windows-terminal','firacode-nerd','git','gh') { Assert $choices[$id] $id }
    }
    Test 'Keyboard back, wrap, cancellation and selections' {
        $nav=@{ Page=2; Cursor=0; Cancel=$false }
        Update-WindowsNavigation $nav 'UpArrow' 3; Assert ($nav.Cursor -eq 2)
        Update-WindowsNavigation $nav 'DownArrow' 3; Assert ($nav.Cursor -eq 0)
        Update-WindowsNavigation $nav 'B' 3; Assert ($nav.Page -eq 1)
        Update-WindowsNavigation $nav 'Enter' 3; Assert ($nav.Page -eq 2)
        Update-WindowsNavigation $nav 'Q' 3; Assert $nav.Cancel
    }
    Test 'Package destination arguments are built per application' {
        $state=New-FixtureState -DryRun
        $git=@($catalog | Where-Object id -EQ 'git')[0]
        $command=Get-WindowsPackageCommand $state $git
        Assert ($command.arguments -contains ('--install-arguments=/DIR="' + (Join-Path $state.SoftwareRoot 'Git') + '"'))
        $nvm=@($catalog | Where-Object id -EQ 'nvm')[0]
        $command=Get-WindowsPackageCommand $state $nvm
        Assert ($command.arguments -contains '--location')
        Assert ($command.arguments -contains (Join-Path $state.SoftwareRoot 'nvm'))
        Assert (-not ($command.arguments -contains '--force'))
    }
    Test 'Errors and restart-required outcomes are distinct' {
        $state=New-FixtureState
        Assert-WindowsExitCode $state 3010; Assert $state.Reboot
        $rejected=$false; try { Assert-WindowsExitCode $state 1603 } catch { $rejected=$true }; Assert $rejected
    }
    Test 'Unknown free space is reported as unknown, not zero' {
        function Get-PSDrive { [pscustomobject]@{ Root='E:\'; Description='external'; Free=0; Used=0 } }
        $drives=@(Get-WindowsDrives)
        Assert ($null -eq $drives[0].FreeGB)
    }
    Test 'Failed install is propagated and never marked installed' {
        function Get-WindowsInventory { @{ Apps=@(); Choco=@(); Store=@(); Fonts=@(); Modules=@() } }
        function Install-WindowsNative { throw 'fixture package failure' }
        $item=[pscustomobject]@{id='fixture-failed';label='Fixture';kind='tool';windows=[pscustomobject]@{method='native';location='system';commands=@();paths=@();detect=''}}
        $state=New-FixtureState
        $choices=@{ 'fixture-failed'=$true; '@clean'=$true }
        Invoke-WindowsSetup $state @($item) @{} $choices
        Assert ($state.Failed.Contains('fixture-failed'))
        Assert (-not $state.InstalledNow.Contains('fixture-failed'))
    }
    Test 'Manual route stays pending rather than installed' {
        function Get-WindowsInventory { @{ Apps=@(); Choco=@(); Store=@(); Fonts=@(); Modules=@() } }
        $item=[pscustomobject]@{id='fixture-manual';label='Fixture';kind='app';windows=[pscustomobject]@{method='manual';package='https://example.com/';location='system';commands=@();paths=@();detect=''}}
        $state=New-FixtureState
        Install-WindowsOption $state $item
        Assert ($state.Manual.Contains('fixture-manual'))
        Assert (-not $state.InstalledNow.Contains('fixture-manual'))
    }
    Test 'Existing installations skip the installer entirely' {
        function Get-WindowsInventory { @{ Apps=@([pscustomobject]@{DisplayName='Fixture Existing'}); Choco=@(); Store=@(); Fonts=@(); Modules=@() } }
        function Install-WindowsNative { throw 'Installer must not run' }
        $item=[pscustomobject]@{id='fixture-existing';label='Fixture';kind='app';windows=[pscustomobject]@{method='native';location='system';commands=@();paths=@();detect='^Fixture Existing$'}}
        $state=New-FixtureState
        Install-WindowsOption $state $item
        Assert ($state.InstalledNow.Count -eq 0)
    }
    Test 'Native argument quoting preserves spaces, quotes and trailing slash' {
        $echoFile=Join-Path $testRoot 'echo-arguments.ps1'
        $outputFile=Join-Path $testRoot 'arguments.json'
        [IO.File]::WriteAllText($echoFile,'param([string]$Output,[string]$Value) [IO.File]::WriteAllText($Output,(ConvertTo-Json -InputObject $Value))')
        foreach ($value in 'E:\External Apps\','--install-arguments=/DIR="E:\My Apps\Git"','plain','') {
            $code=Invoke-WindowsCommand (New-FixtureState) "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" @('-NoProfile','-File',$echoFile,'-Output',$outputFile,'-Value',$value)
            Assert ($code -eq 0)
            $actual=Get-Content -LiteralPath $outputFile -Raw | ConvertFrom-Json
            Assert ($actual -ceq $value) "Argument changed: $value -> $actual"
        }
    }
    Test 'JSONC edits preserve comments, URLs and unrelated nested settings' {
        $text='{"profiles":{"defaults":{"elevate":true,"font":{"size":13}}}, /* keep */ "url":"https://x/a,b}",}'
        $edited=Set-WindowsJsoncProperty $text @('profiles','defaults','font','face') 'FiraCode Nerd Font Mono'
        $edited=Set-WindowsJsoncProperty $edited @('profiles','defaults','colorScheme') 'One Half Dark'
        $doc=Read-WindowsJsonc $edited
        Assert ($edited.Contains('/* keep */'))
        Assert $doc.value.profiles.defaults.elevate
        Assert ($doc.value.profiles.defaults.font.size -eq 13)
        Assert ($doc.value.url -eq 'https://x/a,b}')
    }
    Test 'Missing JSON objects are created without replacing other properties' {
        $text=Set-WindowsJsoncProperty '{"other":1}' @('profiles','defaults','font','face') 'FiraCode Nerd Font Mono'
        $doc=Read-WindowsJsonc $text
        Assert ($doc.value.other -eq 1)
        Assert ($doc.value.profiles.defaults.font.face -eq 'FiraCode Nerd Font Mono')
    }
    Test 'Invalid/duplicate Terminal JSONC is rejected unchanged' {
        foreach ($text in '{broken','{"profiles":{},"profiles":{}}','{/*unterminated') {
            $rejected=$false; try { $null=Read-WindowsJsonc $text } catch { $rejected=$true }; Assert $rejected
        }
    }
    Test 'Terminal appearance preserves profiles and unrelated keybindings' {
        $path=Join-Path $testRoot 'terminal.json'
        [IO.File]::WriteAllText($path,'{"profiles":{"list":[{"name":"Keep","guid":"original"}]},"keybindings":[{"keys":"alt+k","id":"custom"}],"defaultProfile":"original"}')
        $state=New-FixtureState
        Set-WindowsTerminal $state $path
        $doc=Read-WindowsJsonc ([IO.File]::ReadAllText($path))
        Assert ($doc.value.defaultProfile -eq 'original')
        Assert ($doc.value.profiles.list[0].name -eq 'Keep')
        Assert (@($doc.value.keybindings | Where-Object keys -EQ 'alt+k').Count -eq 1)
        $before=[IO.File]::ReadAllText($path)
        Set-WindowsTerminal $state $path
        Assert ([IO.File]::ReadAllText($path) -ceq $before)
    }
    Test 'Profile setup preserves custom content and is idempotent' {
        $path=Join-Path $testRoot 'OneDrive\Documentos\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
        $null=New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force
        [IO.File]::WriteAllText($path,'# private content remains')
        $state=New-FixtureState
        Set-WindowsProfile $state $path
        $before=[IO.File]::ReadAllText($path)
        Set-WindowsProfile $state $path
        Assert ([IO.File]::ReadAllText($path) -ceq $before)
        Assert ($before.Contains('# private content remains'))
        Assert ([regex]::Matches($before,'# >>> ramon-dotfiles >>>').Count -eq 1)
    }
    Test 'Backup and restore preserve file content and current-state backup' {
        $state=New-FixtureState
        $path=Join-Path $testRoot 'restore-file.txt'; [IO.File]::WriteAllText($path,'original')
        $id=Backup-WindowsFile $state $path
        [IO.File]::WriteAllText($path,'changed')
        $backup=$state.Backup
        $entry=Get-WindowsRestoreEntry $state $backup $id
        $state.Backup=''
        Restore-WindowsEntry $state $backup $entry
        Assert ([IO.File]::ReadAllText($path) -eq 'original')
        Assert ($state.Backup -ne $backup)
    }
    Test 'Originally absent file can be restored to absence' {
        $state=New-FixtureState; $path=Join-Path $testRoot 'new-file.txt'
        $id=Backup-WindowsFile $state $path
        [IO.File]::WriteAllText($path,'new')
        $entry=Get-WindowsRestoreEntry $state $state.Backup $id
        Restore-WindowsEntry $state $state.Backup $entry
        Assert (-not (Test-Path $path))
    }
    Test 'Reject traversal and restore outside backup directory' {
        $state=New-FixtureState; $rejected=$false
        try { $null=Get-WindowsRestoreEntry $state $testRoot ('a'*32) } catch { $rejected=$true }; Assert $rejected
        $rejected=$false; try { $null=Get-WindowsRestoreEntry $state $state.StateRoot '../payload' } catch { $rejected=$true }; Assert $rejected
    }
    Test 'Environment manifest restore validates variables and dry-run preserves registry' {
        $state=New-FixtureState
        $id=[guid]::NewGuid().ToString('N')
        Add-WindowsBackupEntry $state @{ id=$id; type='environment'; target='OLLAMA_MODELS'; original='E:\Original Models' }
        $entry=Get-WindowsRestoreEntry $state $state.Backup $id
        Assert ($entry.original -eq 'E:\Original Models')
        $before=[Environment]::GetEnvironmentVariable('OLLAMA_MODELS','User')
        $state.DryRun=$true
        Restore-WindowsEntry $state $state.Backup $entry
        Assert ([Environment]::GetEnvironmentVariable('OLLAMA_MODELS','User') -ceq $before)
        $state.DryRun=$false
        $bad=[guid]::NewGuid().ToString('N')
        Add-WindowsBackupEntry $state @{ id=$bad; type='environment'; target='UNSUPPORTED_VARIABLE'; original='anything' }
        $rejected=$false; try { $null=Get-WindowsRestoreEntry $state $state.Backup $bad } catch { $rejected=$true }; Assert $rejected
    }
    Test 'ZIP traversal cannot write outside extraction directory' {
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $path=Join-Path $testRoot 'malicious.zip'
        $zip=[IO.Compression.ZipFile]::Open($path,[IO.Compression.ZipArchiveMode]::Create)
        $null=$zip.CreateEntry('../escaped.txt'); $zip.Dispose()
        $rejected=$false; try { Expand-WindowsArchive $path (Join-Path $testRoot 'extract') } catch { $rejected=$true }; Assert $rejected
        Assert (-not (Test-Path (Join-Path $testRoot 'escaped.txt')))
    }
    Test 'Dry-run configuration creates no files or directories' {
        $state=New-FixtureState -DryRun
        $before=@(Get-ChildItem -LiteralPath $testRoot -Recurse -Force | Select-Object -ExpandProperty FullName)
        Set-WindowsProfile $state (Join-Path $testRoot 'dry-profile.ps1')
        New-WindowsDevFolders $state
        $after=@(Get-ChildItem -LiteralPath $testRoot -Recurse -Force | Select-Object -ExpandProperty FullName)
        Assert (($before -join '|') -ceq ($after -join '|'))
        Assert (-not $state.Temp -and -not $state.Backup)
    }
    Test 'Full fresh setup dry-run performs no downloads or writes' {
        function Get-WindowsInventory { @{ Apps=@(); Choco=@(); Store=@(); Fonts=@(); Modules=@() } }
        function Get-WindowsDownload { throw 'Dry-run must not download anything' }
        function Write-Host { }
        $fresh=ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject $catalog -Depth 20)
        $choices=@{ '@shell'=$true; '@terminal'=$false; '@git'=$true; '@auth'=$true; '@dev'=$true; '@ollama-data'=$true; '@clean'=$true }
        foreach ($item in $fresh) { $item.windows.commands=@(); $item.windows.paths=@(); $item.windows.detect=''; $choices[$item.id]=$true }
        $state=New-FixtureState -DryRun
        $before=@(Get-ChildItem -LiteralPath $testRoot -Recurse -Force | Select-Object -ExpandProperty FullName)
        Invoke-WindowsSetup $state $fresh @{} $choices
        Assert ($state.Failed.Count -eq 0) ($state.Failed -join ',')
        Assert (-not $state.Temp -and -not $state.Backup)
        $after=@(Get-ChildItem -LiteralPath $testRoot -Recurse -Force | Select-Object -ExpandProperty FullName)
        Assert (($before -join '|') -ceq ($after -join '|'))
    }
    Test 'Cleanup refuses unrelated directories' {
        $state=New-FixtureState; $state.Temp=$testRoot
        $rejected=$false; try { Clear-WindowsTemporary $state } catch { $rejected=$true }; Assert $rejected
        Assert (Test-Path $testRoot)
    }
    # A real symlink verifies that restore replaces the link rather than writing its referent.
    $link=Join-Path $testRoot 'current-link.txt'; $referent=Join-Path $testRoot 'referent.txt'
    [IO.File]::WriteAllText($referent,'referent')
    try { $null=New-Item -ItemType SymbolicLink -Path $link -Target $referent -ErrorAction Stop }
    catch { $skipped++; Write-Host 'SKIP symlink restore: Developer Mode/elevation unavailable in this test host.' }
    if (Get-Item -LiteralPath $link -ErrorAction SilentlyContinue) {
        Test 'Restore replaces symlink without touching referent' {
            $state=New-FixtureState
            $path=Join-Path $testRoot 'restore-link.txt'; [IO.File]::WriteAllText($path,'original')
            $id=Backup-WindowsFile $state $path
            [IO.File]::Delete($path)
            $null=New-Item -ItemType SymbolicLink -Path $path -Target $referent
            $entry=Get-WindowsRestoreEntry $state $state.Backup $id
            Restore-WindowsEntry $state $state.Backup $entry
            Assert ([IO.File]::ReadAllText($referent) -eq 'referent')
            Assert ([IO.File]::ReadAllText($path) -eq 'original')
            Assert (-not ((Get-Item -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint))
        }
    }
} finally {
    $env:USERPROFILE=$originalHome; $env:LOCALAPPDATA=$originalLocal
    $workspaceState=[IO.Path]::GetFullPath((Join-Path $repo '.state')).TrimEnd('\') + '\'
    $resolved=[IO.Path]::GetFullPath($testRoot)
    if ($resolved.StartsWith($workspaceState,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf) -match '^windows-tests-[a-f0-9]{32}$') { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
Write-Host "Windows tests: $passed passed; $failed failed; $skipped skipped."
if ($failed) { exit 1 }
