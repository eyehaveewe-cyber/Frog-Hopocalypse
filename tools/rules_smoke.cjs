const {chromium,devices}=require('playwright');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const out=path.resolve(__dirname,'../docs/previews/rules');fs.mkdirSync(out,{recursive:true});
(async()=>{const b=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader']});const checks=[],errors=[];
try{for(const mobile of [false,true]){
 const opts=mobile?{...devices['iPhone 13 landscape'],userAgent:'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/131.0.0.0 Mobile Safari/537.36'}:{viewport:{width:1280,height:900}};
 const p=await b.newPage(opts);p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 await p.addInitScript(()=>{if(!localStorage.getItem('hopan.profile.v1'))localStorage.setItem('hopan.profile.v1',JSON.stringify({version:1,baby:[0,1,2,3],human:[0,1,2,3],hat:'none',preview:false,sound:false,seen_rules:[]}))});
 const state=()=>p.evaluate(()=>hopanState);
 async function click(text){for(let i=0;i<45;i++){const s=await state(),a=s.buttons.find(b=>b.text===text);assert.ok(a,'Missing '+text);const v=p.viewportSize();if(a.y<10||a.y>v.height-20){await p.mouse.move(a.x,v.height/2);await p.mouse.wheel(0,a.y<10?-150:150);await p.waitForTimeout(180);continue}if(mobile)await p.touchscreen.tap(a.x,a.y);else await p.mouse.click(a.x,a.y);await p.waitForTimeout(300);return}throw Error('Cannot reach '+text)}
 async function ready(){await p.waitForFunction(()=>window.hopanState&&!document.getElementById('loading'),null,{timeout:60000});await p.waitForTimeout(350)}
 await p.goto('http://127.0.0.1:8060/test-web/?browser-test=1');await ready();await click('Tile Hop');await p.waitForFunction(()=>hopanState.rule_notice);
 const time=(await state()).elapsed;await p.waitForTimeout(700);assert.equal((await state()).elapsed,time);
 await p.screenshot({path:path.join(out,mobile?'touch-first-rule.png':'first-rule.png'),scale:'css'});
 await click('Play');await p.waitForFunction(()=>!hopanState.overlay);await click('Rules');await p.waitForFunction(()=>hopanState.rule_notice);await click('Back');checks.push((mobile?'Touch':'Desktop')+': first rule pauses safely; translucent Rules control reopens it');
 await click('Menu');await click('Level editor · Create a maze');await click('Movement demos');await click('Charge Trial · 10 hops');await click('Playtest ▶');await p.waitForFunction(()=>hopanState.rule_notice);
 await p.screenshot({path:path.join(out,mobile?'touch-new-charge-rule.png':'new-charge-rule.png'),scale:'css'});
 if(!mobile){await p.keyboard.press('Enter');await p.waitForFunction(()=>!hopanState.overlay);async function hop(big=false){const n=(await state()).tile_hops;if(big)await p.keyboard.down('Shift');await p.keyboard.press('w');if(big)await p.keyboard.up('Shift');await p.waitForFunction(n=>hopanState.tile_hops===n+1&&!hopanState.hop_active,n)}
 await hop();await hop(true);await p.waitForFunction(()=>hopanState.long_hop_state==='10 TO GO');await p.screenshot({path:path.join(out,'charge-hud.png'),scale:'css'});for(let i=0;i<10;i++)await hop();await p.waitForFunction(()=>hopanState.long_hop_state==='READY');await hop(true);for(let i=0;i<7;i++)await hop();await p.waitForFunction(()=>hopanState.result==='LEVEL COMPLETE!');checks.push('Real keyboard route completes both gates, HUD counts recharge and returns READY');
 }else{await click('Play');await p.waitForFunction(()=>!hopanState.overlay);await click('Rules');await click('Back');checks.push('Touch can dismiss new charge rules and reopen the full active rule set')}
 await p.reload();await ready();await click('Tile Hop');await p.waitForFunction(()=>hopanState.mode==='play'&&!hopanState.overlay);assert.equal((await state()).rule_notice,false);checks.push((mobile?'Touch':'Desktop')+': seen rules survive reload and do not repeat');await p.close();
}assert.deepEqual(errors,[]);const result={checks,errors,deviceScope:'Desktop Chromium and Android-UA touch emulation; physical phones and Safari unverified'};fs.writeFileSync(path.join(out,'results.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));}finally{await b.close()}})().catch(e=>{console.error(e.stack);process.exitCode=1});
