/* Browser acceptance for City Journey. Only real UI/input events drive play.
 * The debug export exposes read-only observations. A second context supplies an
 * existing saved profile to test the unlocked skate level, not to claim a win.
 */
const {chromium} = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const out = 'docs/city-journey-evidence';
const debugURL = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8115/';
const releaseURL = process.env.HOPAN_RELEASE_URL || 'http://127.0.0.1:8116/';
const checks=[], errors=[], screenshots=[], observations=[];
fs.mkdirSync(out,{recursive:true});
const levels=['city_journey_01_blocks_park.json','city_journey_02_skate_escape.json'].map(file=>JSON.parse(fs.readFileSync('game/levels/'+file)));
function check(ok,message){assert.ok(ok,message);checks.push(message);console.log('PASS: '+message);}
function listen(page){page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});}
async function state(page){return page.evaluate(()=>window.hopanState);}
async function ready(page){await page.waitForFunction(()=>window.hopanState&&!document.getElementById('loading'),null,{timeout:120000});}
async function clickWhere(page, choose, touch=false){
 for(let attempt=0;attempt<75;attempt++){
  const s=await state(page),b=choose(s);if(!b){await page.waitForTimeout(160);continue;}
  const c=await page.locator('canvas').boundingBox();
  const x=c.x+b.x*c.width/s.ui_size[0],y=c.y+b.y*c.height/s.ui_size[1];
  if(b.y>24&&b.y<s.ui_size[1]-24){if(touch)await page.touchscreen.tap(x,y);else await page.mouse.click(x,y);await page.waitForTimeout(350);return;}
  await page.mouse.move(c.x+c.width*.65,c.y+c.height*.55);await page.mouse.wheel(0,b.y<24?-180:180);await page.waitForTimeout(160);
 }
 throw Error('Requested game button unavailable in viewport');
}
async function click(page,text,touch=false){await clickWhere(page,s=>s.buttons.find(b=>b.text===text),touch);}
async function openJourney(page,touch=false){
 const s=await state(page);
 if(!s.buttons.some(b=>b.text==='Levels'))await click(page,'Menu',touch);
 await click(page,'Levels',touch);
 await clickWhere(page,s=>{const row=s.buttons.find(b=>b.text==='City Journey');return row&&s.buttons.find(b=>b.text==='+'&&Math.abs(b.y-row.y)<3);},touch);
}
async function choose(page,index,touch=false){
 await openJourney(page,touch);await click(page,'Play · '+levels[index].name,touch);
 await page.waitForFunction(()=>hopanState.mode==='play'&&(!hopanState.overlay||hopanState.buttons.some(b=>b.text==='Play')),null,{timeout:30000});
 if((await state(page)).buttons.some(b=>b.text==='Play'))await click(page,'Play',touch);
 await page.waitForFunction(()=>!hopanState.overlay&&!hopanState.intro_active&&!hopanState.begin_pending,null,{timeout:30000});
}
async function shot(page,name){const file=path.join(out,name+'.png');await page.screenshot({path:file});screenshots.push(file);}
async function keyFor(page,key,ms){await page.keyboard.down(key);await page.waitForTimeout(ms);await page.keyboard.up(key);await page.waitForTimeout(250);}
async function sampleKeys(page,keys,ms){
 const samples=[];for(const key of keys)await page.keyboard.down(key);
 const until=Date.now()+ms;try{while(Date.now()<until){samples.push(await state(page));await page.waitForTimeout(90);}}finally{for(const key of keys)await page.keyboard.up(key);}
 await page.waitForTimeout(250);return samples;
}
function seedProfile(context){return context.addInitScript(()=>{
 if(localStorage.getItem('city-journey-browser.seeded'))return;
 localStorage.setItem('city-journey-browser.seeded','yes');
 localStorage.setItem('hopan.profile.v1',JSON.stringify({version:1,baby:[0,1,2,3],human:[0,1,2,3],bonus:[],tile:[],sync:[],city:{nyc:[0,2],streetlife:[1],city_journey:[0]},hat:'morning',skin:'purple_white',preview:false,sound:false,seen_rules:[]}));
});}
async function run(){
 const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 let current;
 try{
  const fresh=await browser.newContext({viewport:{width:1280,height:800}});
  const page=current=await fresh.newPage();listen(page);await page.goto(debugURL+'?browser-test=1&splash=6');await ready(page);
  check((await state(page)).buttons[0].text==='Play Baby Mode','Baby Mode remains the first menu action');
  await openJourney(page);
  await page.waitForFunction(()=>hopanState.buttons.some(b=>b.text.startsWith('Locked ·')));
  const locked=(await state(page)).buttons.find(b=>b.text==='Locked · '+levels[1].name);
  check(!!locked,'Fresh profile shows Skate Escape locked until Blocks & Park is cleared');
  await click(page,locked.text);
  check((await state(page)).overlay&&(await state(page)).campaign_set!=='city_journey','Clicking the locked skate stage cannot start it');
  await shot(page,'fresh-profile-levels');
  await click(page,'Play · '+levels[0].name);
  await page.waitForFunction(()=>hopanState.buttons.some(b=>b.text==='Play'),null,{timeout:30000});await click(page,'Play');
  await page.waitForFunction(()=>!hopanState.overlay&&!hopanState.begin_pending);
  const start=await state(page);
  check(start.campaign_set==='city_journey'&&start.stage===0&&start.map.width===levels[0].width&&start.map.height===levels[0].height,'Large city level loads through the real menu');
  check(start.journey.movement==='walk'&&!start.result,'City starts with ordinary walking controls and no immediate collision');
  await shot(page,'city-start-play');
  await click(page,'Map');await page.waitForFunction(()=>hopanState.map_view);
  const paused=(await state(page)).elapsed;await page.waitForTimeout(400);
  check((await state(page)).elapsed===paused,'Large city overhead map pauses hazards');await shot(page,'city-overview');
  await click(page,'3D view');await page.waitForFunction(()=>!hopanState.map_view);
  await keyFor(page,'w',700);const moved=await state(page);
  check(moved.player[1]<start.player[1]-.2&&!moved.result,'Normal keyboard input moves into the outbound city route');
  await shot(page,'city-outbound-play');
  await page.keyboard.press('r');await page.waitForFunction(()=>!hopanState.result&&!hopanState.overlay);
  const retry=await state(page);
  check(Math.hypot(retry.player[0]-start.player[0],retry.player[1]-start.player[1])<.15,'City retry restores the spawn before reaching a checkpoint');
  await fresh.close();

  const saved=await browser.newContext({viewport:{width:1280,height:800}});await seedProfile(saved);
  const skate=current=await saved.newPage();listen(skate);await skate.goto(debugURL+'?browser-test=1&splash=6');await ready(skate);await choose(skate,1);
  const skating=await state(skate);
  check(skating.stage===1&&skating.journey.movement==='skate','Saved-profile fixture with the first stage cleared can select Skate Escape');
  await shot(skate,'skate-start-play');
  const acceleration=await sampleKeys(skate,['w'],800);
  check(acceleration.some(s=>s.journey.speed>2)&&!acceleration.at(-1).result,'Keyboard steering accelerates the playable skateboard');
  observations.push({kind:'acceleration',samples:acceleration.map(s=>({elapsed:s.elapsed,player:s.player,journey:s.journey,result:s.result}))});
  const beforeBrake=(await state(skate)).journey.speed;
  await keyFor(skate,'Shift',500);const braking=await state(skate);
  check(braking.journey.speed<beforeBrake&&braking.journey.speed<1,'Shift brakes the moving skateboard');
  const jump=await sampleKeys(skate,['Space'],750);
  check(jump.some(s=>s.journey.airborne),'Space triggers an actual skateboard ollie');
  observations.push({kind:'ollie',samples:jump.map(s=>({elapsed:s.elapsed,journey:s.journey,result:s.result}))});
  await shot(skate,'skate-controls-play');
  await click(skate,'Map');await pageSafeWait(skate,()=>hopanState.map_view);await shot(skate,'skate-overview');
  await click(skate,'3D view');await pageSafeWait(skate,()=>!hopanState.map_view);
  await skate.keyboard.press('Escape');await pageSafeWait(skate,()=>hopanState.overlay);
  const pauseTime=(await state(skate)).elapsed;await skate.waitForTimeout(350);
  check((await state(skate)).elapsed===pauseTime,'Pause stops skateboard simulation');
  await skate.reload();await ready(skate);
  const restored=await state(skate);
  assert.deepEqual(restored.city_progress,{nyc:[0,2],streetlife:[1],city_journey:[0]});
  check(restored.completed_stages.length===4,'Old city and Baby Mode progress, plus the skate unlock, survive browser reload');
  check(restored.hat==='morning'&&restored.skin==='purple_white','Saved outfit and frog color survive the new stages');
  await saved.close();

  const mobile=await browser.newContext({viewport:{width:844,height:390},isMobile:true,hasTouch:true,userAgent:'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/131.0.0.0 Mobile Safari/537.36'});await seedProfile(mobile);
  const phone=current=await mobile.newPage();listen(phone);await phone.goto(debugURL+'?browser-test=1&splash=6');await ready(phone);await choose(phone,1,true);
  check((await state(phone)).buttons.some(b=>b.text==='Jump · Space')&&(await state(phone)).buttons.some(b=>b.text==='Brake · Shift'),'Landscape touch layout exposes separate Jump and Brake controls');
  const cdp=await mobile.newCDPSession(phone),touchStart=await state(phone);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:110,y:290,id:0}]});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:110,y:245,id:0}]});await phone.waitForTimeout(500);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await phone.waitForTimeout(250);
  check((await state(phone)).player[1]<touchStart.player[1]-.2,'Touch joystick accelerates the skateboard');
  const touchBeforeBrake=(await state(phone)).journey.speed;
  async function holdTouchButton(text,ms){
   const s=await state(phone),button=s.buttons.find(b=>b.text===text),canvas=await phone.locator('canvas').boundingBox();
   assert.ok(button,text+' is visible');
   const x=canvas.x+button.x*canvas.width/s.ui_size[0],y=canvas.y+button.y*canvas.height/s.ui_size[1];
   await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y,id:0}]});
   const samples=[];const end=Date.now()+ms;
   while(Date.now()<end){samples.push(await state(phone));await phone.waitForTimeout(80);}
   await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await phone.waitForTimeout(200);return samples;
  }
  const touchBrake=await holdTouchButton('Brake · Shift',600);
  check((await state(phone)).journey.speed<touchBeforeBrake,'Holding the on-screen Brake slows the skateboard');
  await phone.waitForFunction(()=>!hopanState.journey.airborne,null,{timeout:10000});
  const touchJump=await holdTouchButton('Jump · Space',650);
  check(touchJump.some(s=>s.journey.airborne),'The on-screen Jump triggers an airborne skateboard ollie');
  observations.push({kind:'touch-buttons',brake:touchBrake.map(s=>s.journey),jump:touchJump.map(s=>s.journey)});
  await shot(phone,'skate-mobile-play');await mobile.close();

  if(!process.env.HOPAN_SKIP_RELEASE){
  const release=await browser.newContext({viewport:{width:1280,height:800}}),live=current=await release.newPage();listen(live);
  await live.goto(releaseURL+'?splash=6');await live.waitForFunction(()=>!document.getElementById('loading'),null,{timeout:120000});await live.waitForTimeout(1500);
  check(await live.evaluate(()=>typeof window.hopanState==='undefined'),'Release export starts without exposing the debug probe');await shot(live,'release-main');await release.close();
  }
  check(errors.length===0,'No captured browser or engine console errors');
  fs.writeFileSync(path.join(out,'browser.json'),JSON.stringify({checks,errors,screenshots,observations,scope:'Actual Chromium/WebGL with SwiftShader; menu, keyboard, touch and read-only observations. Skate access uses a saved-profile fixture, not a claimed browser win. Native tests cover full traversal. No physical mobile hardware, human difficulty rating or frame-rate claim.'},null,2)+'\n');
  console.log(JSON.stringify({checks:checks.length,errors}));
 }catch(error){if(current&&!current.isClosed())await current.screenshot({path:path.join(out,'failure.png')}).catch(()=>{});fs.writeFileSync(path.join(out,'browser-failed.json'),JSON.stringify({error:error.stack,checks,errors,observations},null,2)+'\n');throw error;}finally{await browser.close();}
}
async function pageSafeWait(page,predicate){await page.waitForFunction(predicate,null,{timeout:20000});}
if(require.main===module)run().catch(error=>{console.error(error.stack);process.exitCode=1;});
module.exports={state,ready,listen,choose,shot,click,checks,errors,observations};
