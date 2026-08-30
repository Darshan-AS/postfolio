const fs = require('fs');
const path = require('path');

const configPath = path.join(process.env.HOME, '.config', 'configstore', 'firebase-tools.json');
try {
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  console.log('Keys in firebase-tools.json:', Object.keys(config));
  if (config.tokens) {
    console.log('Keys in tokens:', Object.keys(config.tokens));
  }
  if (config.user) {
    console.log('User email:', config.user.email);
  }
} catch (e) {
  console.error('Error reading config:', e);
}
