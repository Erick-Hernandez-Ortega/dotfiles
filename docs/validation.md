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

EndeavourOS installation and GUI behavior require testing on that system.

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
