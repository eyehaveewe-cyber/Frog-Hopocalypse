const{chromium}=require('playwright'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const out=path.resolve(__dirname,'../docs/previews/skin-cycle');fs.mkdirSync(out,{recursive:true});
(async()=>{const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader']});const errors=[],checks=[];
try{for(const touch of (process.env.HOPAN_SKIN_TOUCH_ONLY?[true]:[false,true])){
 const page=await browser.newPage(touch?{viewport:{width:390,height:844},isMobile:true,hasTouch:true,userAgent:'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Version/18.0 Mobile/15E148 Safari/604.1'}:{viewport:{width:1280,height:900}});
 page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 await page.addInitScript(()=>{if(!localStorage.getItem('hopan.profile.v1'))localStorage.setItem('hopan.profile.v1',JSON.stringify({version:1,baby:[0,1,2,3],human:[0,2],bonus:[],tile:[],hat:'baby',skin:'green',preview:false,sound:false,seen_rules:[]}));});
 const state=()=>page.evaluate(()=>hopanState);
 async function skinButton(){for(let i=0;i<80;i++){const s=await state(),a=s.buttons.find(x=>x.text.startsWith('Skin:'));assert.ok(a,'Unlocked skin button is available');const v=page.viewportSize(),x=a.x*v.width/s.ui_size[0],y=a.y*v.height/s.ui_size[1];if(y<30||y>v.height-40){await page.mouse.move(x,v.height/2);await page.mouse.wheel(0,(y<30?-1:1)*(touch?20:100));await page.waitForTimeout(450);continue;}return{x,y};}await page.screenshot({path:path.join(out,'unreachable.png')});console.error(JSON.stringify({viewport:page.viewportSize(),ui:(await state()).ui_size,button:(await state()).buttons.find(x=>x.text.startsWith('Skin:'))}));throw Error('Skin selector is not reachable');}
 await page.goto((process.env.HOPAN_TEST_URL||'http://127.0.0.1:8068/test-web/')+'?browser-test=1&compat='+(touch?1:0));
 await page.waitForFunction(()=>window.hopanState&&!document.getElementById('loading'),null,{timeout:60000});
 const portrait=page.getByRole('button',{name:'Continue in portrait'});if(touch&&await portrait.isVisible())await portrait.click();
 const position=await skinButton();
 for(let i=0;i<13;i++){
  const before=(await state()).skin;
  if(touch)await page.touchscreen.tap(position.x,position.y);else await page.mouse.click(position.x,position.y);
  await page.waitForFunction(previous=>hopanState.skin!==previous,before);
  const s=await state(),button=s.buttons.find(b=>b.text.startsWith('Skin:'));
  assert.ok(s.splash_menu&&s.overlay);assert.ok(Math.abs(button.y*page.viewportSize().height/s.ui_size[1]-position.y)<2,'Menu scroll does not jump');
  assert.deepEqual(s.completed_stages,[0,1,2,3]);assert.deepEqual(s.completed_human_stages,[0,2]);assert.equal(s.hat,'baby');
 }
 checks.push(`${touch?'Touch portrait compatibility':'Desktop mouse retro'}: thirteen activations cycle both skins without losing menu position, hat or progress`);
 if(!touch){for(let i=0;i<4;i++){const previous=(await state()).skin;await page.keyboard.press('Enter');await page.waitForFunction(previous=>hopanState.skin!==previous,previous);}checks.push('Desktop Enter repeatedly activates the focused selector without rebuilding or losing focus');}
 assert.equal((await state()).skin,'purple');
 await page.screenshot({path:path.join(out,touch?'touch-purple.png':'desktop-purple.png'),scale:'css'});
 await page.reload();await page.waitForFunction(()=>window.hopanState&&!document.getElementById('loading'),null,{timeout:60000});
 assert.equal((await state()).skin,'purple');assert.deepEqual((await state()).completed_human_stages,[0,2]);assert.equal((await state()).hat,'baby');
 checks.push(`${touch?'Touch':'Desktop'}: purple selection, existing progress and baby hat survive browser reload`);
 if(touch&&await portrait.isVisible())await portrait.click();
 await skinButton();await page.screenshot({path:path.join(out,touch?'touch-reloaded.png':'desktop-reloaded.png'),scale:'css'});
 await page.close();
}assert.deepEqual(errors,[]);const r={checks,errors,scope:'Actual Chromium mouse/Enter plus iPhone-size touch/UA compatibility emulation. This does not establish physical iPhone/Safari behavior. Full original crash was not reproduced; pre-fix repeated mouse cycling lost menu reachability after two activations.'};fs.writeFileSync(path.join(out,'results.json'),JSON.stringify(r,null,2)+'\n');console.log(JSON.stringify(r));}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
