// Run the shared, pinned parity tooling against production and this PR's files.
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';

const tools = path.resolve(process.env.PARITY_TOOLS_DIR || 'parity-tools');
const output = path.resolve('qa-artifacts');
const errors = [];
const config = path.join(tools, 'parity/wispr.json');
const pages = [{name:'home',original:'/',clone:'/wisprflowisdead'}, {name:'pricing',original:'/pricing',clone:'/wisprflowisdead/pricing'}, {name:'login',original:'/get-started',clone:'/wisprflowisdead/login'}];
const viewports = ['1440x900','390x844'];
const targets = {original:'https://wisprflow.ai',live:'https://yourappisdead.com',candidate:'http://127.0.0.1:3300'};
fs.mkdirSync(output, {recursive:true});
try {execFileSync(process.execPath, ['qa/raw-captures.mjs'], {stdio:'inherit',timeout:600000});}
catch (error) {errors.push({stage:'raw viewport captures',status:error.status ?? null,message:error.code || 'Command failed'});}
function run(script, args, stage) {
  try {execFileSync(process.execPath, [path.join(tools, 'scripts', script), ...args], {stdio:'inherit',timeout:600000}); return true;}
  catch (error) {errors.push({stage, status:error.status ?? null, message:error.code || 'Command failed'}); return false;}
}
function report(name) {
  try {return JSON.parse(fs.readFileSync(path.join(output, name, 'report.json'), 'utf8'));}
  catch {return null;}
}
const common = ['--config',config,'--viewports',viewports.join(',')];
run('parity.mjs', [...common,'--clone',targets.live,'--out',path.join(output,'live')], 'live parity');
const live = report('live');
const reuse = live?.results?.length === 6 && live.results.every(row => row.origStatus === 200);
fs.mkdirSync(path.join(output,'candidate'), {recursive:true});
if (reuse) for (const page of pages) for (const viewport of viewports) {
  const filename = `${page.name}-${viewport.split('x')[0]}-orig.png`;
  fs.copyFileSync(path.join(output,'live',filename), path.join(output,'candidate',filename));
}
run('parity.mjs', [...common,'--clone',targets.candidate,'--out',path.join(output,'candidate'),...(reuse ? ['--reuse-orig'] : [])], 'candidate parity');
for (const [target, origin] of Object.entries(targets)) for (const page of pages) for (const viewport of viewports) {
  const directory = path.join(output, 'styles', target); fs.mkdirSync(directory, {recursive:true});
  run('extract-styles.mjs', [origin + (target === 'original' ? page.original : page.clone),'--vp',viewport,'--out',path.join(directory,`${page.name}-${viewport.split('x')[0]}.json`)], `${target} ${page.name} ${viewport} styles`);
}
const candidate = report('candidate');
const valid = data => data?.results?.length === 6 && data.results.every(row => row.origStatus === 200 && row.cloneStatus === 200 && Number.isFinite(row.score));
const measured = valid(live) && valid(candidate);
const passed = measured && candidate.results.every(row => row.score >= 90 && !row.hOverflowClone) && errors.length === 0;
const summary = {
  measuredAt:new Date().toISOString(), commit:execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim(),
  toolsCommit:execFileSync('git',['-C',tools,'rev-parse','HEAD'],{encoding:'utf8'}).trim(),
  originalImagesReused:reuse, measured, passed, errors,
  note:'Live production is compared with the entire PR stack, not attributed to this single PR. Candidate preview supports anonymous rendering only; no authentication pass is implied. Shared parity hides animation/cookie overlays; the raw directory captures unmodified viewports and navigation/footer links. Scores still require visual review of the captured pages.'
};
fs.writeFileSync(path.join(output,'verification.json'), JSON.stringify(summary,null,2));
const lines = ['# Website parity evidence', '', summary.note, '', `Valid measurements: ${measured}. Candidate meets all six 90+ targets without overflow: ${passed}.`, '', '| Page | Viewport | Live | Candidate | Change |','|---|---|---:|---:|---:|'];
for (const row of candidate?.results || []) {
  const before = live?.results?.find(item => item.page === row.page && item.viewport === row.viewport);
  lines.push(`| ${row.page} | ${row.viewport} | ${before?.score ?? 'N/M'} | ${row.score} | ${before ? (row.score-before.score).toFixed(1) : 'N/M'} |`);
}
if (errors.length) lines.push('', 'Capture errors: ' + errors.map(item => item.stage).join(', '));
fs.writeFileSync(path.join(output,'SUMMARY.md'), lines.join('\n') + '\n');
console.log(lines.join('\n'));
if (!passed) process.exitCode = 1;
