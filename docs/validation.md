# Validation / Validación

Checked on macOS on 2026-10-05. No live installation or cleanup was executed.

- PASS: Real-home dry-run leaves active shell and Git files unchanged
- PASS: Backups preserve originals; repeated linking/Git configuration is idempotent; folder-only scaffold
- PASS: Fresh zprofile link remains free of recursive sourcing
- PASS: Cleanup leaves unrelated caches intact
- PASS: Detection recognizes NVM, manual apps and manually installed fonts
- PASS: Fresh-home dry-run creates no files or directories
- PASS: Loaded Zsh keeps robbyrussell, Git plugin, and eza/bat aliases
- PASS: 51 unique bilingual options; catalogs regenerate identically; excluded software absent

- PASS: Linux Docker bundle detection requires Compose; cleanup removes only new orphan dependencies (mock package database)
- PASS: Interactive dry-run accepts numeric toggles and completes without installation

At the original 2026-10-05 inspection, live Linux checks were pending. See the current Linux validation below.

## Keyboard wizard update / Actualización del asistente

- PASS: Arrow-key navigation and Space toggle in a real pseudo-terminal.
- PASS: Existing programs remain checked and locked; Space cannot request reinstall.
- PASS: Going back preserves selections within the current process only.
- PASS: Review screen lists selected agents/apps and configuration before execution.
- PASS: Editable Dev path from the review screen.
- PASS: English and Spanish interfaces; Q cancellation and SIGINT restore cursor and terminal settings.
- PASS: Keyboard dry-run performs no changes to active Zsh/Git files.
- PASS: Plain-text fallback and noninteractive dry-run remain available.

The interactive interface uses native Bash/ANSI controls; no Node, npm package, Python or extra UI dependency is installed.

## Linux implementation · 2026-10-06

Current reproducible checks:

```bash
python3 -m unittest discover -s tests -v
python3 scripts/generate-catalog.py --check
bash bootstrap.sh --dry-run
bash scripts/doctor.sh
```

- PASS: 21 regression tests with isolated HOME, fake package managers and no network or host installation. Covers Arch/EndeavourOS/Zorin 18 detection, rejection of Zorin 17/other distros, localized Dev directories, unchanged macOS package routes, NVM reuse, package failures, one Arch upgrade, APT behavior, Docker/Compose detection, Flatpak deployments, dependencies, UI pages, broken links and symlink-safe restore.
- PASS: Fresh-HOME dry-run creates no user files. Flatpak detection reads deployment metadata because `flatpak info` can initialize user directories.
- PASS: Bash/Zsh syntax checks per file; generated catalog/manifests/matrix consistent; `git diff --check`.
- PASS: Actual EndeavourOS read-only inventory and dry-run recognize the existing NVM and `~/Documentos/Dev`. Active shell/Git configuration was not applied or replaced.
- PASS: Disposable `archlinux:base` container: all catalog pacman package names queried with multilib enabled; actual installation of autosuggestions, highlighting, eza, bat, fd and NVM; Zsh loads the repo and its aliases. No managed Node installation.
- PASS: Disposable `ubuntu:24.04` container: all APT package names queried; actual installation of autosuggestions, highlighting, eza, bat, fd and NVM; Zsh loads batcat and eza aliases. This validates the Ubuntu base, not a complete Zorin desktop.
- PASS: AUR API resolves ngrok, lazyworktree-bin, watchman-bin, tableplus and warp-terminal-bin. Availability does not prove that an AUR build succeeds.
- PASS: Linux temporary-directory traversal works for pacman's alpm download user and APT's _apt user without disabling their sandbox. Run-owned caches return to the invoking user for cleanup.
- CLEANUP: Test containers used `--rm`; downloaded Ubuntu and Arch images were removed after testing.

To reproduce container smoke checks (these install only inside the disposable container):

```bash
docker run --rm -v "$PWD:/repo:ro" ubuntu:24.04 bash /repo/tests/container-smoke.sh ubuntu
docker run --rm -v "$PWD:/repo:ro" archlinux:base bash /repo/tests/container-smoke.sh arch
# Remove the test images afterwards if they were downloaded only for this test.
docker image rm ubuntu:24.04 archlinux:base
```

Not yet validated live: full Zorin 18 desktop/launchers, Wayland/X11 appearance, vendor repository/package installation, Flatpak application launch, Docker service startup and AUR builds. The environment had no /dev/kvm or Zorin disk image, so no GUI VM validation is claimed. macOS routes are preserved and checked against the original catalog; no current macOS execution was available.
