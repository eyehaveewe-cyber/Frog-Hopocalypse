/* Runs real UI interactions against the debug export. The probe is read-only. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8060';
const out = path.resolve(__dirname, '../build/test-results');
const errors = [];
let checks = 0;
const check = (value, description) => { assert.ok(value, description); checks++; console.log('PASS:', description); };
const state = page => page.evaluate(() => window.hopanState);
const wait = (page, predicate, argument) => page.waitForFunction(predicate, argument, { timeout: 30000 });

async function click(page, match) {
  // Godot's menu is canvas-rendered and scrollable. Use actual wheel input to
  // reach later regular levels instead of mutating the game's state via JS.
  for (let attempt = 0; attempt < 24; attempt++) {
    const snapshot = await state(page);
    const button = snapshot.buttons.find(b => typeof match === 'string' ? b.text === match : match.test(b.text));
    assert.ok(button, `Menu button exists: ${match}`);
    const rect = await page.locator('canvas').boundingBox();
    if (button.y > 15 && button.y < snapshot.ui_size[1] - 15) {
      await page.mouse.click(rect.x + button.x * rect.width / snapshot.ui_size[0], rect.y + button.y * rect.height / snapshot.ui_size[1]);
      return;
    }
    await page.mouse.move(rect.x + rect.width * 0.5, rect.y + rect.height * 0.5);
    await page.mouse.wheel(0, button.y < 15 ? -280 : 280);
    await page.waitForTimeout(200);
  }
  throw new Error(`Could not scroll to ${match}`);
}

async function open(page) {
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
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
    const menu = await state(page);
    check(menu.buttons.filter(b => b.text.startsWith('Play · NYC')).length >= 5, 'Five NYC maps are selectable in the regular campaign menu');
    await click(page, /^Play · NYC 05/);
    await wait(page, () => hopanState.mode === 'play' && hopanState.map.theme === 'nyc' && !hopanState.overlay);
    const before = await state(page);
    check(before.traffic.count >= 20, 'Midtown finale runs its full traffic ensemble in WebGL');
    check(new Set(before.traffic.vehicles.map(v => v.kind)).size === 4, 'Browser renders taxis, sedans, buses and delivery trucks');
    await wait(page, clock => hopanState.traffic.clock > clock + 0.4, before.traffic.clock);
    const after = await state(page);
    const differences = after.traffic.vehicles.map((v, index) => v.x - before.traffic.vehicles[index].x).filter(difference => Math.abs(difference) < 10);
    check(differences.some(difference => difference > 0.1) && differences.some(difference => difference < -0.1), 'Opposing traffic streams move in both directions in the browser');
    await page.screenshot({ path: path.join(out, 'nyc-midtown-gameplay.png') });
    await page.keyboard.press('m');
    await wait(page, () => hopanState.map_view && !hopanState.retro);
    const overview = await state(page);
    await page.waitForTimeout(400);
    const mapFrozen = await state(page);
    check(mapFrozen.traffic.clock === overview.traffic.clock && JSON.stringify(mapFrozen.traffic.vehicles) === JSON.stringify(overview.traffic.vehicles), 'Overhead inspection freezes traffic and keeps vehicle poses visible');
    await page.screenshot({ path: path.join(out, 'nyc-midtown-overview.png') });
    await click(page, '3D view');
    await wait(page, () => !hopanState.map_view);
    await click(page, 'Pause');
    await wait(page, () => hopanState.paused);
    const paused = await state(page);
    await page.waitForTimeout(350);
    check((await state(page)).traffic.clock === paused.traffic.clock, 'Pause freezes city traffic in the browser');
    await click(page, 'Resume');
    await wait(page, () => !hopanState.paused);
    await wait(page, () => hopanState.traffic.clock > 3);
    const priorRetry = await state(page);
    await page.keyboard.press('r');
    await wait(page, clock => hopanState.traffic.clock < clock, priorRetry.traffic.clock);
    check((await state(page)).result === '', 'Retry restarts the traffic encounter without a stale death state');
    await click(page, 'Editor');
    await wait(page, () => hopanState.mode === 'edit');
    const editor = await state(page);
    await page.waitForTimeout(300);
    check((await state(page)).traffic.clock === editor.traffic.clock && editor.map.theme === 'nyc', 'Editor preserves the NYC map and holds its traffic preview still');
    const downloadEvent = page.waitForEvent('download');
    await click(page, 'Export JSON');
    const download = await downloadEvent;
    const exported = path.join(out, 'nyc-midtown-export.json');
    await download.saveAs(exported);
    const saved = JSON.parse(await fs.readFile(exported, 'utf8'));
    check(saved.theme === 'nyc' && saved.traffic.length >= 8 && saved.tiles.some(row => row.includes('road')), 'Browser JSON export retains NYC roads and traffic definitions');
    await page.screenshot({ path: path.join(out, 'nyc-midtown-editor.png') });
    await context.close();

    const mobile = await browser.newContext({ viewport: { width: 844, height: 390 }, hasTouch: true, isMobile: true });
    const phone = await mobile.newPage();
    await open(phone);
    await click(phone, /^Play · NYC 05/);
    await wait(phone, () => hopanState.mode === 'play' && !hopanState.overlay);
    const mobileBefore = await state(phone);
    await wait(phone, clock => hopanState.traffic.clock > clock + 0.2, mobileBefore.traffic.clock);
    check((await state(phone)).traffic.count >= 20, 'Landscape phone viewport starts the regular Midtown traffic level');
    await phone.screenshot({ path: path.join(out, 'nyc-midtown-mobile.png') });
    await mobile.close();
    check(errors.length === 0, 'NYC browser sequence produces no JavaScript or Godot runtime errors');
    console.log(`NYC BROWSER: ${checks} checks, 0 failures`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); console.error(errors); process.exitCode = 1; });
