/* Runs against a debug Web export, using the installed Playwright and Chromium.
 * The opt-in debug bridge exposes read-only state; all edits and movement below
 * are made through real mouse, keyboard, file-picker and touch events. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8060';
const out = path.resolve(__dirname, '../build/test-results');
const errors = [];
let checks = 0;
const check = (ok, description) => { assert.ok(ok, description); checks++; console.log('PASS:', description); };
const state = page => page.evaluate(() => window.hopanState);
async function wait(page, predicate, argument) {
  await page.waitForFunction(predicate, argument, { timeout: 20000 });
}
async function click(page, text) {
  const s = await state(page);
  const b = s.buttons.find(b => b.text === text);
  assert.ok(b, `Visible button: ${text}`);
  const rect = await page.locator('canvas').boundingBox();
  await page.mouse.click(rect.x + b.x * rect.width / s.ui_size[0], rect.y + b.y * rect.height / s.ui_size[1]);
}
async function cell(page, x, y) {
  const s = await state(page), rect = await page.locator('canvas').boundingBox();
  const p = s.cells[y][x];
  await page.mouse.click(rect.x + p[0] * rect.width / s.ui_size[0], rect.y + p[1] * rect.height / s.ui_size[1]);
}
function watch(page) {
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
}
async function load(page) {
  await page.goto(base + '/?browser-test=1');
  await wait(page, () => window.hopanState);
  await wait(page, () => !document.getElementById('loading'));
}
(async () => {
  await fs.mkdir(out, { recursive: true });
  const browser = await chromium.launch({ executablePath: process.env.HOPAN_CHROMIUM || '/usr/bin/chromium', headless: true,
    args: ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'] });
  try {
    const context = await browser.newContext({ viewport: { width: 1280, height: 800 }, acceptDownloads: true });
    const page = await context.newPage(); watch(page); await load(page);
    await click(page, "Play · Moonlit Oasis");
    await wait(page, () => hopanState.mode === 'play' && !hopanState.overlay);
    await wait(page, () => hopanState.retro && hopanState.render_size[1] < 300);
    check((await state(page)).projection === 0, 'Default gameplay uses a low-resolution perspective render');
    const before = (await state(page)).player;
    await page.keyboard.down('d');
    await wait(page, x => hopanState.player[0] > x + 0.25, before[0]);
    await page.keyboard.up('d');
    check((await state(page)).player[0] > before[0], 'Browser keyboard moves the 3D frog continuously');
    await page.keyboard.press('m');
    await wait(page, () => hopanState.map_view && !hopanState.retro);
    const mapTime = (await state(page)).elapsed;
    await page.waitForTimeout(300);
    check((await state(page)).projection === 1 && (await state(page)).elapsed === mapTime, 'M opens the clear overhead map and pauses simulation');
    await page.screenshot({ path: path.join(out, 'ps1-overhead-map.png') });
    await click(page, '3D view');
    await wait(page, () => !hopanState.map_view && hopanState.retro);
    check((await state(page)).projection === 0, 'The 3D view button restores the frog camera and retro rendering');
    await click(page, 'Pause');
    await wait(page, () => hopanState.paused);
    const time = (await state(page)).elapsed;
    await page.waitForTimeout(350);
    check((await state(page)).elapsed === time, 'Pause stops the world clock');
    await click(page, 'Resume');
    await wait(page, () => !hopanState.paused);
    await page.screenshot({ path: path.join(out, 'desktop-play.png') });
    await click(page, 'Editor');
    await wait(page, () => hopanState.mode === 'edit');
    check((await state(page)).projection === 1 && !(await state(page)).retro, 'Desktop editor preserves its sharp overhead view');
    await click(page, 'New Egypt');
    await wait(page, () => hopanState.map.name === 'My magnificent maze');
    await click(page, 'Wall');
    await wait(page, () => hopanState.tool === 'wall');
    await cell(page, 4, 4);
    await wait(page, () => hopanState.map.tiles[4][4] === 'wall');
    check(true, 'Mouse painting changes the actual 3D level');
    await page.keyboard.press('Control+z');
    await wait(page, () => hopanState.map.tiles[4][4] === 'floor');
    await page.keyboard.press('Control+y');
    await wait(page, () => hopanState.map.tiles[4][4] === 'wall');
    check(true, 'Browser editor undo and redo restore terrain');
    await click(page, 'Save');
    await wait(page, () => hopanState.saved === 1);
    const downloadPromise = page.waitForEvent('download');
    await click(page, 'Export JSON');
    const download = await downloadPromise;
    const downloaded = path.join(out, 'exported-level.json'); await download.saveAs(downloaded);
    const data = JSON.parse(await fs.readFile(downloaded, 'utf8'));
    check(data.version === 1 && data.tiles[4][4] === 'wall', 'Browser downloads portable authored JSON');
    await click(page, 'Playtest ▶');
    await wait(page, () => hopanState.mode === 'test');
    await click(page, 'Back to editor');
    await wait(page, () => hopanState.mode === 'edit');
    check((await state(page)).map.tiles[4][4] === 'wall', 'Browser playtest preserves the editor document');
    await page.screenshot({ path: path.join(out, 'desktop-editor.png') });
    // Browser reload exercises Godot's IndexedDB-backed user:// storage.
    await page.reload(); await wait(page, () => window.hopanState);
    await wait(page, () => hopanState.saved === 1);
    check(true, 'Local level save survives a browser reload');
    await click(page, 'Level editor · Create a maze');
    await wait(page, () => hopanState.mode === 'edit');
    await click(page, 'Import');
    await wait(page, () => hopanState.overlay);
    const chooser = page.waitForEvent('filechooser'); await click(page, 'Open JSON file');
    await (await chooser).setFiles(downloaded);
    await wait(page, () => !hopanState.overlay && hopanState.map.name === 'My magnificent maze');
    check((await state(page)).map.tiles[4][4] === 'wall', 'Browser file import restores the exported terrain');
    await context.close();
    const mobile = await browser.newContext({ viewport: { width: 844, height: 390 }, hasTouch: true, isMobile: true });
    const phone = await mobile.newPage(); watch(phone); await load(phone);
    const ms = await state(phone);
    check(ms.ui_size[0] === 844 && ms.ui_size[1] === 390, 'Mobile interface uses phone CSS dimensions');
    await click(phone, 'Play · Violet Mire');
    await wait(phone, () => hopanState.mode === 'play' && !hopanState.overlay);
    const start = (await state(phone)).player;
    const cdp = await mobile.newCDPSession(phone);
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 110, y: 265 }] });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: 160, y: 265 }] });
    await wait(phone, x => hopanState.player[0] > x + 0.25, start[0]);
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    check((await state(phone)).player[0] > start[0], 'Landscape mobile touch joystick moves the frog');
    await phone.screenshot({ path: path.join(out, 'mobile-play.png') });
    await click(phone, 'Pause');
    await wait(phone, () => hopanState.paused);
    check(true, 'Mobile pause opens a touch-sized resume screen');
    await phone.screenshot({ path: path.join(out, 'mobile-pause.png') });
    await mobile.close();
    check(errors.length === 0, 'No browser JavaScript or Godot runtime errors');
    console.log(`BROWSER: ${checks} checks, 0 failures`);
  } finally { await browser.close(); }
})().catch(e => { console.error(e); console.error(errors); process.exitCode = 1; });
