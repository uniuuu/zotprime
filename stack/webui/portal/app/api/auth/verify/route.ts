import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/session';
import { getUserKeys } from '@/lib/api';
import { verifyTOTP } from '@/lib/totp';
import { markTOTPVerified } from '@/lib/db';

export async function POST(request: NextRequest) {
  try {
    const { code } = await request.json();
    const session = await getSession();

    if (!session.totpSecret || session.totpVerified) {
      return NextResponse.json({ error: 'No verification pending' }, { status: 400 });
    }

    if (!verifyTOTP(session.totpSecret, code)) {
      return NextResponse.json({ error: 'Invalid code' }, { status: 400 });
    }

    const apiKey = await getUserKeys(session.userId!);
    if (!apiKey) {
      return NextResponse.json({ error: 'No API key found' }, { status: 500 });
    }

    // Mark TOTP as verified in database
    await markTOTPVerified(session.username!);

    session.apiKey = apiKey;
    session.totpVerified = true;
    await session.save();

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Verification error:', error);
    return NextResponse.json({ error: 'Verification failed' }, { status: 500 });
  }
}
