// Public reference rates checked at wisprflow.ai/pricing on 2026-10-15.
// This is a comparison only; it does not create a subscription or checkout.
export function referencePrices(period, notetaker = true) {
  if (!['annual', 'monthly'].includes(period)) throw new Error('Unknown billing period.');
  return period === 'annual'
    ? {pro:12, growth:notetaker ? 26 : 18}
    : {pro:15, growth:notetaker ? 33 : 23};
}

export function estimateTimeValue(hours, rate) {
  const parse = value => typeof value === 'number' ? value
    : typeof value === 'string' && value.trim() ? Number(value) : NaN;
  const h = parse(hours), r = parse(rate);
  const errors = {};
  if (!Number.isFinite(h) || h < 0 || h > 24) errors.hours = 'Enter hours from 0 to 24.';
  if (!Number.isFinite(r) || r < 0 || r > 100000) errors.rate = 'Enter an hourly value from $0 to $100,000.';
  if (Object.keys(errors).length) return {errors};
  const monthlyHours = h * 22 * .5;
  return {errors, monthlyHours, annualValue:monthlyHours * r * 12};
}
