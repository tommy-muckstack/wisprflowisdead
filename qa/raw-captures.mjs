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
    page.on('response', response => {
      if (target === 'candidate' && response.url().startsWith(origin + '/wisprflowisdead/assets/') && response.status() >= 400) errors.push(`Asset HTTP ${response.status()}: ${response.url()}`);
    });
    page.on('requestfailed', request => {
      if (target === 'candidate' && request.url().startsWith(origin + '/wisprflowisdead/assets/')) errors.push(`Asset request failed: ${request.url()}`);
    });
    const entry = {target,page:item.name,width,url:origin + (target === 'original' ? item.original : item.clone),errors};
    try {
      const response = await page.goto(entry.url, {waitUntil:'load',timeout:45000});
      entry.status = response?.status() || 0;
      await page.evaluate(() => Promise.race([document.fonts.ready,new Promise(resolve => setTimeout(resolve,5000))]));
      entry.fontFaces = await page.evaluate(() => [...document.fonts].map(face => ({family:face.family,style:face.style,weight:face.weight,status:face.status})));
      entry.title = await page.title();
      entry.links = await page.locator('nav a,header a,footer a').evaluateAll(links => links.map(link => ({text:link.textContent.trim(),href:link.href,visible:!!(link.getBoundingClientRect().width && link.getBoundingClientRect().height)})));
      entry.image = `${target}-${item.name}-${width}.png`;
      await page.screenshot({path:path.join(output,entry.image)});
      if (item.name === 'login') {
        entry.initialImage = entry.image;
        if (target === 'original') {
          // The original uses different submit markup. This only establishes its visible email form.
          await page.locator('input[type=email]:visible').first().waitFor({state:'visible',timeout:30000});
          entry.loginFormVisible = await page.locator('input[type=email]:visible').first().isEditable();
          entry.readinessCheck = 'Original email field visible and editable; authentication not attempted';
          if (!entry.loginFormVisible) entry.failure = 'Original email field is not editable';
        } else {
          // The clone's SDK setup has a 25-second bound; capture the resulting ready/error state.
          await page.waitForFunction(() => {
            const controls = [...document.querySelectorAll('button,input[type=submit]')];
            return controls.some(button => button.getBoundingClientRect().height && !button.disabled &&
              /^(Continue|Retry sign-in setup)$/.test((button.textContent || button.value).trim()));
          },null,{timeout:30000});
          entry.loginReady = await page.locator('button,input[type=submit]').evaluateAll(buttons => buttons.some(button =>
            button.getBoundingClientRect().height && !button.disabled && (button.textContent || button.value).trim() === 'Continue'));
          if (!entry.loginReady) entry.failure = 'Login setup settled in an error state';
        }
        entry.controls = await page.locator('button,input[type=submit],input[type=button],[role=button]').evaluateAll(controls =>
          controls.filter(control => control.getBoundingClientRect().height).map(control => ({
            tag:control.tagName,type:control.getAttribute('type'),text:(control.textContent || control.value || '').trim().slice(0,100),
            disabled:Boolean(control.disabled),ariaDisabled:control.getAttribute('aria-disabled')
          })));
        entry.image = `${target}-login-${width}-settled.png`;
        await page.screenshot({path:path.join(output,entry.image)});
      }
      if (item.name === 'home') {
        // Scroll normally to load lazy artwork and observe scroll-driven states; never hide overlays.
        const height = await page.evaluate(() => document.documentElement.scrollHeight);
        for (let y = 0; y < height; y += 700) {
          await page.evaluate(y => window.scrollTo({top:y,behavior:'instant'}),y);
          await page.waitForTimeout(120);
        }
        await page.evaluate(() => window.scrollTo({top:0,behavior:'instant'}));
        await page.waitForTimeout(500);
        entry.fullImage = `${target}-home-${width}-full.png`;
        entry.fullCapture = 'After scrolling for lazy content; initial viewport retained separately';
        await page.screenshot({path:path.join(output,entry.fullImage),fullPage:true});
        // A small review copy is readable through repository APIs with file-size limits.
        // Shared parity still scores its original, lossless PNGs independently.
        entry.reviewImage = `${target}-home-${width}-review.jpg`;
        await page.screenshot({path:path.join(output,entry.reviewImage),fullPage:true,type:'jpeg',quality:70});
      }
      if (item.name === 'pricing') {
        // Keep full-page geometry available through the evidence branch for visual review.
        entry.fullImage = `${target}-pricing-${width}-full.png`;
        await page.screenshot({path:path.join(output,entry.fullImage),fullPage:true});
      }
      if (item.name === 'home' || item.name === 'pricing') {
        // A viewport-sized crop keeps the download artwork reviewable at its rendered scale.
        const selector = target === 'original' ? '.section_startflowing' : item.name === 'home' ? '.final' : '.pr-cta';
        const section = page.locator(selector).first();
        await section.evaluate(element => window.scrollTo({top:element.getBoundingClientRect().top + scrollY,behavior:'instant'}));
        if (target === 'candidate') {
          await section.evaluate(async element => {
            const urls = [...getComputedStyle(element).backgroundImage.matchAll(/url\("([^"]+)"\)/g)].map(match => match[1]);
            if (!urls.length) throw Error('Download background is missing');
            await Promise.all(urls.map(async url => {const image = new Image(); image.src = url; await image.decode();}));
          });
        }
        await page.waitForTimeout(300);
        entry.downloadImage = `${target}-${item.name}-${width}-download.png`;
        await page.screenshot({path:path.join(output,entry.downloadImage)});
        entry.downloadSection = await section.evaluate(element => {
          const box = element.getBoundingClientRect(), style = getComputedStyle(element);
          return {x:box.x,y:box.y,width:box.width,height:box.height,backgroundImage:style.backgroundImage,backgroundSize:style.backgroundSize};
        });
      }
      if (item.name === 'home') {
        const selector = target === 'original' ? '.section_nt-faqs' : '.faq';
        await page.locator(selector).first().evaluate(element => window.scrollTo({top:element.getBoundingClientRect().top + scrollY,behavior:'instant'}));
        await page.waitForTimeout(300);
        entry.faqImage = `${target}-home-${width}-faq.png`;
        await page.screenshot({path:path.join(output,entry.faqImage)});
        if (target === 'original' || target === 'candidate') {
          const languageQuestion = target === 'original'
            ? page.getByText('Does Flow work in other languages?',{exact:true}).first()
            : page.locator('#home-question-2');
          await languageQuestion.click();
          entry.faqSelectedControl = await languageQuestion.evaluate(element => {
            const nodes = []; let current = element;
            for (let depth = 0; current && depth < 4; depth++, current = current.parentElement) {
              const box = current.getBoundingClientRect(), style = getComputedStyle(current);
              nodes.push({tag:current.tagName,cls:current.className,x:box.x,y:box.y + scrollY,width:box.width,height:box.height,fontSize:style.fontSize,lineHeight:style.lineHeight,fontWeight:style.fontWeight,padding:style.padding,margin:style.margin,gap:style.gap,background:style.backgroundColor});
            }
            return nodes;
          });
          await page.waitForTimeout(300);
          entry.faqExpandedImage = `${target}-home-${width}-faq-language.png`;
          await page.screenshot({path:path.join(output,entry.faqExpandedImage)});
          entry.faqControls = await page.locator(selector).first().evaluate(section =>
            [...section.querySelectorAll('button,[role=button],[role=tab],h3')].filter(element => element.getBoundingClientRect().height).map(element => {
              const box = element.getBoundingClientRect(), style = getComputedStyle(element);
              return {tag:element.tagName,text:element.textContent.trim().slice(0,120),role:element.getAttribute('role'),expanded:element.getAttribute('aria-expanded'),selected:element.getAttribute('aria-selected'),x:box.x,y:box.y,width:box.width,height:box.height,fontSize:style.fontSize,lineHeight:style.lineHeight,padding:style.padding};
            }));
        }
      }
      if (item.name === 'home' && target !== 'live') {
        const section = page.locator(target === 'original' ? '.section_lang-wrap' : '.lang');
        const bounds = await section.evaluate(element => ({top:element.getBoundingClientRect().top + scrollY,height:element.getBoundingClientRect().height}));
        entry.featureImages = [];
        for (let index = 0; index < 4; index++) {
          await page.evaluate(top => window.scrollTo({top,behavior:'instant'}),bounds.top + bounds.height * index / 4 - 120);
          await page.waitForTimeout(300);
          const filename = `${target}-home-${width}-feature-${index}.png`;
          await page.screenshot({path:path.join(output,filename)});
          entry.featureImages.push(filename);
        }
        entry.featureStyles = await section.evaluate(section => [...section.querySelectorAll('*')]
          .filter(element => element instanceof HTMLElement && element.getBoundingClientRect().height && element.getBoundingClientRect().width).slice(0,160).map(element => {
            const box = element.getBoundingClientRect(), style = getComputedStyle(element);
            return {tag:element.tagName,cls:element.className,text:element.children.length ? '' : element.textContent.trim().slice(0,120),x:box.x,y:box.y + scrollY,width:box.width,height:box.height,fontSize:style.fontSize,fontStyle:style.fontStyle,lineHeight:style.lineHeight,fontWeight:style.fontWeight,letterSpacing:style.letterSpacing,color:style.color,background:style.backgroundColor,padding:style.padding,margin:style.margin,radius:style.borderRadius,position:style.position};
          }));
      }
    } catch (error) {entry.failure = error.message.slice(0,500);}
    results.push(entry); await context.close();
    fs.writeFileSync(path.join(output,'inventory.json'), JSON.stringify(results,null,2));
  }
} finally {await browser.close();}
if (results.some(entry => entry.status !== 200 || entry.failure || (entry.target === 'candidate' && entry.errors.length))) process.exitCode = 1;
