@extends('layout')

@section('title', 'Group Members - ZotPrime Admin')

@section('content')
<div class="px-4 sm:px-0">
    <div class="flex justify-between items-center">
        <div>
            <a href="{{ route('groups.index') }}" class="text-primary-600 hover:text-primary-800 text-sm mb-2 inline-block">← Back to Groups</a>
            <h3 class="text-2xl font-bold text-primary-600 italic">Group Members</h3>
            <p class="mt-1 text-sm text-gray-600">{{ $groupName ?? 'Group #' . $groupId }}</p>
        </div>
    </div>
</div>

<div class="mt-8 bg-white shadow rounded-lg overflow-hidden">
    <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
            <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User ID</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Username</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
            @forelse($members as $member)
            <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ $member['userID'] }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ $member['username'] }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $member['role'] }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    @if($member['role'] !== 'owner')
                    <form method="POST" action="{{ route('groups.removeMember', [$groupId, $member['userID']]) }}" class="inline">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="text-red-600 hover:text-red-900"
                                onclick="return confirm('Remove this member?')">Remove</button>
                    </form>
                    @endif
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="4" class="px-6 py-4 text-center text-sm text-gray-500 italic">No members found</td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>
@endsection
