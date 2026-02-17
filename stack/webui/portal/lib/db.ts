import { JSONFilePreset } from 'lowdb/node';
import path from 'path';

interface TOTPRecord {
  username: string;
  secret: string;
  verified: boolean;
  createdAt: string;
}

interface Database {
  totpSecrets: TOTPRecord[];
}

const dbPath = path.join(process.cwd(), 'data', 'db.json');
let db: Awaited<ReturnType<typeof JSONFilePreset<Database>>> | null = null;

async function getDB() {
  if (!db) {
    db = await JSONFilePreset<Database>(dbPath, { totpSecrets: [] });
  }
  return db;
}

export async function getTOTPSecret(username: string): Promise<{ secret: string; verified: boolean } | null> {
  const database = await getDB();
  const record = database.data.totpSecrets.find(r => r.username === username);
  return record ? { secret: record.secret, verified: record.verified } : null;
}

export async function setTOTPSecret(username: string, secret: string): Promise<void> {
  const database = await getDB();
  const existing = database.data.totpSecrets.findIndex(r => r.username === username);
  
  if (existing >= 0) {
    database.data.totpSecrets[existing].secret = secret;
    database.data.totpSecrets[existing].verified = false;
  } else {
    database.data.totpSecrets.push({
      username,
      secret,
      verified: false,
      createdAt: new Date().toISOString()
    });
  }
  
  await database.write();
}

export async function markTOTPVerified(username: string): Promise<void> {
  const database = await getDB();
  const record = database.data.totpSecrets.find(r => r.username === username);
  
  if (record) {
    record.verified = true;
    await database.write();
  }
}
