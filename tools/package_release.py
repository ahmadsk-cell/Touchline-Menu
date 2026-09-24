"""Verify and package the curated repository with Python's standard library."""
import hashlib,json
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED

ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'manifest.json').read_text())
files=[]
for entry in manifest['files']:
    p=(ROOT/entry['path']).resolve()
    assert p.is_relative_to(ROOT),entry['path']
    assert p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'],entry['path']
    assert p.stat().st_size==entry['size'],entry['path']
    files.append(p)
for name in ['README.md','CREDITS.md','CHANGELOG.md','Install.cmd','Install.ps1','Uninstall.ps1','manifest.json','VERIFICATION.json']:
    files.append(ROOT/name)
for folder in ['scripts','docs/images','artwork','tools','tests']:
    files.extend(p for p in (ROOT/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts)
assert len(files)==len(set(files))
dist=ROOT/'dist';dist.mkdir(exist_ok=True)
out=dist/f"Touchline-Menu-v{manifest['version']}.zip"
with ZipFile(out,'w',ZIP_DEFLATED,compresslevel=6) as z:
    for p in sorted(files):z.write(p,p.relative_to(ROOT).as_posix())
with ZipFile(out) as z:
    assert z.testzip() is None
    for entry in manifest['files']:
        assert hashlib.sha256(z.read(entry['path'])).hexdigest()==entry['sha256']
checksum=hashlib.sha256(out.read_bytes()).hexdigest()
(dist/'SHA256SUMS.txt').write_text(f'{checksum}  {out.name}\n',encoding='ascii')
print(f'{out.name}: {out.stat().st_size:,} bytes; {len(manifest["files"])} verified payload files')
print(f'SHA-256: {checksum}')
