const {chromium}=require('playwright');
const assert=require('node:assert/strict'), fs=require('node:fs'), path=require('node:path');
const jungle=process.env.HOPAN_THEME==='honduras';
const theme=jungle?'honduras':'mexico', newName=jungle?'New Honduras':'New Mexico', demo=jungle?'Jungle River · Honduras':'Courtyard Gardens · Mexico', title=jungle?'Jungle River':'Courtyard Gardens';
const out=path.resolve(__dirname,'../docs/previews/'+theme+'-kit');fs.mkdirSync(out,{recursive:true});
(async()=>{
 const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader']});
 const errors=[],checks=[];
 try{
  for(const compat of [false,true]){
   const page=await browser.newPage({viewport:{width:1280,height:900}});
   page.on('pageerror',e=>errors.push(e.message));
   page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
   const state=()=>page.evaluate(()=>hopanState);
   async function click(text){
    for(let i=0;i<70;i++){
     const s=await state(),b=s.buttons.find(b=>b.text===text);
     if(!b){await page.waitForTimeout(100);continue;}
     const top=s.mode==='edit'&&!s.overlay&&b.x<280?90:10,bottom=s.mode==='edit'&&!s.overlay?840:880;
     if(b.y<top||b.y>bottom){await page.mouse.move(b.x,450);await page.mouse.wheel(0,b.y<top?-160:160);await page.waitForTimeout(450);continue;}
     await page.mouse.click(b.x,b.y);await page.waitForTimeout(200);return;
    }throw Error('Missing/unreachable button '+text);
   }
   await page.goto((process.env.HOPAN_TEST_URL||'http://127.0.0.1:8068/test-web/')+'?browser-test=1&compat='+(compat?1:0));
   await page.waitForFunction(()=>window.hopanState&&!document.getElementById('loading'),null,{timeout:60000});
   await click('Level editor · Create a maze');
   await click(newName);
   await page.waitForFunction(t=>hopanState.map.theme===t,theme);
   assert.ok((await state()).buttons.some(b=>b.text===(jungle?'Jungle tree':'Cactus')));
   await click('Save');
   try{await page.waitForFunction(()=>!hopanState.editor_unsaved,null,{timeout:8000});}catch(e){await page.screenshot({path:path.join(out,'save-failure.png')});const s=await state();console.error(JSON.stringify({status:s.status,mode:s.mode,overlay:s.overlay,buttons:s.buttons.filter(b=>['Save','New Honduras'].includes(b.text))}));throw e;}
   await click('Scenery demos');
   await click(demo);
   await page.waitForFunction(t=>hopanState.map.name===t,title);
   await page.screenshot({path:path.join(out,compat?'compat-editor.png':'editor.png')});
   const authored=(await state()).map;
   await click('Playtest ▶');
   await page.waitForFunction(()=>hopanState.mode==='test'&&!hopanState.overlay);
   await page.waitForTimeout(500);
   await page.screenshot({path:path.join(out,compat?'compat-play.png':'play.png')});
   const before=(await state()).player;
   await page.keyboard.down('w');await page.waitForTimeout(450);await page.keyboard.up('w');
   const after=await state();
   assert.equal(after.result,'');assert.ok(after.player[1]<before[1]-0.5);
   await click('Map');await page.screenshot({path:path.join(out,compat?'compat-map.png':'map.png')});
   assert.deepEqual((await state()).map,authored);
   checks.push(`${compat?'Compatibility':'Retro'}: new theme, contextual palette, save, showcase loading, perspective movement and overhead map preserve the document`);
   await page.close();
  }
  assert.deepEqual(errors,[]);
  const result={checks,errors,scope:'Desktop Chromium/SwiftShader in retro and compatibility render paths; actual keyboard movement. Native controller test completes the full showcase route. Physical phones/Safari and human visual comfort are unverified.'};
  fs.writeFileSync(path.join(out,'results.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
