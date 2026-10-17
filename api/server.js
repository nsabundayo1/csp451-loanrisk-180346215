// Allymon Loan Risk Engine API, Week 5 minimal version. Node.js 22, no dependencies.
// SYNTHETIC DATA ONLY. Configuration comes from App Service application settings.
'use strict';

const http = require('node:http');
const { randomUUID } = require('node:crypto');
const { version } = require('./package.json');

// Fail fast: a silent default that points at localhost is how a demo dies on stage.
const bureauBaseUrl = process.env.BUREAU_BASE_URL;
const rulesVersion = process.env.RULES_VERSION ?? '0.0.0';
if (!bureauBaseUrl) {
  throw new Error('BUREAU_BASE_URL is not configured');
}

// App Service tells the process which port to listen on through PORT.
const port = Number(process.env.PORT ?? 3000);
const APPLICANT_ROUTE = /^\/api\/v1\/bureau-check\/(APP-\d{4})$/;

function send(res, status, body, correlationId) {
  res.writeHead(status, {
    'content-type': 'application/json',
    'x-correlation-id': correlationId
  });
  res.end(JSON.stringify({ ...body, correlationId }));
}

const server = http.createServer(async (req, res) => {
  const correlationId = req.headers['x-correlation-id'] ?? randomUUID();
  const { pathname } = new URL(req.url, 'http://localhost');

  // Health does not call the bureau: the platform health check must not fail
  // just because the bureau VM is deallocated.
  if (req.method === 'GET' && pathname === '/health') {
    return send(res, 200, { status: 'ok', version, rulesVersion }, correlationId);
  }

  const match = pathname.match(APPLICANT_ROUTE);
  if (req.method === 'GET' && match) {
    const applicantId = match[1];
    try {
      const reply = await fetch(`${bureauBaseUrl}/bureau/v1/applicants/${applicantId}`, {
        headers: { 'x-correlation-id': correlationId },
        signal: AbortSignal.timeout(3000)
      });
      const data = await reply.json();
      return send(res, reply.ok ? 200 : 502, {
        applicantId,
        bureauStatus: reply.status,
        creditScore: data.creditScore ?? null,
        riskBand: data.riskBand ?? null,
        syntheticData: true
      }, correlationId);
    } catch (err) {
      console.error(`bureau call failed correlationId=${correlationId} error=${err.name}`);
      return send(res, 502, {
        code: 'BUREAU_UNREACHABLE',
        message: 'The mock bureau could not be reached within 3 seconds.'
      }, correlationId);
    }
  }

  return send(res, 404, { code: 'NOT_FOUND', message: 'Unknown route.' }, correlationId);
});

server.listen(port, () => {
  console.log(`loanrisk-api ${version} listening on port ${port}, rules ${rulesVersion}`);
});
