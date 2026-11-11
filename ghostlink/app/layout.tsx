// ─────────────────────────────────────────────────────────
// Meva HUD — Root Layout (Mobile & Desktop Shell)
// ─────────────────────────────────────────────────────────

import type { Metadata, Viewport } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Meva HUD — Tactical Esports P2P Command Platform',
  description:
    'Ultra-lightweight P2P WebRTC tactical voice & chat HUD for competitive esports teams.',
  manifest: '/manifest.json',
  icons: {
    icon: '/favicon.ico',
    apple: '/icon-192.png',
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'Meva HUD',
  },
  other: {
    'mobile-web-app-capable': 'yes',
  },
};

export const viewport: Viewport = {
  themeColor: '#0B0708',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: 'cover',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="tr" className="dark">
      <body className="font-sans antialiased bg-[#070607] text-[#EDE8EA] overflow-hidden">
        <div className="flex h-[100dvh] w-screen overflow-hidden">
          {children}
        </div>
      </body>
    </html>
  );
}
