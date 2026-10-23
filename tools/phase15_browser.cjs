/* Focused Chromium check of the real editor canvas and save feedback. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const path = require('node:path');

const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8060';
const screenshot = path.resolve(__dirname, '../build/test-results/phase15-unsafe-start.png');
const exitScreenshot = path.resolve(__dirname, '../build/test-results/phase15-missing-exit.png');
const fragmentScreenshot = path.resolve(__dirname, '../build/test-results/phase15-impossible-fragments.png');
const anchorScreenshot = path.resolve(__dirname, '../build/test-results/phase15-seam-anchor.png');

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
    await clickButton(page, 'Cancel');
    await page.waitForFunction(() => !hopanState.overlay);
    await clickButton(page, 'Import');
    await page.waitForFunction(() => hopanState.overlay);
    const fragmentMap = structuredClone(after.map);
    fragmentMap.name = 'Fragment gap';
    fragmentMap.width = 7;
    fragmentMap.height = 7;
    fragmentMap.tiles = Array.from({ length: 7 }, (_, row) => Array.from({ length: 7 }, (_, col) =>
      col === 0 || row === 0 || col === 6 || row === 6 ? 'wall' : row === 3 ? 'water' : 'floor'));
    fragmentMap.spawn = [3, 5];
    fragmentMap.exit = [3, 1];
    fragmentMap.game_mode = 'tile';
    fragmentMap.rules = { long_hop: 'fragments' };
    const fragmentChooser = page.waitForEvent('filechooser');
    await clickButton(page, 'Open JSON file');
    await (await fragmentChooser).setFiles({ name: 'fragment-gap.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(fragmentMap)) });
    await page.waitForFunction(() => hopanState.status.includes('fewer than three fragments'));
    const resourceRejected = await page.evaluate(() => window.hopanState);
    assert.deepEqual(resourceRejected.map, after.map);
    await page.screenshot({ path: fragmentScreenshot });
    console.log(`PASS: Chromium JSON import explains impossible fragments and preserves the editor map; screenshot: ${fragmentScreenshot}`);
    await clickButton(page, 'Cancel');
    await page.waitForFunction(() => !hopanState.overlay);
    await clickButton(page, 'Import');
    await page.waitForFunction(() => hopanState.overlay);
    const seamMap = structuredClone(after.map);
    seamMap.name = 'Misplaced seam anchor';
    seamMap.tiles = Array.from({ length: seamMap.height }, (_, row) => Array.from({ length: seamMap.width }, (_, col) =>
      col === 0 || row === 0 || col === seamMap.width - 1 || row === seamMap.height - 1 ? 'wall' : 'floor'));
    seamMap.objects = [{ id: 'worm', type: 'critter', pos: [5.5, 5.5], behavior: 'seam_patrol', waypoints: [], seam_anchor: [10, 10], speed: 1.6 }];
    const seamChooser = page.waitForEvent('filechooser');
    await clickButton(page, 'Open JSON file');
    await (await seamChooser).setFiles({ name: 'misplaced-seam.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(seamMap)) });
    await page.waitForFunction(() => hopanState.status.includes('placement tile must touch its corner'));
    const seamRejected = await page.evaluate(() => window.hopanState);
    assert.deepEqual(seamRejected.map, after.map);
    await page.screenshot({ path: anchorScreenshot });
    console.log(`PASS: Chromium JSON import explains misplaced seam anchor and preserves the editor map; screenshot: ${anchorScreenshot}`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
