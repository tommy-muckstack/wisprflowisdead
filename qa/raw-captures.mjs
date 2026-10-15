// Unmodified viewport captures preserve cookie/banner/animation states hidden by parity.mjs.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const tools = path.resolve(process.env.PARITY_TOOLS_DIR || 'parity-tools');
const {chromium} = createRequire(path.join(tools, 'scripts/package.json'))('playwright');
const output = path.resolve('qa-artifacts/raw'); fs.mkdirSync(output, {recursive:true});
const targets = {original:'https://wisprflow.ai',live:'https://yourappisdead.com',candidate:'http://127.0.0.1:3300'};
const pages = [{name:'home',original:'/',clone:'/wisprflowisdead'}, {name:'pricing',original:'/pricing',clone:'/wisprflowisdead/pricing'}, {name:'login',original:'/get-started',clone:'/wisprflowisdead/login'}];
const results = [];
const browser = await chromium.launch();
try {
  for (const [target, origin] of Object.entries(targets)) for (const item of pages) for (const width of [1440,390]) {
    const context = await browser.newContext({viewport:{width,height:width === 390 ? 844 : 900},deviceScaleFactor:1,isMobile:width === 390,hasTouch:width === 390,locale:'en-US',timezoneId:'America/New_York'});
    const page = await context.newPage(); const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    const entry = {target,page:item.name,width,url:origin + (target === 'original' ? item.original : item.clone),errors};
    try {
      const response = await page.goto(entry.url, {waitUntil:'load',timeout:45000});
      entry.status = response?.status() || 0;
      await page.evaluate(() => Promise.race([document.fonts.ready,new Promise(resolve => setTimeout(resolve,5000))]));
      entry.title = await page.title();
      entry.links = await page.locator('nav a,header a,footer a').evaluateAll(links => links.map(link => ({text:link.textContent.trim(),href:link.href,visible:!!(link.getBoundingClientRect().width && link.getBoundingClientRect().height)})));
      entry.image = `${target}-${item.name}-${width}.png`;
      await page.screenshot({path:path.join(output,entry.image)});
      if (item.name === 'login') {
        entry.initialImage = entry.image;
        // The clone's SDK setup has a 25-second bound; capture the resulting ready/error state.
        await page.waitForFunction(() => {
          const controls = [...document.querySelectorAll('button,input[type=submit]')];
          return controls.some(button => button.getBoundingClientRect().height && !button.disabled &&
            /^(Continue|Retry sign-in setup)$/.test((button.textContent || button.value).trim()));
        },null,{timeout:30000});
        entry.loginReady = await page.locator('button,input[type=submit]').evaluateAll(buttons => buttons.some(button =>
          button.getBoundingClientRect().height && !button.disabled && (button.textContent || button.value).trim() === 'Continue'));
        entry.image = `${target}-login-${width}-settled.png`;
        await page.screenshot({path:path.join(output,entry.image)});
        if (!entry.loginReady) entry.failure = 'Login setup settled in an error state';
      }
      if (item.name === 'pricing') {
        // Keep full-page geometry available through the evidence branch for visual review.
        entry.fullImage = `${target}-pricing-${width}-full.png`;
        await page.screenshot({path:path.join(output,entry.fullImage),fullPage:true});
      }
    } catch (error) {entry.failure = error.message.slice(0,500);}
    results.push(entry); await context.close();
    fs.writeFileSync(path.join(output,'inventory.json'), JSON.stringify(results,null,2));
  }
} finally {await browser.close();}
if (results.some(entry => entry.status !== 200 || entry.failure || (entry.target === 'candidate' && entry.errors.length))) process.exitCode = 1;
