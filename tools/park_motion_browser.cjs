/* Real editor import/playtest of production modules. These small fixtures are
 * animation/control test scenes, not claimed campaign route completions. */
const {chromium}=require('playwright');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const qa=require('./city_journey_browser.cjs');
const {execFileSync}=require('node:child_process');
const out='docs/ice-skate-evidence';
const captures=[],checks=[],samples=[],errors=[];
async function check(ok,text){assert.ok(ok,text);checks.push(text);console.log('PASS: '+text);}
async function importScene(browser,name){
 const videoStart=Date.now();
 const options={viewport:{width:1280,height:800}};if(name==='park_motion'&&process.env.HOPAN_RECORD_VIDEO==='1')options.recordVideo={dir:'/tmp/hopan-park-motion-video-20261029',size:{width:1280,height:800}};
 const context=await browser.newContext(options),page=await context.newPage();
 page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 await page.goto('http://127.0.0.1:8115/?browser-test=1&splash=6');await qa.ready(page);console.log('READY '+name);
 await qa.click(page,'Level editor · Create a maze');console.log('EDITOR '+name);await qa.click(page,'Import');console.log('IMPORT '+name);
 const [chooser]=await Promise.all([page.waitForEvent('filechooser',{timeout:20000}),qa.click(page,'Open JSON file')]);console.log('FILECHOOSER '+name);
 await chooser.setFiles(path.resolve('game/tests/fixtures/'+name+'.json'));
 await page.waitForFunction(()=>hopanState.mode==='edit'&&!hopanState.overlay&&hopanState.map.name.startsWith('Runtime test scene'),null,{timeout:30000});
 await qa.click(page,'Playtest ▶');
 await page.waitForFunction(()=>hopanState.mode==='test'&&(!hopanState.overlay||hopanState.buttons.some(b=>b.text==='Play')),null,{timeout:30000});
 if((await qa.state(page)).buttons.some(b=>b.text==='Play'))await qa.click(page,'Play');
 await page.waitForFunction(()=>!hopanState.overlay&&!hopanState.intro_active&&!hopanState.begin_pending);
 return {context,page,videoStart};
}
async function capture(page,name){const file=path.join(out,name+'.png');await page.screenshot({path:file});captures.push(file);}
(async()=>{
 const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 try{
  if(!process.env.MOTION_ONLY){
  const park=await importScene(browser,'park_motion');
  const clipStart=(Date.now()-park.videoStart)/1000;
  await check((await qa.state(park.page)).park_poses.length===3,'Editor playtest runs all three revised park encounter modules');
  for(const phase of ['seed','feed','return']){
   await park.page.waitForFunction(phase=>hopanState.park_poses.some(e=>e.kind==='pigeons'&&e.state===phase),phase,{timeout:20000});
   const snapshot=await qa.state(park.page);samples.push({capture:phase,state:{elapsed:snapshot.elapsed,park_poses:snapshot.park_poses,status:snapshot.status}});await capture(park.page,'park-cycle-'+['seed','feed','return'].indexOf(phase));
  }
  await park.page.waitForFunction(()=>hopanState.park_poses.some(e=>e.kind==='purse'&&e.state==='attack'),null,{timeout:20000});await capture(park.page,'park-actors');
  await check(!(await qa.state(park.page)).result,'Seed, feeding and return loop renders while safe sidestep remains available');
  await park.page.waitForTimeout(6000);
  const video=park.page.video();await park.context.close();
  if(video){const raw=await video.path();const clip=path.join(out,'park-cycle.webm');execFileSync('/usr/bin/ffmpeg',['-loglevel','error','-ss',clipStart.toFixed(2),'-i',raw,'-t','8','-an','-c:v','libvpx-vp9','-crf','38','-b:v','0','-vf','scale=960:-2','-y',clip]);captures.push(clip);}
  const bridge=await importScene(browser,'bridge_motion');
  await bridge.page.keyboard.down('w');await bridge.page.waitForTimeout(1300);await bridge.page.keyboard.up('w');
  const states=[];for(let i=0;i<35;i++){const s=await qa.state(bridge.page);states.push(s.stunt_poses);await bridge.page.waitForTimeout(90);}
  await bridge.page.waitForFunction(()=>hopanState.stunt_poses.some(r=>r.position[2]>6&&r.height>2.5),null,{timeout:20000});await capture(bridge.page,'bridge-rail-hoppers');
  await check(states.some(group=>group.some(r=>r.state==='grind'))&&states.some(group=>group.some(r=>r.height>3)),'Actual browser shows both rail grinding and airborne overpass riders');
  samples.push({bridge:states});await bridge.context.close();
  }
  const rail=await importScene(browser,'highway_grind');
  await rail.page.keyboard.down('g');await rail.page.keyboard.down('w');
  await rail.page.waitForFunction(()=>hopanState.journey.grinding,null,{timeout:20000});
  await rail.page.keyboard.up('g');await rail.page.keyboard.up('w');await capture(rail.page,'highway-grind-play');
  await check((await qa.state(rail.page)).journey.grinding,'G latches the real raised rail and stays latched on key release');
  await rail.page.keyboard.down('Space');await rail.page.waitForFunction(()=>hopanState.journey.airborne&&!hopanState.journey.grinding,null,{timeout:5000});await rail.page.keyboard.up('Space');
  await check((await qa.state(rail.page)).journey.airborne,'Space physically releases the browser grind');
  await rail.context.close();await check(errors.length===0,'No browser or engine errors in imported animation/control fixtures');
  fs.writeFileSync(path.join(out,process.env.MOTION_ONLY?'grind-browser.json':'motion-browser.json'),JSON.stringify({checks,errors,captures,samples,scope:'Actual production modules through normal editor file import, playtest and keyboard input. Purpose-built test scenes, not campaign completions.'},null,2)+'\n');
 }finally{await browser.close();}
})().catch(e=>{console.error(e.stack);process.exitCode=1;});
