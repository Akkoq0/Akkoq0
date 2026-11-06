// ─────────────────────────────────────────────────────────
// Meva HUD — Root Layout (Mobile & Desktop Shell)
// ─────────────────────────────────────────────────────────

import type { Metadata, Viewport } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Meva HUD — Tactical Esports P2P Command Platform',
  description:
    'Ultra-lightweight P2P WebRTC tactical voice & chat HUD for competitive esports teams.',
  icons: { icon: '/favicon.ico' },
};

export const viewport: Viewport = {
  themeColor: '#050608',
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
      <body className="font-sans antialiased bg-[#050608] text-[#F3F4F6] selection:bg-gl-accent selection:text-white overflow-hidden">
        <div className="flex h-[100dvh] w-screen overflow-hidden">
          {children}
        </div>
      </body>
    </html>
  );
}
