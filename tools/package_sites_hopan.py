#!/usr/bin/env python3
"""Replace Hopan's root export, proving preservation of every other static file."""
import argparse,hashlib,json,shutil,subprocess
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--site',type=Path,required=True);p.add_argument('--build',type=Path,required=True);p.add_argument('--evidence',type=Path,required=True);a=p.parse_args()
source='6b1e4b049cf63d2578e82951dcd6b94c71785950';site=a.site;dist=site/'dist'
assert not subprocess.check_output(['git','status','--porcelain'],cwd=site,text=True)
assert json.loads((site/'.openai/hosting.json').read_text())=={'project_id':'appgprj_6ad43a1975c08191965b198fbd79aac1','static':{'directory':'dist'}}
qa=json.loads((a.evidence/'release-browser.json').read_text());assert not qa['errors'] and len(qa['checks'])==4
campaign=json.loads((a.evidence/'campaign-browser.json').read_text());assert campaign['checks']==20 and campaign['failures']==0 and not campaign['errors']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
old={str(p.relative_to(dist)):sha(p) for p in dist.rglob('*') if p.is_file()};old_build=json.loads((dist/'build.json').read_text());hosting=(site/'.openai/hosting.json').read_bytes();river=json.loads((dist/'riversim/build.json').read_text())
allowed={'build.json'}
for f in a.build.iterdir():
    assert f.is_file() and f.stat().st_size<24*1024*1024
    shutil.copy2(f,dist/f.name);allowed.add(f.name)
build={'game_source_commit':source,'game_source_branch':'main','release_label':'NYC traffic, streetlife assets and six-level campaign','native_checks':217,'browser_campaign_checks':20,'production_browser_checks':qa,'preserved_riversim':{'version':river['version'],'source_commit':river['source_commit']},'previous_hopan_source_commit':old_build['game_source_commit'],'wasm_loader':json.loads((a.evidence/'loader-release.json').read_text())}
(dist/'build.json').write_text(json.dumps(build,indent=2)+'\n')
preserved={}
for n,h in old.items():
    if n not in allowed:assert (dist/n).is_file() and sha(dist/n)==h,n;preserved[n]=h
assert (site/'.openai/hosting.json').read_bytes()==hosting
report={'game_source_commit':source,'preserved_riversim':build['preserved_riversim'],'preserved_files':preserved,'hosting_manifest':'byte-identical','updated_files':{n:sha(dist/n) for n in sorted(allowed)}}
(a.evidence/'preservation.json').write_text(json.dumps(report,indent=2)+'\n')
receipt=site/'.openai/releases/hopan-6b1e4b0.json';receipt.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'source':source,'unrelated_files_preserved':len(preserved),'river':build['preserved_riversim']}))
