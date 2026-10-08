// test/ratios.test.js
const { debtToIncomeRatio } = require('../src/lib/ratios');

describe('debtToIncomeRatio', () => {
  test('computes a normal ratio to four decimal places', () => {
    expect(debtToIncomeRatio(1500, 6000)).toBe(0.3);
  });

  test('rejects zero income rather than returning Infinity', () => {
    expect(() => debtToIncomeRatio(1500, 0)).toThrow(RangeError);
  });

  test('rejects negative debt payments', () => {
    expect(() => debtToIncomeRatio(-1, 6000)).toThrow(RangeError);
  });
});
