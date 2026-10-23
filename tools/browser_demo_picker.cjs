/* Check the documented unsaved-map choice before replacing an editor map. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8066';
const screenshot = path.resolve(__dirname, '../build/test-results/demo-picker-unsaved.png');

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
    const page = await browser.newPage({ viewport: { width: 1280, height: 1600 } });
    await page.goto(base + '/?browser-test=1');
    await page.waitForFunction(() => window.hopanState && !document.getElementById('loading'));
    await click(page, 'Level editor · Create a maze');
    await page.waitForFunction(() => hopanState.mode === 'edit');
    await click(page, 'New Egypt');
    await page.waitForFunction(() => hopanState.map.name === 'New Egypt');
    await click(page, 'Movement demos');
    await page.waitForFunction(() => hopanState.buttons.some(b => b.text === 'Big Hop Boulevard'));
    await click(page, 'Big Hop Boulevard');
    await page.waitForFunction(() => hopanState.editor_leave_open);
    const pending = await page.evaluate(() => window.hopanState);
    assert.equal(pending.map.name, 'New Egypt');
    assert.ok(pending.buttons.some(b => b.text === 'No · Leave without saving'));
    fs.mkdirSync(path.dirname(screenshot), { recursive: true });
    await page.screenshot({ path: screenshot });
    await click(page, 'No · Leave without saving');
    await page.waitForFunction(() => hopanState.mode === 'edit' && hopanState.map.name === 'Big Hop Boulevard' && !hopanState.editor_leave_open);
    const loaded = await page.evaluate(() => window.hopanState);
    assert.equal(loaded.map.game_mode, 'tile');
    assert.equal(loaded.map.move_with_me, false);
    console.log(`PASS: Chromium demo picker protects unsaved map and loads Tile Hop after explicit choice; screenshot: ${screenshot}`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
