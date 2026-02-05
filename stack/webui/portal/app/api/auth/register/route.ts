import { NextRequest, NextResponse } from 'next/server';
import bcrypt from 'bcrypt';
import { createUser, createApiKey } from '@/lib/api';
import { getSession } from '@/lib/session';

export async function POST(request: NextRequest) {
  try {
    const { username, email, password } = await request.json();

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user in dataserver
    const user = await createUser(username, email, hashedPassword);

    // Create API key for user
    const apiKey = await createApiKey(user.userID, 'Portal Access');

    // Store in session
    const session = await getSession();
    session.userId = user.userID;
    session.username = username;
    session.email = email;
    session.apiKey = apiKey;
    await session.save();

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Registration error:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Registration failed' },
      { status: 500 }
    );
  }
}
