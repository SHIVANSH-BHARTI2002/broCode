from pathlib import Path
import json,lzma,tarfile,hashlib,io
root=Path('work/installer-v11.0.1');payload=root/'payload'
blob=(root/'application.tar.xz').read_bytes()
assert hashlib.sha256(blob).hexdigest()=='5948a1d2e0ee36ebeccec5ed15b39d98863567d2160dc34498cb8295e5aec7b1'
allowed={'svchost.exe','BroQuickSwitch.dll','Dll1.dll','MinHook.x64.dll','sysblend.dll','syscheck.dll','wdaclr.dll','WebView2Loader.dll','BroCode.local.ini','hotkeys.json'}
with tarfile.open(fileobj=io.BytesIO(lzma.decompress(blob)),mode='r:') as t:
    assert {m.name for m in t.getmembers()}==allowed
    for m in t.getmembers():
        assert m.isfile() and m.name in allowed
        (payload/m.name).write_bytes(t.extractfile(m).read())
files=[]
for p in sorted(payload.rglob('*')):
    if p.is_file():files.append({'name':p.relative_to(payload).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
lines=''.join(x['name']+'\0'+x['sha256']+'\n' for x in sorted(files,key=lambda x:x['name']))
assert len(files)==1819
assert hashlib.sha256(lines.encode()).hexdigest()=='378e536399ecd9feb29e406fbdc0520551ce66828acd47cdc79e7cffb7fdeb45','Payload differs from locally verified build'
Path('outputs/v11.0.1-payload-manifest.json').write_text(json.dumps({'version':'v11.0.1','all_payload_bytes_match_locally_verified_build':True,'files':files},indent=2))
print('Verified all 1819 payload files match the locally tested build.')
