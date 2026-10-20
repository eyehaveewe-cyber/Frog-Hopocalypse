"""Package the local standalone Godot Web export; does not publish a Site."""
from pathlib import Path
import hashlib,json,subprocess,zipfile
root=Path(__file__).resolve().parents[1]
build=root/'build/web';out=root/'artifacts';out.mkdir(exist_ok=True)
sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
files=sorted(p for p in build.rglob('*') if p.is_file())
assert (build/'index.html').is_file() and (build/'index.wasm').stat().st_size>1000000
manifest={'game_source_commit':sha,'engine':'Godot 4.7.2','scope':'Standalone Web game; local comparison only. No RiverSim or Site source included. Do not replace the whole Site with this archive.','export_sha256':{str(p.relative_to(build)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
archive=out/'hopan-hop-feel-web.zip'
def put(z,name,data):
 info=zipfile.ZipInfo(name,date_time=(2026,10,20,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o644<<16;z.writestr(info,data)
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for p in files:put(z,str(p.relative_to(build)),p.read_bytes())
 put(z,'SOURCE.json',json.dumps(manifest,indent=2).encode())
 put(z,'SOUND_ATTRIBUTION.md',(root/'game/audio/hop/ATTRIBUTION.md').read_bytes())
 put(z,'PLAY.txt',b'''Hopan requested hop feel comparison - local standalone Web build
Unzip the whole archive, open a terminal in that folder, and run:
  python3 -m http.server 8000
Then visit http://127.0.0.1:8000 in a browser. Opening index.html as a file will not load WASM.
Choose Hop feel comparison from the menu or Pause. Smooth/Stepped (12 poses/s),
Soft/Retro original sound palettes, and hop volume can be compared in one session.
To try Tile Hop without campaign progress: Level editor > Movement demos >
Big Hop Boulevard > Playtest. Space then direction or the Long hop button arms it.
Sound Off mutes voices and effects. Settings are session-only except global Sound.
This is not a live Site deployment package. It does not include RiverSim.
The existing public Site remains version 26. No paid or downloaded sounds.
''')
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 for p in files:assert z.read(str(p.relative_to(build)))==p.read_bytes()
record={'archive':archive.name,'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'game_source_commit':sha,'export_files':len(files),'verification':'every archived export file matched build bytes; ZIP CRC checks pass'}
(out/'hopan-hop-feel-web.json').write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps(record))
