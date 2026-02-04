<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class GroupController extends Controller
{
    private function apiCall($method, $endpoint, $data = [], $isXml = false)
    {
        $config = yaml_parse_file(base_path('../config.yaml'));
        $url = $config['dataserver']['url'] . $endpoint;
        $token = env('API_SUPER_TOKEN');
        
        $request = Http::withToken($token);
        
        if ($isXml) {
            $request = $request->withHeaders(['Content-Type' => 'application/xml']);
        }
        
        $response = $request->$method($url, $data);
        
        return $response;
    }
    
    public function index()
    {
        $response = $this->apiCall('get', '/groups');
        
        if ($response->successful()) {
            // Parse XML response
            $xml = simplexml_load_string($response->body());
            $groups = json_decode(json_encode($xml), true);
        } else {
            $groups = [];
            session()->flash('error', 'Failed to fetch groups: ' . $response->body());
        }
        
        return view('groups.index', compact('groups'));
    }
    
    public function create(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|in:PublicOpen,PublicClosed,Private',
            'owner_id' => 'required|integer',
        ]);
        
        // Build XML payload
        $xml = '<?xml version="1.0" encoding="UTF-8"?>';
        $xml .= '<group>';
        $xml .= '<name>' . htmlspecialchars($validated['name']) . '</name>';
        $xml .= '<type>' . $validated['type'] . '</type>';
        $xml .= '<owner>' . $validated['owner_id'] . '</owner>';
        $xml .= '</group>';
        
        $response = $this->apiCall('post', '/groups', $xml, true);
        
        if ($response->successful()) {
            return back()->with('success', 'Group created successfully!');
        } else {
            return back()->with('error', 'Failed to create group: ' . $response->body());
        }
    }
    
    public function delete($id)
    {
        $response = $this->apiCall('delete', "/groups/$id");
        
        if ($response->successful()) {
            return back()->with('success', 'Group deleted successfully!');
        } else {
            return back()->with('error', 'Failed to delete group: ' . $response->body());
        }
    }
    
    public function addMember(Request $request, $id)
    {
        $validated = $request->validate([
            'user_id' => 'required|integer',
            'role' => 'required|in:member,admin',
        ]);
        
        // Build XML payload
        $xml = '<?xml version="1.0" encoding="UTF-8"?>';
        $xml .= '<member>';
        $xml .= '<userID>' . $validated['user_id'] . '</userID>';
        $xml .= '<role>' . $validated['role'] . '</role>';
        $xml .= '</member>';
        
        $response = $this->apiCall('put', "/groups/$id/users/{$validated['user_id']}", $xml, true);
        
        if ($response->successful()) {
            return back()->with('success', 'Member added successfully!');
        } else {
            return back()->with('error', 'Failed to add member: ' . $response->body());
        }
    }
    
    public function removeMember($id, $userId)
    {
        $response = $this->apiCall('delete', "/groups/$id/users/$userId");
        
        if ($response->successful()) {
            return back()->with('success', 'Member removed successfully!');
        } else {
            return back()->with('error', 'Failed to remove member: ' . $response->body());
        }
    }
}
