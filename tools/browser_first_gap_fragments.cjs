/* Import an impossible first-gap fragment map through the actual browser editor. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8067';
const screenshot = path.resolve(__dirname, '../build/test-results/phase17-first-gap.png');
const map = { version: 1, name: 'Fragments beyond first gap', theme: 'egypt', width: 7, height: 7,
  game_mode: 'tile', rules: { long_hop: 'fragments' }, spawn: [3, 5], exit: [3, 1],
  objects: Array.from({ length: 3 }, (_, i) => ({ id: `fragment_${i}`, type: 'hop_fragment', pos: [i + 2, 2], solid: false })),
  tiles: Array.from({ length: 7 }, (_, y) => Array.from({ length: 7 }, (_, x) =>
    x === 0 || y === 0 || x === 6 || y === 6 ? 'wall' : y === 3 ? 'water' : 'floor')) };

async function click(page, name) {
  const state = await page.evaluate(() => window.hopanState);
  const button = state.buttons.find(b => b.text === name);
  assert.ok(button, `Visible button: ${name}`);
  const canvas = await page.locator('canvas').boundingBox();
  await page.mouse.click(canvas.x + button.x * canvas.width / state.ui_size[0], canvas.y + button.y * canvas.height / state.ui_size[1]);
}

async function importFile(page, level, filename) {
  const chooser = page.waitForEvent('filechooser');
  await click(page, 'Open JSON file');
  await (await chooser).setFiles({ name: filename, mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(level)) });
}

(async () => {
  const browser = await chromium.launch({ executablePath: process.env.HOPAN_CHROMIUM || '/usr/bin/chromium', headless: true,
    args: ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'] });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 1200 } });
    await page.goto(base + '/?browser-test=1');
    await page.waitForFunction(() => window.hopanState && !document.getElementById('loading'));
    await click(page, 'Level editor · Create a maze');
    await page.waitForFunction(() => hopanState.mode === 'edit');
    await click(page, 'New Egypt');
    await page.waitForFunction(() => hopanState.map.name === 'New Egypt');
    const original = (await page.evaluate(() => window.hopanState)).map;
    await click(page, 'Import');
    await page.waitForFunction(() => hopanState.overlay);
    await importFile(page, map, 'fragments-beyond-gap.json');
    await page.waitForFunction(() => hopanState.status.includes('three fragments reachable by short hops before the gap'));
    const rejected = await page.evaluate(() => window.hopanState);
    assert.deepEqual(rejected.map, original);
    fs.mkdirSync(path.dirname(screenshot), { recursive: true });
    await page.screenshot({ path: screenshot });
    const fixed = structuredClone(map);
    fixed.objects.forEach((item, i) => { item.pos = [i + 2, 4]; });
    await importFile(page, fixed, 'reachable-fragments.json');
    await page.waitForFunction(() => hopanState.editor_leave_open);
    await click(page, 'No · Leave without saving');
    await page.waitForFunction(() => hopanState.mode === 'edit' && hopanState.map.name === 'Fragments beyond first gap' && !hopanState.overlay);
    console.log(`PASS: Chromium rejects inaccessible pre-gap fragments without losing edits and imports corrected map; screenshot: ${screenshot}`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
