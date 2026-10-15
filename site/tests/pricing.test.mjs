import {test} from 'node:test';
import assert from 'node:assert/strict';
import {referencePrices, estimateTimeValue} from '../wisprflowisdead/assets/pricing.mjs';

test('reference billing and Notetaker choices select the published price combinations', () => {
  assert.deepEqual(referencePrices('annual'), {pro:12, growth:26});
  assert.deepEqual(referencePrices('annual', false), {pro:12, growth:18});
  assert.deepEqual(referencePrices('monthly'), {pro:15, growth:33});
  assert.deepEqual(referencePrices('monthly', false), {pro:15, growth:23});
  assert.throws(() => referencePrices('weekly'));
});

test('empty, negative, nonnumeric and nonfinite inputs cannot produce a savings claim', () => {
  for (const value of ['', '  ', null, undefined, true, -1, '-2', 'abc', Infinity, '1e999', NaN]) {
    const badHours = estimateTimeValue(value, 50), badRate = estimateTimeValue(2, value);
    assert.ok(badHours.errors.hours); assert.ok(badRate.errors.rate);
    assert.equal(badHours.monthlyHours, undefined); assert.equal(badRate.annualValue, undefined);
  }
  assert.ok(estimateTimeValue(24.01, 0).errors.hours);
  assert.ok(estimateTimeValue(0, 100000.01).errors.rate);
});

test('the illustration accepts zero and preserves fractional hours before annualizing', () => {
  assert.deepEqual(estimateTimeValue('2', '50'), {errors:{}, monthlyHours:22, annualValue:13200});
  assert.deepEqual(estimateTimeValue(0, 100), {errors:{}, monthlyHours:0, annualValue:0});
  assert.deepEqual(estimateTimeValue(2, 0), {errors:{}, monthlyHours:22, annualValue:0});
  assert.deepEqual(estimateTimeValue(.25, 80), {errors:{}, monthlyHours:2.75, annualValue:2640});
});

test('valid boundary inputs produce finite results consistent with the disclosed assumptions', () => {
  for (const hours of [0, .001, 1.25, 12, 24]) {
    for (const rate of [0, .01, 50.5, 100000]) {
      const result = estimateTimeValue(hours, rate);
      assert.deepEqual(result.errors, {});
      assert.ok(Number.isFinite(result.annualValue));
      assert.ok(result.monthlyHours <= hours * 22);
      assert.equal(result.annualValue, result.monthlyHours * rate * 12);
    }
  }
});
