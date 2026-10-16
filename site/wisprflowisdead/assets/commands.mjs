import {cleanText} from './text.mjs';

export class CommandError extends Error {}

// Deliberately finite commands: an unrecognized instruction never becomes text.
const commands = new Map([
  ['uppercase', 'upper'], ['upper case', 'upper'], ['make it uppercase', 'upper'],
  ['lowercase', 'lower'], ['lower case', 'lower'], ['make it lowercase', 'lower'],
  ['bullet list', 'bullets'], ['make a bullet list', 'bullets'], ['make it a bullet list', 'bullets'],
  ['numbered list', 'numbers'], ['make a numbered list', 'numbers'], ['make it a numbered list', 'numbers'],
  ['trim spacing', 'spacing'], ['clean up spacing', 'spacing'],
  ['clean up text', 'cleanup'], ['clean up', 'cleanup']
]);

export function captureCommand(text, start, end) {
  if (typeof text !== 'string' || !Number.isInteger(start) || !Number.isInteger(end)
    || start < 0 || end < start || end > text.length) throw new CommandError('Select the text again and retry.');
  if (start === end) {start = 0; end = text.length;}
  const target = text.slice(start, end);
  if (!target.trim()) throw new CommandError('Write some text or select a nonempty passage before running a command.');
  if (target.length > 200000) throw new CommandError('Select a shorter passage: commands accept up to 200,000 characters.');
  return {text, start, end, target};
}

export function transformText(instruction, {target, ...options} = {}) {
  if (typeof instruction !== 'string' || !instruction.trim()) throw new CommandError('Say or type a command first.');
  if (instruction.length > 1000) throw new CommandError('Use a short command from the supported list.');
  if (typeof target !== 'string') throw new CommandError('Select the text again and retry.');
  captureCommand(target, 0, target.length);
  const name = instruction.trim().toLowerCase().replace(/[.!?]+$/, '').trim().replace(/^please\s+/, '').replace(/\s+/g, ' ');
  const command = commands.get(name);
  if (!command) throw new CommandError('Command not supported. Try “uppercase”, “lowercase”, “bullet list”, “numbered list”, “trim spacing”, or “clean up text”. Your draft is unchanged.');
  let result;
  if (command === 'upper') result = target.toUpperCase();
  if (command === 'lower') result = target.toLowerCase();
  if (command === 'spacing') result = target.replace(/\r\n?/g, '\n').split('\n').map(line => line.replace(/[ \t]+/g, ' ').trim()).join('\n').trim();
  if (command === 'cleanup') result = cleanText(target, options);
  if (command === 'bullets' || command === 'numbers') {
    result = target.replace(/\r\n?/g, '\n').split('\n').map(line => line.trim()).filter(Boolean)
      .map((line, i) => `${command === 'bullets' ? '•' : (i + 1) + '.'} ${line.replace(/^(?:[-*•]|\d+[.)])\s+/, '')}`).join('\n');
  }
  if (!result?.trim()) throw new CommandError('That command would leave no text. Your draft is unchanged.');
  if (result.length > 200000) throw new CommandError('The result is too long. Select a shorter passage and retry.');
  return result;
}

export function applyCommand(selection, result) {
  // No dictation boundary spaces: a selection may be inside a word or URL.
  return {value:selection.text.slice(0, selection.start) + result + selection.text.slice(selection.end),
    start:selection.start, end:selection.start + result.length};
}
