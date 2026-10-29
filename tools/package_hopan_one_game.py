#!/usr/bin/env python3
"""Package the single Hopán export without changing RiverSim or hosting settings."""
import argparse, hashlib, json, shutil
from pathlib import Path
parser = argparse.ArgumentParser()
parser.add_argument('site', type=Path)
parser.add_argument('build', type=Path)
parser.add_argument('source_commit')
parser.add_argument('--release-label', default='One Hopán game, Baby Mode first')
parser.add_argument('--evidence', default='docs/one-game-evidence/')
args = parser.parse_args()
if len(args.source_commit) != 40 or any(c not in '0123456789abcdef' for c in args.source_commit):
    parser.error('source_commit must be a full Git commit SHA')
site, build = args.site.resolve(), args.build.resolve()
dist = site / 'dist'
manifest = site / '.openai/hosting.json'
config = json.loads(manifest.read_text())
assert config['project_id'] == 'appgprj_6ad43a1975c08191965b198fbd79aac1'
assert config['static']['directory'] == 'dist'
assert (dist/'riversim').is_dir()
assert (build/'index.wasm').read_bytes()[:2] == b'\x1f\x8b'
for name in ['index.html','index.js','index.pck','index.wasm','hopan-wasm.js']:
    assert (build/name).is_file(), name
assert 'hopan-wasm.js' in (build/'index.html').read_text()
assert all(f.stat().st_size < 24*1024*1024 for f in build.iterdir() if f.is_file())
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def unrelated():
    return {str(f.relative_to(site)):digest(f) for f in [manifest,*sorted((dist/'riversim').rglob('*'))] if f.is_file()}
before = unrelated()
previous = json.loads((dist/'build.json').read_text())
for f in build.iterdir():
    if f.is_file(): shutil.copyfile(f, dist/f.name)
old = dist/'classic'
if old.exists(): shutil.rmtree(old)
redirect = '<!doctype html><meta charset="utf-8"><title>Hopán</title><meta http-equiv="refresh" content="0;url=/"><script>location.replace("/")</script><a href="/">Play Hopán</a>\n'
for path in [old/'index.html',old/'game/index.html']:
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(redirect)
(dist/'build.json').write_text(json.dumps({
    'game_source_commit':args.source_commit,
    'release_label':args.release_label,
    'campaign_levels':36,
    'preserved_riversim':previous['preserved_riversim'],
    'save_libraries':'One editor imports both previous libraries; existing backups retained.',
    'evidence':args.evidence
},indent=2)+'\n')
assert unrelated() == before
print(json.dumps({'preserved_files':len(before),'preserved_hashes':before,'source_commit':args.source_commit},indent=2))
