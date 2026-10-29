/* Exercise the packaged game through ordinary menu, keyboard and touch input.
 * The existing debug export probe is read only. No game state is injected.
 * Profile seeding below represents a returning player's saved browser profile.
 */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const out = 'docs/nyc-difficulty-evidence';
const debugURL = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8115/';
const releaseURL = process.env.HOPAN_RELEASE_URL || 'http://127.0.0.1:8116/';
const checks = [], errors = [], screenshots = [], selections = [];
fs.mkdirSync(out, { recursive: true });
const sets = [
  { key: 'nyc', title: 'New York City', prefix: 'nyc_' },
  { key: 'streetlife', title: 'NYC Streetlife', prefix: 'streetlife_' }
].map(set => ({ ...set, levels: fs.readdirSync('game/levels').filter(f => f.startsWith(set.prefix) && f.endsWith('.json')).sort().map(f => ({ file: f, data: JSON.parse(fs.readFileSync(path.join('game/levels', f))) })) }));
function check(ok, text) { assert.ok(ok, text); checks.push(text); console.log('PASS: ' + text); }
function serializedGeometry(value) {
  return JSON.parse(JSON.stringify(value, (_, item) => typeof item === 'number' ? Math.round(item * 1e6) / 1e6 : item));
}
async function state(page) { return page.evaluate(() => window.hopanState); }
function listen(page) {
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
}
async function ready(page) {
  await page.waitForFunction(() => window.hopanState && !document.getElementById('loading'), null, { timeout: 120000 });
}
async function clickWhere(page, choose, touch = false) {
  for (let attempt = 0; attempt < 50; attempt++) {
    const s = await state(page), b = choose(s);
    // The read-only probe refreshes on an engine frame. A slower software
    // renderer may finish a menu animation before publishing its next probe.
    if (!b) { await page.waitForTimeout(150); continue; }
    const c = await page.locator('canvas').boundingBox();
    const x = c.x + b.x * c.width / s.ui_size[0];
    const y = c.y + b.y * c.height / s.ui_size[1];
    if (b.y > 18 && b.y < s.ui_size[1] - 20) {
      if (touch) await page.touchscreen.tap(x, y); else await page.mouse.click(x, y);
      await page.waitForTimeout(300);
      return;
    }
    await page.mouse.move(Math.min(x, c.x + c.width - 20), c.y + c.height * .55);
    await page.mouse.wheel(0, b.y < 18 ? -150 : 150);
    await page.waitForTimeout(110);
  }
  throw new Error('Game button did not become available inside the menu viewport');
}
async function click(page, text, touch = false) {
  return clickWhere(page, s => s.buttons.find(b => b.text === text), touch);
}
async function chooseLevel(page, set, index, touch = false) {
  const s = await state(page);
  if (s.mode !== 'menu' || !s.buttons.some(b => b.text === 'Levels')) await click(page, 'Menu', touch);
  await click(page, 'Levels', touch);
  await clickWhere(page, s => {
    const row = s.buttons.find(b => b.text === set.title);
    return row && s.buttons.find(b => b.text === '+' && Math.abs(b.y - row.y) < 3);
  }, touch);
  await click(page, 'Play · ' + set.levels[index].data.name, touch);
  await page.waitForFunction(() => hopanState.mode === 'play' && (!hopanState.overlay || hopanState.buttons.some(b => b.text === 'Play')));
  if ((await state(page)).buttons.some(b => b.text === 'Play')) await click(page, 'Play', touch);
  await page.waitForFunction(() => !hopanState.overlay && !hopanState.intro_active && !hopanState.begin_pending, null, { timeout: 20000 });
}
async function screenshot(page, name) {
  const file = path.join(out, name + '.png');
  await page.screenshot({ path: file }); screenshots.push(file);
}
async function keyFor(page, key, duration) {
  await page.keyboard.down(key);
  await page.waitForTimeout(duration);
  await page.keyboard.up(key);
  await page.waitForTimeout(180);
}
async function verifyWallAndRetry(page, set) {
  await chooseLevel(page, set, 0);
  const start = await state(page);
  await keyFor(page, 's', 1800);
  const stopped = await state(page);
  await keyFor(page, 's', 1000);
  const held = await state(page);
  check(stopped.player[1] > start.player[1] + .1 && Math.abs(held.player[1] - stopped.player[1]) < .08 && !held.result,
    set.title + ': ordinary movement reaches the southern wall and cannot pass through it');
  await page.keyboard.press('r');
  await page.waitForFunction(() => !hopanState.overlay && !hopanState.intro_active && !hopanState.begin_pending);
  const retry = await state(page);
  check(Math.hypot(retry.player[0] - start.player[0], retry.player[1] - start.player[1]) < .08 && retry.stage === 0 && retry.campaign_set === set.key,
    set.title + ': R retries the selected level at its original spawn');
  await keyFor(page, 'w', 300);
  const moved = await state(page);
  check(moved.player[1] < retry.player[1] - .15 && !moved.result,
    set.title + ': keyboard controls move the frog into the level after retry');
  if (set.key === 'nyc') {
    await page.keyboard.down('w');
    try { await page.waitForFunction(() => hopanState.result.length > 0, null, { timeout: 15000 }); }
    finally { await page.keyboard.up('w'); }
    check((await state(page)).result !== 'LEVEL COMPLETE!', 'Central Park: rushing straight into the pond triggers a real gameplay failure');
    await page.waitForFunction(() => hopanState.overlay);
    await page.keyboard.press('r');
    await page.waitForFunction(() => !hopanState.overlay && !hopanState.result && !hopanState.begin_pending);
    const recovered = await state(page);
    check(Math.hypot(recovered.player[0] - start.player[0], recovered.player[1] - start.player[1]) < .08,
      'Central Park: retry after water failure returns to the safe spawn');
  }
}
async function run() {
  const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', headless: true,
    args: ['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  let currentPage;
  try {
    const context = await browser.newContext({ viewport: { width: 1280, height: 800 } });
    await context.addInitScript(() => {
      if (localStorage.getItem('difficulty-test.seeded')) return;
      localStorage.setItem('difficulty-test.seeded', 'yes');
      localStorage.setItem('hopan.profile.v1', JSON.stringify({ version: 1, baby: [0,1,2,3], human: [0,1,2,3], bonus: [], tile: [], sync: [], city: { nyc: [0,2], streetlife: [1] }, hat: 'morning', skin: 'purple_white', preview: false, sound: false, seen_rules: [] }));
    });
    const page = currentPage = await context.newPage(); listen(page);
    await page.goto(debugURL + '?browser-test=1&splash=6'); await ready(page);
    check((await state(page)).buttons[0].text === 'Play Baby Mode', 'Baby Mode remains the first main-menu action');
    for (const set of sets) {
      assert.equal(set.levels.length, 6);
      for (let i = 0; i < set.levels.length; i++) {
        await chooseLevel(page, set, i);
        const s = await state(page), expected = set.levels[i].data;
        assert.deepEqual(s.map.tiles, expected.tiles);
        assert.deepEqual(s.map.spawn, expected.spawn);
        assert.deepEqual(s.map.exit, expected.exit);
        assert.deepEqual(serializedGeometry(s.map.objects), serializedGeometry(expected.objects));
        check(s.campaign_set === set.key && s.stage === i && s.map.name === expected.name && !s.result,
          expected.name + ': selected from the real level menu and renders the packaged candidate layout');
        selections.push({ set: set.key, stage: i, name: s.map.name, traffic: s.city_traffic, skaters: s.city_skaters });
        if (i === 5) await screenshot(page, set.key + '-' + (i+1) + '-play');
        await click(page, 'Map');
        await page.waitForFunction(() => hopanState.map_view);
        const elapsed = (await state(page)).elapsed;
        await page.waitForTimeout(400);
        check((await state(page)).elapsed === elapsed, expected.name + ': overhead inspection pauses the hazards');
        if (i === (set.key === 'nyc' ? 4 : 5)) await screenshot(page, set.key + '-' + (i+1) + '-map');
        await click(page, '3D view');
        await page.waitForFunction(() => !hopanState.map_view);
      }
      await verifyWallAndRetry(page, set);
    }
    await page.reload(); await ready(page);
    const resumed = await state(page);
    check(JSON.stringify(resumed.city_progress) === JSON.stringify({ nyc: [0,2], streetlife: [1] }) && resumed.completed_stages.length === 4,
      'Returning-player city clears and Baby Mode progress survive both redesigned sets and reload');
    check(resumed.hat === 'morning' && resumed.skin === 'purple_white', 'Existing outfit and frog color survive reload');
    await context.close();

    const mobile = await browser.newContext({ viewport: { width: 844, height: 390 }, isMobile: true, hasTouch: true,
      userAgent: 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/131.0.0.0 Mobile Safari/537.36' });
    const touchPage = currentPage = await mobile.newPage(); listen(touchPage);
    await touchPage.goto(debugURL + '?browser-test=1&splash=6'); await ready(touchPage);
    const cdp = await mobile.newCDPSession(touchPage);
    for (const set of sets) {
      await chooseLevel(touchPage, set, 0, true);
      const before = await state(touchPage);
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 110, y: 290, id: 0 }] });
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: 110, y: 245, id: 0 }] });
      await touchPage.waitForTimeout(350);
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
      await touchPage.waitForTimeout(300);
      const after = await state(touchPage);
      check(after.player[1] < before.player[1] - .15 && !after.result, set.title + ': touch joystick moves the frog in landscape emulation');
      await screenshot(touchPage, set.key + '-mobile');
      await click(touchPage, 'Map', true);
      check((await state(touchPage)).map_view, set.title + ': touch opens the overhead map');
      await click(touchPage, '3D view', true);
    }
    await mobile.close();

    const release = await browser.newContext({ viewport: { width: 1280, height: 800 } });
    const releasePage = currentPage = await release.newPage(); listen(releasePage);
    await releasePage.goto(releaseURL + '?splash=6');
    await releasePage.waitForFunction(() => !document.getElementById('loading'), null, { timeout: 120000 });
    await releasePage.waitForTimeout(1500);
    check(await releasePage.evaluate(() => typeof window.hopanState === 'undefined'), 'Normal release starts without exposing the debug probe');
    await screenshot(releasePage, 'release-main');
    await release.close();
    check(errors.length === 0, 'No captured browser or engine console errors');
    fs.writeFileSync(path.join(out, 'browser.json'), JSON.stringify({ checks, errors, selections, screenshots,
      scope: 'Chromium WebGL with SwiftShader. Actual mouse/keyboard/touch events and read-only debug-export observations. The normal release startup is separately checked. Not physical mobile hardware, human attempt counts, or full browser-route completion.' }, null, 2) + '\n');
    console.log(JSON.stringify({ checks: checks.length, errors }));
  } catch (error) {
    if (currentPage && !currentPage.isClosed()) await currentPage.screenshot({ path: path.join(out, 'failure.png') }).catch(() => {});
    fs.writeFileSync(path.join(out, 'browser-failed.json'), JSON.stringify({ error: error.stack, checks, errors }, null, 2) + '\n');
    throw error;
  } finally { await browser.close(); }
}
run().catch(error => { console.error(error.stack); process.exitCode = 1; });
