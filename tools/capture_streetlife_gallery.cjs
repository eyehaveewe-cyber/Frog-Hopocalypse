/* Repeatable debug-export art evidence. HOPAN_TEST_URL defaults to local test server. */
const { chromium } = require('playwright');
const fs = require('node:fs/promises');
const path = require('node:path');
const assert = require('node:assert/strict');
const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8060';
const output = path.resolve(__dirname, '../docs/assets/nyc_streetlife/previews');

(async () => {
  await fs.mkdir(output, { recursive: true });
  const browser = await chromium.launch({ executablePath: process.env.HOPAN_CHROMIUM || '/usr/bin/chromium', headless: true,
    args: ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'] });
  const errors = [];
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    const kinds = (process.env.HOPAN_GALLERY_VEHICLES || 'roach,skater0,skater1,skater2,props').split(',');
    assert.ok(kinds.every(kind => ['roach','skater0','skater1','skater2','props'].includes(kind)), 'Known vehicle kinds required');
    for (const kind of kinds) {
      for (const view of ['front', 'side', 'threequarter']) {
        await page.goto(`${base}/?streetlife-gallery=${view}&asset=${kind}`);
        await page.waitForFunction(({ kind, view }) => window.streetlifeGalleryReady?.kind === kind && window.streetlifeGalleryReady?.view === view,
          { kind, view }, { timeout: 30000 });
        await page.waitForFunction(() => !document.getElementById('loading'));
        await page.waitForTimeout(350);
        const file = `${kind}_${view}.png`;
        await page.screenshot({ path: path.join(output, file) });
        console.log(`CAPTURED ${file}`);
      }
    }
    assert.equal(errors.length, 0, errors.join('\n'));
    await fs.writeFile(path.join(output, kinds.length === 5 ? 'capture.json' : `capture-${kinds.join('-')}.json`), JSON.stringify({ viewport: [1280, 800], images: kinds.length * 3, vehicles: kinds, errors, renderer: 'Godot Web debug export / Chromium SwiftShader' }, null, 2) + '\n');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
