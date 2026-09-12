// CSP451 2026F - Allymon Loan Risk Engine - Mock credit bureau service.
// SYNTHETIC DATA ONLY. There is no real bureau, no real applicant, no real score.
// Deterministic: the same applicantId always returns the same payload on every
// machine, which is what makes the shared decision test vectors work cohort wide.
'use strict';

const crypto = require('node:crypto');
const express = require('express');

const PORT = Number(process.env.PORT || 8080);
const HOST = process.env.HOST || '0.0.0.0';
const DATA_VERSION = '2026F.1';
const BUREAUS = ['EQUIFAX_MOCK', 'TRANSUNION_MOCK'];
const ID_PATTERN = /^[A-Za-z0-9-]{1,32}$/;

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '16kb' }));

// Turn an applicant ID into a stable stream of numbers. Same algorithm as the
// Week 3 Learning Notes so the VM copy and this copy agree byte for byte.
function seededValues(applicantId) {
  const digest = crypto.createHash('sha256').update(String(applicantId)).digest();
  return (index, min, max) => min + (digest[index % digest.length] % (max - min + 1));
}

function bureauPayload(applicantId) {
  const pick = seededValues(applicantId);
  const creditScore = pick(0, 480, 850);
  const openTradelines = pick(2, 0, 9);
  const fileAgeMonths = pick(7, 3, 180);
  return {
    applicantId,
    bureau: BUREAUS[pick(1, 0, 1)],
    dataVersion: DATA_VERSION,
    retrievedAt: new Date().toISOString(),
    creditScore,
    riskBand: creditScore >= 720 ? 'LOW' : creditScore >= 640 ? 'MEDIUM' : 'HIGH',
    openTradelines,
    delinquencies24m: pick(3, 0, 4),
    inquiries6m: pick(4, 0, 6),
    monthlyDebtPayments: pick(5, 0, 40) * 50,
    utilizationPct: pick(6, 0, 99),
    fileAgeMonths,
    thinFile: fileAgeMonths < 12 || openTradelines < 2,
    syntheticData: true
  };
}

function fail(res, status, code, message) {
  return res.status(status).json({
    error: code,
    message,
    correlationId: res.getHeader('x-correlation-id')
  });
}

// Every response carries a correlation ID: echoed if the caller sent one,
// generated if not. Week 11 traces this value end to end in Application Insights.
app.use((req, res, next) => {
  const incoming = req.get('x-correlation-id');
  res.setHeader('x-correlation-id', incoming && incoming.length <= 64 ? incoming : crypto.randomUUID());
  next();
});

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', dataVersion: DATA_VERSION, syntheticData: true });
});

// Canonical path, matching the Week 3 Learning Notes service on the bureau VM.
app.get('/bureau/v1/applicants/:applicantId', (req, res) => {
  const { applicantId } = req.params;
  if (!ID_PATTERN.test(applicantId)) {
    return fail(res, 400, 'INVALID_APPLICANT_ID', 'applicantId must be 1 to 32 characters of A-Z, a-z, 0-9 or hyphen.');
  }
  return res.json(bureauPayload(applicantId));
});

app.post('/bureau/query', (req, res) => {
  const body = req.body || {};
  const { applicantId, consentReference } = body;
  if (typeof applicantId !== 'string' || !ID_PATTERN.test(applicantId)) {
    return fail(res, 400, 'INVALID_APPLICANT_ID', 'Field applicantId is required and must match ^[A-Za-z0-9-]{1,32}$.');
  }
  if (typeof consentReference !== 'string' || consentReference.trim() === '') {
    return fail(res, 400, 'CONSENT_REFERENCE_REQUIRED', 'Field consentReference is required. A bureau pull without a consent reference is refused.');
  }
  return res.json({ ...bureauPayload(applicantId), consentReference });
});

// Convenience alias. Do not let it swallow the versioned prefix.
app.get('/bureau/:applicantId', (req, res) => {
  const { applicantId } = req.params;
  if (applicantId === 'v1' || applicantId === 'query') {
    return fail(res, 404, 'NOT_FOUND', 'Unknown route. Try GET /bureau/v1/applicants/{applicantId}.');
  }
  if (!ID_PATTERN.test(applicantId)) {
    return fail(res, 400, 'INVALID_APPLICANT_ID', 'applicantId must be 1 to 32 characters of A-Z, a-z, 0-9 or hyphen.');
  }
  return res.json(bureauPayload(applicantId));
});

app.use((_req, res) => fail(res, 404, 'NOT_FOUND', 'Unknown route.'));

// Never throw an unhandled exception: the Key Success Factor is 0% unhandled
// exceptions on schema-valid JSON, and a crashed process fails it loudly.
app.use((err, _req, res, _next) => {
  const status = err && err.status === 400 ? 400 : 500;
  const code = status === 400 ? 'MALFORMED_JSON' : 'INTERNAL_ERROR';
  return fail(res, status, code, status === 400 ? 'Request body is not valid JSON.' : 'Unexpected server error.');
});

if (require.main === module) {
  app.listen(PORT, HOST, () => console.log(`mock-bureau listening on ${HOST}:${PORT}`));
}

module.exports = { app, bureauPayload, seededValues, DATA_VERSION };
