from pathlib import Path
import hashlib,json
out=Path('outputs');version='11.0.1';name=f'broCodeSetup-{version}.exe'
sha=hashlib.sha256((out/name).read_bytes()).hexdigest()
url=f'https://github.com/SHIVANSH-BHARTI2002/broCode/releases/download/v{version}/{name}'
command=f"$p = Join-Path $env:TEMP '{name}'; Invoke-WebRequest '{url}' -OutFile $p; Start-Process -FilePath $p"
checks=json.loads((out/'v11.0.1-installer-tests.json').read_text())
assert checks['fresh_install'] and checks['all_payload_hashes_match'] and checks['upgrade_preserves_settings'] and checks['uninstall_removes_program_and_registration']
notes=f'''Windows installer for the latest broCode build, preserving the current application code and functionality. Packaged Windows version metadata: **v{version}**.

Download **{name}** and run it, or paste this into **PowerShell**:

```powershell
{command}
```

Windows 10 (version 2004+) / Windows 11, x64. Setup installs into `%LOCALAPPDATA%\\Programs\\broCode`, creates a Start Menu shortcut and optional desktop shortcut, and includes an uninstaller. Missing Microsoft Visual C++ and WebView2 runtimes are handled by setup. WebView2 installation requires internet, and Visual C++ setup may request administrator approval.

Private Python 3.13.17, Moonshine Voice 0.1.5, and speech dependencies are included. Speech models use the app's existing first-use download behavior. No system Python installation or PATH change is needed.

Includes the latest Chat/Interview Markdown display and fixed Interview message bar, existing Interview language/approach controls and prompt, audio controls, Dual mode, provider support, light theme, visibility defaults, and saved shortcuts. Automatic application updates remain disabled. The app starts in Chat mode at the existing 0.05 window visibility; increase visibility in settings if needed.

Personal API keys, tokens, sign-in sessions, chat history, backups, and machine-specific paths are excluded. Enter your own API keys or sign in on each PC. Current shortcut bindings are included; reinstall and uninstall preserve personal configuration.

**Verified on the build PC:** Windows Security payload scan completed without detections; fresh installation; all {checks['verified_file_count']:,} payload hashes; version registration; private Python command resolution; speech imports; reinstall preserves settings; uninstall removes program/registration and preserves settings. Native Markdown rendering, Interview scrolling, and fixed-footer resize checks also passed.

The installer is unsigned. Full application behavior on a separate clean PC was not tested; microphone permissions, graphics support, network access, and account access still apply.

Installer SHA-256: `{sha}`.

See `README-v{version}.md` for additional install instructions and `SHA256SUMS-{version}.txt` for checksums.
'''
(out/f'release-notes-v{version}.md').write_text(notes)
readme=f'''# broCode v{version} for Windows

{notes}

## From Command Prompt or Windows Run

```cmd
powershell -NoProfile -Command "{command}"
```

## Verify the downloaded installer

```powershell
(Get-FileHash (Join-Path $env:TEMP '{name}') -Algorithm SHA256).Hash
```

Compare it with the SHA-256 above before running setup.

## Silent installation

```cmd
{name} /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
```

Silent installation does not launch broCode. A missing Visual C++ runtime may still require administrator approval. Use the broCode Start Menu shortcut after installation.

## Existing installations

This updates the existing per-user broCode installer registration. Older machine-wide installations remain separate. Your manually maintained source folder is unchanged. Configuration already present in the selected installation folder takes precedence over packaged defaults.
'''
(out/f'README-v{version}.md').write_text(readme)
assets=[name,f'README-v{version}.md']
(out/f'SHA256SUMS-{version}.txt').write_text(''.join(f'{hashlib.sha256((out/n).read_bytes()).hexdigest()}  {n}\n' for n in assets))
print('Release documentation and installer checksums generated after installation tests passed.')
