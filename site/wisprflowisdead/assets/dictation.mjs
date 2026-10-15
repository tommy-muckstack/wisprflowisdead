import {cleanText} from './text.mjs';

export const speechErrors = {
  'not-allowed': 'Microphone access was denied. Allow the microphone in your browser’s site settings, then try again.',
  'service-not-allowed': 'Your browser has blocked speech recognition. Check its permissions or use typed practice below.',
  'audio-capture': 'No usable microphone was found. Connect or enable a microphone, then try again.',
  'no-speech': 'No speech was detected. Check your microphone and try speaking again.',
  'network': 'The speech service could not connect. Check your connection, or use typed practice below.',
  'language-not-supported': 'The speech service does not support this language. Choose another language.',
  'aborted': 'Dictation stopped before it finished. You can try again.'
};

export class Dictation {
  constructor({createRecognition, onChange, polish = cleanText, schedule = setTimeout, unschedule = clearTimeout}) {
    Object.assign(this, {createRecognition, onChange, polish, schedule, unschedule});
    this.state = 'idle';
    this.generation = 0;
    this.raw = this.interim = this.result = this.message = '';
  }
  get busy() { return ['requesting', 'listening', 'transcribing', 'polishing'].includes(this.state); }
  emit(state, message = '') {
    this.state = state; this.message = message;
    this.onChange({state, message, raw:this.raw, interim:this.interim, result:this.result});
  }
  clearTimer() { if (this.timer != null) this.unschedule(this.timer); this.timer = null; }
  detach() {
    this.clearTimer();
    const recognition = this.recognition; this.recognition = null;
    if (recognition) {
      recognition.onstart = recognition.onresult = recognition.onerror = recognition.onend = null;
      try { recognition.abort(); } catch { /* Already stopped. */ }
    }
  }
  fail(message) {
    ++this.generation; this.detach();
    this.emit('error', message);
  }
  start(options = {}) {
    if (this.busy) return false;
    this.options = {...options};
    this.raw = this.interim = this.result = '';
    if (!this.createRecognition) {
      this.emit('error', 'Speech recognition is unavailable in this browser. Try a supported browser or use typed practice below.');
      return false;
    }
    const generation = ++this.generation;
    try {
      const recognition = this.recognition = this.createRecognition();
      recognition.lang = options.language || 'en-US';
      recognition.continuous = true;
      recognition.interimResults = true;
      recognition.maxAlternatives = 1;
      recognition.onstart = () => {
        if (generation !== this.generation || recognition !== this.recognition || this.state !== 'requesting') return;
        this.clearTimer(); this.emit('listening');
      };
      recognition.onresult = event => {
        if (generation !== this.generation || recognition !== this.recognition) return;
        const final = [], interim = [];
        for (const result of Array.from(event.results)) {
          (result.isFinal ? final : interim).push(result[0]?.transcript || '');
        }
        this.raw = final.join(' ').trim(); this.interim = interim.join(' ').trim();
        this.emit(this.state);
      };
      recognition.onerror = event => {
        if (generation === this.generation && recognition === this.recognition) this.fail(speechErrors[event.error] || 'Speech recognition failed. Try again or use typed practice.');
      };
      recognition.onend = () => {
        if (generation !== this.generation || recognition !== this.recognition) return;
        this.detach();
        if (!this.raw.trim()) {
          this.fail(this.interim ? 'No final transcript was returned. You can recover the draft below.' : speechErrors['no-speech']);
          return;
        }
        void this.finish(generation);
      };
      this.emit('requesting');
      this.timer = this.schedule(() => this.fail('Microphone access timed out. Check the permission prompt and try again.'), 30000);
      recognition.start();
      return true;
    } catch {
      this.fail('Could not start the microphone. Check your browser permissions and try again.');
      return false;
    }
  }
  stop() {
    if (this.state === 'requesting') { this.cancel(); return; }
    if (this.state !== 'listening') return;
    this.emit('transcribing');
    this.clearTimer();
    this.timer = this.schedule(() => this.fail('The speech service did not finish. Recover the draft below or try again.'), 15000);
    try { this.recognition.stop(); } catch { this.fail('Could not finish this recording. Recover the draft below or try again.'); }
  }
  async finish(generation) {
    this.emit('polishing');
    try {
      const result = await this.polish(this.raw, this.options);
      if (generation !== this.generation) return;
      this.result = result;
      this.emit(result ? 'result' : 'error', result ? '' : 'There was no text left after cleanup. Try a longer sentence.');
    } catch { if (generation === this.generation) this.fail('Cleanup failed. Your original words are available below.'); }
  }
  async practice(text, options = {}) {
    if (this.busy) return false;
    this.raw = String(text).trim(); this.interim = this.result = '';
    if (!this.raw) { this.emit('error', 'Type something to clean up first.'); return false; }
    this.options = {...options};
    await this.finish(++this.generation);
    return true;
  }
  cancel() {
    ++this.generation; this.detach();
    this.raw = this.interim = this.result = '';
    this.emit('idle', 'Dictation cancelled.');
  }
}
