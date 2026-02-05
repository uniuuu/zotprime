<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class UserController extends Controller
{
    private function apiCall($method, $endpoint, $data = [])
    {
        $config = yaml_parse_file(base_path('../config.yaml'));
        $url = $config['dataserver']['url'] . $endpoint;
        $token = env('API_SUPER_TOKEN');
        
        $response = Http::timeout($config['dataserver']['timeout'])->withToken($token)->$method($url, $data);
        
        return $response;
    }
    
    public function dashboard()
    {
        return view('dashboard');
    }
    
    public function index()
    {
        $response = $this->apiCall('get', '/admin/users');
        
        if ($response->successful()) {
            $users = $response->json();
        } else {
            $users = [];
            session()->flash('error', 'Failed to fetch users: ' . $response->body());
        }
        
        $config = yaml_parse_file(base_path('../config.yaml'));
        $dataserverUrl = $config['dataserver']['url'];
        
        return view('users.index', compact('users', 'dataserverUrl'));
    }
    
    public function create(Request $request)
    {
        $validated = $request->validate([
            'username' => 'required|string|max:255',
            'email' => 'required|email|max:255',
            'password' => 'required|string|min:8',
        ]);
        
        $response = $this->apiCall('post', '/admin/users', $validated);
        
        if ($response->successful()) {
            return back()->with('success', 'User created successfully!');
        } else {
            return back()->with('error', 'Failed to create user: ' . $response->body());
        }
    }
    
    public function disable(Request $request, $id)
    {
        $response = $this->apiCall('put', "/admin/users/$id/status", ['enabled' => false]);
        
        if ($response->successful()) {
            return back()->with('success', 'User disabled successfully!');
        } else {
            return back()->with('error', 'Failed to disable user: ' . $response->body());
        }
    }
    
    public function enable(Request $request, $id)
    {
        $response = $this->apiCall('put', "/admin/users/$id/status", ['enabled' => true]);
        
        if ($response->successful()) {
            return back()->with('success', 'User enabled successfully!');
        } else {
            return back()->with('error', 'Failed to enable user: ' . $response->body());
        }
    }
    
    public function getQuota($id)
    {
        $response = $this->apiCall('get', "/users/$id/storageadmin");
        
        if ($response->successful()) {
            $xml = simplexml_load_string($response->body());
            return response()->json([
                'success' => true,
                'quota' => (string)$xml->quota ?? 'N/A',
                'usage' => (string)$xml->usage ?? 'N/A',
                'expiration' => (string)$xml->expiration ?? null
            ]);
        } else {
            return response()->json(['success' => false], 500);
        }
    }
    
    public function setQuota(Request $request, $id)
    {
        $validated = $request->validate([
            'quota' => 'required|integer|min:0',
            'expiration' => 'nullable|date',
        ]);
        
        $config = yaml_parse_file(base_path('../config.yaml'));
        $url = $config['dataserver']['url'] . "/users/$id/storageadmin";
        $token = env('API_SUPER_TOKEN');
        
        $response = Http::timeout($config['dataserver']['timeout'])
            ->withToken($token)
            ->asForm()
            ->post($url, [
                'quota' => $validated['quota'],
                'expiration' => $validated['expiration'] ? strtotime($validated['expiration']) : 0,
            ]);
        
        if ($response->successful()) {
            return back()->with('success', 'Quota updated successfully!');
        } else {
            return back()->with('error', 'Failed to update quota: ' . $response->body());
        }
    }
    
    public function destroy($id)
    {
        $response = $this->apiCall('delete', "/admin/users/$id");
        
        if ($response->successful()) {
            return redirect()->route('users.index')->with('success', 'User deleted successfully!');
        } else {
            return back()->with('error', 'Failed to delete user: ' . $response->body());
        }
    }
}
