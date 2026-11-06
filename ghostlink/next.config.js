/** @type {import('next').NextConfig} */
const nextConfig = {
  output: process.env.NEXT_EXPORT === 'true' ? 'export' : undefined,
  images: { unoptimized: true },
  reactStrictMode: false,
  experimental: {
    optimizePackageImports: ['@supabase/supabase-js', 'zustand'],
  },
};

module.exports = nextConfig;
