$ErrorActionPreference='Stop'
$workspace=(Resolve-Path '.').Path
$testRoot=Join-Path $workspace 'work\installer-v11.0.1\validation-final-install'
$setup=(Resolve-Path 'outputs\broCodeSetup-11.0.1.exe').Path
$payload=(Resolve-Path 'work\installer-v11.0.1\payload').Path
$registryKey='HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{5047B195-DC09-4DFE-A164-06400B6D1007}_is1'
if(Test-Path -LiteralPath $registryKey){throw 'An installation already uses the new AppId; do not overwrite it during validation.'}
if(Test-Path -LiteralPath $testRoot){throw 'Validation directory already exists.'}
function Install-TestCopy($logName) {
 $log=Join-Path $workspace ('outputs\'+$logName)
 $process=Start-Process -FilePath $setup -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/NOICONS',('/DIR="'+$testRoot+'"'),'/GROUP="broCode v11.0.1 validation"',('/LOG="'+$log+'"')) -WindowStyle Hidden -Wait -PassThru
 if($process.ExitCode -ne 0){throw ('Setup failed: '+$process.ExitCode)}
}
Install-TestCopy 'v11.0.1-install-test.log'
$checks=@()
Get-ChildItem -LiteralPath $payload -File -Recurse | ForEach-Object {
 $relative=$_.FullName.Substring($payload.Length+1)
 $installed=Join-Path $testRoot $relative
 if((Get-FileHash -LiteralPath $_.FullName).Hash -ne (Get-FileHash -LiteralPath $installed).Hash){throw ('Installed payload mismatch: '+$_.Name)}
 $checks+=$relative
}
Push-Location -LiteralPath $testRoot
try {
 $pythonProbe=& cmd.exe /d /c 'python --version 2>&1'
 if($LASTEXITCODE -ne 0 -or $pythonProbe -notmatch 'Python 3.13.17'){throw 'Native speech Python command does not resolve the bundled runtime'}
 & '.\python.exe' -B -c "import numpy,sounddevice,requests;from moonshine_voice import get_model_for_language;from moonshine_voice.transcriber import Transcriber,TranscriptEventListener,ModelArch;assert ModelArch(5).value==5;print('Installed speech runtime passed')"
 if($LASTEXITCODE -ne 0){throw 'Installed speech runtime import failed'}
} finally {Pop-Location}
$installedVersion=(Get-Item -LiteralPath (Join-Path $testRoot 'svchost.exe')).VersionInfo
if($installedVersion.ProductVersion -ne '11.0.1' -or $installedVersion.FileVersion -ne '11.0.1'){throw 'Application version metadata mismatch'}
$registered=Get-ItemProperty -LiteralPath $registryKey
if($registered.DisplayVersion -ne '11.0.1'){throw 'Installed Apps version mismatch'}
$ini=Join-Path $testRoot 'BroCode.local.ini'
$hotkeys=Join-Path $testRoot 'hotkeys.json'
Add-Content -LiteralPath $ini -Value "`r`n[InstallerValidation]`r`nSentinel=preserve-on-upgrade"
Add-Content -LiteralPath $hotkeys -Value ' '
$iniHash=(Get-FileHash -LiteralPath $ini).Hash
$hotkeysHash=(Get-FileHash -LiteralPath $hotkeys).Hash
Install-TestCopy 'v11.0.1-upgrade-test.log'
if((Get-FileHash -LiteralPath $ini).Hash -ne $iniHash -or (Get-FileHash -LiteralPath $hotkeys).Hash -ne $hotkeysHash){throw 'Upgrade overwrote settings'}
$uninstall=Join-Path $testRoot 'unins000.exe'
$uninstallLog=Join-Path $workspace 'outputs\v11.0.1-uninstall-test.log'
$process=Start-Process -FilePath $uninstall -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/LOG="'+$uninstallLog+'"')) -WindowStyle Hidden -Wait -PassThru
if($process.ExitCode -ne 0){throw ('Uninstall failed: '+$process.ExitCode)}
if(Test-Path -LiteralPath (Join-Path $testRoot 'svchost.exe')){throw 'Uninstall left the executable'}
if(Test-Path -LiteralPath $registryKey){throw 'Uninstall left registration'}
if((Get-FileHash -LiteralPath $ini).Hash -ne $iniHash -or (Get-FileHash -LiteralPath $hotkeys).Hash -ne $hotkeysHash){throw 'Uninstall removed personal settings'}
$result=[ordered]@{fresh_install=$true;all_payload_hashes_match=$true;verified_file_count=$checks.Count;bundled_python_native_command_passed=$true;speech_dependencies_import_passed=$true;version='11.0.1';upgrade_preserves_settings=$true;uninstall_removes_program_and_registration=$true;uninstall_preserves_settings=$true;full_app_launched=$false;clean_PC_tested=$false}
$result | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath 'outputs\v11.0.1-installer-tests.json'
$result | ConvertTo-Json -Depth 4
