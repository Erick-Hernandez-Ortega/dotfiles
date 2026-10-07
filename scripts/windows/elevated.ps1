# Isolated package operation; the calling user configures their own profile afterwards.
param([Parameter(Mandatory)][string]$Request, [Parameter(Mandatory)][string]$Result)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/install.ps1"
try {
    $operation=Get-Content -LiteralPath $Request -Raw -Encoding UTF8 | ConvertFrom-Json
    $leaf=Split-Path $operation.executable -Leaf
    if ($leaf -notin 'choco.exe','powershell.exe') { throw 'Unsupported elevated executable.' }
    if ($leaf -eq 'powershell.exe') {
        $script=@($operation.arguments)[-1]
        if ((Split-Path $script -Leaf) -ne 'chocolatey-install.ps1' -or (Split-Path (Split-Path $script -Parent) -Leaf) -notmatch '^ramon-dotfiles-[a-f0-9]{32}$') { throw 'Unsupported bootstrap script.' }
    }
    $info=[Diagnostics.ProcessStartInfo]::new()
    $info.FileName=$operation.executable
    $info.Arguments=(@($operation.arguments | ForEach-Object { ConvertTo-WindowsArgument $_ }) -join ' ')
    $info.UseShellExecute=$false
    $process=[Diagnostics.Process]::Start($info)
    $process.WaitForExit()
    [IO.File]::WriteAllText($Result,[string]$process.ExitCode)
    exit $process.ExitCode
} catch { [IO.File]::WriteAllText($Result,'1'); exit 1 }
