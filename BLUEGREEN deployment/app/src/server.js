const express = require('express');
const os = require('os');

const PORT = process.env.PORT || 3000;
const APP_COLOR = process.env.APP_COLOR || 'unknown';
const APP_VERSION = process.env.APP_VERSION || 'v1';

const app = express();

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', color: APP_COLOR, version: APP_VERSION });
});

app.get('/', (_req, res) => {
  res.send(`Blue/Green demo (${APP_COLOR}) running on ${os.hostname()} — version ${APP_VERSION}`);
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Blue/Green demo listening on ${PORT} [${APP_COLOR}]`);
  });
}

module.exports = app;
