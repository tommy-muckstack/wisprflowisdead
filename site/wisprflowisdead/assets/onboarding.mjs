export const ONBOARDING_KEY = 'wisprflowisdead.onboarding.v1';
export const steps = ['privacy', 'microphone', 'preferences', 'practice'];
export class Onboarding {
  constructor(storage) {this.storage = storage; this.open();}
  open() {this.visible = true; this.index = 0; this.marks = {}; this.persisted = false;}
  load() {
    let saved;
    try {saved = this.storage?.getItem(ONBOARDING_KEY) ?? null;}
    catch {return 'Setup progress cannot be read. You can still use this guide for this visit.';}
    if (saved === null) return '';
    try {
      if (saved.length > 500) throw Error();
      const data = JSON.parse(saved);
      if (data.version !== 1 || !['completed','skipped'].includes(data.status)) throw Error();
      this.visible = false; this.persisted = true;
      return '';
    } catch {return 'Saved setup progress could not be read. Complete or skip the guide to replace it.';}
  }
  get current() {return steps[this.index];}
  get ready() {return !['microphone','practice'].includes(this.current) || this.marks[this.current] === 'completed';}
  observe(step, succeeded) {
    if (this.visible && succeeded && ['microphone','practice'].includes(step)) this.marks[step] = 'completed';
  }
  previous() {this.index = Math.max(0, this.index - 1);}
  next(skip = false) {
    if (!skip && !this.ready) throw Error('Try this step or choose Skip step to continue.');
    this.marks[this.current] = skip ? 'skipped' : 'completed';
    if (this.index === steps.length - 1) return this.finish('completed');
    this.index++; return '';
  }
  finish(status = 'skipped') {
    if (!['completed','skipped'].includes(status)) throw Error('Unknown setup outcome.');
    if (status === 'completed' && (this.index !== steps.length - 1 || !steps.every(step => ['completed','skipped'].includes(this.marks[step])))) {
      throw Error('Complete or skip each setup step before finishing.');
    }
    this.visible = false; this.persisted = false;
    const message = status === 'skipped' ? 'Setup skipped. You can reopen it from Setup at any time.'
      : 'Setup complete. You can keep dictating, or reopen the guide from Setup.';
    try {
      if (!this.storage) throw Error();
      this.storage.setItem(ONBOARDING_KEY, JSON.stringify({version:1, status})); this.persisted = true;
      return message;
    } catch {return message + ' This choice could not be remembered, so the guide may return after reload.';}
  }
}
