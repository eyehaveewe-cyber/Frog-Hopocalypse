/* Play the real Skate Escape through menu and keyboard. Only hopanState is read. */
const {chromium}=require('playwright');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const qa=require('./city_journey_browser.cjs');const {execFileSync}=require('node:child_process');
const out='docs/skate-frog-evidence';fs.mkdirSync(out,{recursive:true});
const checks=[],errors=[],observations=[];
function check(ok,text){assert.ok(ok,text);checks.push(text);console.log('PASS: '+text);}
async function screenshot(page,name){await page.screenshot({path:path.join(out,name+'.png')});}
(async()=>{
 const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 try{
  const videoStart=Date.now();const options={viewport:{width:1280,height:800}};if(process.env.HOPAN_RECORD_VIDEO==='1')options.recordVideo={dir:'/tmp/hopan-skate-frog-video',size:{width:1280,height:800}};
  const context=await browser.newContext(options);
  await context.addInitScript(()=>localStorage.setItem('hopan.profile.v1',JSON.stringify({version:1,baby:[0,1,2,3],human:[0,1,2,3],bonus:[],tile:[],sync:[],city:{nyc:[],streetlife:[],city_journey:[0]},hat:'none',skin:'green',preview:false,sound:false,seen_rules:[]})));
  const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  await page.goto((process.env.HOPAN_TEST_URL||'http://127.0.0.1:8125/')+'?browser-test=1&splash=6');await qa.ready(page);await qa.choose(page,1);const clipStart=(Date.now()-videoStart)/1000;
  let state=await qa.state(page);
  check(state.journey.rider_pose==='standing'&&state.journey.movement==='skate','Third City Journey level loads with a standing skateboard frog');
  await screenshot(page,'standing-frog');
  for(const [name,key,side] of [['left','a',-1],['right','d',1]]){
   await page.keyboard.press('r');await page.waitForFunction(()=>!hopanState.result&&!hopanState.overlay&&!hopanState.begin_pending);
   await page.keyboard.down('w');await page.waitForTimeout(400);await page.keyboard.down('Space');
   await page.waitForFunction(()=>hopanState.journey.airborne,null,{timeout:4000});
   await page.keyboard.down(key);
   await page.waitForFunction(side=>hopanState.journey.trick_direction===side,side,{timeout:4000});
   state=await qa.state(page);observations.push({action:name,elapsed:state.elapsed,journey:state.journey});
   check(state.journey.rider_pose==='trick_'+name&&state.journey.trick_name===(side<0?'kickflip':'shove-it'),'Airborne '+name+' input starts its matching Zendelves trick');
   await screenshot(page,'airborne-'+name);
   await page.keyboard.up(key);await page.keyboard.up('w');await page.keyboard.up('Space');
   await page.waitForFunction(()=>!hopanState.journey.airborne&&hopanState.journey.rider_pose==='standing',null,{timeout:6000});
   check((await qa.state(page)).journey.trick_direction===0,name+' landing restores the standing pose');
  }
  check(errors.length===0,'No captured browser or Godot console errors');
  fs.writeFileSync(path.join(out,'browser.json'),JSON.stringify({checks,errors,observations,scope:'Real Skate Escape via normal menus and keyboard; saved-profile fixture unlocks the existing stage. Chromium software rendering; no physical device or human animation-quality claim.'},null,2)+'\n');
  const video=page.video();await context.close();if(video){const raw=await video.path();execFileSync('/usr/bin/ffmpeg',['-loglevel','error','-ss',clipStart.toFixed(2),'-i',raw,'-t','8','-an','-vf','scale=960:-2','-c:v','libvpx-vp9','-crf','38','-b:v','0','-y',path.join(out,'skate-tricks.webm')]);}
 }finally{await browser.close();}
})().catch(e=>{console.error(e.stack);process.exitCode=1;});
