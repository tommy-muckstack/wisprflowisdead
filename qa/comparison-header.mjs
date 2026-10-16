import assert from 'node:assert/strict';
import {writeFile} from 'node:fs/promises';

// Browser contract: one header follows the rows vertically and shares their horizontal scroll.
export async function checkComparisonHeader(page, width, screenshot) {
  const region = page.locator('.table-scroll');
  const header = page.locator('.topwrap');
  assert.equal(await header.count(),1,'Comparison duplicates its interactive header');
  const bounds = await page.locator('.reference-table').evaluate(element => {
    const box = element.getBoundingClientRect();
    return {top:box.top + scrollY,bottom:box.bottom + scrollY};
  });
  await region.evaluate(element => {element.scrollLeft = 0;});
  await page.evaluate(top => window.scrollTo({top,behavior:'instant'}),bounds.top - 300);
  await page.waitForFunction(() => Math.abs(document.querySelector('.topwrap').getBoundingClientRect().top - 300) < 1);
  await page.evaluate(top => window.scrollTo({top,behavior:'instant'}),bounds.top + 700);
  const top = width <= 900 ? 8 : 16;
  await page.waitForFunction(top => Math.abs(document.querySelector('.topwrap').getBoundingClientRect().top - top) < 1,top);
  async function aligned() {
    const columns = await page.evaluate(() => ({
      headings:[...document.querySelectorAll('.topwrap .th')].map(e => {const r=e.getBoundingClientRect(); return r.x+r.width/2;}),
      cells:[...document.querySelector('.tr').querySelectorAll('.tc')].map(e => {const r=e.getBoundingClientRect(); return r.x+r.width/2;})
    }));
    assert.equal(columns.headings.length,4);
    columns.headings.forEach((x,i) => assert.ok(Math.abs(x-columns.cells[i]) <= 2,'Header and value columns are misaligned'));
  }
  await aligned();
  assert.equal(await header.evaluate(element => {
    const box = element.getBoundingClientRect();
    return element.contains(document.elementFromPoint(innerWidth/2,box.top+30));
  }),true,'Navigation or rows cover the comparison header');
  await page.screenshot({path:screenshot});
  const home = page.locator('.nav .logo');
  await home.evaluate(element => element.focus({preventScroll:true}));
  assert.equal(await home.evaluate(element => {
    const box=element.getBoundingClientRect();
    return element.contains(document.elementFromPoint(box.x+box.width/2,box.y+box.height/2));
  }),true,'Keyboard-focused navigation is covered by the comparison');
  await region.evaluate(element => element.focus({preventScroll:true}));
  if (width <= 900) {
    await region.evaluate(element => element.focus({preventScroll:true}));
    await page.keyboard.press('ArrowRight');
    await page.waitForFunction(() => document.querySelector('.table-scroll').scrollLeft > 0);
    await aligned();
    await header.locator('a').last().focus();
    await page.waitForFunction(() => {
      const region = document.querySelector('.table-scroll').getBoundingClientRect();
      const link = [...document.querySelectorAll('.topwrap a')].at(-1).getBoundingClientRect();
      return link.left >= region.left && link.right <= region.right;
    });
    await page.waitForFunction(top => Math.abs(document.querySelector('.topwrap').getBoundingClientRect().top-top)<1,top);
    await aligned();
    await region.evaluate(element => {element.scrollLeft = element.scrollWidth;});
    const viewport = await region.boundingBox(), enterprise = await header.locator('.th').last().boundingBox();
    assert.ok(enterprise.x >= viewport.x && enterprise.x+enterprise.width <= viewport.x+viewport.width,'Enterprise is clipped');
    await aligned();
    await page.screenshot({path:screenshot.replace('.png','-enterprise.png')});
  }
  await page.emulateMedia({reducedMotion:'reduce'});
  await page.setViewportSize({width:width === 390 ? 1440 : 390,height:width === 390 ? 900 : 844});
  await page.locator('.reference-table').evaluate(element => window.scrollTo({top:element.getBoundingClientRect().top+scrollY+700,behavior:'instant'}));
  await page.waitForFunction(top => Math.abs(document.querySelector('.topwrap').getBoundingClientRect().top-top)<1,width === 390 ? 16 : 8);
  await aligned();
  await page.setViewportSize({width,height:width === 390 ? 844 : 900});
  await page.emulateMedia({reducedMotion:'no-preference'});
  // Breakpoint handlers change card heights above the table. Wait for layout and
  // its scheduled header update, then measure the restored page rather than
  // reusing coordinates from before the two viewport changes.
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  const restoredBounds = await page.locator('.reference-table').evaluate(element => {
    const box=element.getBoundingClientRect();
    return {top:box.top+scrollY,bottom:box.bottom+scrollY};
  });
  await writeFile(screenshot.replace('.png','.json'),JSON.stringify({beforeResize:bounds,afterResize:restoredBounds},null,2));
  // The header must leave with its table, so later sections remain readable/clickable.
  await page.evaluate(top => window.scrollTo({top,behavior:'instant'}),restoredBounds.bottom - 100);
  await page.waitForFunction(() => {
    const header = document.querySelector('.topwrap').getBoundingClientRect();
    const table = document.querySelector('.reference-table').getBoundingClientRect();
    return header.bottom <= table.bottom+1 && header.top < 0;
  }).catch(async error => {
    const geometry=await page.evaluate(() => ({scrollY,header:document.querySelector('.topwrap').getBoundingClientRect().toJSON(),table:document.querySelector('.reference-table').getBoundingClientRect().toJSON()}));
    throw new Error(`Comparison header did not leave at the current table end: ${JSON.stringify(geometry)}`,{cause:error});
  });
  await page.evaluate(top => window.scrollTo({top,behavior:'instant'}),restoredBounds.bottom+300);
  await page.waitForFunction(() => document.querySelector('.topwrap').getBoundingClientRect().bottom <= 0);
  await page.evaluate(() => window.scrollTo({top:0,behavior:'instant'}));
  await page.waitForFunction(() => {
    const header=document.querySelector('.topwrap').getBoundingClientRect(), table=document.querySelector('.reference-table').getBoundingClientRect();
    return Math.abs(header.top-table.top)<1;
  });
}
