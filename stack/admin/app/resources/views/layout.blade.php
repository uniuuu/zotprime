<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'ZotPrime Admin')</title>
    <link href="{{ asset('css/app.css') }}" rel="stylesheet">
</head>
<body class="bg-gray-50">
    @auth
    <nav class="bg-white shadow-sm border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between h-16">
                <div class="flex">
                    <div class="flex-shrink-0 flex items-center">
                        <h1 class="text-xl font-bold text-primary-600 italic">ZotPrime Admin</h1>
                    </div>
                    <div class="hidden sm:ml-8 sm:flex sm:space-x-8">
                        <a href="{{ route('users.index') }}" class="inline-flex items-center px-1 pt-1 text-sm font-medium {{ request()->routeIs('users.*') ? 'text-primary-600 border-b-2 border-primary-600' : 'text-gray-500 hover:text-primary-600' }}">
                            Users
                        </a>
                        <a href="{{ route('groups.index') }}" class="inline-flex items-center px-1 pt-1 text-sm font-medium {{ request()->routeIs('groups.*') ? 'text-primary-600 border-b-2 border-primary-600' : 'text-gray-500 hover:text-primary-600' }}">
                            Groups
                        </a>
                    </div>
                </div>
                <div class="flex items-center">
                    <form method="POST" action="{{ route('logout') }}">
                        @csrf
                        <button type="submit" class="text-sm text-gray-500 hover:text-primary-600">
                            Logout
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </nav>
    @endauth

    <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        @if(session('success'))
        <div class="mb-4 bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded">
            {{ session('success') }}
        </div>
        @endif

        @if(session('error'))
        <div class="mb-4 bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded">
            {{ session('error') }}
        </div>
        @endif

        @if($errors->any())
        <div class="mb-4 bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded">
            <ul class="list-disc list-inside">
                @foreach($errors->all() as $error)
                <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
        @endif

        @yield('content')
    </main>

    <script>
        // Auto-hide success messages after 5 seconds
        setTimeout(() => {
            document.querySelectorAll('.bg-green-50').forEach(el => el.remove());
        }, 5000);
    </script>
</body>
</html>
