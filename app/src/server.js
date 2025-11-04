const express = require('express');

function createApp() {
  const app = express();

  app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok', service: 'cat2-pipeline-app' });
  });

  app.get('/', (_req, res) => {
    res.status(200).send('CI/CD pipeline demo application is running.');
  });

  return app;
}

function start() {
  const app = createApp();
  const port = process.env.PORT || 3000;
  return app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
  });
}

if (require.main === module) {
  start();
}

module.exports = { createApp, start };
