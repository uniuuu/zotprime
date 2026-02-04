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
        
        $response = Http::withToken($token)->$method($url, $data);
        
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
        
        return view('users.index', compact('users'));
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
        $response = $this->apiCall('put', "/admin/users/$id/status", ['status' => 'disabled']);
        
        if ($response->successful()) {
            return back()->with('success', 'User disabled successfully!');
        } else {
            return back()->with('error', 'Failed to disable user: ' . $response->body());
        }
    }
    
    public function enable(Request $request, $id)
    {
        $response = $this->apiCall('put', "/admin/users/$id/status", ['status' => 'enabled']);
        
        if ($response->successful()) {
            return back()->with('success', 'User enabled successfully!');
        } else {
            return back()->with('error', 'Failed to enable user: ' . $response->body());
        }
    }
    
    public function setQuota(Request $request, $id)
    {
        $validated = $request->validate([
            'quota' => 'required|integer|min:0',
            'expiration' => 'nullable|date',
        ]);
        
        $response = $this->apiCall('post', "/users/$id/storageadmin", [
            'quota' => $validated['quota'],
            'expiration' => $validated['expiration'] ?? null,
        ]);
        
        if ($response->successful()) {
            return back()->with('success', 'Quota updated successfully!');
        } else {
            return back()->with('error', 'Failed to update quota: ' . $response->body());
        }
    }
}
