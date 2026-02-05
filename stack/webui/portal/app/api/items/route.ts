import { NextResponse } from 'next/server';
import { requireAuth } from '@/lib/session';
import { getUserGroups, getGroupItems } from '@/lib/api';

export async function GET() {
  try {
    const session = await requireAuth();
    
    // Get user's groups
    const groups = await getUserGroups(session.userId, session.apiKey);
    
    // Fetch items from all groups
    const groupsWithItems = await Promise.all(
      groups.map(async (group: any) => {
        try {
          const items = await getGroupItems(group.id, session.apiKey);
          return {
            group: {
              id: group.id,
              name: group.data.name,
              type: group.data.type,
            },
            items,
          };
        } catch (error) {
          console.error(`Failed to fetch items for group ${group.id}:`, error);
          return {
            group: {
              id: group.id,
              name: group.data.name,
              type: group.data.type,
            },
            items: [],
          };
        }
      })
    );
    
    return NextResponse.json(groupsWithItems);
  } catch (error) {
    console.error('Get items error:', error);
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
}
