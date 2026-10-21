const{chromium}=require('playwright'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const out=path.resolve(__dirname,'../docs/previews/lane-tunnels');fs.mkdirSync(out,{recursive:true});
const fixture=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../game/tests/fixtures/lane_tunnels.json'),'utf8'));
(async()=>{const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader']});const errors=[],checks=[];
try{for(const theme of ['egypt','swamp','mexico','honduras']){
 const mobile=theme==='honduras';
 const page=await browser.newPage(mobile?{viewport:{width:1024,height:768},isMobile:true,hasTouch:true,userAgent:'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/140.0.0.0 Mobile Safari/537.36'}:{viewport:{width:1440,height:900}});
 page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 const state=()=>page.evaluate(()=>hopanState);
 async function click(text){for(let i=0;i<70;i++){
  const s=await state(),b=s.buttons.find(x=>x.text===text);if(!b){await page.waitForTimeout(120);continue;}
  const v=page.viewportSize(),x=b.x*v.width/s.ui_size[0],y=b.y*v.height/s.ui_size[1];
  const top=s.mode==='edit'&&!s.overlay&&b.x<310?90:10,bottom=v.height-75;
  if(y<top||y>bottom){await page.mouse.move(x,v.height/2);await page.mouse.wheel(0,y<top?-120:120);await page.waitForTimeout(450);continue;}
  if(mobile)await page.touchscreen.tap(x,y);else await page.mouse.click(x,y);await page.waitForTimeout(320);return;
 }throw Error('Unreachable '+text);}

 await page.goto((process.env.HOPAN_TEST_URL||'http://127.0.0.1:8068/test-web/')+'?browser-test=1&compat='+(mobile?1:0));
 await page.waitForFunction(()=>window.hopanState&&!document.getElementById('loading'),null,{timeout:60000});
 const map=structuredClone(fixture);map.theme=theme;
 await page.evaluate(d=>window.hopanImported=JSON.stringify(d),map);
 await page.waitForFunction(t=>hopanState.mode==='edit'&&hopanState.map.theme===t,theme);
 assert.equal((await state()).lane_tunnels.length,4);
 await page.screenshot({path:path.join(out,theme+'-editor.png'),scale:'css'});
 await click('Playtest ▶');await page.waitForFunction(()=>hopanState.mode==='test'&&!hopanState.overlay);
 await page.waitForTimeout(500);
 await page.screenshot({path:path.join(out,theme+'-play.png'),scale:'css'});
 assert.equal((await state()).result,'');assert.equal((await state()).lane_tunnels.length,4);
 assert.deepEqual((await state()).map,map);
 await click('Map');await page.waitForFunction(()=>hopanState.map_view);
 const paused=(await state()).elapsed;await page.waitForTimeout(300);assert.equal((await state()).elapsed,paused);
 await page.screenshot({path:path.join(out,theme+'-map.png'),scale:'css'});
 checks.push(`${theme}: four generated portals load in editor/game without changing the map; overhead inspection pauses the actual lane simulation (${mobile?'Android-UA touch compatibility':'desktop retro'})`);
 await page.close();
}assert.deepEqual(errors,[]);const r={checks,errors,scope:'Three desktop retro themes and Honduras Android-UA touch compatibility. Native checks cover wrap seam bounds and active full routes. Physical devices/Safari and subjective readability unverified.'};fs.writeFileSync(path.join(out,'results.json'),JSON.stringify(r,null,2)+'\n');console.log(JSON.stringify(r));}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
