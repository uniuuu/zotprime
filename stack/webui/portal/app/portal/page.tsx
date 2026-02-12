import { redirect } from 'next/navigation';
import { getSession } from '@/lib/session';
import { getUserGroups, getGroupItems } from '@/lib/api';
import Link from 'next/link';

async function getGroupsWithItems() {
  const session = await getSession();
  
  if (!session.apiKey) {
    redirect('/login');
  }

  const groups = await getUserGroups(session.userId, session.apiKey);
  
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
  
  return groupsWithItems;
}

export default async function PortalPage() {
  const session = await getSession();
  
  if (!session.apiKey) {
    redirect('/login');
  }

  const groupsWithItems = await getGroupsWithItems();

  const handleLogout = async () => {
    'use server';
    const session = await getSession();
    session.destroy();
    redirect('/');
  };

  return (
    <div className="min-h-screen flex flex-col">
      <header className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900">ZotPrime Portal</h1>
          <div className="flex items-center gap-4">
            <span className="text-gray-800">Welcome, {session.username}</span>
            <form action={handleLogout}>
              <button className="text-blue-600 hover:underline">
                Logout
              </button>
            </form>
          </div>
        </div>
      </header>

      <main className="flex-1 bg-gray-50 py-8">
        <div className="max-w-7xl mx-auto px-4">
          <h2 className="text-3xl font-bold mb-6 text-gray-900">Your Groups</h2>

          {groupsWithItems.length === 0 ? (
            <div className="bg-white rounded-lg shadow p-8 text-center text-gray-800">
              <p className="mb-2">You are not a member of any groups yet.</p>
              <p className="text-sm">Contact your administrator to be added to research groups.</p>
            </div>
          ) : (
            <div className="space-y-8">
              {groupsWithItems.map((groupData: any) => (
                <div key={groupData.group.id} className="bg-white rounded-lg shadow p-6">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-2xl font-bold text-gray-900">{groupData.group.name}</h3>
                    <span className="text-sm text-gray-700 bg-gray-100 px-3 py-1 rounded">
                      {groupData.group.type}
                    </span>
                  </div>

                  {groupData.items.length === 0 ? (
                    <p className="text-gray-700 text-center py-4">No items in this group yet.</p>
                  ) : (
                    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                      {groupData.items.map((item: any) => (
                        <Link
                          key={item.key}
                          href={`/portal/item/${groupData.group.id}:${item.key}`}
                          className="border rounded-lg p-4 hover:shadow-md transition"
                        >
                          <h4 className="font-semibold text-lg mb-2 line-clamp-2">
                            {item.data.title || 'Untitled'}
                          </h4>
                          
                          {item.data.creators && item.data.creators.length > 0 && (
                            <p className="text-gray-800 text-sm mb-2 line-clamp-1">
                              {item.data.creators.map((c: any) => 
                                c.name || `${c.firstName} ${c.lastName}`
                              ).join(', ')}
                            </p>
                          )}

                          <div className="flex items-center gap-2 text-sm text-gray-700">
                            <span className="bg-gray-100 px-2 py-1 rounded text-xs">
                              {item.data.itemType}
                            </span>
                            {item.data.date && <span className="text-xs">{item.data.date}</span>}
                          </div>
                        </Link>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
