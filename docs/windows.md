# Windows setup / Configuración Windows

Windows 10/11 x64, Windows PowerShell 5.1 or PowerShell 7. Start from a normal user terminal. Keep the repository in a permanent location: the managed profile loads its configuration from here.

```powershell
powershell -NoProfile -File .\bootstrap.ps1 -List
powershell -NoProfile -File .\bootstrap.ps1 -DryRun
powershell -NoProfile -File .\bootstrap.ps1
powershell -NoProfile -File .\bootstrap.ps1 -TargetDrive E: -Lang en
powershell -NoProfile -File .\scripts\windows\doctor.ps1
```

Si una política bloquea scripts, revisa primero `Get-ExecutionPolicy -List`. Puedes usar `powershell -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1` para esa ejecución; el asistente no cambia la política permanente ni omite políticas de organización.

Git Bash delegates `bash bootstrap.sh` to Windows PowerShell. WSL runs the Unix installer for its Linux distribution; it does not install applications on the Windows host. A universal script cannot assume Bash is installed on a fresh Windows computer, so PowerShell has its own entry point.

## Elegir el SSD / Choose a drive

The first screen lists mounted local drives with labels and available space when accessible. E: is proposed when present; it is not permanently hardcoded. Choose another drive or enter a drive letter, then edit any of these roots:

| Content | Example |
|---|---|
| Applications supporting custom installation | `E:\Software` |
| Development directories | `E:\Development` |
| New application data with supported settings | `E:\Data` |

Sin E:, se propone la unidad del usuario, Documentos para proyectos y una carpeta Software para apps configurables; las aplicaciones con destino estándar usan sus ubicaciones habituales. Las rutas también pueden indicarse con `-SoftwareRoot`, `-DevRoot` y `-DataRoot`. Si cambias la unidad durante el asistente, se vuelven a proponer las tres carpetas y puedes editarlas.

Each option states its installation method and destination in the review. Official portable releases are used for several CLI tools because their Chocolatey packages keep the binary under Chocolatey's own directory. Other custom routes use verified installer parameters. This is not a promise that all files go to the SSD: settings, shared components, services, package metadata and updater files can remain on C:.

Si el disco desaparece o no permite escribir, las acciones dependientes fallan y aparecen como incompletas. No se cambia silenciosamente a C:. El resumen continúa mostrando lo pendiente. Mantén conectado el SSD al usar sus aplicaciones; si cambia su letra, revisa rutas y variables antes de utilizarlas.

Existing applications are detected and reused, regardless of their original manager/location. The wizard does not migrate installed applications or existing data. No global Program Files/AppData redirection, directory junctions or moves after installation are performed. See [the generated matrix](windows-compatibility.md).

## Gestores y datos / Managers and data

Chocolatey is the primary manager for applications with an appropriate package. WinGet handles separate verified routes and Store applications; official installers/releases cover the other automatic options. Each option has exactly one route; failures do not silently trigger another manager.

Chocolatey setup and package operations may request UAC. Only the package operation is elevated; profile, Git and user variables are configured by the initiating user. Prefer approving UAC with the same account: packages that install per user use the account of the elevated operation. The review identifies prerequisites and sources. Missing WinGet prints App Installer instructions and leaves affected options pending. Package agreements are accepted for the options confirmed in the review.

NVM for Windows installs only the manager. Existing `NVM_HOME`, `NVM_SYMLINK` and Node versions are retained. Bun, pnpm and Deno use their official scripts and supported root variables for a new installation. An existing variable conflicting with a new destination requires manual resolution rather than overwriting it. Existing Node/pnpm installations are reused.

For a **new** Ollama installation only, model storage can be configured as `DataRoot\Ollama` using the user variable `OLLAMA_MODELS`. Existing variables or installed Ollama are preserved. No models are moved or downloaded; restart Ollama after configuring the variable. Docker disk images, WSL2/virtualization and Android SDK destinations require their application-specific setup; the wizard does not provision them automatically.

Manual options print official links and stay pending. They are not counted as installed. App presence does not prove that login, license, daemon access or GUI behavior works.

## Terminal y recuperación / Terminal and recovery

The managed profile resolves Windows Documents, including OneDrive. It appends/updates one marked loading block and preserves unrelated content. The portable initialization avoids repeating an existing Oh My Posh/module setup; the included theme reproduces the inspected robbyrussell appearance. Private settings go in `%USERPROFILE%\.config\ramon-dotfiles\windows.local.ps1` and are never tracked.

Windows Terminal appearance is optional. It updates One Half Dark, FiraCode Nerd Font Mono and the inspected shortcuts. It preserves comments and unrelated properties/profiles; the edited keybinding array is rewritten. Invalid JSONC or duplicate properties are reported and left untouched. Default profile and elevation are not changed.

Backups and environment-variable originals are stored locally under `%LOCALAPPDATA%\ramon-dotfiles\backups`, with one manifest per run. They can contain private configuration and never belong in the repository. Restore replaces the file itself rather than writing through its current symlink. Restoring an original symlink requires Windows Developer Mode or the relevant privilege; unsupported reparse ancestors are rejected.

```powershell
powershell -NoProfile -File .\scripts\windows\restore.ps1 -List
powershell -NoProfile -File .\scripts\windows\restore.ps1 -Backup '<run-directory>' -Id '<manifest-id>' -DryRun
powershell -NoProfile -File .\scripts\windows\restore.ps1 -Backup '<run-directory>' -Id '<manifest-id>'
```

Restore asks for `RESTORE` and backs up the current state first. It handles original files, absent files and supported file symlinks, plus the managed user variables. No automatic uninstallation or rollback of package-manager operations is attempted.

Downloads use a unique temporary directory, with cleanup in `finally`. Disabling maximum cleanup retains downloaded archives/installers and the run's Chocolatey cache under local state. Other caches, dependencies, Node versions, models, Docker data, projects and backups remain untouched. Official installers and managers may maintain necessary data outside that directory.

`-List` and noninteractive `-DryRun` work offline and create no user files. Dry-run prints default selections and configuration actions; it does not call package managers, install modules, download installers or prepare prerequisites. Interactive dry-run allows changing selections before reviewing them. Starting the wizard requires no maintenance/test dependencies.

## Maintenance and tests

Edit catalog JSON, then run `python3 scripts/generate-catalog.py`; `--check` verifies generated artifacts without writing. Modern Python is only needed for maintenance, not installation. On Windows, use your Python 3 command (`py -3` if installed); the inspected computer's `python` resolves to Python 2 and its `python3` is a Store alias.

```powershell
powershell -NoProfile -File .\tests\windows-tests.ps1
```

The tests use disposable workspace fixtures without host installation or persistent user configuration changes. Unix regression tests require a Unix environment with Bash, Zsh and Python 3. See [validation status](validation.md).

In a disposable Windows Sandbox/VM only, `powershell -NoProfile -File .\tests\windows-smoke.ps1 -DisposableMachine` performs real installs of a small package/portable subset and checks the chosen folder. It changes that VM's packages and PATH; discard the VM afterwards. Do not run this smoke command on your normal computer. The CI workflow runs catalog checks, Unix regression tests and the isolated Windows suite under PowerShell 5.1 and 7; it does not run installation smoke checks.
