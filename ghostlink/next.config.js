/** @type {import('next').NextConfig} */
const isStaticExport = process.env.NEXT_EXPORT === 'true';
const isProd = process.env.NODE_ENV === 'production';

function buildConnectSrc() {
  const sources = new Set([
    "'self'",
    'https://*.supabase.co',
    'wss://*.supabase.co',
    'wss://broker.emqx.io:8084',
    'wss://broker.hivemq.com:8884',
    'wss:',
    'ws:',
  ]);
  if (!isProd) {
    sources.add('ws:');
    sources.add('wss:');
  }
  const rawUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (rawUrl) {
    try {
      const parsed = new URL(rawUrl.trim());
      if (
        parsed.protocol === 'https:' &&
        !/(placeholder|your-project|ornek-proje|example)/i.test(parsed.hostname)
      ) {
        sources.add(parsed.origin);
        sources.add(`wss://${parsed.host}`);
      }
    } catch {
      // Ignore invalid env URL
    }
  }
  return `connect-src ${Array.from(sources).join(' ')}`;
}

const scriptSrc = isProd
  ? "script-src 'self' 'unsafe-inline'"
  : "script-src 'self' 'unsafe-inline' 'unsafe-eval'";

const cspDirectives = [
  "default-src 'self'",
  scriptSrc,
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob: https:",
  "media-src 'self' blob: mediastream:",
  buildConnectSrc(),
  "font-src 'self' data:",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  ...(isProd ? ["frame-ancestors 'none'"] : []),
];

const securityHeaders = [
  { key: 'X-DNS-Prefetch-Control', value: 'on' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  ...(isProd ? [{ key: 'X-Frame-Options', value: 'DENY' }] : []),
  { key: 'Cross-Origin-Opener-Policy', value: 'same-origin' },
  { key: 'X-Permitted-Cross-Domain-Policies', value: 'none' },
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
    value: cspDirectives.join('; '),
  },
];

const nextConfig = {
  output: isStaticExport ? 'export' : undefined,
  images: { unoptimized: true },
  poweredByHeader: false,
  reactStrictMode: true,
  swcMinify: true,
  compiler: {
    removeConsole: isProd ? { exclude: ['error', 'warn'] } : false,
  },
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
