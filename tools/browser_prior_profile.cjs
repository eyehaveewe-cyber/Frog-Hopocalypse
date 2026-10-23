/* Load a v47 localStorage profile in the current debug Web build. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');

const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8060';
// Matches the fields saved by game/scripts/main.gd at commit 0e6f93f.
const prior = { version: 1, baby: [0, 1, 2, 3], human: [0, 1], bonus: [0, 1, 2], tile: [0],
  last_cleared: { baby: 3, human: 1, bonus: 2, tile: 0 }, hat: 'baby', skin: 'purple',
  preview: false, sound: true, seen_rules: [] };

function check(state, stored) {
  assert.deepEqual(state.completed_stages, prior.baby);
  assert.deepEqual(state.completed_human_stages, prior.human);
  assert.deepEqual(state.completed_bonus_stages, prior.bonus);
  assert.deepEqual(state.completed_sync_stages, []);
  assert.ok(state.unlocked_hats.includes('baby'));
  assert.equal(state.hat, 'baby');
  assert.equal(state.skin, 'purple');
  for (const field of ['baby', 'human', 'bonus', 'tile', 'last_cleared'])
    assert.deepEqual(stored[field], prior[field], `${field} changed during migration`);
  assert.equal(stored.hat, 'baby');
  assert.equal(stored.skin, 'purple');
}

(async () => {
  const browser = await chromium.launch({ executablePath: process.env.HOPAN_CHROMIUM || '/usr/bin/chromium', headless: true,
    args: ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'] });
  try {
    const context = await browser.newContext({ viewport: { width: 1280, height: 800 } });
    await context.addInitScript(old => {
      if (sessionStorage.getItem('phase69-seeded')) return;
      localStorage.setItem('hopan.profile.v1', JSON.stringify(old));
      sessionStorage.setItem('phase69-seeded', '1');
    }, prior);
    const page = await context.newPage();
    for (const pass of ['first load', 'reload']) {
      if (pass === 'first load') await page.goto(base + '/?browser-test=1');
      else await page.reload();
      await page.waitForFunction(() => window.hopanState && !document.getElementById('loading'));
      const result = await page.evaluate(() => ({ state: window.hopanState, stored: JSON.parse(localStorage.getItem('hopan.profile.v1')) }));
      check(result.state, result.stored);
      console.log(`PASS: v47 browser profile retains completed maps and baby hat on ${pass}`);
    }
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
