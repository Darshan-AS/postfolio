const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT_ID = 'postfolio-app';
const UID = 'xeQSKSJoJbf5vIcCEblgIFg0hMn1';

// Get access token from firebase-tools config
function getAccessToken() {
  const configPath = path.join(process.env.HOME, '.config', 'configstore', 'firebase-tools.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  return config.tokens.access_token;
}

// Helper to make HTTPS requests
function makeRequest(url, token) {
  return new Promise((resolve, reject) => {
    const options = {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/json'
      }
    };
    https.get(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`Status ${res.statusCode}: ${data}`));
        }
      });
    }).on('error', reject);
  });
}

// Fetch all documents in a subcollection of a user
async function fetchCollection(collectionName, token) {
  let documents = [];
  let pageToken = '';
  const baseUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${UID}/${collectionName}?pageSize=300`;

  console.log(`Fetching ${collectionName}...`);
  do {
    const url = pageToken ? `${baseUrl}&pageToken=${pageToken}` : baseUrl;
    try {
      const response = await makeRequest(url, token);
      if (response.documents) {
        documents = documents.concat(response.documents);
      }
      pageToken = response.nextPageToken || '';
    } catch (e) {
      console.error(`Error fetching page for ${collectionName}:`, e.message);
      throw e;
    }
  } while (pageToken);

  console.log(`Fetched ${documents.length} documents for ${collectionName}.`);
  return documents;
}

async function run() {
  try {
    const token = getAccessToken();
    console.log(`Authenticated with token. User UID: ${UID}`);

    const customers = await fetchCollection('customers', token);
    const oneTimeDeposits = await fetchCollection('one_time_deposits', token);
    const recurringDeposits = await fetchCollection('recurring_deposits', token);

    const outDir = path.join(__dirname, '..', 'data_export');
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir);
    }

    fs.writeFileSync(path.join(outDir, 'customers.json'), JSON.stringify(customers, null, 2));
    fs.writeFileSync(path.join(outDir, 'one_time_deposits.json'), JSON.stringify(oneTimeDeposits, null, 2));
    fs.writeFileSync(path.join(outDir, 'recurring_deposits.json'), JSON.stringify(recurringDeposits, null, 2));

    console.log(`\nExport complete! Files saved to data_export/`);
  } catch (e) {
    console.error('Run failed:', e);
  }
}

run();
