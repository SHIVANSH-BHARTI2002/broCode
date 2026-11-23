$ErrorActionPreference='Stop'
$buildRoot=Join-Path $env:GITHUB_WORKSPACE 'work\installer-v11.0.1'
$baseInstall=Join-Path $env:RUNNER_TEMP 'brocode-verified-runtime'
$baseSetup=Join-Path $env:RUNNER_TEMP 'broCodeSetup-10.0.7.exe'
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
New-Item -ItemType Directory -Path outputs -Force | Out-Null
Invoke-WebRequest 'https://github.com/SHIVANSH-BHARTI2002/broCode/releases/download/v10.0.7/broCodeSetup-10.0.7.exe' -OutFile $baseSetup
if((Get-FileHash $baseSetup).Hash -ne '72B58115663DD5238B1FC4CE98B061AF5F6B8CD8B7AEBE7B8C353903DCC45C89'){throw 'Base runtime installer checksum mismatch'}
$process=Start-Process $baseSetup -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/NOICONS',('/DIR="'+$baseInstall+'"')) -WindowStyle Hidden -Wait -PassThru
if($process.ExitCode -ne 0){throw 'Base runtime extraction installation failed'}
$payload=Join-Path $buildRoot 'payload'
New-Item -ItemType Directory -Path $payload -Force | Out-Null
Get-ChildItem -LiteralPath $baseInstall | Where-Object {$_.Name -notlike 'unins*'} | Copy-Item -Destination $payload -Recurse
$process=Start-Process (Join-Path $baseInstall 'unins000.exe') -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -WindowStyle Hidden -Wait -PassThru
if($process.ExitCode -ne 0){throw 'Base runtime temporary install cleanup failed'}
python work/installer-v11.0.1/restore-payload.py
if($LASTEXITCODE -ne 0){throw 'Payload restoration failed'}
$prerequisites=Join-Path $buildRoot 'prerequisites'
New-Item -ItemType Directory -Path $prerequisites -Force | Out-Null
Invoke-WebRequest 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile (Join-Path $prerequisites 'vc_redist.x64.exe')
Invoke-WebRequest 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' -OutFile (Join-Path $prerequisites 'MicrosoftEdgeWebview2Setup.exe')
Get-ChildItem $prerequisites -Filter '*.exe' | ForEach-Object {
 $signature=Get-AuthenticodeSignature $_.FullName
 if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation'){throw 'Prerequisite Microsoft signature verification failed'}
}
$innoSetup=Join-Path $env:RUNNER_TEMP 'innosetup-6.7.3.exe'
Invoke-WebRequest 'https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe' -OutFile $innoSetup
if((Get-FileHash $innoSetup).Hash -ne '9C73C3BAE7ED48D44112A0F48E66742C00090BDB5BEF71D9D3C056C66E97B732'){throw 'Compiler installer checksum mismatch'}
$compilerDirectory=Join-Path $env:RUNNER_TEMP 'brocode-inno-6.7.3'
$process=Start-Process $innoSetup -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/NOICONS',('/DIR="'+$compilerDirectory+'"')) -WindowStyle Hidden -Wait -PassThru
if($process.ExitCode -ne 0){throw 'Compiler setup failed'}
& (Join-Path $compilerDirectory 'ISCC.exe') /Qp (Join-Path $buildRoot 'broCode.iss')
if($LASTEXITCODE -ne 0){throw 'Installer compilation failed'}
