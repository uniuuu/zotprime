import { redirect } from 'next/navigation';
import { getSession } from '@/lib/session';
import Link from 'next/link';

async function getItemData(itemId: string) {
  const session = await getSession();
  
  if (!session.apiKey) {
    redirect('/login');
  }

  const response = await fetch(`http://localhost:3000/api/items/${itemId}`, {
    cache: 'no-store',
  });

  if (!response.ok) return null;
  return response.json();
}

export default async function ItemDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const item = await getItemData(id);

  if (!item) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">Item Not Found</h1>
          <Link href="/portal" className="text-blue-600 hover:underline">
            Back to Portal
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <Link href="/portal" className="text-blue-600 hover:underline">
            ← Back to Portal
          </Link>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-8">
        <article className="bg-white rounded-lg shadow p-8">
          <div className="mb-4 flex items-center gap-2">
            <span className="bg-gray-100 px-3 py-1 rounded text-sm">
              {item.data.itemType}
            </span>
            {item.library && (
              <span className="text-sm text-gray-700">
                in {item.library.name}
              </span>
            )}
          </div>

          <h1 className="text-3xl font-bold mb-4">
            {item.data.title || 'Untitled'}
          </h1>

          {item.data.creators && item.data.creators.length > 0 && (
            <div className="mb-4">
              <h2 className="font-semibold text-gray-700 mb-2">Authors</h2>
              <p className="text-gray-800">
                {item.data.creators.map((c: any) => 
                  c.name || `${c.firstName} ${c.lastName}`
                ).join(', ')}
              </p>
            </div>
          )}

          {item.data.date && (
            <div className="mb-4">
              <h2 className="font-semibold text-gray-700 mb-2">Date</h2>
              <p className="text-gray-800">{item.data.date}</p>
            </div>
          )}

          {item.data.abstractNote && (
            <div className="mb-4">
              <h2 className="font-semibold text-gray-700 mb-2">Abstract</h2>
              <p className="text-gray-800 whitespace-pre-wrap">
                {item.data.abstractNote}
              </p>
            </div>
          )}

          {item.data.url && (
            <div className="mb-4">
              <h2 className="font-semibold text-gray-700 mb-2">URL</h2>
              <a
                href={item.data.url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:underline break-all"
              >
                {item.data.url}
              </a>
            </div>
          )}

          {item.data.tags && item.data.tags.length > 0 && (
            <div className="mb-4">
              <h2 className="font-semibold text-gray-700 mb-2">Tags</h2>
              <div className="flex flex-wrap gap-2">
                {item.data.tags.map((tag: any, idx: number) => (
                  <span
                    key={idx}
                    className="bg-blue-50 text-blue-700 px-3 py-1 rounded-full text-sm"
                  >
                    {tag.tag}
                  </span>
                ))}
              </div>
            </div>
          )}
        </article>
      </main>
    </div>
  );
}
