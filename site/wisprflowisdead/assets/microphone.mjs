const errors = {
  NotAllowedError:'Microphone access was denied. Allow it in browser site settings and try again.',
  SecurityError:'Microphone access is blocked by this browser or page policy.',
  NotFoundError:'No microphone was found. Connect one and try again.',
  NotReadableError:'The microphone could not be opened. Check whether another app is using it.',
  AbortError:'The microphone check was interrupted. Try again.',
  InvalidStateError:'Open this page in the active browser tab and try again.'
};
export class MicrophoneCheck {
  constructor({getUserMedia, createContext, onChange, onLevel = () => {}, schedule = (fn, delay) => setTimeout(fn, delay), unschedule = id => clearTimeout(id),
    frame = fn => requestAnimationFrame(fn), cancelFrame = id => cancelAnimationFrame(id)}) {
    Object.assign(this, {getUserMedia, createContext, onChange, onLevel, schedule, unschedule, frame, cancelFrame});
    this.generation = 0; this.state = 'idle';
  }
  get busy() {return this.state === 'requesting' || this.state === 'testing';}
  emit(state, message) {this.state = state; this.onChange({state, message});}
  dispose() {
    this.unschedule(this.timer); this.cancelFrame(this.frameID);
    if (this.stream) {
      this.stream.getTracks().forEach(track => {track.onended = null; track.stop();}); this.stream = null;
    }
    try {this.source?.disconnect();} catch { /* Already disconnected. */ }
    this.source = null;
    if (this.context) {try {Promise.resolve(this.context.close()).catch(() => {});} catch { /* Already closed. */ } this.context = null;}
    this.onLevel(0);
  }
  stop(message = 'Microphone check stopped.') {++this.generation; this.dispose(); this.emit('idle', message);}
  fail(message) {++this.generation; this.dispose(); this.emit('error', message);}
  async start() {
    if (this.busy) return;
    if (!this.getUserMedia || !this.createContext) {this.fail('Microphone checking is unavailable here. Use a supported browser over HTTPS.'); return;}
    const generation = ++this.generation;
    this.emit('requesting', 'Allow the microphone to test your browser’s default input.');
    this.timer = this.schedule(() => {if (generation === this.generation) this.fail('The microphone check timed out. Check the permission prompt and try again when ready.');}, 15000);
    try {
      const stream = await this.getUserMedia({audio:true, video:false});
      if (generation !== this.generation) {stream.getTracks().forEach(track => track.stop()); return;}
      this.stream = stream;
      const tracks = stream.getAudioTracks();
      if (!tracks.length || tracks[0].readyState === 'ended') throw Error('No live audio track.');
      tracks.forEach(track => {track.onended = () => {if (generation === this.generation) this.fail('The microphone disconnected. Check the device and try again.');};});
      this.emit('requesting', 'Starting the input level check…');
      const context = this.context = this.createContext();
      const analyser = context.createAnalyser(); analyser.fftSize = 2048;
      this.source = context.createMediaStreamSource(stream); this.source.connect(analyser);
      await context.resume();
      if (generation !== this.generation) return;
      this.unschedule(this.timer);
      this.emit('testing', `Connected${tracks[0].label ? ': ' + tracks[0].label : ''}. Speak and watch the input level. This check stops after 20 seconds.`);
      this.timer = this.schedule(() => {if (generation === this.generation) this.stop('Microphone check finished.');}, 20000);
      const samples = new Float32Array(analyser.fftSize);
      const measure = () => {
        if (generation !== this.generation) return;
        try {
          analyser.getFloatTimeDomainData(samples);
          const rms = Math.sqrt(samples.reduce((sum, sample) => sum + sample * sample, 0) / samples.length);
          this.onLevel(Math.min(1, rms * 8));
          this.frameID = this.frame(measure);
        } catch {this.fail('The input level could not be read. Check your microphone and try again.');}
      };
      measure();
    } catch (error) {
      if (generation === this.generation) this.fail(errors[error?.name] || 'The microphone check failed. Check your input device and try again.');
    }
  }
}
