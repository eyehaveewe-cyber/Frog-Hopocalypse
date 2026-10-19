// Local debug export only: real pointer, keyboard and touch input.
const {chromium, devices} = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const output = process.env.HOPAN_SPLASH_EVIDENCE || path.resolve(__dirname, '../docs/previews/splash');
fs.mkdirSync(output, {recursive:true});
(async()=>{
 const browser = await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader']});
 const checks=[],errors=[];
 try {
  for (const variant of ['desktop','portrait','landscape']) {
   const opts = variant==='desktop' ? {viewport:{width:1280,height:900}} : {...devices[variant==='portrait'?'iPhone 13':'iPhone 13 landscape'],userAgent:'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/131.0.0.0 Mobile Safari/537.36'};
   const page=await browser.newPage(opts);
   page.on('pageerror',e=>errors.push(e.message));
   page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
   const state=()=>page.evaluate(()=>hopanState);
   async function click(text) {
    for(let i=0;i<40;i++) {
     const button=(await state()).buttons.find(b=>b.text===text);
     assert.ok(button,'Missing '+text);
     const viewport=page.viewportSize();
     if(button.y<10||button.y>viewport.height-20) {
      await page.mouse.move(viewport.width-100,viewport.height/2);
      await page.mouse.wheel(0,button.y<10?-180:180);
      await page.waitForTimeout(180);continue;
     }
     assert.ok(button.x>0&&button.x<viewport.width,text+' fits viewport');
     if(variant==='desktop')await page.mouse.click(button.x,button.y);
     else await page.touchscreen.tap(button.x,button.y);
     await page.waitForTimeout(320);return;
    }
    throw Error('Unable to scroll to '+text);
   }
   await page.goto('http://127.0.0.1:8060/test-web/?browser-test=1');
   await page.waitForFunction(()=>window.hopanState&&!document.getElementById('loading'),null,{timeout:60000});
   if(variant==='portrait') await page.getByRole('button',{name:'Continue in portrait'}).click();
   await page.waitForTimeout(500);
   assert.equal((await state()).splash_menu,true);
   assert.equal((await state()).splash_portrait,variant==='portrait');
   await page.screenshot({path:path.join(output,variant+'.png'),scale:'css'});
   if(variant==='desktop') {
    // The first action receives focus, and Tab/Shift+Tab stay in the menu.
    await page.keyboard.press('Tab');
    await page.keyboard.press('Shift+Tab');
    await page.keyboard.press('Enter');
   } else await click('Baby Mode');
   await page.waitForFunction(()=>!hopanState.overlay&&hopanState.mode==='play');
   checks.push(variant==='desktop' ? 'Desktop: Tab/Shift+Tab then Enter starts Baby Mode' : variant+': splash plays Baby Mode through its real button');
   await click('Menu');
   await click('Level editor · Create a maze');
   await page.waitForFunction(()=>hopanState.mode==='edit'&&!hopanState.overlay);
   checks.push(variant+': editor action works after scrolling when needed');
   if(variant==='desktop') {
    await page.evaluate(()=>localStorage.setItem('hopan.profile.v1',JSON.stringify({version:1,baby:[0,1,2,3],human:[0,1,2,3],hat:'none',preview:false,sound:false})));
    await page.reload();
    await page.waitForFunction(()=>window.hopanState&&!document.getElementById('loading'),null,{timeout:60000});
    await page.waitForTimeout(500);
    await page.screenshot({path:path.join(output,'unlocked-desktop.png'),scale:'css'});
    await click('Tile Hop');
    await page.waitForFunction(()=>hopanState.long_hop_state==='READY'&&!hopanState.overlay);
    await click('Long hop');
    await page.waitForFunction(()=>hopanState.long_hop_state==='ARMED');
    await page.keyboard.press('w');
    await page.waitForFunction(()=>hopanState.tile_hops===1&&hopanState.long_hop_state==='READY');
    await page.screenshot({path:path.join(output,'tile-ready.png'),scale:'css'});
    await click('Map');
    await page.waitForFunction(()=>hopanState.long_hop_state==='PAUSED');
    checks.push('Tile mode: READY → touch-button ARMED → real hop → READY; Map shows PAUSED');
   }
   await page.close();
  }
  assert.deepEqual(errors,[]);
  const result={checks,errors,scope:'Local debug Web export, desktop Chromium with Android-UA touch emulation; no physical device or Safari test, no deployment'};
  fs.writeFileSync(path.join(output,'browser-results.json'),JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify(result));
 }finally{await browser.close()}
})().catch(e=>{console.error(e.stack);process.exitCode=1});
