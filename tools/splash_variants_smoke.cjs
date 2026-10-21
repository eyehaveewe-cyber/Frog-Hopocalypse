// Same-source debug export: exercise both launch overrides and all title layouts.
const {chromium,devices}=require('playwright');
const assert=require('node:assert/strict'),fs=require('node:fs');
const output='docs/previews/hat-implementation';
(async()=>{
 const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader']});
 const checks=[],errors=[];
 try{
  for(const style of ['6','4'])for(const layout of ['desktop','landscape','portrait']){
   const options=layout==='desktop'?{viewport:{width:1280,height:900}}:{...devices[layout==='portrait'?'iPhone 13':'iPhone 13 landscape']};
   const page=await browser.newPage(options);
   page.on('pageerror',e=>errors.push(e.message));
   page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
   const ready=()=>page.waitForFunction(()=>window.hopanState&&!document.getElementById('loading'),null,{timeout:60000});
   const state=()=>page.evaluate(()=>hopanState);
   const expected=style==='4'?'layered':'wrapped';
   async function click(text){
    for(let i=0;i<45;i++){
     const button=(await state()).buttons.find(b=>b.text===text);
     assert.ok(button,'Missing '+text);
     const viewport=page.viewportSize();
     if(button.y<10||button.y>viewport.height-20){await page.mouse.move(viewport.width-70,viewport.height/2);await page.mouse.wheel(0,button.y<10?-150:150);await page.waitForTimeout(120);continue;}
     assert.ok(button.x>0&&button.x<viewport.width);
     if(layout==='desktop')await page.mouse.click(button.x,button.y);else await page.touchscreen.tap(button.x,button.y);
     return;
    }
    throw Error('Button unreachable: '+text);
   }
   await page.goto('http://127.0.0.1:8076/test-web/?browser-test=1&splash='+style);
   await ready();
   if(layout==='portrait')await page.getByRole('button',{name:'Continue in portrait'}).click();
   await page.waitForTimeout(300);
   assert.equal((await state()).splash_variant,expected);
   assert.equal((await state()).splash_portrait,layout==='portrait');
   assert.equal((await state()).splash_menu,true);
   await page.screenshot({path:`${output}/${style}-${layout}.png`,scale:'css'});
   await click('Baby Mode');
   await page.waitForFunction(()=>hopanState.mode==='play'&&!hopanState.overlay);
   assert.equal((await state()).splash_variant,expected);
   await click('Menu');
   await page.waitForFunction(()=>hopanState.splash_menu);
   assert.equal((await state()).splash_variant,expected);
   if(layout==='desktop'){
    await page.setViewportSize({width:600,height:950});
    await page.waitForTimeout(500);
    assert.equal((await state()).splash_variant,expected);
    await page.setViewportSize({width:1280,height:900});
    await page.waitForTimeout(500);
    assert.equal((await state()).splash_variant,expected);
   }
   checks.push(`#${style} ${layout}: correct artwork, playable Baby Mode and same title on return${layout==='desktop'?', also stable through two orientation changes':''}`);
   console.log(checks.at(-1));
   await page.close();
  }
  assert.deepEqual(errors,[]);
  const result={checks,errors,scope:'Actual Chromium mouse/touch, desktop and iPhone-size landscape/portrait. Physical iPhone/Safari/Edge not tested. Native deterministic tests cover the 15% boundary.'};
  fs.writeFileSync(`${output}/browser-results.json`,JSON.stringify(result,null,2)+'\n');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
