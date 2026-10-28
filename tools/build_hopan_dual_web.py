#!/usr/bin/env python3
"""Assemble two Hopan runtimes on one origin without overwriting either build."""
import argparse,hashlib,json,shutil
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--modern',type=Path,required=True);p.add_argument('--classic',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--debug',action='store_true');a=p.parse_args()
assert (a.modern/'index.html').is_file() and (a.classic/'index.html').is_file()
assert not a.output.exists(), 'Choose an empty output path; existing artifacts are never deleted.'
a.output.mkdir(parents=True)
for f in a.modern.iterdir():
    if f.is_file():shutil.copy2(f,a.output/f.name)
game=a.output/'classic/game';game.mkdir(parents=True)
for f in a.classic.iterdir():
    if f.is_file():shutil.copy2(f,game/f.name)
html='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><link rel="icon" href="/index.icon.png"><title>Hopán levels</title><style>html,body{margin:0;height:100%;background:#10271f;color:#f3e9c7;font:14px system-ui}body{display:flex;flex-direction:column}nav{box-sizing:border-box;min-height:38px;display:flex;align-items:center;gap:20px;padding:4px 12px}a{color:#e5efaa;font-weight:700;padding:5px}iframe{border:0;width:100%;flex:1;min-height:0}</style></head><body><nav><a href="/?levels=1">← Level collections</a><span>Hopán</span></nav><iframe title="Classic Hopán game" src="game/" allow="autoplay; fullscreen; gamepad" allowfullscreen></iframe></body></html>'
html=html.replace('src="game/"', 'id="hopan-game"')
script = '<script>const frame=document.getElementById("hopan-game"),p=new URLSearchParams(location.search),s=p.get("set"),q=new URLSearchParams();if(s&&["baby","human","bonus","tile","sync"].includes(s))q.set("set",s);if(' + json.dumps(a.debug) + ')q.set("browser-test","1");frame.src="game/"+(q.size?"?"+q.toString():"");window.addEventListener("message",e=>{if(e.origin===location.origin&&e.source===frame.contentWindow&&e.data&&e.data.type==="hopan-return-levels")location.assign("/?levels=1")});</script>'
html=html.replace('</body></html>',script+'</body></html>')
(a.output/'classic/index.html').write_text(html)
files={str(f.relative_to(a.output)):{'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in a.output.rglob('*') if f.is_file()}
assert all(r['bytes']<24*1024*1024 for r in files.values())
print(json.dumps({'files':len(files),'classic_route':'/classic/','source_files':files},indent=2))
