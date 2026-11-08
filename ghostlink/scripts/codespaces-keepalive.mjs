#!/usr/bin/env node

// ─────────────────────────────────────────────────────────
// Meva HUD — GitHub Codespaces Inactivity & Keep-Alive Daemon
// ─────────────────────────────────────────────────────────
// Prevents GitHub Codespaces from idling or timing out during
// extended autonomous development sessions.
// Features:
// 1. High-frequency (40s) internal HTTP heartbeat to local Next.js server
// 2. Heartbeat file touch with POSIX mtime update
// 3. Graceful error recovery with zero process crash

import http from 'http';
import fs from 'fs';
import path from 'path';

const HEARTBEAT_FILE = '/workspaces/Akkoq0/.codespaces-heartbeat';
const HEALTH_URL = 'http://127.0.0.1:3000/';
const INTERVAL_MS = 40_000; // 40 seconds

let beatCount = 0;

function pingHealth() {
  beatCount++;
  const now = new Date().toISOString();

  // 1. Touch heartbeat file
  try {
    fs.writeFileSync(
      HEARTBEAT_FILE,
      JSON.stringify({
        heartbeat: beatCount,
        lastPing: now,
        status: 'codespaces-active',
        pid: process.pid,
      }, null, 2),
    );
  } catch (err) {
    // Ignore file write errors
  }

  // 2. Perform HTTP ping to keep Next.js event loop active
  http
    .get(HEALTH_URL, (res) => {
      res.resume();
      if (beatCount % 5 === 0) {
        console.log(`[Codespaces Keep-Alive] Beat #${beatCount} — HTTP ${res.statusCode} at ${now}`);
      }
    })
    .on('error', (err) => {
      if (beatCount % 5 === 0) {
        console.log(`[Codespaces Keep-Alive] Beat #${beatCount} — Health check warning: ${err.message} at ${now}`);
      }
    });
}

console.log('[Codespaces Keep-Alive] Starting daemon on PID', process.pid);
pingHealth();
setInterval(pingHealth, INTERVAL_MS);
