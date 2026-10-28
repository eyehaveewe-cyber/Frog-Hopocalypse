#!/usr/bin/env python3
"""Package both Hopan level runtimes while preserving other Site content."""
import argparse,hashlib,json,shutil,subprocess
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--site',type=Path,required=True);p.add_argument('--stage',type=Path,required=True);p.add_argument('--evidence',type=Path,required=True);p.add_argument('--modern-commit',required=True);p.add_argument('--older-commit',required=True);a=p.parse_args();site=a.site;dist=site/'dist'
assert not subprocess.check_output(['git','status','--porcelain'],cwd=site,text=True)
hosting=(site/'.openai/hosting.json').read_bytes();assert json.loads(hosting)=={'project_id':'appgprj_6ad43a1975c08191965b198fbd79aac1','static':{'directory':'dist'}}
for name in ['menu-browser.json','library-roundtrip.json']:
 q=json.loads((a.evidence/name).read_text());assert not q['errors'] and len(q['checks'])>=4
assert (a.stage/'index.html').exists() and (a.stage/'classic/game/index.html').exists()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before={str(f.relative_to(dist)):sha(f) for f in dist.rglob('*') if f.is_file()};old=json.loads((dist/'build.json').read_text());river=json.loads((dist/'riversim/build.json').read_text())
allowed={'build.json'}
for f in a.stage.rglob('*'):
 if f.is_file():
  n=str(f.relative_to(a.stage));assert not n.startswith('riversim/');assert f.stat().st_size<24*1024*1024
  if n.startswith('classic/'):assert n not in before,'Refuse to overwrite an existing classic route'
  target=dist/n;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(f,target);allowed.add(n)
metadata={'game_source_commit':a.modern_commit,'older_levels_source_commit':a.older_commit,'release_label':'Frog menu and unified level collections','previous_hopan_source_commit':old['game_source_commit'],'preserved_riversim':{'version':river['version'],'source_commit':river['source_commit']},'browser_checks':'See saved source evidence','save_libraries':'Older and NYC editors use separate files; preexisting data is copied without replacing the original.'}
(dist/'build.json').write_text(json.dumps(metadata,indent=2)+'\n')
preserved={}
for name,digest in before.items():
 if name not in allowed:assert (dist/name).is_file() and sha(dist/name)==digest,name;preserved[name]=digest
assert (site/'.openai/hosting.json').read_bytes()==hosting
report={'modern_commit':a.modern_commit,'older_commit':a.older_commit,'preserved_riversim':metadata['preserved_riversim'],'preserved_files':preserved,'hosting_manifest':'byte-identical','updated_files':{n:sha(dist/n) for n in sorted(allowed)}}
(a.evidence/'preservation.json').write_text(json.dumps(report,indent=2)+'\n');f=site/'.openai/releases/hopan-unified-levels.json';f.parent.mkdir(parents=True,exist_ok=True);f.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'preserved_files':len(preserved),'river':metadata['preserved_riversim'],'modern':a.modern_commit,'older':a.older_commit}))
