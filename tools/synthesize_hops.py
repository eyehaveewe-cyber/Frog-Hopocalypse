"""Original procedural Hopan effects; no recordings or third-party samples. CC0."""
from pathlib import Path
import math,random,wave,struct,json,hashlib
ROOT=Path(__file__).resolve().parents[1]/'game/audio/hop'
ROOT.mkdir(parents=True,exist_ok=True)
rate=24000;stats=[]
for palette in ['soft','retro']:
 for event in ['takeoff','landing']:
  for variant in range(3):
   rng=random.Random(721+variant+(event=='landing')*20+(palette=='retro')*100)
   duration=(.115 if event=='takeoff' else .095) if palette=='soft' else (.14 if event=='takeoff' else .11)
   phase=0.;low=0.;samples=[]
   for i in range(int(rate*duration)):
    t=i/rate;p=t/duration
    frequency=(170+350*p if event=='takeoff' else 170-95*p)*(1+(variant-1)*.035)
    if palette=='retro':frequency=(240+530*p if event=='takeoff' else 210-110*p)*(1+(variant-1)*.03)
    phase+=2*math.pi*frequency/rate
    low+=.23*(rng.uniform(-1,1)-low)
    envelope=min(1,t/.004)*min(1,(duration-t)/.015)*math.exp(-p*(3 if event=='takeoff' else 5))
    v=(math.sin(phase)*(.38 if palette=='soft' else .65)+low*(1.4 if palette=='soft' else .45))*envelope
    samples.append(v)
   peak=max(map(abs,samples));samples=[s*.48/peak for s in samples]
   path=ROOT/f'{palette}_{event}_{variant}.wav'
   with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(b''.join(struct.pack('<h',round(s*32767)) for s in samples))
   stats.append({'file':path.name,'duration':duration,'sample_peak_dbfs':20*math.log10(max(map(abs,samples))),'rms_dbfs':20*math.log10(math.sqrt(sum(s*s for s in samples)/len(samples))),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
(ROOT/'measurements.json').write_text(json.dumps(stats,indent=2)+'\n')
