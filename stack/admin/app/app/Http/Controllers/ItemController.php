<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class ItemController extends Controller
{
    private function apiCall($method, $endpoint, $data = [], $isXml = false, $isJson = false)
    {
        $config = yaml_parse_file(base_path('../config.yaml'));
        $url = $config['dataserver']['url'] . $endpoint;
        $token = env('API_SUPER_TOKEN');
        
        $request = Http::timeout($config['dataserver']['timeout'])->withToken($token);
        
        if ($isXml) {
            $request = $request->withHeaders(['Content-Type' => 'application/xml'])->withBody($data, 'application/xml');
            $response = $request->send($method, $url);
        } elseif ($isJson) {
            $response = $request->withHeaders(['Content-Type' => 'application/json'])->send($method, $url, ['body' => json_encode($data)]);
        } else {
            $response = $request->$method($url, $data);
        }
        
        return $response;
    }
    
    public function index()
    {
        $response = $this->apiCall('get', '/admin/items');
        
        if ($response->successful()) {
            $items = $response->json();
        } else {
            $items = [];
            session()->flash('error', 'Failed to fetch items: ' . $response->body());
        }
        
        // Fetch groups for dropdown
        $groupsResponse = $this->apiCall('get', '/admin/groups');
        $groups = $groupsResponse->successful() ? $groupsResponse->json() : [];
        
        return view('items.index', compact('items', 'groups'));
    }
    
    public function publish(Request $request)
    {
        $validated = $request->validate([
            'item_key' => 'required|string',
            'group_id' => 'required|integer',
        ]);
        
        // Get current library ID from item key
        $itemsResponse = $this->apiCall('get', '/admin/items');
        if (!$itemsResponse->successful()) {
            return back()->with('error', 'Failed to fetch items');
        }
        
        $items = $itemsResponse->json();
        $sourceItem = collect($items)->firstWhere('key', $validated['item_key']);
        
        if (!$sourceItem) {
            return back()->with('error', 'Item not found');
        }
        
        // Fetch full item JSON from source library
        $libraryID = $sourceItem['libraryID'] ?? 1;
        $itemJson = $this->apiCall('get', "/users/{$libraryID}/items/{$validated['item_key']}");
        
        if (!$itemJson->successful()) {
            return back()->with('error', 'Failed to fetch item data');
        }
        
        $itemData = $itemJson->json();
        
        // Remove fields that shouldn't be copied
        unset($itemData['key']);
        unset($itemData['version']);
        unset($itemData['library']);
        unset($itemData['links']);
        unset($itemData['meta']);
        
        // POST as JSON array to group
        $response = $this->apiCall('post', "/groups/{$validated['group_id']}/items", [$itemData], false, true);
        
        if ($response->successful()) {
            return back()->with('success', 'Item published to group successfully!');
        } else {
            return back()->with('error', 'Failed to publish item: ' . $response->body());
        }
    }
}
