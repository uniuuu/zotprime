@extends('layout')

@section('title', 'Dashboard - ZotPrime Admin')

@section('content')
<div class="px-4 sm:px-0">
    <h3 class="text-2xl font-bold text-primary-600 italic">Dashboard</h3>
    <p class="mt-1 text-sm text-gray-600">Welcome to ZotPrime Admin</p>
</div>

<div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2">
    <a href="{{ route('users.index') }}" class="block p-6 bg-white rounded-lg shadow hover:shadow-md transition">
        <h4 class="text-lg font-semibold text-primary-600">User Management</h4>
        <p class="mt-2 text-sm text-gray-600">Create, list, and manage user accounts and quotas</p>
    </a>

    <a href="{{ route('groups.index') }}" class="block p-6 bg-white rounded-lg shadow hover:shadow-md transition">
        <h4 class="text-lg font-semibold text-primary-600">Group Management</h4>
        <p class="mt-2 text-sm text-gray-600">Create, delete, and manage groups and members</p>
    </a>
</div>
@endsection
