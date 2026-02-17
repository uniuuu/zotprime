import { getConfig } from './config';
import { ZoteroItem } from '@/types';

const config = getConfig();

export async function createUser(username: string, email: string, password: string) {
  const response = await fetch(`${config.dataserver.url}/admin/users`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${config.dataserver.api_super_token}`,
    },
    body: JSON.stringify({ username, email, password }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to create user: ${error}`);
  }

  return response.json();
}

export async function createApiKey(userId: number, keyName: string) {
  const response = await fetch(`${config.dataserver.url}/users/${userId}/keys`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${config.dataserver.api_super_token}`,
    },
    body: JSON.stringify({
      name: keyName,
      access: {
        user: { library: true, files: true, notes: true, write: true },
        groups: { all: { library: true, write: true } },
      },
    }),
  });

  if (!response.ok) {
    throw new Error('Failed to create API key');
  }

  const data = await response.json();
  return data.key;
}

export async function getUserKeys(userId: number): Promise<string | null> {
  const response = await fetch(`${config.dataserver.url}/users/${userId}/keys`, {
    headers: {
      'Authorization': `Bearer ${config.dataserver.api_super_token}`,
    },
  });

  if (!response.ok) return null;

  const keys = await response.json();
  return keys.length > 0 ? keys[0].key : null;
}

export async function getUserGroups(userId: number, apiKey: string) {
  const response = await fetch(`${config.dataserver.url}/users/${userId}/groups?format=json`, {
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Zotero-API-Version': '3',
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch groups: ${response.statusText}`);
  }

  return response.json();
}

export async function getGroupItems(groupId: number, apiKey: string): Promise<ZoteroItem[]> {
  const response = await fetch(`${config.dataserver.url}/groups/${groupId}/items?format=json`, {
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Zotero-API-Version': '3',
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch group items: ${response.statusText}`);
  }

  return response.json();
}

export async function getItem(groupId: number, itemKey: string, apiKey: string): Promise<ZoteroItem> {
  const response = await fetch(`${config.dataserver.url}/groups/${groupId}/items/${itemKey}?format=json`, {
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Zotero-API-Version': '3',
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch item: ${response.statusText}`);
  }

  return response.json();
}
