function Test-WindowsInteractive {
    try { return (-not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected) }
    catch { return $false }
}
function New-WindowsChoices($Catalog, $Inventory, $State) {
    $choices = @{}
    foreach ($item in $Catalog) {
        $choices[$item.id] = (Test-WindowsInstalled $item $Inventory $State) -or [bool]$item.windows.default
    }
    $choices['@shell'] = $true; $choices['@git'] = $true; $choices['@dev'] = $true
    $choices['@auth'] = $false; $choices['@terminal'] = $false; $choices['@clean'] = $true
    $choices['@ollama-data'] = $true
    return $choices
}
function Get-WindowsActionRows($State) {
    @(
        @{ id='@shell'; label=(Get-WindowsText $State 'Tu perfil de PowerShell' 'Your PowerShell profile'); description='robbyrussell + Terminal-Icons; backup before editing; private overrides supported.' },
        @{ id='@terminal'; label=(Get-WindowsText $State 'Apariencia de Windows Terminal' 'Windows Terminal appearance'); description='One Half Dark, FiraCode Nerd Font Mono, keyboard shortcuts. Existing profiles and elevation settings stay.' },
        @{ id='@git'; label=(Get-WindowsText $State 'Tu identidad Git' 'Your Git identity'); description='Erick Ramon Hernandez Ortega / erickramon47@live.com.mx' },
        @{ id='@auth'; label=(Get-WindowsText $State 'GitHub por HTTPS' 'GitHub over HTTPS'); description='Optional browser login as Erick-Hernandez-Ortega; credentials stay outside this repo.' },
        @{ id='@dev'; label=(Get-WindowsText $State 'Crear carpetas de desarrollo' 'Create development directories'); description='Only missing directories; no cloning, moving or project creation.' },
        @{ id='@ollama-data'; label=(Get-WindowsText $State 'Modelos nuevos de Ollama en el disco elegido' 'New Ollama models on the chosen drive'); description='Only for a new Ollama installation and unset OLLAMA_MODELS. Existing models are never moved.' },
        @{ id='@clean'; label=(Get-WindowsText $State 'Eliminar descargas de esta ejecución' 'Remove downloads from this run'); description='Preserves unrelated caches, backups, runtimes, projects and application data.' }
    )
}
function Add-WindowsDependencies($Choices, $Catalog, $Inventory, $State) {
    $ids = @()
    if ($Choices['@shell']) { $ids += 'oh-my-posh','terminal-icons','psreadline' }
    if ($Choices['@terminal']) { $ids += 'windows-terminal','firacode-nerd' }
    if ($Choices['@git'] -or $Choices['@auth']) { $ids += 'git' }
    if ($Choices['@auth']) { $ids += 'gh' }
    foreach ($id in $ids) { $Choices[$id] = $true }
}
function Edit-WindowsDestinations($State) {
    Write-Host (Get-WindowsText $State 'Unidad para nuevas apps, proyectos y datos compatibles:' 'Drive for new apps, projects and supported data:')
    $drives = @(Get-WindowsDrives)
    for ($i=0; $i -lt $drives.Count; $i++) {
        $free = if ($null -eq $drives[$i].FreeGB) { 'unknown / desconocido' } else { "$($drives[$i].FreeGB) GB" }
        Write-Host "  $($i+1). $($drives[$i].Root) $($drives[$i].Label) | free: $free"
    }
    $answer = Read-Host "Drive number or letter [$($State.TargetDrive)] / Q cancels"
    if ($answer -match '^[qQ]$') { return $false }
    if ($answer) {
        $index = 0
        if ([int]::TryParse($answer, [ref]$index) -and $index -gt 0 -and $index -le $drives.Count) { $answer = $drives[$index-1].Root }
        Set-WindowsPaths $State $answer '' '' ''
    }
    foreach ($key in 'SoftwareRoot','DevRoot','DataRoot') {
        $answer = Read-Host "$key [$($State[$key])]"
        if ($answer -match '^[qQ]$') { return $false }
        if ($answer) { $State[$key] = Resolve-WindowsPath $answer }
        Assert-WindowsDestination $State $State[$key] $true
    }
    return $true
}
function Show-WindowsSummary($State, $Catalog, $Inventory, $Choices) {
    Add-WindowsDependencies $Choices $Catalog $Inventory $State
    Write-Host "`nRAMON | WINDOWS | $(Get-WindowsText $State 'Revisar y comenzar' 'Review and start')"
    Write-Host "Software: $($State.SoftwareRoot)`nDev: $($State.DevRoot)`nData: $($State.DataRoot)"
    $methods = @{}
    foreach ($item in $Catalog) {
        if (-not $Choices[$item.id] -or (Test-WindowsInstalled $item $Inventory $State)) { continue }
        $methods[$item.windows.method] = $true
        $admin = if ($item.windows.admin) { ' | administrator/UAC' } else { '' }
        Write-Host "  + $($item.label) | $($item.windows.method):$($item.windows.package)$admin"
        Write-Host "    $(Get-WindowsLocationText $State $item)"
        if ($item.windows.notes) { Write-Host "    $($item.windows.notes)" }
        if ($item.windows.dataVariable -and $Choices['@ollama-data']) {
            if ([Environment]::GetEnvironmentVariable($item.windows.dataVariable,'User') -or [Environment]::GetEnvironmentVariable($item.windows.dataVariable,'Process')) { Write-Host '    Preserve existing model location.' }
            else { Write-Host "    New data: $(Join-Path $State.DataRoot $item.windows.dataFolder)" }
        }
    }
    foreach ($row in Get-WindowsActionRows $State) { if ($Choices[$row.id]) { Write-Host "  * $($row.label)" } }
    if ($methods['choco'] -and -not (Get-Command choco.exe -ErrorAction SilentlyContinue)) { Write-Host '  Prerequisite: install Chocolatey using its official script (administrator/UAC).' }
    if ($methods['winget'] -and -not (Get-Command winget.exe -ErrorAction SilentlyContinue)) { Write-Host '  Prerequisite: App Installer / WinGet; manual setup instructions will be printed.' }
    if ($methods['module']) { Write-Host '  Modules: PowerShell Gallery, CurrentUser; NuGet provider may be prepared.' }
    Write-Host '  External-drive applications require the drive to remain connected. Shared components/settings may stay on C:.'
    if ($State.DryRun) { Write-Host 'DRY RUN: no downloads, configuration changes or installations.' }
}
function Update-WindowsNavigation($Navigation, [string]$Key, [int]$Count) {
    switch ($Key) {
        'UpArrow' { if ($Count) { $Navigation.Cursor = ($Navigation.Cursor + $Count - 1) % $Count } }
        'DownArrow' { if ($Count) { $Navigation.Cursor = ($Navigation.Cursor + 1) % $Count } }
        'LeftArrow' { $Navigation.Page = [math]::Max(0,$Navigation.Page-1); $Navigation.Cursor=0 }
        'B' { $Navigation.Page = [math]::Max(0,$Navigation.Page-1); $Navigation.Cursor=0 }
        'Enter' { $Navigation.Page++; $Navigation.Cursor=0 }
        'Q' { $Navigation.Cancel=$true }
        'Escape' { $Navigation.Cancel=$true }
    }
}
function Show-WindowsWizard($State, $Catalog, $Inventory, $Choices) {
    if (-not (Edit-WindowsDestinations $State)) { return $false }
    $titles = if ($State.Language -eq 'es') { @('Esenciales','Runtimes','Agentes de IA','Editores','Desarrollo','Tu día a día','Fuentes','Personalización','Revisar y comenzar') } else { @('Essentials','Runtimes','AI agents','Editors','Development','Everyday apps','Fonts','Personalization','Review and start') }
    $navigation = @{ Page=0; Cursor=0; Cancel=$false }
    $keyboard = $Host.Name -eq 'ConsoleHost' -and $env:TERM -ne 'dumb'
    $previousCursor = $true
    try {
        if ($keyboard) { try { $previousCursor=[Console]::CursorVisible; [Console]::CursorVisible=$false } catch {} }
        while ($navigation.Page -lt 9 -and -not $navigation.Cancel) {
            if ($keyboard) { try { [Console]::Clear() } catch {} }
            Write-Host "RAMON | WINDOWS | $($navigation.Page+1)/9 | $($titles[$navigation.Page])"
            if ($navigation.Page -eq 8) {
                Show-WindowsSummary $State $Catalog $Inventory $Choices
                Write-Host 'Enter: continue | B/Left: back | D: destinations | Q: cancel'
                $key = if ($keyboard) { [Console]::ReadKey($true).Key.ToString() } else { $v=Read-Host; if (-not $v) {'Enter'} else {$v.ToUpperInvariant()} }
                if ($key -eq 'D') { if (-not (Edit-WindowsDestinations $State)) { return $false }; continue }
                Update-WindowsNavigation $navigation $key 0
                continue
            }
            $rows = @()
            if ($navigation.Page -eq 7) {
                $rows = @(Get-WindowsActionRows $State | ForEach-Object { [pscustomobject]@{ id=$_.id; label=$_.label; description=$_.description; locked=$false } })
            } else {
                foreach ($item in $Catalog | Where-Object { $_.windows.group -eq $navigation.Page }) {
                    $description = if ($State.Language -eq 'es') { $item.description_es } else { $item.description_en }
                    $rows += [pscustomobject]@{ id=$item.id; label=$item.label; description=$description; locked=(Test-WindowsInstalled $item $Inventory $State) }
                }
            }
            $height = 16
            if ($keyboard) { try { $height = [math]::Max(3,[Console]::WindowHeight-9) } catch {} }
            $start = if ($keyboard) { [math]::Max(0,$navigation.Cursor-$height+1) } else { 0 }
            $end = if ($keyboard) { [math]::Min($rows.Count,$start+$height) } else { $rows.Count }
            for ($i=$start; $i -lt $end; $i++) {
                $mark = if ($Choices[$rows[$i].id]) { 'x' } else { ' ' }
                $cursor = if ($i -eq $navigation.Cursor) { '>' } else { ' ' }
                $locked = if ($rows[$i].locked) { ' | installed / instalado' } else { '' }
                Write-Host "$cursor $($i+1) [$mark] $($rows[$i].label)$locked"
            }
            if ($rows.Count) { Write-Host "`n$($rows[$navigation.Cursor].description)" }
            Write-Host 'Up/Down: move | Space: select | Enter: next | B/Left: back | Q: cancel'
            if ($keyboard) {
                $key = [Console]::ReadKey($true).Key.ToString()
                if ($key -eq 'Spacebar' -and $rows.Count -and -not $rows[$navigation.Cursor].locked) {
                    $id=$rows[$navigation.Cursor].id; $Choices[$id] = -not $Choices[$id]
                } else { Update-WindowsNavigation $navigation $key $rows.Count }
            } else {
                $answer = Read-Host 'Numbers separated by spaces toggle; Enter continues'
                if ($answer -match '^\s*\d+(\s+\d+)*\s*$') {
                    foreach ($number in $answer.Trim() -split '\s+') {
                        $index=0
                        if ([int]::TryParse($number,[ref]$index) -and $index -gt 0 -and $index -le $rows.Count -and -not $rows[$index-1].locked) {
                            $id=$rows[$index-1].id; $Choices[$id] = -not $Choices[$id]
                        }
                    }
                } else { $key=if (-not $answer) {'Enter'} else {$answer.ToUpperInvariant()}; Update-WindowsNavigation $navigation $key $rows.Count }
            }
        }
    } finally { if ($keyboard) { try { [Console]::CursorVisible=$previousCursor } catch {} } }
    return (-not $navigation.Cancel)
}
