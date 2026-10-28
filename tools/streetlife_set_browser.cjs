/* Actual menu, keyboard and pointer input against the debug Web export. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8060';
const output = path.resolve(__dirname, '../build/test-results/streetlife-set');
let checks = 0;
const errors = [];
const check = (value, description) => { assert.ok(value, description); checks++; console.log('PASS:', description); };
const state = page => page.evaluate(() => window.hopanState);
const wait = (page, predicate, argument) => page.waitForFunction(predicate, argument, { timeout: 45000 });

async function click(page, match) {
  for (let attempt = 0; attempt < 48; attempt++) {
    const snapshot = await state(page);
    const button = snapshot.buttons.find(item => typeof match === 'string' ? item.text === match : match.test(item.text));
    assert.ok(button, `Menu entry exists: ${match}`);
    const bounds = await page.locator('canvas').boundingBox();
    if (button.y > 15 && button.y < snapshot.ui_size[1] - 15) {
      await page.mouse.click(bounds.x + button.x * bounds.width / snapshot.ui_size[0], bounds.y + button.y * bounds.height / snapshot.ui_size[1]);
      return;
    }
    await page.mouse.move(bounds.x + bounds.width * .5, bounds.y + bounds.height * .5);
    await page.mouse.wheel(0, button.y < 15 ? -320 : 320);
    await page.waitForTimeout(150);
  }
  throw new Error(`Could not scroll to ${match}`);
}

async function open(page) {
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
  await page.goto(`${base}/?browser-test=1`);
  await wait(page, () => window.hopanState && !document.getElementById('loading'));
}

async function selectLevel(page, index) {
  await click(page, new RegExp(`^Play · Streetlife 0${index}`, "i"));
  await wait(page, desired => hopanState.mode === 'play' && !hopanState.overlay && hopanState.map.level_set === 'nyc_streetlife' && hopanState.map.set_index === desired, index);
}

(async () => {
  await fs.mkdir(output, { recursive: true });
  const browser = await chromium.launch({ executablePath: process.env.HOPAN_CHROMIUM || '/usr/bin/chromium', headless: true,
    args: ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'] });
  try {
    const desktop = await browser.newContext({ viewport: { width: 1280, height: 800 }, acceptDownloads: true });
    const page = await desktop.newPage();
    await open(page);
    const menu = await state(page);
    check(menu.buttons.filter(button => /^Play · Streetlife 0[1-6]/i.test(button.text)).length === 6, 'The menu offers all six maps in the new Streetlife set');
    check(menu.buttons.some(button => button.text === 'Start NYC Streetlife · 6 levels'), 'The set has a direct start entry separate from the earlier campaign');
    await click(page, 'Start NYC Streetlife · 6 levels');
    await wait(page, () => hopanState.map.level_set === 'nyc_streetlife' && hopanState.map.set_index === 1 && hopanState.mode === 'play' && !hopanState.overlay);
    check(true, 'Starting the set launches level one with the ordinary game controls');
    const first = await state(page);
    await click(page, 'Pause');
    await wait(page, () => hopanState.paused);
    const paused = await state(page);
    await page.waitForTimeout(350);
    const still = await state(page);
    check(still.elapsed === paused.elapsed && JSON.stringify(still.streetlife) === JSON.stringify(paused.streetlife) && JSON.stringify(still.traffic) === JSON.stringify(paused.traffic), 'Pause freezes the complete set encounter');
    await click(page, 'Resume');
    await wait(page, () => !hopanState.paused);
    await wait(page, elapsed => hopanState.elapsed > elapsed + .25, paused.elapsed);
    const priorRetry = await state(page);
    await page.keyboard.press('r');
    await wait(page, before => hopanState.result === '' && hopanState.map.set_index === 1 && hopanState.elapsed < before, priorRetry.elapsed);
    check((await state(page)).map.name === first.map.name, 'Retry resets the encounter clock while preserving the selected set level');
    await click(page, 'Menu');
    await wait(page, () => hopanState.overlay);
    const summaries = [];
    for (let index = 1; index <= 6; index++) {
      await selectLevel(page, index);
      const playing = await state(page);
      check(playing.result === '' && playing.map.set_index === index, `Set map ${index} starts without a stale encounter result`);
      summaries.push({ index, name: playing.map.name, riders: playing.streetlife.skaters.length, roaches: playing.streetlife.roaches.length, props: playing.streetlife.prop_count, traffic: playing.traffic.count });
      await page.screenshot({ path: path.join(output, `level-${index}-gameplay.png`) });
      await page.keyboard.press('m');
      await wait(page, () => hopanState.map_view);
      const overview = await state(page);
      await page.waitForTimeout(250);
      const frozen = await state(page);
      check(frozen.elapsed === overview.elapsed && JSON.stringify(frozen.streetlife) === JSON.stringify(overview.streetlife), `Map inspection freezes level ${index} while keeping its authored assets visible`);
      await page.screenshot({ path: path.join(output, `level-${index}-overview.png`) });
      await click(page, '3D view');
      await wait(page, () => !hopanState.map_view);
      await click(page, 'Menu');
      await wait(page, () => hopanState.overlay);
    }
    await selectLevel(page, 6);
    await click(page, 'Editor');
    await wait(page, () => hopanState.mode === 'edit');
    const downloadEvent = page.waitForEvent('download');
    await click(page, 'Export JSON');
    const download = await downloadEvent;
    const saved = path.join(output, 'finale-export.json');
    await download.saveAs(saved);
    const exported = JSON.parse(await fs.readFile(saved, 'utf8'));
    check(exported.level_set === 'nyc_streetlife' && exported.set_index === 6 && exported.objects.some(object => object.type === 'skater') && exported.objects.some(object => object.type === 'city_prop'), 'The editor exports the finale with set identity, enemies and city assets');
    await desktop.close();
    const mobile = await browser.newContext({ viewport: { width: 844, height: 390 }, isMobile: true, hasTouch: true });
    const phone = await mobile.newPage();
    await open(phone);
    await selectLevel(phone, 6);
    const finale = await state(phone);
    check(finale.ui_size[0] === 844 && finale.map.set_index === 6 && finale.streetlife.skaters.length > 0, 'The final set map loads with its enemies in a landscape phone viewport');
    await phone.screenshot({ path: path.join(output, 'level-6-mobile.png') });
    await mobile.close();
    check(errors.length === 0, 'The complete six-map browser sequence has no JavaScript or Godot runtime errors');
    await fs.writeFile(path.join(output, 'browser-summary.json'), JSON.stringify({ checks, failures: 0, maps: summaries, errors }, null, 2) + '\n');
    console.log(`STREETLIFE SET BROWSER: ${checks} checks, 0 failures`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); console.error(errors); process.exitCode = 1; });
