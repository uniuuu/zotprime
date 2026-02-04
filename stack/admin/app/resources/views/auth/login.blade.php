@extends('layout')

@section('title', 'Login - ZotPrime Admin')

@section('content')
<div class="min-h-screen flex items-center justify-center">
    <div class="max-w-md w-full space-y-8">
        <div>
            <h2 class="text-center text-3xl font-bold text-primary-600 italic">
                ZotPrime Admin
            </h2>
            <p class="mt-2 text-center text-sm text-gray-600">
                Sign in to manage users and groups
            </p>
        </div>
        <form class="mt-8 space-y-6 bg-white p-8 rounded-lg shadow" method="POST" action="{{ route('login') }}">
            @csrf
            <div class="space-y-4">
                <div>
                    <label for="username" class="block text-sm font-medium text-gray-700">
                        Username
                    </label>
                    <input id="username" name="username" type="text" required
                           class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500">
                </div>
                <div>
                    <label for="password" class="block text-sm font-medium text-gray-700">
                        Password
                    </label>
                    <input id="password" name="password" type="password" required
                           class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500">
                </div>
            </div>

            <div>
                <button type="submit"
                        class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500">
                    Sign in
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
