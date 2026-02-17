@extends('layout')

@section('title', 'Users - ZotPrime Admin')

@section('content')
<div class="px-4 sm:px-0">
    <div class="flex justify-between items-center">
        <div>
            <a href="/" class="text-primary-600 hover:text-primary-800 text-sm mb-2 inline-block">← Back to Dashboard</a>
            <h3 class="text-2xl font-bold text-primary-600 italic">Users</h3>
            <p class="mt-1 text-sm text-gray-600">Manage user accounts and quotas</p>
        </div>
        <button onclick="document.getElementById('createModal').classList.remove('hidden')"
                class="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700">
            Create User
        </button>
    </div>
</div>

<div class="mt-8 bg-white shadow rounded-lg overflow-hidden">
    <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
            <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Username</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
            @forelse($users as $user)
            <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ $user['id'] ?? $user['userID'] }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ $user['username'] }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $user['email'] }}</td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                        active
                    </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                    <button onclick="openQuotaModal({{ $user['id'] ?? $user['userID'] }})"
                            class="text-primary-600 hover:text-primary-900">Manage Quota</button>
                    {{-- Disable/Enable commented out - Zotero only supports active/deleted states
                    @if($user['enabled'] ?? true)
                    <form method="POST" action="{{ route('users.disable', $user['id'] ?? $user['userID']) }}" class="inline">
                        @csrf
                        <button type="submit" class="text-yellow-600 hover:text-yellow-900"
                                onclick="return confirm('Disable this user?')">Disable</button>
                    </form>
                    @else
                    <form method="POST" action="{{ route('users.enable', $user['id'] ?? $user['userID']) }}" class="inline">
                        @csrf
                        <button type="submit" class="text-green-600 hover:text-green-900">Enable</button>
                    </form>
                    @endif
                    --}}
                    <form method="POST" action="{{ route('users.destroy', $user['id'] ?? $user['userID']) }}" class="inline">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="text-red-600 hover:text-red-900"
                                onclick="return confirm('Are you sure you want to DELETE this user? This cannot be undone!')">Delete</button>
                    </form>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500 italic">No users found</td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>

<!-- Create User Modal -->
<div id="createModal" class="hidden fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full">
    <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-medium text-primary-600 italic">Create User</h3>
            <button onclick="document.getElementById('createModal').classList.add('hidden')" class="text-gray-400 hover:text-gray-600">✕</button>
        </div>
        <form method="POST" action="{{ route('users.create') }}" class="space-y-4">
            @csrf
            <div>
                <label class="block text-sm font-medium text-gray-700">Username</label>
                <input type="text" name="username" required class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Email</label>
                <input type="email" name="email" required class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Password</label>
                <input type="password" name="password" required minlength="8" class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md">
            </div>
            <button type="submit" class="w-full px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700">Create</button>
        </form>
    </div>
</div>

<!-- Set Quota Modal -->
<div id="quotaModal" class="hidden fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full">
    <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-medium text-primary-600 italic">Set Quota</h3>
            <button onclick="document.getElementById('quotaModal').classList.add('hidden')" class="text-gray-400 hover:text-gray-600">✕</button>
        </div>
        <div id="quotaInfo" class="mb-4 p-3 bg-gray-50 rounded text-sm">
            <div class="flex justify-center">
                <span class="text-gray-500">Loading quota...</span>
            </div>
        </div>
        <form id="quotaForm" method="POST" class="space-y-4">
            @csrf
            <div>
                <label class="block text-sm font-medium text-gray-700">Quota (MB)</label>
                <input type="number" name="quota" id="quotaInput" required min="0" class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700">Expiration (optional)</label>
                <input type="date" name="expiration" class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md">
            </div>
            <button type="submit" class="w-full px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700">Update Quota</button>
        </form>
    </div>
</div>

<script>
async function openQuotaModal(userId) {
    document.getElementById('quotaForm').action = `/users/${userId}/quota`;
    document.getElementById('quotaModal').classList.remove('hidden');
    
    // Fetch current quota
    const quotaInfo = document.getElementById('quotaInfo');
    quotaInfo.innerHTML = '<div class="flex justify-center"><span class="text-gray-500">Loading quota...</span></div>';
    
    try {
        const response = await fetch(`/users/${userId}/quota-info`);
        const data = await response.json();
        
        if (data.success) {
            let expirationText = (data.expiration && data.expiration > 0) ? `Expires: ${new Date(data.expiration * 1000).toLocaleDateString()}` : 'Never expires';
            quotaInfo.innerHTML = `<div class="text-gray-700">
                <div><strong>Current:</strong> ${data.usage} MB used / ${data.quota} MB total</div>
                <div class="text-sm text-gray-600 mt-1">${expirationText}</div>
            </div>`;
            document.getElementById('quotaInput').value = data.quota;
        } else {
            quotaInfo.innerHTML = '<div class="text-red-600">Failed to load quota</div>';
        }
    } catch (e) {
        quotaInfo.innerHTML = '<div class="text-red-600">Failed to load quota</div>';
    }
}
</script>
@endsection
