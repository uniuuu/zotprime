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
        
        $request = Http::timeout($config['dataserver']['timeout'])->withToken($token);
        
        if ($isXml) {
            $request = $request->withHeaders(['Content-Type' => 'application/xml'])->withBody($data, 'application/xml');
            $response = $request->send($method, $url);
        } else {
            $response = $request->$method($url, $data);
        }
        
        return $response;
    }
    
    public function index()
    {
        $response = $this->apiCall('get', '/admin/groups');
        
        if ($response->successful()) {
            $groups = $response->json();
        } else {
            $groups = [];
            session()->flash('error', 'Failed to fetch groups: ' . $response->body());
        }
        
        // Fetch users for dropdown
        $usersResponse = $this->apiCall('get', '/admin/users');
        $users = $usersResponse->successful() ? $usersResponse->json() : [];
        
        return view('groups.index', compact('groups', 'users'));
    }
    
    public function create(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|in:PublicOpen,PublicClosed,Private',
            'owner_id' => 'required|integer',
        ]);
        
        // Build XML payload with default permissions (from test suite defaults)
        $xml = '<group name="' . htmlspecialchars($validated['name']) . '" '
             . 'type="' . $validated['type'] . '" '
             . 'owner="' . $validated['owner_id'] . '" '
             . 'libraryEditing="members" '
             . 'libraryReading="members" '
             . 'fileEditing="none"/>';
        
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
        
        $xml = '<user id="' . $validated['user_id'] . '" role="' . $validated['role'] . '"/>';
        
        $response = $this->apiCall('put', "/groups/$id/users/{$validated['user_id']}", $xml, true);
        
        if ($response->successful()) {
            return back()->with('success', 'Member added successfully!');
        } else {
            return back()->with('error', 'Failed to add member: ' . $response->body());
        }
    }
    
    public function members($id)
    {
        $response = $this->apiCall('get', "/groups/$id/users");
        
        if ($response->successful()) {
            $xml = simplexml_load_string($response->body());
            $xml->registerXPathNamespace('atom', 'http://www.w3.org/2005/Atom');
            $xml->registerXPathNamespace('xfer', 'http://zotero.org/ns/transfer');
            
            $members = [];
            $users_xml = $xml->xpath('//xfer:user');
            
            foreach ($users_xml as $user) {
                $userId = (string)$user['id'];
                $role = (string)$user['role'];
                $members[] = [
                    'userID' => $userId,
                    'role' => $role,
                    'username' => 'User ' . $userId
                ];
            }
            
            // Fetch usernames
            $usersResponse = $this->apiCall('get', '/admin/users');
            if ($usersResponse->successful()) {
                $users = $usersResponse->json();
                foreach ($members as &$member) {
                    foreach ($users as $user) {
                        if ($user['userID'] == $member['userID']) {
                            $member['username'] = $user['username'];
                            break;
                        }
                    }
                }
            }
        } else {
            $members = [];
            session()->flash('error', 'Failed to fetch members: ' . $response->body());
        }
        
        $groupId = $id;
        return view('groups.members', compact('members', 'groupId'));
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
