export interface User {
  userID: number;
  username: string;
  email: string;
}

export interface SessionData {
  userId: number;
  username: string;
  email: string;
  apiKey: string;
  totpSecret?: string;
  totpVerified?: boolean;
}

export interface ZoteroGroup {
  id: number;
  version: number;
  data: {
    id: number;
    version: number;
    name: string;
    description?: string;
    type: string;
    owner: number;
  };
}

export interface ZoteroItem {
  key: string;
  version: number;
  library: {
    type: string;
    id: number;
    name: string;
  };
  data: {
    key: string;
    version: number;
    itemType: string;
    title?: string;
    creators?: Array<{
      creatorType: string;
      firstName?: string;
      lastName?: string;
      name?: string;
    }>;
    abstractNote?: string;
    date?: string;
    url?: string;
    tags?: Array<{ tag: string }>;
    [key: string]: any;
  };
}

export interface RegistrationData {
  username: string;
  email: string;
  password: string;
  honeypot?: string;
  captchaToken: string;
}

export interface LoginData {
  username: string;
  password: string;
  captchaToken: string;
}
