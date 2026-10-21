/* Focused Bonus entry check; browser input is real mouse/touch, probe read-only. */
const {chromium}=require('playwright');
const fs=require('node:fs');
const assert=require('node:assert/strict');
const path=require('node:path');
const out=path.resolve(__dirname,'../docs/previews/cramerton');
const expected=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../game/levels/bonus/Cramerton.json')));
const errors=[], results=[];
const state=p=>p.evaluate(()=>window.hopanState);
const wait=(p,f)=>p.waitForFunction(f,null,{timeout:45000});
async function click(p,b,touch=false){
 const s=await state(p),r=await p.locator('canvas').boundingBox();
 const x=r.x+b.x*r.width/s.ui_size[0],y=r.y+b.y*r.height/s.ui_size[1];
 if(touch)await p.touchscreen.tap(x,y);else await p.mouse.click(x,y);
}
async function button(p,text,touch=false){const s=await state(p); const b=s.buttons.find(b=>b.text===text); assert.ok(b,`Button ${text}`);await click(p,b,touch);}
(async()=>{
 const browser=await chromium.launch({executablePath:'/usr/bin/chromium',args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader'],headless:true});
 try{
 for(const phone of [false,true]){
  const c=await browser.newContext({viewport:phone?{width:844,height:390}:{width:1440,height:900},hasTouch:phone,isMobile:phone});
  const p=await c.newPage();p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  await p.goto((process.env.HOPAN_TEST_URL||'http://127.0.0.1:8076')+'/?browser-test=1');
  await wait(p,()=>window.hopanState && !document.getElementById('loading'));
  let s=await state(p);fs.writeFileSync(out+'/initial-buttons.json',JSON.stringify(s.buttons,null,2));
  // Locate the compact Bonus row, scrolling the actual menu when needed.
  for(let i=0;i<12;i++){
   s=await state(p);const b=s.buttons.find(b=>/^Bonus/.test(b.text));
   if(b&&b.y>0&&b.y<s.ui_size[1]-25)break;
   await p.mouse.move(phone?700:1250,phone?280:650);await p.mouse.wheel(0,350);await p.waitForTimeout(150);
  }
  s=await state(p);const bonus=s.buttons.find(b=>/^Bonus/.test(b.text));assert.ok(bonus,'Bonus header exists');
  const expand=s.buttons.find(b=>b.text==='+'&&Math.abs(b.y-bonus.y)<10);assert.ok(expand,'Bonus expand control');await click(p,expand,phone);
  await wait(p,()=>hopanState.buttons.some(b=>b.text==='Play · Cramerton'));
  for(let i=0;i<12;i++){
   s=await state(p);const b=s.buttons.find(b=>b.text==='Play · Cramerton');
   if(b.y>0&&b.y<s.ui_size[1]-25)break;
   await p.mouse.wheel(0,250);await p.waitForTimeout(150);
  }
  await p.screenshot({path:out+`/${phone?'phone':'desktop'}-bonus.png`});
  await button(p,'Play · Cramerton',phone);
  await wait(p,()=>hopanState.mode==='play'&&hopanState.map.name==='Cramerton');
  s=await state(p);
  if(s.rule_notice){const start=s.buttons.find(b=>/^Play/.test(b.text));assert.ok(start,'Rule card play');await click(p,start,phone);}
  await wait(p,()=>!hopanState.overlay&&!hopanState.intro_active);
  s=await state(p);assert.deepEqual(s.map.tiles,expected.tiles);assert.deepEqual(s.map.objects,expected.objects);
  assert.equal(s.map.rules.long_hop,'fragments');assert.equal(s.campaign_set,'bonus');assert.equal(s.tile_unlocked,false);
  assert.ok(s.tile_mode);assert.ok(s.long_hop_state);assert.equal(s.saved,0);
  await p.screenshot({path:out+`/${phone?'phone':'desktop'}-play.png`});
  await button(p,'Map',phone);await wait(p,()=>hopanState.map_view);
  await p.screenshot({path:out+`/${phone?'phone':'desktop'}-map.png`});
  results.push({device:phone?'Chromium phone landscape emulation':'Chromium desktop',bonusUnlockedWithoutCampaign:true,exportedTilesAndObjectsExact:true,fragmentRules:true,longHopIndicator:true,editorSavesUnchanged:true});
  await c.close();
 }
 assert.deepEqual(errors,[]);fs.writeFileSync(out+'/browser-results.json',JSON.stringify({results,errors,limits:'Chromium emulation; no physical phone, Edge or hosted-origin runtime test'},null,2)+'\n');console.log(JSON.stringify({results,errors},null,2));
 }finally{await browser.close();}
})().catch(e=>{console.error(e);console.error(errors);process.exitCode=1;});
