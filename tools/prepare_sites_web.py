#!/usr/bin/env python3
"""Apply Hopan's established Sites gzip loader to a completed Web export."""
import argparse,gzip,hashlib,json
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('directory',type=Path);a=p.parse_args()
wasm=a.directory/'index.wasm';raw=wasm.read_bytes();assert raw[:4]==b'\0asm'
wasm.write_bytes(gzip.compress(raw,compresslevel=9,mtime=0))
html=a.directory/'index.html';s=html.read_text();needle='<script src="index.js"></script>';assert s.count(needle)==1
html.write_text(s.replace(needle,'<script src="hopan-wasm.js"></script>\n'+needle))
(a.directory/'hopan-wasm.js').write_bytes(Path(__file__).with_name('sites-wasm-loader.js').read_bytes())
assert all(x.stat().st_size<24*1024*1024 for x in a.directory.iterdir() if x.is_file())
print(json.dumps({'raw_wasm_sha256':hashlib.sha256(raw).hexdigest(),'raw_bytes':len(raw),'gzip_bytes':wasm.stat().st_size,'fallback':'streaming gzip signature sniff; works with or without server gzip decoding'}))
