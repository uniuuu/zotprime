@extends('layout')

@section('title', '2FA Setup - ZotPrime Admin')

@section('content')
<div class="min-h-screen flex items-center justify-center">
    <div class="max-w-md w-full space-y-8">
        <div>
            <h2 class="text-center text-3xl font-bold text-primary-600 italic">
                Two-Factor Authentication
            </h2>
            <p class="mt-2 text-center text-sm text-gray-600">
                Scan the QR code with Google Authenticator
            </p>
        </div>
        <div class="bg-white p-8 rounded-lg shadow space-y-6">
            <div class="flex justify-center">
                <img src="{{ $qrCodeUrl }}" alt="QR Code" class="border-4 border-primary-100 rounded-lg">
            </div>
            
            <div class="text-center">
                <p class="text-sm text-gray-600 italic">Or enter this secret manually:</p>
                <code class="block mt-2 p-2 bg-gray-100 rounded text-sm font-mono">{{ $secret }}</code>
            </div>

            <form method="POST" action="{{ route('2fa') }}" class="space-y-4">
                @csrf
                <div>
                    <label for="code" class="block text-sm font-medium text-gray-700">
                        Enter 6-digit code
                    </label>
                    <input id="code" name="code" type="text" pattern="[0-9]{6}" maxlength="6" required
                           class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-center text-2xl tracking-widest">
                </div>

                <button type="submit"
                        class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500">
                    Verify
                </button>
            </form>
        </div>
    </div>
</div>
@endsection
