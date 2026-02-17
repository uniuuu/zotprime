<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Redis;
use PragmaRX\Google2FA\Google2FA;
use BaconQrCode\Renderer\ImageRenderer;
use BaconQrCode\Renderer\Image\SvgImageBackEnd;
use BaconQrCode\Renderer\RendererStyle\RendererStyle;
use BaconQrCode\Writer;

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
        
        // Honeypot check
        if ($request->filled('website')) {
            return back()->withErrors(['error' => 'Invalid submission.']);
        }
        
        // Rate limiting
        $config = yaml_parse_file(base_path('../config.yaml'));
        $ip = $request->ip();
        $attempts = Redis::get("rate_limit:$ip") ?? 0;
        
        if ($attempts >= $config['security']['rate_limit']['attempts']) {
            return back()->withErrors(['error' => 'Too many login attempts. Try again in ' . $config['security']['rate_limit']['decay_minutes'] . ' minutes.']);
        }
        
        // Verify credentials
        $username = env('WEBADMIN_USERNAME');
        $hashedPassword = env('WEBADMIN_PASSWORD');
        
        if ($request->username !== $username || !password_verify($request->password, $hashedPassword)) {
            Redis::incr("rate_limit:$ip");
            Redis::expire("rate_limit:$ip", $config['security']['rate_limit']['decay_minutes'] * 60);
            
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
        
        // Check if user has ever successfully authenticated with 2FA
        $has2faCompleted = \DB::table('admin_settings')->where('key', '2fa_completed')->value('value');
        
        // Check if 2FA secret exists in database
        $secret = \DB::table('admin_settings')->where('key', '2fa_secret')->value('value');
        
        if (!$secret) {
            // Generate new secret (first time setup)
            $secret = $this->google2fa->generateSecretKey();
            \DB::table('admin_settings')->insert([
                'key' => '2fa_secret',
                'value' => $secret,
                'created_at' => now(),
                'updated_at' => now()
            ]);
        }
        
        $qrCodeUrl = null;
        if (!$has2faCompleted) {
            // Generate QR code until first successful authentication
            $config = yaml_parse_file(base_path('../config.yaml'));
            $qrCodeUrl = $this->google2fa->getQRCodeUrl(
                $config['security']['2fa']['issuer'],
                $request->session()->get('username'),
                $secret
            );
            
            // Generate QR code image as base64 SVG
            $writer = new Writer(
                new ImageRenderer(
                    new RendererStyle(200),
                    new SvgImageBackEnd()
                )
            );
            $qrCodeSvg = $writer->writeString($qrCodeUrl);
            $qrCodeUrl = 'data:image/svg+xml;base64,' . base64_encode($qrCodeSvg);
        }
        
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
        
        $config = yaml_parse_file(base_path('../config.yaml'));
        $secret = \DB::table('admin_settings')->where('key', '2fa_secret')->value('value');
        $valid = $this->google2fa->verifyKey($secret, $request->code, $config['security']['2fa']['window']);
        
        if (!$valid) {
            return back()->withErrors(['error' => 'Invalid 2FA code.']);
        }
        
        // Mark 2FA as completed
        if (!\DB::table('admin_settings')->where('key', '2fa_completed')->exists()) {
            \DB::table('admin_settings')->insert([
                'key' => '2fa_completed',
                'value' => '1',
                'created_at' => now(),
                'updated_at' => now()
            ]);
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
