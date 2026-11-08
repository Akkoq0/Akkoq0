import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  return NextResponse.json({
    status: 'alive',
    platform: 'Meva HUD Enterprise Esports Platform',
    uptime: Math.round(process.uptime()),
    timestamp: Date.now(),
    keepAlive: true,
  });
}
