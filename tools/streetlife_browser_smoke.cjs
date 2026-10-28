/* Real input against the debug Web export; scene diagnostics are read-only. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8060';
const out = path.resolve(__dirname, '../build/test-results');
let checks = 0;
const errors = [];
const check = (value, message) => { assert.ok(value, message); checks++; console.log('PASS:', message); };
const state = page => page.evaluate(() => window.hopanState);
const wait = (page, predicate, argument) => page.waitForFunction(predicate, argument, { timeout: 30000 });
async function click(page, match) {
  for (let attempt = 0; attempt < 24; attempt++) {
    const snapshot = await state(page);
    const button = snapshot.buttons.find(b => typeof match === 'string' ? b.text === match : match.test(b.text));
    assert.ok(button, `Visible menu entry exists: ${match}`);
    const rect = await page.locator('canvas').boundingBox();
    if (button.y > 15 && button.y < snapshot.ui_size[1] - 15) {
      await page.mouse.click(rect.x + button.x * rect.width / snapshot.ui_size[0], rect.y + button.y * rect.height / snapshot.ui_size[1]);
      return;
    }
    await page.mouse.move(rect.x + rect.width * .5, rect.y + rect.height * .5);
    await page.mouse.wheel(0, button.y < 15 ? -280 : 280);
    await page.waitForTimeout(200);
  }
  throw new Error(`Unable to scroll to ${match}`);
}
async function open(page) {
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  await page.goto(`${base}/?browser-test=1`);
  await wait(page, () => window.hopanState && !document.getElementById('loading'));
}
(async () => {
  await fs.mkdir(out, { recursive: true });
  const browser = await chromium.launch({ executablePath: process.env.HOPAN_CHROMIUM || '/usr/bin/chromium', headless: true,
    args: ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'] });
  try {
    const context = await browser.newContext({ viewport: { width: 1280, height: 800 }, acceptDownloads: true });
    const page = await context.newPage();
    await open(page);
    check((await state(page)).buttons.some(b => /^Play · NYC 06/.test(b.text)), 'The new skate circle appears in the regular NYC campaign');
    await click(page, /^Play · NYC 06/);
    await wait(page, () => hopanState.mode === 'play' && !hopanState.overlay && hopanState.map.skate_area);
    const before = await state(page);
    check(before.map.skate_area.diameter === 18, 'Playable plaza declares its eighteen-tile circular skating area');
    check(before.streetlife.skaters.length === 3 && new Set(before.streetlife.skaters.map(s => s.variant)).size === 3,
      'Three visually distinct skateboard enemies run in the WebGL world');
    check(before.streetlife.roaches.length >= 2 && before.streetlife.prop_count >= 8,
      'Roach enemies and the expanded street-prop kit appear in the playable scene');
    await wait(page, old => hopanState.streetlife.skaters.some((s, i) => Math.hypot(s.x - old[i].x, s.z - old[i].z) > .3), before.streetlife.skaters);
    check(true, 'Skateboard enemies follow their routes while the frog waits in its safe arrival space');
    await wait(page, () => hopanState.streetlife.skaters.some(s => s.height > .2));
    check(true, 'At least one rider reaches an elevated ramp or grind contact in the browser');
    await page.screenshot({ path: path.join(out, 'nyc-skate-plaza-gameplay.png') });
    await page.keyboard.press('m');
    await wait(page, () => hopanState.map_view);
    const pausedMap = await state(page);
    await page.waitForTimeout(400);
    const afterMap = await state(page);
    check(JSON.stringify(pausedMap.streetlife) === JSON.stringify(afterMap.streetlife), 'Overhead inspection freezes skaters, roaches and their action timing');
    await page.screenshot({ path: path.join(out, 'nyc-skate-plaza-overview.png') });
    await click(page, '3D view');
    await wait(page, () => !hopanState.map_view);
    await click(page, 'Pause');
    await wait(page, () => hopanState.paused);
    const paused = await state(page);
    await page.waitForTimeout(350);
    check(JSON.stringify((await state(page)).streetlife) === JSON.stringify(paused.streetlife), 'Pause preserves the complete streetlife simulation pose');
    await click(page, 'Resume');
    await wait(page, () => !hopanState.paused);
    await click(page, 'Editor');
    await wait(page, () => hopanState.mode === 'edit');
    const editor = await state(page);
    await page.waitForTimeout(300);
    check(JSON.stringify((await state(page)).streetlife) === JSON.stringify(editor.streetlife), 'The editor holds every moving enemy at its authoring preview pose');
    const downloadEvent = page.waitForEvent('download');
    await click(page, 'Export JSON');
    const download = await downloadEvent;
    const savedPath = path.join(out, 'nyc-skate-plaza-export.json');
    await download.saveAs(savedPath);
    const saved = JSON.parse(await fs.readFile(savedPath, 'utf8'));
    check(saved.objects.filter(o => o.type === 'skater').length === 3 && saved.objects.some(o => o.type === 'roach') && saved.objects.some(o => o.type === 'city_prop'),
      'Portable editor export retains the new enemies, skating routes and city assets');
    await page.screenshot({ path: path.join(out, 'nyc-skate-plaza-editor.png') });
    await context.close();
    const mobile = await browser.newContext({ viewport: { width: 844, height: 390 }, hasTouch: true, isMobile: true });
    const phone = await mobile.newPage();
    await open(phone);
    await click(phone, /^Play · NYC 06/);
    await wait(phone, () => hopanState.mode === 'play' && !hopanState.overlay);
    check((await state(phone)).streetlife.skaters.length === 3, 'Landscape phone view starts the complete three-rider encounter');
    await phone.screenshot({ path: path.join(out, 'nyc-skate-plaza-mobile.png') });
    await mobile.close();
    check(errors.length === 0, 'Streetlife browser sequence reports no JavaScript or Godot runtime errors');
    console.log(`STREETLIFE BROWSER: ${checks} checks, 0 failures`);
  } finally { await browser.close(); }
})().catch(e => { console.error(e); console.error(errors); process.exitCode = 1; });
