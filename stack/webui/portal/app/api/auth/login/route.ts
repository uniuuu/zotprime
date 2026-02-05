import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/session';
import { generateTOTPSecret, generateTOTPUri, generateQRCode } from '@/lib/totp';
import { getConfig } from '@/lib/config';

export async function POST(request: NextRequest) {
  try {
    const { username, password } = await request.json();

    const config = getConfig();
    const response = await fetch(`${config.dataserver.url}/admin/users`, {
      headers: {
        'Authorization': `Bearer ${config.dataserver.api_super_token}`,
      },
    });

    if (!response.ok) {
      return NextResponse.json({ error: 'Login failed' }, { status: 401 });
    }

    const users = await response.json();
    const user = users.find((u: any) => u.username === username);

    if (!user) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }

    const secret = generateTOTPSecret();
    const uri = generateTOTPUri(username, secret);
    const qrCode = await generateQRCode(uri);

    const session = await getSession();
    session.userId = user.userID;
    session.username = user.username;
    session.email = user.email;
    session.totpSecret = secret;
    session.totpVerified = false;
    await session.save();

    return NextResponse.json({ qrCode, secret });
  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json({ error: 'Login failed' }, { status: 500 });
  }
}
