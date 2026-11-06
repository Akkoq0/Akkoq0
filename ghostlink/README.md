# GhostLink

**Ultra-lightweight, zero-cost P2P voice & text chat for competitive gamers.**

> Discord alternative built for esports — no server costs, no FPS drops.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      CLIENT (Next.js 14)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Server   │  │ Channel  │  │ Chat     │  │ Voice    │    │
│  │ Sidebar  │  │ Sidebar  │  │ Area     │  │ Panel    │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                       │              │              │         │
│                  Zustand Store (1KB gzipped)                  │
│                       │              │              │         │
│              ┌────────┴──────────────┴──────────────┘         │
│              │                                                │
│  ┌───────────┴───────────┐    ┌─────────────────────────┐    │
│  │ Supabase Client       │    │ WebRTC P2P Mesh         │    │
│  │ (Auth, DB, Realtime)  │    │ (Audio only, Opus 24k)  │    │
│  └───────────┬───────────┘    └──────────┬──────────────┘    │
└──────────────┼───────────────────────────┼───────────────────┘
               │                           │
               ▼                           ▼
   ┌───────────────────┐      ┌─────────────────────────┐
   │ Supabase (Free)   │      │ Direct P2P Connection   │
   │ • Auth             │      │ • STUN: Google (free)   │
   │ • PostgreSQL       │      │ • No SFU/MCU            │
   │ • Realtime         │      │ • No media server       │
   │   (Signaling)      │      │ • $0 voice cost         │
   └───────────────────┘      └─────────────────────────┘
```

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Copy environment variables
cp .env.local.example .env.local
# Fill in your Supabase URL and anon key

# 3. Run the SQL schema in Supabase SQL Editor
# → supabase/schema.sql

# 4. Start development server
npm run dev
```

## Tech Stack

| Layer | Technology | Cost |
|-------|-----------|------|
| Frontend | Next.js 14 (App Router) + TypeScript | $0 (Vercel free) |
| Styling | Tailwind CSS | $0 |
| State | Zustand (~1KB) | $0 |
| Auth | Supabase Auth | $0 (free tier) |
| Database | Supabase PostgreSQL | $0 (free tier) |
| Realtime | Supabase Realtime | $0 (free tier) |
| Voice | WebRTC P2P Mesh | $0 |
| STUN | Google STUN servers | $0 |
| **Total** | | **$0** |

## Project Structure

```
ghostlink/
├── app/
│   ├── layout.tsx           # Root layout (Server Component)
│   ├── page.tsx             # Dashboard (Client Component)
│   ├── globals.css          # Tailwind + global styles
│   └── auth/
│       └── callback/
│           └── page.tsx     # OAuth redirect handler
├── components/
│   ├── layout/
│   │   ├── ServerSidebar.tsx   # Server icon bar
│   │   └── ChannelSidebar.tsx  # Channel list panel
│   ├── chat/
│   │   └── ChatArea.tsx        # Text chat messages + input
│   └── voice/
│       └── VoicePanel.tsx      # Voice participants + controls
├── hooks/
│   ├── useWebRTC.ts         # P2P voice engine
│   ├── useRealtimeChat.ts   # Live text chat
│   └── useAuth.ts           # Authentication
├── lib/
│   ├── supabase.ts          # Browser client (singleton)
│   ├── supabase-server.ts   # Server client (RSC)
│   └── store.ts             # Zustand global state
├── types/
│   └── index.ts             # TypeScript interfaces
└── supabase/
    └── schema.sql           # Database schema + RLS
```

## License

MIT

