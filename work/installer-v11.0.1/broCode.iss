#define AppVersion "11.0.1"
[Setup]
AppId={{5047B195-DC09-4DFE-A164-06400B6D1007}
AppName=broCode
AppVersion={#AppVersion}
AppVerName=broCode v{#AppVersion}
AppPublisher=SHIVANSH-BHARTI2002
AppPublisherURL=https://github.com/SHIVANSH-BHARTI2002/broCode
AppSupportURL=https://github.com/SHIVANSH-BHARTI2002/broCode/issues
AppUpdatesURL=https://github.com/SHIVANSH-BHARTI2002/broCode/releases
DefaultDirName={localappdata}\Programs\broCode
DefaultGroupName=broCode
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.19041
OutputDir=..\..\outputs
OutputBaseFilename=broCodeSetup-11.0.1
VersionInfoVersion=11.0.1.0
VersionInfoProductName=broCode
VersionInfoProductVersion=11.0.1
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
UninstallDisplayName=broCode
UninstallDisplayIcon={app}\svchost.exe
CloseApplications=yes
RestartApplications=no
SetupLogging=yes

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[Files]
Source: "payload\*"; DestDir: "{app}"; Excludes: "hotkeys.json,BroCode.local.ini,*.pyc"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "payload\hotkeys.json"; DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "payload\BroCode.local.ini"; DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "prerequisites\vc_redist.x64.exe"; Flags: dontcopy
Source: "prerequisites\MicrosoftEdgeWebview2Setup.exe"; Flags: dontcopy

[Icons]
Name: "{group}\broCode"; Filename: "{app}\svchost.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall broCode"; Filename: "{uninstallexe}"
Name: "{autodesktop}\broCode"; Filename: "{app}\svchost.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\svchost.exe"; WorkingDir: "{app}"; Description: "Launch broCode"; Flags: nowait postinstall skipifsilent runasoriginaluser; Check: RuntimesReady

[Code]
var
  PrerequisiteRestart: Boolean;

function HasVCRuntime: Boolean;
var
  Installed, Major, Minor, Build: Cardinal;
  Key: String;
begin
  Key := 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64';
  Result := RegQueryDWordValue(HKLM64, Key, 'Installed', Installed) and (Installed = 1)
    and RegQueryDWordValue(HKLM64, Key, 'Major', Major)
    and RegQueryDWordValue(HKLM64, Key, 'Minor', Minor)
    and RegQueryDWordValue(HKLM64, Key, 'Bld', Build);
  if Result then
    Result := (Major > 14) or ((Major = 14) and ((Minor > 44) or ((Minor = 44) and (Build >= 35211))));
end;

function HasWebViewAt(Root: Integer; Key: String): Boolean;
var
  Version: String;
begin
  Result := RegQueryStringValue(Root, Key, 'pv', Version) and (Version <> '') and (Version <> '0.0.0.0');
end;

function HasWebView: Boolean;
var
  Key: String;
begin
  Key := 'Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}';
  Result := HasWebViewAt(HKCU, Key) or HasWebViewAt(HKLM32, Key) or HasWebViewAt(HKLM64, Key);
end;

function RuntimesReady: Boolean;
begin
  Result := HasVCRuntime and HasWebView and not PrerequisiteRestart;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Code: Integer;
begin
  Result := '';
  if not HasVCRuntime then begin
    WizardForm.StatusLabel.Caption := 'Installing Microsoft Visual C++ runtime...';
    ExtractTemporaryFile('vc_redist.x64.exe');
    if not ShellExec('runas', ExpandConstant('{tmp}\vc_redist.x64.exe'), '/install /quiet /norestart', '', SW_HIDE, ewWaitUntilTerminated, Code) then begin
      Result := 'Microsoft Visual C++ runtime installation was not completed. Allow the Windows administrator prompt, then try again.';
      Exit;
    end;
    if (Code <> 0) and (Code <> 3010) then begin
      Result := 'Microsoft Visual C++ runtime installation failed (code ' + IntToStr(Code) + ').';
      Exit;
    end;
    if Code = 3010 then begin
      PrerequisiteRestart := True;
      NeedsRestart := True;
    end;
    if not HasVCRuntime then begin
      Result := 'The required Microsoft Visual C++ x64 runtime could not be detected. Restart Windows if requested, then run setup again.';
      Exit;
    end;
  end;
  if not HasWebView then begin
    WizardForm.StatusLabel.Caption := 'Installing Microsoft Edge WebView2 runtime...';
    ExtractTemporaryFile('MicrosoftEdgeWebview2Setup.exe');
    if not Exec(ExpandConstant('{tmp}\MicrosoftEdgeWebview2Setup.exe'), '/silent /install', '', SW_HIDE, ewWaitUntilTerminated, Code) then begin
      Result := 'WebView2 setup could not start. Check your internet connection and try again.';
      Exit;
    end;
    if not HasWebView then begin
      Result := 'Microsoft Edge WebView2 installation did not finish (code ' + IntToStr(Code) + '). Check your internet connection and run setup again.';
      Exit;
    end;
  end;
end;

function NeedRestart: Boolean;
begin
  Result := PrerequisiteRestart;
end;
