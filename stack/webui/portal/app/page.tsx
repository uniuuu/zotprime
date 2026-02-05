import Link from 'next/link';

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col">
      <header className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          {/* <h1 className="text-2xl font-bold">ZotPrime</h1> */}
          <nav className="space-x-4">
            <Link href="/login" className="text-blue-600 hover:underline">
              Login
            </Link>
            <Link href="/register" className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">
              Register
            </Link>
          </nav>
        </div>
      </header>

      <main className="flex-1 flex items-center justify-center bg-gray-50">
        <div className="text-center max-w-2xl px-4">
          <h2 className="text-4xl font-bold mb-4">Research Library Portal</h2>
          <p className="text-xl text-gray-700 mb-8">
            Browse and access published research materials from our institutional repository.
          </p>
          <div className="space-x-4">
            <Link
              href="/register"
              className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700"
            >
              Get Started
            </Link>
            <Link
              href="/login"
              className="inline-block border border-gray-300 px-6 py-3 rounded-lg hover:bg-gray-100"
            >
              Sign In
            </Link>
          </div>
        </div>
      </main>
    </div>
  );
}
