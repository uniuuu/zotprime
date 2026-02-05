@extends('layout')

@section('title', 'Items - ZotPrime Admin')

@section('content')
<div class="px-4 sm:px-0">
    <div class="flex justify-between items-center">
        <div>
            <a href="/" class="text-primary-600 hover:text-primary-800 text-sm mb-2 inline-block">← Back to Dashboard</a>
            <h3 class="text-2xl font-bold text-primary-600 italic">Items</h3>
            <p class="mt-1 text-sm text-gray-600">Browse and publish items to groups</p>
        </div>
    </div>
</div>

<div class="mt-8 bg-white shadow rounded-lg overflow-hidden">
    <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
            <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Key</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Title</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Owner</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
            @forelse($items as $item)
            <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-900">{{ $item['key'] }}</td>
                <td class="px-6 py-4 text-sm text-gray-900">{{ $item['title'] ?? 'Untitled' }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $item['itemType'] ?? 'N/A' }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ $item['createdByUserID'] ?? 'N/A' }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <button onclick="openPublishModal('{{ $item['key'] }}')"
                            class="text-primary-600 hover:text-primary-900">Publish to Group</button>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500 italic">No items found</td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>

<!-- Publish Modal -->
<div id="publishModal" class="hidden fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full">
    <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-medium text-primary-600 italic">Publish Item</h3>
            <button onclick="document.getElementById('publishModal').classList.add('hidden')" class="text-gray-400 hover:text-gray-600">✕</button>
        </div>
        <form id="publishForm" method="POST" action="{{ route('items.publish') }}" class="space-y-4">
            @csrf
            <input type="hidden" name="item_key" id="itemKey">
            <div>
                <label class="block text-sm font-medium text-gray-700">Group</label>
                <select name="group_id" required class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md">
                    <option value="">Select a group...</option>
                    @foreach($groups as $group)
                    <option value="{{ $group['id'] }}">{{ $group['name'] }}</option>
                    @endforeach
                </select>
            </div>
            <button type="submit" class="w-full px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700">Publish</button>
        </form>
    </div>
</div>

<script>
function openPublishModal(itemKey) {
    document.getElementById('itemKey').value = itemKey;
    document.getElementById('publishModal').classList.remove('hidden');
}
</script>
@endsection
