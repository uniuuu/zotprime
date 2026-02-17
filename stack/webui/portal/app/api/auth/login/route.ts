import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/session';
import { generateTOTPUri, generateQRCode } from '@/lib/totp';
import { getConfig } from '@/lib/config';
import { getTOTPSecret } from '@/lib/db';

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

    // Verify password (dataserver stores MD5 hashes)
    const crypto = require('crypto');
    const passwordHash = crypto.createHash('md5').update(password).digest('hex');
    
    if (user.password !== passwordHash) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }

    // Fetch existing TOTP secret from database
    const totpRecord = await getTOTPSecret(username);
    
    if (!totpRecord) {
      return NextResponse.json({ error: 'TOTP not configured' }, { status: 400 });
    }

    const session = await getSession();
    session.userId = user.userID;
    session.username = user.username;
    session.email = user.email;
    session.totpSecret = totpRecord.secret;
    session.totpVerified = false;
    await session.save();

    // Only return QR code if not yet verified
    if (!totpRecord.verified) {
      const uri = generateTOTPUri(username, totpRecord.secret);
      const qrCode = await generateQRCode(uri);
      return NextResponse.json({ qrCode, secret: totpRecord.secret, showQR: true });
    }

    return NextResponse.json({ showQR: false });
  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json({ error: 'Login failed' }, { status: 500 });
  }
}
