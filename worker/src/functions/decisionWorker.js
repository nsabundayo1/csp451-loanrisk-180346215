const { app } = require('@azure/functions');
const { randomUUID } = require('node:crypto');

app.http('decisionWorker', {
  methods: ['POST'],
  authLevel: 'function',
  handler: async (request, context) => {
    const correlationId = request.headers.get('x-correlation-id') ?? randomUUID();
    context.log(`decisionWorker received request correlationId=${correlationId}`);

    let body;
    try {
      body = await request.json();
    } catch {
      return {
        status: 400,
        headers: { 'x-correlation-id': correlationId },
        jsonBody: { code: 'VALIDATION_FAILED', message: 'Body is not valid JSON.', correlationId }
      };
    }

    // Week 10 replaces this placeholder with the Service Bus triggered rules engine.
    return {
      status: 200,
      headers: { 'x-correlation-id': correlationId },
      jsonBody: {
        received: true,
        applicantRef: body.applicantRef ?? null,
        rulesVersion: process.env.RULES_VERSION ?? '1.0.0',
        correlationId
      }
    };
  }
});
