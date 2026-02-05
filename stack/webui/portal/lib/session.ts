import { getIronSession, IronSession } from 'iron-session';
import { cookies } from 'next/headers';
import { SessionData } from '@/types';
import { getConfig, getSessionSecret } from './config';

export async function getSession(): Promise<IronSession<SessionData>> {
  const config = getConfig();
  
  return getIronSession<SessionData>(await cookies(), {
    password: getSessionSecret(),
    cookieName: 'zotprime_session',
    cookieOptions: {
      secure: process.env.NODE_ENV === 'production',
      httpOnly: true,
      sameSite: 'lax',
      maxAge: config.session.max_age,
    },
  });
}

export async function requireAuth(): Promise<SessionData> {
  const session = await getSession();
  
  if (!session.userId || !session.apiKey) {
    throw new Error('Unauthorized');
  }
  
  return session as SessionData;
}
