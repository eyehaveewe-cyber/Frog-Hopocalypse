/* Focused Chromium check of rejected Tile Hop input and feedback. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8064';
const screenshot = path.resolve(__dirname, '../build/test-results/phase03-blocked-hop.png');
const map = { version: 1, name: 'Blocked hop', theme: 'egypt', width: 7, height: 7,
  game_mode: 'tile', move_with_me: true, spawn: [2, 4], exit: [4, 1], objects: [],
  tiles: Array.from({ length: 7 }, (_, y) => Array.from({ length: 7 }, (_, x) =>
    x === 0 || y === 0 || x === 6 || y === 6 || (x === 2 && y === 3) ? 'wall' : 'floor')) };

async function click(page, name) {
  const state = await page.evaluate(() => window.hopanState);
  const button = state.buttons.find(b => b.text === name);
  assert.ok(button, `Visible button: ${name}`);
  const canvas = await page.locator('canvas').boundingBox();
  await page.mouse.click(canvas.x + button.x * canvas.width / state.ui_size[0], canvas.y + button.y * canvas.height / state.ui_size[1]);
}

(async () => {
  const browser = await chromium.launch({ executablePath: process.env.HOPAN_CHROMIUM || '/usr/bin/chromium', headless: true,
    args: ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'] });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 1200 }, acceptDownloads: true });
    await page.goto(base + '/?browser-test=1');
    await page.waitForFunction(() => window.hopanState && !document.getElementById('loading'));
    await click(page, 'Level editor · Create a maze');
    await page.waitForFunction(() => hopanState.mode === 'edit');
    await click(page, 'Import');
    await page.waitForFunction(() => hopanState.overlay);
    const chooser = page.waitForEvent('filechooser');
    await click(page, 'Open JSON file');
    await (await chooser).setFiles({ name: 'blocked-hop.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(map)) });
    await page.waitForFunction(() => hopanState.mode === 'edit' && hopanState.map.name === 'Blocked hop' && !hopanState.overlay);
    await click(page, 'Playtest ▶');
    await page.waitForFunction(() => hopanState.mode === 'test');
    if ((await page.evaluate(() => window.hopanState)).rule_notice) await click(page, 'Play');
    await page.waitForFunction(() => !hopanState.overlay);
    const before = await page.evaluate(() => window.hopanState);
    await page.keyboard.press('ArrowUp');
    await page.waitForFunction(() => hopanState.status.includes('blocked landing'));
    const blocked = await page.evaluate(() => window.hopanState);
    assert.equal(blocked.tile_hops, before.tile_hops);
    assert.equal(blocked.tile_beats, before.tile_beats);
    fs.mkdirSync(path.dirname(screenshot), { recursive: true });
    await page.screenshot({ path: screenshot });
    await page.keyboard.press('ArrowRight');
    await page.waitForFunction(count => hopanState.tile_hops === count + 1, before.tile_hops);
    console.log(`PASS: Chromium shows blocked-hop reason without a hop or hazard beat, then accepts an open hop; screenshot: ${screenshot}`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
