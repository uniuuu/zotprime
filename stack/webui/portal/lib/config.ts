import fs from 'fs';
import path from 'path';
import yaml from 'js-yaml';

interface Config {
  dataserver: {
    url: string;
    api_super_token: string;
  };
  session: {
    max_age: number;
  };
  security: {
    rate_limit: {
      auth_requests_per_minute: number;
      browse_requests_per_minute: number;
    };
  };
}

let config: Config | null = null;

export function getConfig(): Config {
  if (config) return config;

  const configPath = path.join(process.cwd(), 'config.yaml');
  const fileContents = fs.readFileSync(configPath, 'utf8');
  config = yaml.load(fileContents) as Config;
  
  return config;
}

export function getSessionSecret(): string {
  const secret = process.env.PORTAL_SESSION_SECRET;
  if (!secret) {
    throw new Error('PORTAL_SESSION_SECRET environment variable is required');
  }
  return secret;
}
