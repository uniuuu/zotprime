import api from 'zotero-api-client';
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
  const client = api(apiKey, { base: config.dataserver.url });
  const response = await client.library('user', userId).groups().get();
  return response.getData();
}

export async function getGroupItems(groupId: number, apiKey: string): Promise<ZoteroItem[]> {
  const client = api(apiKey, { base: config.dataserver.url });
  const response = await client.library('group', groupId).items().get();
  return response.getData() as ZoteroItem[];
}

export async function getItem(groupId: number, itemKey: string, apiKey: string): Promise<ZoteroItem> {
  const client = api(apiKey, { base: config.dataserver.url });
  const response = await client.library('group', groupId).items(itemKey).get();
  return response.getData() as ZoteroItem;
}
