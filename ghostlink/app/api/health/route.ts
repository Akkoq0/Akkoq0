import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  const payload = {
    status: 'healthy',
    service: 'Meva HUD',
    version: '2.5.0',
    protocol: 'WebRTC P2P Mesh + Opus 48kHz',
    uptimeSeconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
    features: {
      audioDsp: true,
      e2eeSecurity: true,
      stratbookStudio: true,
      cleanArchitecture: true,
      gameBoostOptimization: true,
    },
  };

  return NextResponse.json(payload, {
    status: 200,
    headers: {
      'Cache-Control': 'no-store, no-cache, must-revalidate',
      'Content-Type': 'application/json',
    },
  });
}
