/** @type {import('next').NextConfig} */
const isStaticExport = process.env.NEXT_EXPORT === 'true';

const securityHeaders = [
  { key: 'X-DNS-Prefetch-Control', value: 'on' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), geolocation=(), payment=(), usb=(), microphone=(self)',
  },
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=63072000; includeSubDomains; preload',
  },
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: blob: https:",
      "media-src 'self' blob: mediastream:",
      "connect-src 'self' https://*.supabase.co wss://*.supabase.co",
      "font-src 'self' data:",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      "frame-ancestors 'none'",
    ].join('; '),
  },
];

const nextConfig = {
  output: isStaticExport ? 'export' : undefined,
  images: { unoptimized: true },
  poweredByHeader: false,
  reactStrictMode: true,
  experimental: {
    optimizePackageImports: ['@supabase/supabase-js', 'zustand', 'clsx'],
  },
  ...(isStaticExport
    ? {}
    : {
        async headers() {
          return [
            {
              source: '/:path*',
              headers: securityHeaders,
            },
          ];
        },
      }),
};

module.exports = nextConfig;
