// CSP451 2026F - Mock bureau tests. Run with: npm test
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { bureauPayload, DATA_VERSION } = require('../server');

test('the same applicantId always produces the same payload', () => {
  const a = bureauPayload('APP-0001');
  const b = bureauPayload('APP-0001');
  delete a.retrievedAt;
  delete b.retrievedAt;
  assert.deepEqual(a, b);
});

test('different applicant IDs produce different credit scores', () => {
  const scores = new Set(['APP-0001', 'APP-0002', 'APP-0003', 'APP-0004'].map((id) => bureauPayload(id).creditScore));
  assert.ok(scores.size > 1, 'expected the seeded values to vary across applicants');
});

test('every payload is flagged as synthetic and carries the data version', () => {
  const payload = bureauPayload('APP-0042');
  assert.equal(payload.syntheticData, true);
  assert.equal(payload.dataVersion, DATA_VERSION);
});

test('payload values stay inside the documented ranges', () => {
  for (let i = 1; i <= 60; i += 1) {
    const id = `APP-${String(i).padStart(4, '0')}`;
    const p = bureauPayload(id);
    assert.ok(p.creditScore >= 480 && p.creditScore <= 850, `${id} creditScore out of range`);
    assert.ok(p.openTradelines >= 0 && p.openTradelines <= 9, `${id} openTradelines out of range`);
    assert.ok(p.delinquencies24m >= 0 && p.delinquencies24m <= 4, `${id} delinquencies24m out of range`);
    assert.ok(p.inquiries6m >= 0 && p.inquiries6m <= 6, `${id} inquiries6m out of range`);
    assert.ok(p.utilizationPct >= 0 && p.utilizationPct <= 99, `${id} utilizationPct out of range`);
    assert.ok(p.fileAgeMonths >= 3 && p.fileAgeMonths <= 180, `${id} fileAgeMonths out of range`);
    assert.equal(p.thinFile, p.fileAgeMonths < 12 || p.openTradelines < 2);
  }
});

test('the payload contains no personally identifiable fields', () => {
  const forbidden = ['name', 'firstName', 'lastName', 'sin', 'email', 'phone', 'address', 'postalCode', 'dateOfBirth'];
  const keys = Object.keys(bureauPayload('APP-0007')).map((k) => k.toLowerCase());
  for (const field of forbidden) {
    assert.ok(!keys.includes(field.toLowerCase()), `payload must not expose ${field}`);
  }
});
