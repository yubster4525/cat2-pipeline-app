const assert = require('assert');
const http = require('http');
const { createApp } = require('../src/server');

function httpRequest(server, path) {
  const { port } = server.address();
  const options = {
    hostname: '127.0.0.1',
    port,
    path,
    method: 'GET'
  };

  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, body: Buffer.concat(chunks).toString() });
      });
    });
    req.on('error', reject);
    req.end();
  });
}

async function run() {
  const server = http.createServer(createApp());

  await new Promise((resolve) => server.listen(0, resolve));

  try {
    const health = await httpRequest(server, '/health');
    assert.strictEqual(health.statusCode, 200, 'health endpoint should return 200');
    const parsed = JSON.parse(health.body);
    assert.strictEqual(parsed.status, 'ok');

    const home = await httpRequest(server, '/');
    assert.strictEqual(home.statusCode, 200, 'home endpoint should return 200');
    assert.ok(home.body.includes('CI/CD pipeline demo application'));

    console.log('All tests passed');
  } finally {
    server.close();
  }
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
