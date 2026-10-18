/* Focused WebGL2 checks. This is desktop SwiftShader with Android UA/touch,
 * not Android Chrome or evidence of physical-device recovery.
 * Serve build/ on :8060 after a debug Web export into build/test-web/.
 * Optionally export unmodified v12 into build/baseline/ for comparison. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const base = process.env.HOPAN_TEST_URL || 'http://127.0.0.1:8060/test-web/';
const results = [];
async function capture() {
  window.linkedShaders = [];
  const original = WebGL2RenderingContext.prototype.linkProgram;
  WebGL2RenderingContext.prototype.linkProgram = function (program) {
    original.call(this, program);
    const sources = (this.getAttachedShaders(program) || []).map(s => this.getShaderSource(s));
    window.linkedShaders.push({ ok: this.getProgramParameter(program, this.LINK_STATUS),
      log: this.getProgramInfoLog(program), sources });
  };
}
(async () => {
  const browser = await chromium.launch({ executablePath: process.env.HOPAN_CHROMIUM || '/usr/bin/chromium',
    args: ['--no-sandbox', '--enable-unsafe-swiftshader', '--use-angle=swiftshader'] });
  try {
    await fs.mkdir('build/test-results', { recursive: true });
    for (const mode of ['android', 'compat', 'retro', ...(process.env.HOPAN_BASELINE_URL ? ['baseline'] : [])]) {
      const context = await browser.newContext({ viewport: { width: 844, height: 390 }, isMobile: true, hasTouch: true,
        userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 6) AppleWebKit/537.36 Chrome/130.0.0.0 Mobile Safari/537.36' });
      await context.addInitScript(capture);
      const page = await context.newPage();
      const errors = [];
      page.on('pageerror', e => errors.push(e.message));
      page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
      const url = new URL(mode === 'baseline' ? process.env.HOPAN_BASELINE_URL : base);
      url.searchParams.set('browser-test', '1');
      if (mode !== 'android') url.searchParams.set('compat', mode === 'retro' ? '0' : '1');
      if (mode !== 'baseline' && mode !== 'compat') url.searchParams.set('graphics-debug', '1');
      await page.goto(url.href);
      await page.waitForFunction(() => window.hopanState && !document.getElementById('loading'), null, { timeout: 60000 });
      assert.equal(await page.evaluate(() => hopanState.compatibility_mode), mode !== 'retro');
      assert.equal(await page.evaluate(() => !!window.hopanGraphicsReport), !['baseline', 'compat'].includes(mode));
      const click = async text => {
        const state = await page.evaluate(() => hopanState);
        const button = state.buttons.find(b => b.text.includes(text));
        assert.ok(button, `button ${text}`);
        await page.mouse.click(button.x * 844 / state.ui_size[0], button.y * 390 / state.ui_size[1]);
      };
      const compactMenu = await page.evaluate(() => hopanState.buttons.some(b => b.text === 'Baby Mode'));
      await click(compactMenu ? 'Baby Mode' : 'Play ·');
      await page.waitForFunction(() => hopanState.mode === 'play' && !hopanState.overlay);
      await page.waitForFunction(() => !hopanState.intro_active);
      const before = await page.evaluate(() => hopanState.player[0]);
      await page.keyboard.down('d');
      await page.waitForFunction(x => hopanState.player[0] > x + 0.15, before);
      await page.keyboard.up('d');
      await page.keyboard.press('m');
      await page.waitForFunction(() => hopanState.map_view);
      await click('3D view');
      await page.waitForFunction(() => !hopanState.map_view);
      if (compactMenu) {
        await page.keyboard.press('Escape');
        await page.waitForFunction(() => hopanState.paused);
        await click('Menu');
        await page.waitForFunction(() => hopanState.buttons.some(b => b.text === 'Bonus'));
        await click('Bonus');
        await page.waitForFunction(() => hopanState.map.name === 'Shelby' && !hopanState.overlay);
      }
      await page.screenshot({ path: `build/test-results/android-${mode}.png` });
      assert.deepEqual(errors, []);
      const programs = await page.evaluate(() => linkedShaders);
      assert.ok(programs.every(p => p.ok));
      const scene = programs.filter(p => p.sources.some(s => s.includes('#define MAX_FORWARD_LIGHTS')));
      const materialScene = scene.filter(p => p.sources.some(s => /^#define MATERIAL_UNIFORMS_USED\s*$/m.test(s)));
      assert.ok(scene.length);
      const lit = scene.filter(p => p.sources.some(s => /^#define USE_VERTEX_LIGHTING\s*$/m.test(s)));
      const unshaded = scene.filter(p => p.sources.some(s => /^#define MODE_UNSHADED\s*$/m.test(s)));
      if (['android', 'compat'].includes(mode)) {
        assert.equal(lit.length, 0, 'safe path must avoid vertex-lighting variants');
        assert.equal(unshaded.length, materialScene.length, 'all game material variants unshaded');
      } else assert.ok(lit.length, 'baseline and retro retain lit scene variants');
      results.push({ mode, programs: programs.length, scenePrograms: scene.length, vertexLit: lit.length,
        unshaded: unshaded.length, materialScenePrograms: materialScene.length, errors, graphics: await page.evaluate(() => window.hopanGraphicsReport || null) });
      if (mode === 'android') {
        // Individually valid stages with incompatible varying types: actual
        // desktop linker failure used only to verify report/recovery handling.
        await page.evaluate(() => {
          const gl = document.getElementById('canvas').getContext('webgl2');
          const program = gl.createProgram();
          for (const [type, source] of [
            [gl.VERTEX_SHADER, '#version 300 es\nprecision highp float; out vec3 mismatch; void main(){mismatch=vec3(1.0); gl_Position=vec4(0.0,0.0,0.0,1.0);}'],
            [gl.FRAGMENT_SHADER, '#version 300 es\nprecision highp float; in vec4 mismatch; out vec4 color; void main(){color=mismatch;}']]) {
            const shader = gl.createShader(type); gl.shaderSource(shader, source); gl.compileShader(shader); gl.attachShader(program, shader); gl.deleteShader(shader);
          }
          gl.linkProgram(program); gl.deleteProgram(program);
          for (let i = 0; i < 40; i++) hopanBoot.log('ERROR: Method/function failed.');
        });
        const failure = await page.evaluate(() => hopanGraphicsReport.failures[0]);
        assert.ok(failure.log && failure.shaders.length === 2);
        assert.ok(failure.shaders.every(s => s.compiled && s.source.includes('mismatch')));
        assert.ok((await page.locator('#detail').textContent()).includes(failure.log));
        const download = page.waitForEvent('download');
        await page.getByRole('button', { name: 'Save graphics report' }).click();
        const downloaded = await download;
        const contents = JSON.parse(await fs.readFile(await downloaded.path(), 'utf8'));
        assert.equal(contents.failures[0].log, failure.log);
        results.push({ mode: 'injected-link-failure', log: failure.log, reportDownload: true, recovery: await page.locator('#recovery').isVisible() });
      }
      await context.close();
      console.log('PASS:', mode, 'startup, movement, map and shader variants');
    }
    await fs.mkdir('build/test-results', { recursive: true });
    await fs.writeFile('build/test-results/android-shaders.json', JSON.stringify(results, null, 2));
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
