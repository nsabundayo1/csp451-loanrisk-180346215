// src/lib/ratios.js
function debtToIncomeRatio(monthlyDebtPayments, monthlyGrossIncome) {
  if (typeof monthlyGrossIncome !== 'number' || monthlyGrossIncome <= 0) {
    throw new RangeError('monthlyGrossIncome must be a positive number');
  }
  if (typeof monthlyDebtPayments !== 'number' || monthlyDebtPayments < 0) {
    throw new RangeError('monthlyDebtPayments must be zero or greater');
  }
  return Number((monthlyDebtPayments / monthlyGrossIncome).toFixed(4));
}

module.exports = { debtToIncomeRatio };
