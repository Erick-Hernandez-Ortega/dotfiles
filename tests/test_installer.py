"""Installer regression checks: isolated HOME, fake package managers, no network/sudo."""
import json
import os
from pathlib import Path
import pty
import shlex
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.home = Path(self.tmp.name)
        self.env = dict(os.environ, HOME=str(self.home), NVM_DIR="", XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_DATA_HOME=str(self.home / ".local/share"))

    def tearDown(self):
        self.tmp.cleanup()

    def bash(self, code, success=True):
        prelude = f'source {shlex.quote(str(ROOT / "scripts/common.sh"))}\nOS=linux\nPLATFORM_FAMILY=arch\n'
        result = subprocess.run(["bash", "-c", prelude + code], env=self.env, text=True, capture_output=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def release(self, text):
        path = self.home / "os-release"
        path.write_text(text)
        return shlex.quote(str(path))

    def test_distribution_detection(self):
        for distro in ("arch", "endeavouros"):
            path = self.release(f'ID={distro}\n')
            self.bash(f'pacman() {{ :; }}; detect_linux {path}; [[ "$PLATFORM_FAMILY" == arch ]]')
        path = self.release('ID=zorin\nVERSION_ID=18.1\nUBUNTU_CODENAME=noble\n')
        self.bash(f'apt-get() {{ :; }}; detect_linux {path}; [[ "$PLATFORM_FAMILY" == ubuntu && "$BASE_CODENAME" == noble ]]')
        for text in ('ID=zorin\nVERSION_ID=17\nUBUNTU_CODENAME=jammy\n', 'ID=fedora\n', 'ID=zorin\nVERSION_ID=18\nUBUNTU_CODENAME=jammy\n'):
            path = self.release(text)
            self.assertNotEqual(self.bash(f'detect_linux {path}', success=False).returncode, 0)

    def test_localized_dev_directory(self):
        path = self.release('ID=arch\n')
        self.bash(f'pacman() {{ :; }}; xdg-user-dir() {{ echo "$HOME/Documentos"; }}; detect_linux {path}; [[ "$DEV_ROOT" == "$HOME/Documentos/Dev" ]]')

    def test_mac_routes_and_new_options_are_linux_only(self):
        self.bash('OS=mac; row ghostty; [[ "$(route)" == cask:ghostty ]]; row jq; [[ -z "$(route)" ]]; row nvm; [[ "$(route)" == native:nvm ]]')

    def test_zorin_routes(self):
        self.bash('PLATFORM_FAMILY=ubuntu; row fd; [[ "$(route)" == apt:fd-find ]]; row cursor; [[ "$(route)" == repo:cursor ]]; row ghostty; [[ "$(route)" == manual:* ]]')

    def test_nvm_reuses_xdg_or_system_install(self):
        nvm = self.home / '.config/nvm'
        nvm.mkdir(parents=True)
        (nvm / 'nvm.sh').write_text('# fixture\n')
        self.bash('row nvm; is_installed')
        result = subprocess.run(['zsh', '-fc', f'source {shlex.quote(str(ROOT / "shell/tools.zsh"))}; [[ "$NVM_DIR" == "$HOME/.config/nvm" ]]'], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_arch_upgrades_once_and_configuration_does_not_update(self):
        result = self.bash('DRY_RUN=1; linux_packages eza; linux_packages bat')
        self.assertEqual(result.stdout.count('pacman -Syu'), 1)
        self.assertEqual(result.stdout.count('pacman -S --needed'), 1)
        result = self.bash('DRY_RUN=1; zsh() { :; }; configure_shell')
        self.assertNotIn('pacman', result.stdout)
        self.assertFalse((self.home / '.zshrc').exists())

    def test_failed_install_is_propagated_and_not_marked_ready(self):
        self.bash('DRY_RUN=1; run() { return 23; }; if linux_packages eza; then exit 1; fi; [[ "$LINUX_READY" == 0 ]]')
        self.bash('linux_packages() { return 23; }; if linux_prerequisites this-command-does-not-exist; then exit 1; fi')

    def test_apt_does_not_use_pacman_or_upgrade(self):
        result = self.bash('DRY_RUN=1; PLATFORM_FAMILY=ubuntu; linux_packages jq; linux_packages bat')
        self.assertEqual(result.stdout.count('apt-get update'), 1)
        self.assertNotIn('pacman', result.stdout)
        self.assertNotIn('upgrade', result.stdout)

    def test_docker_requires_compose(self):
        self.bash('row docker; dockerd() { :; }; docker() { return 1; }; if is_installed; then exit 1; fi; docker() { return 0; }; is_installed')

    def test_docker_client_and_compose_do_not_satisfy_engine(self):
        self.bash('row docker; docker() { :; }; command() { if [[ "$1" == -v && "$2" == dockerd ]]; then return 1; fi; builtin command "$@"; }; if is_installed; then exit 1; fi')

    def test_ubuntu_command_names_and_flatpak(self):
        self.bash('PLATFORM_FAMILY=ubuntu; batcat() { :; }; row bat; is_installed; fdfind() { :; }; row fd; is_installed; mkdir -p "$HOME/.local/share/flatpak/app/com.spotify.Client/current/active"; touch "$HOME/.local/share/flatpak/app/com.spotify.Client/current/active/metadata"; row spotify; is_installed')

    def test_dependencies_match_both_interfaces(self):
        self.bash('is_installed() { return 1; }; CONFIG_GHOSTTY=1; CONFIG_DOCKER=1; CONFIG_FASTFETCH=1; AUTH_GIT=1; selection_dependencies; [[ "${SELECTED[*]}" == "gh docker fastfetch jetbrains-nerd" ]]; selection_dependencies; [[ ${#SELECTED[@]} == 4 ]]')

    def test_manual_is_not_reported_as_installed(self):
        result = self.bash('DRY_RUN=1; PLATFORM_FAMILY=ubuntu; is_installed() { return 1; }; install_option ghostty; [[ "${MANUAL[*]}" == ghostty ]]')
        self.assertIn('https://ghostty.org/', result.stdout)

    def test_linking_is_idempotent_and_backup_preserves_symlink(self):
        target = self.home / '.zshrc'
        target.write_text('old configuration\n')
        self.bash('link_file "$ROOT/shell/.zshrc" "$HOME/.zshrc" zshrc; first="$BACKUP_DIR"; link_file "$ROOT/shell/.zshrc" "$HOME/.zshrc" zshrc; [[ "$BACKUP_DIR" == "$first" ]]; [[ -f "$first/manifest.tsv" ]]; grep -q "old configuration" "$first/zshrc"')
        self.assertTrue(target.is_symlink())

    def test_restore_never_writes_through_current_symlink(self):
        original = self.home / 'original'
        original.write_text('repo content\n')
        target = self.home / '.zshrc'
        target.symlink_to(original)
        backup = self.home / '.local/state/ramon-dotfiles/backups/fixture'
        backup.mkdir(parents=True)
        (backup / 'zshrc').write_text('restored settings\n')
        (backup / 'manifest.tsv').write_text(f'zshrc\t{target}\n')
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen(['bash', str(ROOT / 'scripts/restore.sh'), '--backup', str(backup), '--file', 'zshrc'], env=self.env, stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            os.write(master, b'y\n')
            output, error = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, output + error)
        finally:
            os.close(master)
            os.close(slave)
        self.assertEqual(original.read_text(), 'repo content\n')
        self.assertFalse(target.is_symlink())
        self.assertEqual(target.read_text(), 'restored settings\n')
        self.assertTrue(any(p.is_symlink() for p in backup.parent.glob('*/before-restore-zshrc')))

    def test_ui_every_page_loads_on_all_platforms(self):
        self.bash('source "$ROOT/scripts/ui.sh"; for platform in mac arch ubuntu; do PLATFORM_FAMILY="$platform"; OS=linux; [[ "$platform" != mac ]] || OS=mac; for ((UI_STEP=0;UI_STEP<8;UI_STEP++)); do ui_load_page; [[ ${#UI_IDS[@]} -gt 0 ]]; done; done')

    def test_vendor_dry_run_shows_source_and_propagates_failure(self):
        result = self.bash('DRY_RUN=1; PLATFORM_FAMILY=ubuntu; BASE_CODENAME=noble; linux_repo_present() { return 1; }; linux_repo cursor')
        self.assertIn('downloads.cursor.com/aptrepo', result.stdout)
        self.assertIn('signed-by=', result.stdout)
        self.assertIn('apt-get', result.stdout)
        self.bash('DRY_RUN=1; PLATFORM_FAMILY=ubuntu; linux_repo_present() { return 0; }; linux_packages() { return 23; }; if linux_repo cursor; then exit 1; fi')

    def test_broken_links_make_doctor_fail(self):
        (self.home / '.zshrc').symlink_to(self.home / 'missing')
        result = subprocess.run(['bash', str(ROOT / 'scripts/doctor.sh')], env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Broken link', result.stdout)

    def test_dry_run_does_not_create_home_files(self):
        result = subprocess.run(['bash', str(ROOT / 'bootstrap.sh'), '--dry-run'], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_mac_catalog_routes_are_unchanged(self):
        for name in ('tools', 'apps', 'fonts'):
            original = json.loads(subprocess.check_output(['git', 'show', f'HEAD:catalog/{name}.json'], cwd=ROOT))
            current = {x['id']: x for x in json.loads((ROOT / 'catalog' / f'{name}.json').read_text())}
            for entry in original:
                self.assertEqual(entry['mac'], current[entry['id']]['mac'])

    def test_catalog_is_unique_and_keeps_mac_entries(self):
        ids = []
        for name in ('tools', 'apps', 'fonts'):
            data = json.loads((ROOT / 'catalog' / f'{name}.json').read_text())
            ids += [x['id'] for x in data]
            for row in data:
                self.assertTrue(all(k in row for k in ('mac', 'linux', 'ubuntu', 'flatpak_id')))
        self.assertEqual(len(ids), len(set(ids)))
        # Windows-only additions have no Unix routes; the original Unix catalog stays intact.
        unix = []
        for name in ('tools', 'apps', 'fonts'):
            unix += [x for x in json.loads((ROOT / 'catalog' / f'{name}.json').read_text())
                     if x['mac'] or x['linux'] or x['ubuntu']]
        self.assertEqual(len(unix), 64)


if __name__ == '__main__':
    unittest.main()
