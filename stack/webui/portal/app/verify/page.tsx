'use client';

import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { useRouter } from 'next/navigation';
import Image from 'next/image';

type VerifyFormData = {
  code: string;
};

export default function VerifyPage() {
  const router = useRouter();
  const { register, handleSubmit, formState: { errors } } = useForm<VerifyFormData>();
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [qrCode, setQrCode] = useState('');
  const [secret, setSecret] = useState('');

  useEffect(() => {
    const data = sessionStorage.getItem('totp');
    if (data) {
      const { qrCode, secret } = JSON.parse(data);
      setQrCode(qrCode || '');
      setSecret(secret || '');
    }
  }, []);

  const onSubmit = handleSubmit(async (data) => {
    setLoading(true);
    setError('');

    try {
      const response = await fetch('/api/auth/verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Verification failed');
      }

      sessionStorage.removeItem('totp');
      router.push('/portal');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Verification failed');
    } finally {
      setLoading(false);
    }
  });

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow p-8">
        <h1 className="text-2xl font-bold mb-2 text-gray-900">
          {qrCode ? 'Setup Authenticator' : 'Enter Verification Code'}
        </h1>
        <p className="text-gray-800 mb-6">
          {qrCode 
            ? 'Scan QR code with Google Authenticator or similar app'
            : 'Enter the 6-digit code from your authenticator app'
          }
        </p>

        {qrCode && (
          <div className="mb-6 text-center">
            <Image src={qrCode} alt="QR Code" width={200} height={200} className="mx-auto" />
            <p className="text-xs text-gray-700 mt-2">Secret: {secret}</p>
          </div>
        )}

        {error && (
          <div className="bg-red-50 text-red-600 p-3 rounded mb-4">
            {error}
          </div>
        )}

        <form onSubmit={onSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1 text-gray-900">Enter 6-digit code</label>
            <input
              {...register('code', {
                required: 'Code is required',
                pattern: { value: /^\d{6}$/, message: 'Must be 6 digits' },
              })}
              className="w-full border rounded px-3 py-2 text-center text-2xl tracking-widest font-mono text-gray-900"
              maxLength={6}
              placeholder="000000"
            />
            {errors.code && (
              <p className="text-red-600 text-sm mt-1">{errors.code.message}</p>
            )}
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Verifying...' : 'Verify'}
          </button>
        </form>
      </div>
    </div>
  );
}
