import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/session';
import { getItem } from '@/lib/api';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const session = await requireAuth();
    
    // Parse groupId and itemKey from id (format: groupId:itemKey)
    const [groupId, itemKey] = id.split(':');
    
    if (!groupId || !itemKey) {
      return NextResponse.json({ error: 'Invalid item ID format' }, { status: 400 });
    }
    
    const item = await getItem(parseInt(groupId), itemKey, session.apiKey);
    return NextResponse.json(item);
  } catch (error) {
    console.error('Get item error:', error);
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }
}
