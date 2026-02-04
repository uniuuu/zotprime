<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Redis;
use PragmaRX\Google2FA\Google2FA;

class AuthController extends Controller
{
    private $google2fa;
    
    public function __construct()
    {
        $this->google2fa = new Google2FA();
    }
    
    public function showLogin()
    {
        return view('auth.login');
    }
    
    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);
        
        // Rate limiting
        $ip = $request->ip();
        $attempts = Redis::get("rate_limit:$ip") ?? 0;
        
        if ($attempts >= 5) {
            return back()->withErrors(['error' => 'Too many login attempts. Try again in 15 minutes.']);
        }
        
        // Verify credentials
        $username = env('WEBADMIN_USERNAME');
        $hashedPassword = env('WEBADMIN_PASSWORD');
        
        if ($request->username !== $username || !password_verify($request->password, $hashedPassword)) {
            Redis::incr("rate_limit:$ip");
            Redis::expire("rate_limit:$ip", 900); // 15 minutes
            
            return back()->withErrors(['error' => 'Invalid credentials.']);
        }
        
        // Reset rate limit on successful login
        Redis::del("rate_limit:$ip");
        
        // Store temp session for 2FA
        $request->session()->put('2fa_pending', true);
        $request->session()->put('username', $username);
        
        return redirect()->route('2fa');
    }
    
    public function show2fa(Request $request)
    {
        if (!$request->session()->get('2fa_pending')) {
            return redirect()->route('login');
        }
        
        // Check if 2FA secret exists
        $secret = Redis::get('2fa:secret');
        
        if (!$secret) {
            // Generate new secret
            $secret = $this->google2fa->generateSecretKey();
            Redis::set('2fa:secret', $secret);
        }
        
        // Generate QR code URL
        $qrCodeUrl = $this->google2fa->getQRCodeUrl(
            config('app.name'),
            $request->session()->get('username'),
            $secret
        );
        
        return view('auth.2fa', compact('qrCodeUrl', 'secret'));
    }
    
    public function verify2fa(Request $request)
    {
        $request->validate([
            'code' => 'required|digits:6',
        ]);
        
        if (!$request->session()->get('2fa_pending')) {
            return redirect()->route('login');
        }
        
        $secret = Redis::get('2fa:secret');
        $valid = $this->google2fa->verifyKey($secret, $request->code, 2); // 2 = ±30 seconds tolerance
        
        if (!$valid) {
            return back()->withErrors(['error' => 'Invalid 2FA code.']);
        }
        
        // Create authenticated session
        $request->session()->forget('2fa_pending');
        $request->session()->put('authenticated', true);
        $request->session()->put('last_activity', time());
        
        return redirect()->route('dashboard');
    }
    
    public function logout(Request $request)
    {
        $request->session()->flush();
        return redirect()->route('login');
    }
}
