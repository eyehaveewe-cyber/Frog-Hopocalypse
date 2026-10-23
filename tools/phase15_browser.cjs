/* Focused Chromium check of the real editor canvas and save feedback. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const path = require('node:path');

const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8060';
const screenshot = path.resolve(__dirname, '../build/test-results/phase15-unsafe-start.png');
const exitScreenshot = path.resolve(__dirname, '../build/test-results/phase15-missing-exit.png');

async function clickButton(page, name) {
  let state = await page.evaluate(() => window.hopanState);
  let button = state.buttons.find(b => b.text === name);
  assert.ok(button, `Visible button: ${name}`);
  if (button.y > state.ui_size[1] || button.y < 0) {
    await page.mouse.move(200, 500);
    await page.mouse.wheel(0, button.y < 0 ? -700 : 700);
    await page.waitForTimeout(200);
    state = await page.evaluate(() => window.hopanState);
    button = state.buttons.find(b => b.text === name);
  }
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
    await clickButton(page, 'Level editor · Create a maze');
    await page.waitForFunction(() => hopanState.mode === 'edit');
    await clickButton(page, 'New Egypt');
    await page.waitForFunction(() => hopanState.map.name === 'New Egypt');
    await clickButton(page, 'Road');
    await page.waitForFunction(() => hopanState.tool === 'road');
    const state = await page.evaluate(() => window.hopanState);
    const [x, y] = state.map.spawn;
    const [cx, cy] = state.cells[y][x];
    const canvas = await page.locator('canvas').boundingBox();
    await page.mouse.click(canvas.x + cx * canvas.width / state.ui_size[0], canvas.y + cy * canvas.height / state.ui_size[1]);
    await page.waitForFunction(([x, y]) => hopanState.map.tiles[y][x] === 'road', [x, y]);
    await clickButton(page, 'Save');
    await page.waitForFunction(() => hopanState.status.includes('frog start is on a road'));
    const after = await page.evaluate(() => window.hopanState);
    assert.equal(after.map.tiles[y][x], 'road');
    assert.equal(after.saved, 0);
    require('node:fs').mkdirSync(path.dirname(screenshot), { recursive: true });
    await page.screenshot({ path: screenshot });
    console.log(`PASS: Chromium editor shows unsafe-start correction, keeps the road edit, and creates no save; screenshot: ${screenshot}`);
    await clickButton(page, 'Import');
    await page.waitForFunction(() => hopanState.overlay);
    const missingExit = structuredClone(after.map);
    delete missingExit.exit;
    const chooser = page.waitForEvent('filechooser');
    await clickButton(page, 'Open JSON file');
    await (await chooser).setFiles({ name: 'missing-exit.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(missingExit)) });
    await page.waitForFunction(() => hopanState.status.includes('Exit gate is missing'));
    const rejected = await page.evaluate(() => window.hopanState);
    assert.deepEqual(rejected.map, after.map);
    await page.screenshot({ path: exitScreenshot });
    console.log(`PASS: Chromium JSON import explains the missing exit and preserves the editor map; screenshot: ${exitScreenshot}`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
