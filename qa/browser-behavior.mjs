import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const tools = path.resolve(process.env.PARITY_TOOLS_DIR || 'parity-tools');
const {chromium} = createRequire(path.join(tools,'scripts/package.json'))('playwright');
const base = 'http://127.0.0.1:3300/wisprflowisdead';
const output = path.resolve('qa-artifacts/behavior'); fs.mkdirSync(output,{recursive:true});
const results = [];
const browser = await chromium.launch();

async function check(name, width, route, task) {
  const context = await browser.newContext({viewport:{width,height:width === 390 ? 844 : 900},isMobile:width === 390,hasTouch:width === 390,locale:'en-US'});
  const page = await context.newPage(); page.setDefaultTimeout(10000);
  const errors = []; page.on('pageerror', error => errors.push(error.message));
  const result = {name,width,passed:false,errors};
  try {
    const response = await page.goto(base + route,{waitUntil:'load',timeout:30000});
    assert.equal(response.status(),200);
    await task(page);
    assert.deepEqual(errors,[], 'Unexpected application JavaScript errors');
    result.passed = true;
  } catch (error) {result.failure = error.message.slice(0,1800);}
  try {await page.screenshot({path:path.join(output,`${name}-${width}.png`),fullPage:true});}
  catch (error) {result.screenshotError = error.message.slice(0,200); result.passed = false;}
  results.push(result); await context.close();
  fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({results},null,2));
  console.log(`${result.passed ? 'PASS' : 'FAIL'} ${name} ${width}${result.failure ? ': ' + result.failure : ''}`);
}
async function value(page, selector, expected) {
  await page.waitForFunction(({selector,expected}) => document.querySelector(selector)?.value === expected,{selector,expected},{timeout:10000});
}
async function noOverflow(page) {
  const size = await page.evaluate(() => ({content:document.documentElement.scrollWidth,viewport:innerWidth}));
  assert.ok(size.content <= size.viewport, `Horizontal overflow: ${size.content} > ${size.viewport}`);
}
async function confirm(page, text, action) {
  const dialog = page.waitForEvent('dialog').then(async dialog => {
    if (!dialog.message().includes(text)) {await dialog.dismiss(); throw Error('Unexpected confirmation: ' + dialog.message());}
    await dialog.accept();
  });
  await Promise.all([dialog,action()]);
}
try {
  for (const width of [1440,390]) {
    await check('navigation',width,'',async page => {
      await noOverflow(page);
      if (width === 390) {
        const menu = page.locator('.nav .burger');
        await menu.click();
        assert.equal(await menu.getAttribute('aria-expanded'),'true');
        assert.equal(await page.locator('#main-links').isVisible(),true);
        await page.keyboard.press('Escape');
        assert.equal(await menu.getAttribute('aria-expanded'),'false');
        assert.equal(await menu.evaluate(button => document.activeElement === button),true);
        await menu.click();
        await page.locator('#main-links').getByRole('link',{name:'Pricing',exact:true}).click();
        await page.waitForURL(base + '/pricing');
      } else {
        assert.equal(await page.locator('.nav .burger').isVisible(),false);
        assert.equal(await page.locator('.nav [data-account-link]').isVisible(),false);
        const button = await page.locator('.nav > .btn').boundingBox();
        const links = await page.locator('.nav .links').boundingBox();
        assert.ok(button.x >= links.x + links.width, 'Desktop navigation overlaps the CTA');
      }
    });
    await check('pricing',width,'/pricing',async page => {
      await page.locator('[data-billing="monthly"]').click();
      assert.deepEqual(await page.locator('[data-price="pro"]').allTextContents(),['$15','$15']);
      assert.deepEqual(await page.locator('[data-price="growth"]').allTextContents(),['$33','$33']);
      await page.locator('#notetaker-addon').uncheck();
      assert.deepEqual(await page.locator('[data-price="growth"]').allTextContents(),['$23','$23']);
      await page.locator('#roiH').fill('');
      assert.equal(await page.locator('#roiH').getAttribute('aria-invalid'),'true');
      assert.equal(await page.locator('#roiS').textContent(),'—');
      await page.locator('#roiH').fill('3'); await page.locator('#roiR').fill('40');
      assert.equal(await page.locator('#roiS').textContent(),'$15,840');
      const questions = page.locator('.fq'); assert.ok(await questions.count() > 1);
      const second = questions.nth(1); await second.click();
      if (width === 390) {
        assert.equal(await second.getAttribute('aria-expanded'),'true');
        assert.equal(await page.locator('#answer-1').isVisible(),true);
        await second.click(); assert.equal(await second.getAttribute('aria-expanded'),'false');
        const cards = page.locator('.seeall'); assert.equal(await cards.count(),4);
        await cards.nth(0).click(); assert.equal(await page.locator('#plan-features-0').isVisible(),true);
        const comparison = page.locator('.table-scroll');
        await comparison.evaluate(element => {element.scrollLeft = element.scrollWidth;});
        const region = await comparison.boundingBox();
        const enterprise = await page.locator('.topwrap .th').last().boundingBox();
        assert.ok(enterprise.x >= region.x && enterprise.x + enterprise.width <= region.x + region.width,
          'Enterprise comparison cannot be reached in the mobile scroll region');
      } else {
        assert.equal(await second.getAttribute('aria-selected'),'true');
        assert.equal(await page.locator('#faq-answer').getAttribute('aria-labelledby'),await second.getAttribute('id'));
      }
      await noOverflow(page);
    });
    await check('demo',width,'/demo',async page => {
      await page.getByRole('button',{name:'Skip setup',exact:true}).click();
      assert.equal(await page.locator('#setup-guide').isVisible(),false);
      await noOverflow(page);
      await page.locator('.practice summary').click();
      const editor = page.locator('#editor');
      const draft = 'um send the the outline tomorrow question mark';
      await page.locator('#practice-input').fill(draft);
      await page.locator('#practice-submit').click();
      await value(page,'#editor','Send the outline tomorrow?');
      assert.equal(await page.locator('#history-list > li').count(),1);
      await page.locator('#undo').click(); await value(page,'#editor',draft);
      await editor.fill('Keep preFixSuffix.');
      await editor.evaluate(element => element.setSelectionRange(8,11));
      await page.locator('#command-mode').click();
      await page.locator('#command-input').fill('uppercase'); await page.locator('#command-submit').click();
      await value(page,'#editor','Keep preFIXSuffix.');
      assert.deepEqual(await editor.evaluate(element => [element.selectionStart,element.selectionEnd]),[8,11]);
      await page.locator('#undo').click(); await value(page,'#editor','Keep preFixSuffix.');
      await page.locator('#command-input').fill('make it friendlier'); await page.locator('#command-submit').click();
      await page.locator('#state').filter({hasText:'Command not supported'}).waitFor();
      await value(page,'#editor','Keep preFixSuffix.');
      assert.equal(await page.locator('#history-list > li').count(),2);
      await page.locator('#recover').click(); await value(page,'#command-input','make it friendlier');
      await page.locator('#add-entry').click(); await page.locator('#primary').fill('OpenAI');
      await page.locator('#correction').check(); await page.locator('#wrong').fill('open aye');
      await page.locator('#save-entry').click();
      await page.locator('#practice-input').fill('send it to open aye'); await page.locator('#practice-submit').click();
      await value(page,'#editor','Send it to OpenAI.');
      await page.locator('#library-snippet').click(); await page.locator('#add-entry').click();
      await page.locator('#primary').fill('my sign off'); await page.locator('#expansion').fill('Best,\nQA');
      await page.locator('#save-entry').click();
      await page.locator('#practice-input').fill('my sign off'); await page.locator('#practice-submit').click();
      await value(page,'#editor','Best,\nQA');
      await page.locator('#remember-library').check();
      await confirm(page,'Save history in this browser',() => page.locator('#history-mode').selectOption('forever'));
      await page.locator('#open-settings').click(); await page.locator('#settings-dialog').waitFor();
      await page.locator('#settings-style').selectOption('casual'); await page.locator('#remember-settings').check();
      await page.locator('#settings-close').click(); await page.locator('#settings-dialog').waitFor({state:'hidden'});
      await value(page,'#style','casual');
      await page.reload({waitUntil:'load'}); await value(page,'#style','casual');
      assert.equal(await page.locator('#setup-guide').isVisible(),false);
      assert.equal(await page.locator('#history-list > li').count(),4);
      assert.equal(await page.locator('#remember-library').isChecked(),true);
      await confirm(page,'Delete all history',() => page.locator('#history-clear').click());
      assert.equal(await page.locator('#history-list > li').count(),0);
      await noOverflow(page);
    });
  }
} finally {await browser.close();}
if (results.some(result => !result.passed)) process.exitCode = 1;
