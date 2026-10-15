// Conservative, local cleanup. This does not reproduce a language model.
export function cleanText(input, {style = 'formal', language = 'en-US', cleanup = 'light'} = {}) {
  if (cleanup === 'none') return String(input);
  let text = String(input).replace(/\r\n?/g, '\n').trim();
  if (!text) return '';
  if (!language.startsWith('en')) return text;
  const literals = [];
  text = text.replace(/(?:https?:\/\/|www\.)[^\s]+|[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Z0-9-]+(?:\.[A-Z0-9-]+)+|`[^`\n]+`|\uE000\d+\uE001/gi, value => {
    literals.push(value); return `\uE000${literals.length - 1}\uE001`;
  });
  const restore = value => value.replace(/\uE000(\d+)\uE001/g, (_, index) => literals[Number(index)]);
  if (cleanup === 'medium') {
    // A small, disclosed local substitute for model-based rewriting.
    text = text.replace(/\bin order to\b/gi, 'to')
      .replace(/\bat this point in time\b/gi, 'now')
      .replace(/\bdue to the fact that\b/gi, 'because');
  }
  text = text
    .replace(/\b(?:um+|uh+|erm+)\b[,.!?;]?\s*/gi, '')
    .replace(/\b(the|a|an|i|we|you|and|to|my)(?:\s+\1)+\b/gi, '$1')
    .replace(/\bnew paragraph\b/gi, '\n\n')
    .replace(/\bnew line\b/gi, '\n')
    .replace(/\b(?:new bullet|new item)\b/gi, '\n• ')
    .replace(/\b(question mark|exclamation mark|exclamation point|full stop|semicolon|comma|colon)\b/gi,
      word => ({'question mark':'?', 'exclamation mark':'!', 'exclamation point':'!', 'full stop':'.', semicolon:';', comma:',', colon:':'})[word.toLowerCase()])
    .replace(/\bperiod\s*$/i, '.')
    .replace(/[ \t]+/g, ' ')
    .replace(/ *\n */g, '\n')
    .replace(/ +([,.?!;:])/g, '$1')
    .replace(/\bi\b/g, 'I').trim();
  if (!text || !/[\p{L}\p{N}]/u.test(text)) return '';
  if (style === 'very-casual') return restore(text.toLowerCase().replace(/\.$/, ''));
  text = text.replace(/(^|[.!?]\s+|\n)(• )?([a-z])/g, (_, prefix, bullet, letter) => prefix + (bullet || '') + letter.toUpperCase());
  if (style === 'casual') return restore(text.replace(/\.$/, ''));
  if (style === 'excited') return restore(/[!?\uE001]$/.test(text) ? text : text.replace(/\.$/, '') + '!');
  return restore(/[.!?:;\uE001]$/.test(text) ? text : text + '.');
}
