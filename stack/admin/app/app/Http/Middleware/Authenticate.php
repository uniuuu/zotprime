<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class Authenticate
{
    public function handle(Request $request, Closure $next)
    {
        if (!$request->session()->get('authenticated')) {
            return redirect()->route('login');
        }
        
        // Check session timeout (30 minutes)
        $lastActivity = $request->session()->get('last_activity', 0);
        if (time() - $lastActivity > 1800) {
            $request->session()->flush();
            return redirect()->route('login')->withErrors(['error' => 'Session expired.']);
        }
        
        // Update last activity
        $request->session()->put('last_activity', time());
        
        return $next($request);
    }
}
