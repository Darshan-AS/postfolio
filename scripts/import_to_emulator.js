const fs = require('fs');
const path = require('path');
const http = require('http');

const EMULATOR_HOST = '127.0.0.1';
const EMULATOR_PORT = 8080;
const PROJECT_ID = 'postfolio-app';

function makePatchRequest(pathSuffix, data) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(data);
    const options = {
      hostname: EMULATOR_HOST,
      port: EMULATOR_PORT,
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${pathSuffix}`,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(body));
        } else {
          reject(new Error(`Status ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

async function importFile(fileName, collectionName) {
  const filePath = path.join(__dirname, '..', 'data_export', fileName);
  if (!fs.existsSync(filePath)) {
    console.log(`Skipping ${fileName}: file does not exist.`);
    return;
  }

  const docs = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  console.log(`Importing ${docs.length} documents from ${fileName} into emulator...`);

  let successCount = 0;
  for (const doc of docs) {
    // Extract document path suffix after "/documents/"
    const match = doc.name.match(/\/documents\/(.+)$/);
    if (!match) {
      console.warn(`Could not parse document name: ${doc.name}`);
      continue;
    }
    const pathSuffix = match[1];

    try {
      await makePatchRequest(pathSuffix, { fields: doc.fields });
      successCount++;
    } catch (e) {
      console.error(`Failed to import document ${pathSuffix}:`, e.message);
    }
  }
  console.log(`Successfully imported ${successCount}/${docs.length} documents for ${collectionName}.`);
}

async function run() {
  try {
    await importFile('customers.json', 'customers');
    await importFile('one_time_deposits.json', 'one_time_deposits');
    await importFile('recurring_deposits.json', 'recurring_deposits');
    console.log('\nImport to Firebase Emulator complete!');
  } catch (e) {
    console.error('Import process failed:', e);
  }
}

run();
