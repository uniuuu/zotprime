@extends('layout')

@section('title', 'Groups - ZotPrime Admin')

@section('content')
<div class="px-4 sm:px-0">
    <div class="flex justify-between items-center">
        <div>
            <a href="/" class="text-primary-600 hover:text-primary-800 text-sm mb-2 inline-block">← Back to Dashboard</a>
            <h3 class="text-2xl font-bold text-primary-600 italic">Groups</h3>
            <p class="mt-1 text-sm text-gray-600">Manage groups and members</p>
        </div>
        <button onclick="document.getElementById('createModal').classList.remove('hidden')"
                class="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700">
            Create Group
        </button>
    </div>
</div>

<div class="mt-8 bg-white shadow rounded-lg overflow-hidden">
    <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
            <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Owner</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
            @forelse($groups as $group)
            <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ $group['id'] }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ $group['name'] }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $group['type'] }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $group['owner'] ?? 'N/A' }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                    <button onclick="window.location.href='{{ route('groups.members', $group['id']) }}'"
                            class="px-3 py-1 bg-primary-600 text-white rounded hover:bg-primary-700 text-xs">View Members</button>
                    <button onclick="openMemberModal({{ $group['id'] }})"
                            class="px-3 py-1 bg-primary-600 text-white rounded hover:bg-primary-700 text-xs">Add Member</button>
                    <form method="POST" action="{{ route('groups.delete', $group['id']) }}" class="inline">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700 text-xs"
                                onclick="return confirm('PERMANENTLY DELETE this group? This cannot be undone!')">Delete</button>
                    </form>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500 italic">No groups found</td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>

<!-- Create Group Modal -->
<div id="createModal" class="hidden fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full">
    <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-medium text-primary-600 italic">Create Group</h3>
            <button onclick="document.getElementById('createModal').classList.add('hidden')" class="text-gray-400 hover:text-gray-600">✕</button>
        </div>
        <form method="POST" action="{{ route('groups.create') }}" class="space-y-4">
            @csrf
            <div>
                <label class="block text-sm font-medium text-gray-700">Group Name</label>
                <input type="text" name="name" required class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Type</label>
                <select name="type" required class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md">
                    <option value="PublicOpen">Public Open</option>
                    <option value="PublicClosed">Public Closed</option>
                    <option value="Private">Private</option>
                </select>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Owner</label>
                <select name="owner_id" required class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md">
                    <option value="">Select owner...</option>
                    @foreach($users as $user)
                    <option value="{{ $user['userID'] }}">{{ $user['username'] }} ({{ $user['email'] }})</option>
                    @endforeach
                </select>
            </div>
            <button type="submit" class="w-full px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700">Create</button>
        </form>
    </div>
</div>

<!-- Add Member Modal -->
<div id="memberModal" class="hidden fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full">
    <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-medium text-primary-600 italic">Add Member</h3>
            <button onclick="document.getElementById('memberModal').classList.add('hidden')" class="text-gray-400 hover:text-gray-600">✕</button>
        </div>
        <form id="memberForm" method="POST" class="space-y-4">
            @csrf
            <div>
                <label class="block text-sm font-medium text-gray-700">User</label>
                <select name="user_id" required class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md">
                    <option value="">Select a user...</option>
                    @foreach($users as $user)
                    <option value="{{ $user['userID'] }}">{{ $user['username'] }} ({{ $user['email'] }})</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Role</label>
                <select name="role" required class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md">
                    <option value="member">Member</option>
                    <option value="admin">Admin</option>
                </select>
            </div>
            <button type="submit" class="w-full px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700">Add Member</button>
        </form>
    </div>
</div>

<script>
function openMemberModal(groupId) {
    document.getElementById('memberForm').action = `/groups/${groupId}/members`;
    document.getElementById('memberModal').classList.remove('hidden');
}
</script>
@endsection
