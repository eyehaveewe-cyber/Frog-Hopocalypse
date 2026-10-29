/* Browser screenshots and render metrics via real menus; state probe is read-only. */
const {chromium}=require('playwright'),fs=require('fs'),assert=require('node:assert/strict');
const qa=require('./city_journey_browser.cjs');
const name=process.env.AA_RUN||'after',url=process.env.HOPAN_TEST_URL||'http://127.0.0.1:8140/';
const out='docs/city-aa-evidence',obs=[],errors=[];
async function state(p){return qa.state(p)}
async function snap(p,label){await p.screenshot({path:`${out}/${name}-${label}.png`});const s=await state(p);obs.push({label,render_size:s.render_size,ui_size:s.ui_size,retro:s.retro,msaa_3d:s.msaa_3d,view_filter:s.view_filter,stretch_shrink:s.stretch_shrink,map_view:s.map_view,campaign_set:s.campaign_set,stage:s.stage});}
async function run(){const b=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});try{
 const c=await b.newContext({viewport:{width:1280,height:800}});await c.addInitScript(()=>localStorage.setItem('hopan.profile.v1',JSON.stringify({version:1,baby:[],human:[],bonus:[],tile:[],sync:[],city:{city_journey:[0]},hat:'none',skin:'green',preview:false,sound:false,seen_rules:[]})));
 const p=await c.newPage();p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text());});await p.goto(url+'?browser-test=1&splash=6');await qa.ready(p);
 await qa.click(p,'Play Baby Mode');await p.waitForFunction(()=>hopanState.mode==='play');if((await state(p)).buttons.some(x=>x.text==='Play'))await qa.click(p,'Play');await p.waitForFunction(()=>!hopanState.overlay&&!hopanState.begin_pending);await snap(p,'baby');
 await qa.choose(p,0);await snap(p,'city');await qa.click(p,'Map');await p.waitForFunction(()=>hopanState.map_view);await snap(p,'city-map');await qa.click(p,'3D view');
 await qa.choose(p,2);await snap(p,'frozen');await qa.choose(p,1);await snap(p,'skate');await c.close();
 const mob=await b.newContext({viewport:{width:844,height:390},isMobile:true,hasTouch:true,userAgent:'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/131.0.0.0 Mobile Safari/537.36'});await mob.addInitScript(()=>localStorage.setItem('hopan.profile.v1',JSON.stringify({version:1,baby:[],human:[],city:{city_journey:[0]},hat:'none',preview:false,sound:false,seen_rules:[]})));const mp=await mob.newPage();mp.on('pageerror',e=>errors.push(e.message));mp.on('console',m=>{if(m.type()==='error')errors.push(m.text());});await mp.goto(url+'?browser-test=1&splash=6');await qa.ready(mp);await qa.choose(mp,0,true);await snap(mp,'mobile-city');await mob.close();
 assert.equal(errors.length,0,JSON.stringify(errors));fs.writeFileSync(`${out}/${name}.json`,JSON.stringify({obs,errors,scope:'Actual Chromium SwiftShader renderer; touch emulated, no physical hardware or FPS claims.'},null,2)+'\n');console.log(JSON.stringify({name,obs,errors}));
 }finally{await b.close()}}
run().catch(e=>{console.error(e.stack);process.exitCode=1;});
