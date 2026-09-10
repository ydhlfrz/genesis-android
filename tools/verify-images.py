from pathlib import Path
import hashlib,json,sys,zipfile
root=Path(__file__).resolve().parents[1]
assets=root/'app/src/main/assets'
manifest=json.loads((assets/'image-manifest.json').read_text())
assert len(manifest)==45, 'Expected 43 race images and 2 branding images'
archive=zipfile.ZipFile(sys.argv[1]) if len(sys.argv)>1 else None
for name,digest in manifest.items():
    data=archive.read('assets/'+name) if archive else (assets/name).read_bytes()
    assert data.startswith(b'\x89PNG\r\n\x1a\n'), name+' is not PNG'
    assert hashlib.sha256(data).hexdigest()==digest, name+' is missing or changed'
print('PASS: all 45 required images verified in '+('APK' if archive else 'source'))
