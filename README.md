# broCode v11.0.1

Windows 10 (2004+) / Windows 11 x64 installer for the current broCode application.

[Download broCodeSetup-11.0.1.exe](https://github.com/SHIVANSH-BHARTI2002/broCode/releases/download/v11.0.1/broCodeSetup-11.0.1.exe) · [Release notes and checksums](https://github.com/SHIVANSH-BHARTI2002/broCode/releases/tag/v11.0.1)

Paste into **PowerShell**:

```powershell
$p = Join-Path $env:TEMP 'broCodeSetup-11.0.1.exe'; Invoke-WebRequest 'https://github.com/SHIVANSH-BHARTI2002/broCode/releases/download/v11.0.1/broCodeSetup-11.0.1.exe' -OutFile $p; Start-Process -FilePath $p
```

Setup installs per user into `%LOCALAPPDATA%\Programs\broCode`, creates a Start Menu shortcut and optional desktop shortcut, handles missing Visual C++ and WebView2 prerequisites, and includes private Python/Moonshine speech dependencies and an uninstaller. Internet is required for online AI, sign-in, first-use speech model downloads, and WebView2 setup when missing. Visual C++ setup may request administrator approval.

Existing application code and features are preserved. The app starts in Chat mode at its existing 0.05 window visibility; increase visibility in settings if needed. Automatic application updates remain disabled.

Personal API keys, tokens, sessions, history, and machine-specific paths are not distributed. Enter your own keys or sign in on each PC. Current shortcut bindings are included. Reinstall and uninstall preserve personal configuration.

Fresh install, all 1,819 payload file hashes, private speech runtime imports, version registration, reinstall preservation, and uninstall checks passed locally and on GitHub's Windows runner. The full app was not tested on a separate desktop PC. The installer is unsigned.

Silent installation:

```cmd
broCodeSetup-11.0.1.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
```

The release includes `README-v11.0.1.md` with additional instructions and `SHA256SUMS-11.0.1.txt` for verification.
